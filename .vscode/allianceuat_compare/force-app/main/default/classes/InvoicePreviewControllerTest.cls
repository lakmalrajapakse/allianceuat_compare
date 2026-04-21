@IsTest
public class InvoicePreviewControllerTest extends SkieInvoicePDFBaseSetupTest {

    private static Id   seededBranchId;
    private static Date seededStartDt;
    private static Date seededEndDt;

    private static ContentVersion attachFileToRecord(Id parentId, String title, String ext, String content){
        ContentVersion cv = new ContentVersion();
        cv.Title = title;
        cv.PathOnClient = title + '.' + ext;
        cv.VersionData  = Blob.valueOf(content);
        cv.FirstPublishLocationId = parentId;
        insert cv;

        return [
            SELECT Id, ContentDocumentId, Title, FileType, IsLatest
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
        ];
    }

    private static void makeData(){
        insert prepareSetting();

        Date startDate = Date.today();
        Date endDate   = startDate.addDays(30);

        tc9_et__Payment_Terms__c pTerm = preparePaymentTerm(); insert pTerm;

        tc9_pr__Schedule__c paySchedule = prepareSchedule('Weekly','W','Pay_Schedule');
        tc9_pr__Schedule__c invSchedule = prepareSchedule('Weekly','W','Invoice_Schedule');
        insert new List<tc9_pr__Schedule__c>{paySchedule, invSchedule};

        tc9_pr__Location__c location = prepareTaxLocation(); insert location;

        Account clientAcc     = prepareClientAccount(location.Id, 'Client',         paySchedule.Id);
        Account invoiceEntity = prepareClientAccount(location.Id, 'Invoice_Entity', paySchedule.Id);
        Account paymentEntity = prepareClientAccount(location.Id, 'Payment_Entity', paySchedule.Id);
        Account employeeAcc   = prepareEmployeeAccount(location.Id);
        if (Schema.SObjectType.Account.fields.getMap().containsKey('Approval_Type__c')){
            clientAcc.put('Approval_Type__c','Not Charged');
            invoiceEntity.put('Approval_Type__c','Not Charged');
            paymentEntity.put('Approval_Type__c','Not Charged');
            employeeAcc.put('Approval_Type__c','Not Charged');
        }
        insert new List<Account>{clientAcc, invoiceEntity, paymentEntity, employeeAcc};

        Contact clientCon = new Contact(LastName='Client Contact', AccountId=clientAcc.Id); insert clientCon;
        Contact employee  = new Contact(LastName='Employee Contact', AccountId=employeeAcc.Id); insert employee;

        tc9_pr__Project_Code__c prj = prepareClientProjectCode(clientAcc.Id); insert prj;

        tc9_pr__Pay_Code__c payCodePayment = preparePayCode('Payment'); insert payCodePayment;
        tc9_pr__Pay_Code__c payCodeExpense = preparePayCode('Expense'); insert payCodeExpense;

        tc9_pr__Payee__c payeeRec = preparePayee(paySchedule.Id, employee.Id, paymentEntity.Id, 'PAYE');
        if (Schema.SObjectType.tc9_pr__Payee__c.fields.getMap().containsKey('Payroll_Tax_Exempt__c')){
            payeeRec.put('Payroll_Tax_Exempt__c', 'No');
        }
        insert payeeRec;

        tc9_et__Invoice_Setting__c invSetting =
            prepareInvoiceSetting('Payroll_Items', 'Payroll_Items', clientAcc.Id, invoiceEntity.Id, pTerm.Id);
        insert invSetting;

        Map<String, Schema.SObjectField> calFields =
            Schema.SObjectType.tc9_pr__Calendar__c.fields.getMap();
        Schema.DescribeFieldResult beDfr = calFields.get('tc9_et__Break_Entry_Format__c').getDescribe();
        Schema.DescribeFieldResult tsDfr = calFields.get('tc9_et__Timesheet_Entry_Format__c').getDescribe();
        String beFormat = beDfr.getPicklistValues().isEmpty() ? null : beDfr.getPicklistValues()[0].getValue();
        String tsFormat = tsDfr.getPicklistValues().isEmpty() ? null : tsDfr.getPicklistValues()[0].getValue();

        tc9_pr__Calendar__c tsCal = prepareTimesheetCalendar(
            paySchedule.Id, paymentEntity.Id, true, startDate,
            'Weekly', beFormat, tsFormat, invSchedule.Id, invoiceEntity.Id
        );
        tc9_pr__Calendar__c pubHolCal = preparePublicHolidayCalendar(paySchedule.Id, paymentEntity.Id);
        insert new List<tc9_pr__Calendar__c>{tsCal, pubHolCal};

        Branch__c branch = new Branch__c(Branch_Code__c='T001', Branch_Name__c='Test Branch', City__c='Melbourne');
        insert branch;

        tc9_pr__Assignment__c assignment = new tc9_pr__Assignment__c();
        assignment.tc9_et__Timesheet_Calendar__c      = tsCal.Id;
        assignment.tc9_pr__Assignment_Start_Date__c   = startDate.addDays(-3);
        assignment.tc9_pr__Assignment_End_Date__c     = startDate.addDays(10);
        assignment.tc9_pr__Assignment_Name__c         = 'Test Assignment';
        assignment.tc9_pr__Payee__c                   = payeeRec.Id;
        assignment.tc9_pr__Payment_Entity__c          = paymentEntity.Id;
        assignment.tc9_pr__Client__c                  = clientAcc.Id;
        assignment.tc9_et__Client_Hiring_Manager__c   = clientCon.Id;
        assignment.tc9_pr__Schedule__c                = paySchedule.Id;
        assignment.tc9_et__Public_Holiday_Calendar__c = pubHolCal.Id;
        assignment.tc9_pr__Employee__c                = employee.Id;
        assignment.Branch__c                           = branch.Id;
        insert assignment;

        tc9_et__Invoice__c inv1 = prepareInvoice(clientAcc.Id, clientCon.Id, pTerm.Id, invoiceEntity.Id, invSetting.Id);
        inv1.tc9_et__Invoice_Date__c = startDate.addDays(1);
        tc9_et__Invoice__c inv2 = prepareInvoice(clientAcc.Id, clientCon.Id, pTerm.Id, invoiceEntity.Id, invSetting.Id);
        inv2.tc9_et__Invoice_Date__c = startDate.addDays(2);
        tc9_et__Invoice__c inv3 = prepareInvoice(clientAcc.Id, clientCon.Id, pTerm.Id, invoiceEntity.Id, invSetting.Id);
        inv3.tc9_et__Invoice_Date__c = startDate.addDays(3);
        insert new List<tc9_et__Invoice__c>{inv1, inv2, inv3};

        seededBranchId = branch.Id;
        seededStartDt  = inv1.tc9_et__Invoice_Date__c;
        seededEndDt    = inv3.tc9_et__Invoice_Date__c;

        tc9_et__Expense_Claim__c expClaim = prepareExpenseClaim(assignment.Id, employee.Id, payeeRec.Id, 'Approved');
        insert expClaim;
        tc9_et__Expense__c expense = prepareExpense(expClaim.Id, true, payCodeExpense.Id);
        insert expense;

        tc9_et__Invoice_Item__c ii1 = prepareInvoiceItem(
            inv1.Id, prj.Id, clientAcc.Id, assignment.Id, employee.Id, payeeRec.Id, expense.Id, payCodePayment.Id);
        tc9_et__Invoice_Item__c ii2 = prepareInvoiceItem(
            inv2.Id, prj.Id, clientAcc.Id, assignment.Id, employee.Id, payeeRec.Id, expense.Id, payCodePayment.Id);
        insert new List<tc9_et__Invoice_Item__c>{ii1, ii2};

        tc9_pr__Pay_Transaction__c pt1 = preparePaymentPayTransaction(
            clientAcc.Id, assignment.Id, payCodePayment.Id, payeeRec.Id, employee.Id, paymentEntity.Id, paySchedule.Id);
        insert pt1; pt1.tc9_et__Invoice_Item__c = ii1.Id; update pt1;

        tc9_pr__Pay_Transaction__c pt2 = preparePaymentPayTransaction(
            clientAcc.Id, assignment.Id, payCodePayment.Id, payeeRec.Id, employee.Id, paymentEntity.Id, paySchedule.Id);
        insert pt2; pt2.tc9_et__Invoice_Item__c = ii2.Id; update pt2;

        attachFileToRecord(inv1.Id, 'inv1', 'pdf', 'PDF ONE');
        attachFileToRecord(inv2.Id, 'inv2', 'pdf', 'PDF TWO');
        attachFileToRecord(inv3.Id, 'inv3', 'txt',  'not a pdf');
    }

    @TestSetup
    static void globalSetup(){ makeData(); }

    private static Map<String,Object> ourBranchAndRange() {
        tc9_pr__Assignment__c a = [
            SELECT Id, Branch__c
            FROM tc9_pr__Assignment__c
            WHERE tc9_pr__Assignment_Name__c = 'Test Assignment'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (a.Branch__c == null) {
            Branch__c b = [
                SELECT Id
                FROM Branch__c
                WHERE Branch_Code__c = 'T001'
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            a.Branch__c = b.Id;
            update a;
        }

        Set<Id> invIds = new Set<Id>();
        for (tc9_et__Invoice_Item__c ii : [
            SELECT tc9_et__Invoice__c
            FROM tc9_et__Invoice_Item__c
            WHERE tc9_et__Assignment__c = :a.Id
              AND tc9_et__Invoice__c != null
        ]) invIds.add(ii.tc9_et__Invoice__c);

        Date startDt, endDt;
        if (!invIds.isEmpty()) {
            AggregateResult ar = [
                SELECT MIN(tc9_et__Invoice_Date__c) m, MAX(tc9_et__Invoice_Date__c) x
                FROM tc9_et__Invoice__c
                WHERE Id IN :invIds
            ];
            startDt = (Date) ar.get('m');
            endDt   = (Date) ar.get('x');
        }
        if (startDt == null || endDt == null) {
            startDt = Date.today().addYears(-5);
            endDt   = Date.today().addYears( 5);
        }

        return new Map<String,Object>{
            'branchId' => a.Branch__c,
            'start'    => startDt,
            'end'      => endDt
        };
    }

    @IsTest
    static void test_getInvoices_and_countInvoices_positive(){
        Map<String,Object> info = ourBranchAndRange();
        Id branchId = (Id) info.get('branchId');
        Date startDt  = (Date) info.get('start');
        Date endDt    = (Date) info.get('end');
        System.assertNotEquals(null, branchId, 'Setup failed: no branch found');

        Test.startTest();
        List<tc9_et__Invoice__c> got = InvoicePreviewController.getInvoices(branchId, startDt, endDt);
        Integer cnt = InvoicePreviewController.countInvoices(branchId, startDt, endDt);
        Test.stopTest();

        System.assertEquals(2, got.size(), 'Only invoices with a latest PDF should be returned');
        System.assertEquals(2, cnt,       'Count should match list size');
    }

    @IsTest
    static void test_getInvoices_and_countInvoices_paramGuards(){
        Date d = Date.today();
        System.assertEquals(0, InvoicePreviewController.countInvoices(null, d, d));
        System.assertEquals(0, InvoicePreviewController.countInvoices(Id.valueOf(UserInfo.getUserId()), null, d));
        System.assertEquals(0, InvoicePreviewController.countInvoices(Id.valueOf(UserInfo.getUserId()), d, null));

        System.assertEquals(0, InvoicePreviewController.getInvoices(null, d, d).size());
        System.assertEquals(0, InvoicePreviewController.getInvoices(Id.valueOf(UserInfo.getUserId()), null, d).size());
        System.assertEquals(0, InvoicePreviewController.getInvoices(Id.valueOf(UserInfo.getUserId()), d, null).size());
    }

    @IsTest
    static void test_getSelectedInvoicePdfs_mixed(){
        List<tc9_et__Invoice__c> invs = [
            SELECT Id, tc9_et__Invoice_Date__c, Name
            FROM tc9_et__Invoice__c
            ORDER BY tc9_et__Invoice_Date__c ASC, Name ASC
        ];
        List<Id> ids = new List<Id>{ invs[1].Id, invs[2].Id, invs[0].Id };

        Test.startTest();
        List<Map<String,String>> files = InvoicePreviewController.getSelectedInvoicePdfs(ids);
        Test.stopTest();

        System.assertEquals(2, files.size(), 'Should only return the two PDFs');
        System.assert(files[0].get('name') != null && files[0].get('name').endsWith('.pdf'),
                      'First file name should end with .pdf');
        System.assert(files[1].get('name') != null && files[1].get('name').endsWith('.pdf'),
                      'Second file name should end with .pdf');
        System.assertNotEquals(null, files[0].get('base64'));
    }
}