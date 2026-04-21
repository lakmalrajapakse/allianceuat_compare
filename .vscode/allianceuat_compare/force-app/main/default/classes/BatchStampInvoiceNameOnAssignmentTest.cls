@isTest(SeeAllData=true)
private class BatchStampInvoiceNameOnAssignmentTest {

    // ─── Helpers ─────────────────────────────────────────────────────────────

    /**
     * Returns an active Assignment that:
     *   - has a Rate Calculator
     *   - has blank Invoice Name
     *   - has NO existing primary RCR (so we can safely attach our own)
     */
    private static tc9_pr__Assignment__c getAssignmentWithBlankInvoice() {
        List<tc9_pr__Assignment__c> assignments = [
            SELECT Id, Invoice_Name__c, tc9_et__Rate_Calculator__c,
                   tc9_et__Has_Assignment_Rate__c
            FROM tc9_pr__Assignment__c
            WHERE tc9_et__Has_Assignment_Rate__c = true
            AND   tc9_et__Rate_Calculator__c != null
            AND   Invoice_Name__c = null
            AND   tc9_pr__Status__c = 'Active'
            LIMIT 50
        ];

        for (tc9_pr__Assignment__c a : assignments) {
            List<tc9_et__Rate_Calculator_Rate__c> existing = [
                SELECT Id FROM tc9_et__Rate_Calculator_Rate__c
                WHERE tc9_et__Rate_Calculator__c = :a.tc9_et__Rate_Calculator__c
                AND   tc9_et__Primary_Record__c  = true
                LIMIT 1
            ];
            if (existing.isEmpty()) {
                return a;
            }
        }
        return null;
    }

    private static tc9_pr__Assignment__c getAssignmentWithInvoice() {
        return [
            SELECT Id, Invoice_Name__c, tc9_et__Rate_Calculator__c
            FROM tc9_pr__Assignment__c
            WHERE tc9_et__Has_Assignment_Rate__c = true
            AND   Invoice_Name__c != null
            AND   tc9_pr__Status__c = 'Active'
            LIMIT 1
        ];
    }

    /**
     * Creates a new MPR using real lookup IDs from an existing active MPR,
     * first inactivating any conflicting records to satisfy package uniqueness rules.
     */
    private static tc9_et__Minimum_Pay_Rate__c createMPR(String invoiceName) {
        tc9_et__Minimum_Pay_Rate__c seed = [
            SELECT Id,
                   tc9_et__Interpretation_Rule__c,
                   tc9_et__Award_Classification__c,
                   tc9_et__Award_Level__c,
                   tc9_et__Rate_Calculator_Template__c
            FROM tc9_et__Minimum_Pay_Rate__c
            WHERE tc9_et__Interpretation_Rule__c       != null
            AND   tc9_et__Award_Classification__c      != null
            AND   tc9_et__Award_Level__c               != null
            AND   tc9_et__Rate_Calculator_Template__c  != null
            AND   tc9_et__Status__c = 'Active'
            LIMIT 1
        ];

        // Inactivate conflicting active MPRs (package enforces uniqueness on this combo)
        List<tc9_et__Minimum_Pay_Rate__c> conflicts = [
            SELECT Id FROM tc9_et__Minimum_Pay_Rate__c
            WHERE tc9_et__Interpretation_Rule__c      = :seed.tc9_et__Interpretation_Rule__c
            AND   tc9_et__Award_Classification__c     = :seed.tc9_et__Award_Classification__c
            AND   tc9_et__Award_Level__c              = :seed.tc9_et__Award_Level__c
            AND   tc9_et__Rate_Calculator_Template__c = :seed.tc9_et__Rate_Calculator_Template__c
            AND   tc9_et__Status__c = 'Active'
        ];
        for (tc9_et__Minimum_Pay_Rate__c m : conflicts) {
            m.tc9_et__Status__c       = 'Inactive';
            m.tc9_et__Expiry_Date__c  = Date.today().addDays(-1);
        }
        if (!conflicts.isEmpty()) {
            update conflicts;
        }

        tc9_et__Minimum_Pay_Rate__c mpr = new tc9_et__Minimum_Pay_Rate__c(
            Invoice_Name__c                     = invoiceName,
            tc9_et__Effective_Date__c           = Date.today(),
            tc9_et__Interpretation_Rule__c      = seed.tc9_et__Interpretation_Rule__c,
            tc9_et__Award_Classification__c     = seed.tc9_et__Award_Classification__c,
            tc9_et__Award_Level__c              = seed.tc9_et__Award_Level__c,
            tc9_et__Pay_Rate__c                 = 25.00,
            tc9_et__Status__c                   = 'Active',
            tc9_et__Rate_Calculator_Template__c = seed.tc9_et__Rate_Calculator_Template__c
        );
        insert mpr;
        return mpr;
    }

    private static tc9_et__Rate_Calculator_Rate__c createRCR(Id rcId, Id mprId) {
        tc9_et__Rate_Calculator_Rate__c rcr = new tc9_et__Rate_Calculator_Rate__c(
            tc9_et__Rate_Calculator__c  = rcId,
            tc9_et__Minimum_Pay_Rate__c = mprId,
            tc9_et__Primary_Record__c   = true
        );
        insert rcr;
        return rcr;
    }

    // ─── Tests ────────────────────────────────────────────────────────────────

    @isTest
    static void testBatchStampsInvoiceName() {
        tc9_pr__Assignment__c assignment = getAssignmentWithBlankInvoice();
        if (assignment == null) {
            System.debug('SKIP: No eligible assignment found — all active assignments already have Invoice Name populated.');
            return;
        }

        tc9_et__Minimum_Pay_Rate__c mpr = createMPR('Test Invoice Name');
        createRCR(assignment.tc9_et__Rate_Calculator__c, mpr.Id);

        Test.startTest();
        Database.executeBatch(new BatchStampInvoiceNameOnAssignment(), 200);
        Test.stopTest();

        tc9_pr__Assignment__c result = [
            SELECT Invoice_Name__c FROM tc9_pr__Assignment__c WHERE Id = :assignment.Id
        ];
        System.assertEquals('Test Invoice Name', result.Invoice_Name__c,
            'Invoice Name should be stamped from the MPR');
    }

    @isTest
    static void testBatchSkipsAssignmentWithInvoiceName() {
        tc9_pr__Assignment__c assignment = getAssignmentWithInvoice();
        String originalInvoiceName = assignment.Invoice_Name__c;

        Test.startTest();
        Database.executeBatch(new BatchStampInvoiceNameOnAssignment(), 200);
        Test.stopTest();

        tc9_pr__Assignment__c result = [
            SELECT Invoice_Name__c FROM tc9_pr__Assignment__c WHERE Id = :assignment.Id
        ];
        System.assertEquals(originalInvoiceName, result.Invoice_Name__c,
            'Invoice Name must not be overwritten when already populated');
    }

    @isTest
    static void testBatchSkipsAssignmentWithBlankMPRInvoiceName() {
        tc9_pr__Assignment__c assignment = getAssignmentWithBlankInvoice();
        if (assignment == null) {
            System.debug('SKIP: No eligible assignment found — all active assignments already have Invoice Name populated.');
            return;
        }

        tc9_et__Minimum_Pay_Rate__c mpr = createMPR(null);
        createRCR(assignment.tc9_et__Rate_Calculator__c, mpr.Id);

        Test.startTest();
        Database.executeBatch(new BatchStampInvoiceNameOnAssignment(), 200);
        Test.stopTest();

        tc9_pr__Assignment__c result = [
            SELECT Invoice_Name__c FROM tc9_pr__Assignment__c WHERE Id = :assignment.Id
        ];
        System.assertEquals(null, result.Invoice_Name__c,
            'Invoice Name should remain blank when MPR Invoice Name is null');
    }

    @isTest
    static void testScheduler() {
        Test.startTest();
        String jobId = System.schedule(
            'Test BatchStampInvoiceName ' + DateTime.now().getTime(),
            '0 0 0 1 1 ? 2099',
            new ScheduleBatchStampInvoiceName()
        );
        Test.stopTest();

        System.assertNotEquals(null, jobId,
            'Scheduler should return a valid CronTrigger job ID');
    }
}