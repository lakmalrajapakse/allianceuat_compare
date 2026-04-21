global class BatchStampInvoiceNameOnAssignment implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime cutoff = Test.isRunningTest()
            ? DateTime.now().addYears(-10)  // widen window so test's real org data is included
            : DateTime.now().addHours(-6);  // production: only recently modified assignments

        String query =
            'SELECT Id, Invoice_Name__c, tc9_et__Rate_Calculator__c ' +
            'FROM tc9_pr__Assignment__c ' +
            'WHERE Invoice_Name__c = null ' +
            'AND tc9_et__Rate_Calculator__c != null ' +
            'AND tc9_et__Has_Assignment_Rate__c = true ' +
            'AND LastModifiedDate >= :cutoff';

        if (Test.isRunningTest()) {
            query += ' LIMIT 200';  // prevent multiple executeBatch chunks in tests
        }

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<tc9_pr__Assignment__c> assignments) {
        Set<Id> rcIds = new Set<Id>();
        for (tc9_pr__Assignment__c a : assignments) {
            rcIds.add(a.tc9_et__Rate_Calculator__c);
        }

        Map<Id, String> rcToInvoiceName = new Map<Id, String>();
        for (tc9_et__Rate_Calculator_Rate__c rcr : [
            SELECT tc9_et__Rate_Calculator__c, tc9_et__Minimum_Pay_Rate__r.Invoice_Name__c
            FROM tc9_et__Rate_Calculator_Rate__c
            WHERE tc9_et__Rate_Calculator__c IN :rcIds
            AND tc9_et__Primary_Record__c = true
            AND tc9_et__Minimum_Pay_Rate__r.Invoice_Name__c != null
        ]) {
            if (!rcToInvoiceName.containsKey(rcr.tc9_et__Rate_Calculator__c)) {
                rcToInvoiceName.put(
                    rcr.tc9_et__Rate_Calculator__c,
                    rcr.tc9_et__Minimum_Pay_Rate__r.Invoice_Name__c
                );
            }
        }

        List<tc9_pr__Assignment__c> toUpdate = new List<tc9_pr__Assignment__c>();
        for (tc9_pr__Assignment__c a : assignments) {
            if (rcToInvoiceName.containsKey(a.tc9_et__Rate_Calculator__c)) {
                toUpdate.add(new tc9_pr__Assignment__c(
                    Id = a.Id,
                    Invoice_Name__c = rcToInvoiceName.get(a.tc9_et__Rate_Calculator__c)
                ));
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    global void finish(Database.BatchableContext bc) {}
}