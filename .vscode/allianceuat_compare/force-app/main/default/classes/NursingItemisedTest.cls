@isTest
public with sharing class NursingItemisedTest extends SkieInvoiceTemplateBaseSetupTest {
    @TestSetup
    static void makeData() {
        tc9_pr__Override_TC9P_Validation__c setting = prepareSetting();
        insert setting;

        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User adminUser = new User(
            Alias = 'admin',
            Email = 'admin@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Admin',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'admin@test.com2'
        );
        insert adminUser;

        System.runAs(adminUser) {

            Date startDate = Date.today().toStartOfWeek();
            Date endDate = startDate.addDays(30);

            tc9_et__Interpretation_Rule__c intRule = prepareInterpretationRule(38.0, 15.0, 5.0, 5.0, 5.0, false);
            insert intRule;

            tc9_et__Payment_Terms__c pTerm = preparePaymentTerm();
            insert pTerm;

            tc9_pr__Location__c location = prepareTaxLocation();
            insert location;

            List<tc9_pr__Schedule__c> schList = new List<tc9_pr__Schedule__c>();
            tc9_pr__Schedule__c schedule = prepareSchedule('Weekly','W','Pay_Schedule');
            schList.add(schedule);

            tc9_pr__Schedule__c scheduleInv = prepareSchedule('Weekly','W','Invoice_Schedule');
            schList.add(scheduleInv);

            Account acc = prepareClientAccount(location.Id, 'Client', schedule.Id);
            acc.Name = 'client 1';
            acc.Payroll_Tax_Exempt__c = 'No';
            acc.Approval_Type__c = 'Always Charged - As Paid';
            Account invoiceEntity = prepareClientAccount(location.Id, 'Invoice_Entity', schedule.Id);
            invoiceEntity.Name = 'inv entity 1';
            invoiceEntity.Payroll_Tax_Exempt__c = 'No';
            invoiceEntity.Approval_Type__c = 'Always Charged - As Paid';
            Account paymentEntity = prepareClientAccount(location.Id, 'Payment_Entity', schedule.Id);
            paymentEntity.Name = 'pm entity 1';
            paymentEntity.Payroll_Tax_Exempt__c = 'No';
            paymentEntity.Approval_Type__c = 'Always Charged - As Paid';
            Account candAcc = prepareEmployeeAccount(location.Id);
            candAcc.Name = 'cand acc 1';
            candAcc.Payroll_Tax_Exempt__c = 'No';
            candAcc.Approval_Type__c = 'Always Charged - As Paid';
            insert new List<Account>{acc, invoiceEntity, paymentEntity, candAcc};

            acc.Default_Invoice_Entity__c = invoiceEntity.Id;
            update acc;

            Contact clientCon = prepareClientContact(acc);
            insert clientCon;
            
            Contact employee = prepareEmployee(candAcc);
            employee.AccountId = candAcc.Id;
            employee.RecordTypeId  = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Client_Contact')?.getRecordTypeId();
            insert employee;
            
            tc9_pr__Project_Code__c clientPrjCode = prepareClientProjectCode(acc.Id);
            insert clientPrjCode;

            tc9_pr__Payee__c payee = preparePayee(schedule.Id, employee.Id, paymentEntity.Id, 'PAYE');
            insert payee;

            tc9_et__Invoice_Setting__c invSetting = prepareInvoiceSetting('Payroll_Items', 'Payroll_Items', acc.Id, invoiceEntity.Id, pterm.Id);
            invSetting.tc9_et__Invoice_Visualforce_Page__c = 'InvoicePayrollItemsAUS';
            insert invSetting;

            tc9_et__Invoice_Setting__c creditSetting = prepareInvoiceSetting('Payroll_Items', 'Credit_Payroll_Items', acc.Id, invoiceEntity.Id, pterm.Id);
            creditSetting.tc9_et__Invoice_Visualforce_Page__c = 'InvoicePayrollItemsNZ';
            insert creditSetting;

            tc9_pr__Calendar__c tsCal = prepareTimesheetCalendar(schedule.Id, paymentEntity.Id, true, startDate, 'Weekly', 'Start/End Times', 'Start/End Times', scheduleInv.Id, invoiceEntity.Id);
            insert tsCal;

            tc9_pr__Calendar__c pubCal = preparePublicHolidayCalendar(schedule.Id, paymentEntity.Id);
            insert pubCal;

            tc9_pr__Assignment__c assignment = prepareAssignment(tsCal.Id, acc.Id, clientCon.Id, schedule.Id, pubCal.Id, employee.Id, startDate, endDate, intRule.Id, 'Temp', pterm.Id, payee.Id, scheduleInv.Id, paymentEntity.Id);
            insert assignment;

            tc9_pr__Pay_Code__c expCode = preparePayCode('Expense');
            insert expCode;

            tc9_pr__Pay_Code__c payCodeLeave = preparePayCode('Payment');
            insert payCodeLeave;

            tc9_et__Expense_Claim__c expenseClaim = prepareExpenseClaim(assignment.Id, employee.Id, payee.Id, 'New');
            insert expenseClaim;

            tc9_et__Expense__c expense = prepareExpense(expenseClaim.Id, true, expCode.Id);
            insert expense;

            tc9_et__Invoice__c invoice = prepareInvoice(acc.Id, clientCon.Id, pTerm.Id, invoiceEntity.Id, invSetting.Id);
            insert invoice;

            tc9_et__Timesheet__c ts = prepareTimesheet(assignment.Id, employee.Id, payee.Id, 'Approved');
            tc9_et__Timesheet__c ts2 = prepareTimesheet(assignment.Id, employee.Id, payee.Id, 'Approved');
            insert new List<tc9_et__Timesheet__c>{ts, ts2};
                

            tc9_et__Timesheet_Entry__c tse = prepareTimesheetEntry(ts.Id, assignment.Id, payee.Id, employee.Id, System.today(), System.today().addDays(1));
            
            tc9_et__Timesheet_Entry__c tse2 = prepareTimesheetEntry(ts.Id, assignment.Id, payee.Id, employee.Id, System.today().addDays(1), System.today().addDays(2));
            tc9_et__Timesheet_Entry__c tse3 = prepareTimesheetEntry(ts.Id, assignment.Id, payee.Id, employee.Id, System.today().addDays(1), System.today().addDays(2));
            insert new List<tc9_et__Timesheet_Entry__c>{tse, tse2, tse3};

            tc9_et__Invoice_Item__c item = prepareInvoiceItem(invoice.Id, clientPrjCode.Id, acc.Id, assignment.Id, employee.Id, payee.Id, expense.Id, expCode.Id);
            tc9_et__Invoice_Item__c item2 = prepareInvoiceItem(invoice.Id, clientPrjCode.Id, acc.Id, assignment.Id, employee.Id, payee.Id, expense.Id, expCode.Id);
            tc9_et__Invoice_Item__c item3 = prepareInvoiceItem(invoice.Id, clientPrjCode.Id, acc.Id, assignment.Id, employee.Id, payee.Id, expense.Id, expCode.Id);
            item.tc9_et__Timesheet_Entry__c = tse.Id;
            item2.tc9_et__Timesheet_Entry__c = tse.Id;
            item3.tc9_et__Timesheet_Entry__c = tse.Id;
            insert new List<tc9_et__Invoice_Item__c>{item, item2, item3};
                
            item.tc9_et__Expense__c = expense.Id;
            update item;
            
            tc9_et__Timesheet_Item__c tsItem = new tc9_et__Timesheet_Item__c();
            tsItem.RecordTypeId = Schema.SObjectType.tc9_et__Timesheet_Item__c.getRecordTypeInfosByDeveloperName().get('Allowance').getRecordTypeId();
            tsItem.tc9_et__Timesheet__c = ts.Id;
            tsItem.tc9_et__Date_Incurred__c = System.today();
            insert tsItem;

            tc9_pr__Pay_Transaction__c payt = preparePaymentPayTransaction(acc.Id, assignment.Id, payCodeLeave.Id, payee.Id, employee.Id, paymentEntity.Id, schedule.Id);
            payt.tc9_et__Timesheet__c = ts.Id;
            payt.tc9_et__Invoice_Item__c = item.Id;
            payt.tc9_et__Invoice_Rate__c = 1000.0;
            payt.tc9_pr__Quantity__c = 1; 
            payt.tc9_et__Timesheet_Entry__c = tse.Id;

            tc9_pr__Pay_Transaction__c payt2 = preparePaymentPayTransaction(acc.Id, assignment.Id, payCodeLeave.Id, payee.Id, employee.Id, paymentEntity.Id, schedule.Id);
            payt2.tc9_et__Timesheet__c = ts.Id;
            payt2.tc9_et__Invoice_Item__c = item2.Id;
            payt2.tc9_et__Invoice_Rate__c = 2000.0;
            payt2.tc9_pr__Quantity__c = 1; 
            payt.tc9_et__Timesheet_Entry__c = tse2.Id;

            tc9_pr__Pay_Transaction__c payt3 = preparePaymentPayTransaction(acc.Id, assignment.Id, payCodeLeave.Id, payee.Id, employee.Id, paymentEntity.Id, schedule.Id);
            payt3.tc9_et__Timesheet__c = ts2.Id;
            payt3.tc9_et__Invoice_Item__c = item3.Id;
            payt3.tc9_et__Invoice_Rate__c = 1000.0;
            payt3.tc9_pr__Quantity__c = 1; 
            payt.tc9_et__Timesheet_Entry__c = tse3.Id;
            payt.tc9_et__Expense_Claim__c = expenseClaim.Id;
            insert new List<tc9_pr__Pay_Transaction__c>{payt, payt2, payt3};
                
            item.tc9_et__Pay_Transaction__c = payt.Id;
            item2.tc9_et__Pay_Transaction__c = payt2.Id;
            item3.tc9_et__Pay_Transaction__c = payt3.Id;
            update new List<tc9_et__Invoice_Item__c>{item, item2, item3};
            ContentVersion cv = new ContentVersion();
            cv.PathOnClient ='test_file.png';
            cv.Title = 'test file '+DateTime.now();
            cv.versiondata = Blob.valueOf('test file body 1');
            insert cv;

            ContentVersion cv2 = new ContentVersion();
            cv2.PathOnClient ='test_file2.jpg';
            cv2.Title = 'test file 2 '+DateTime.now();
            cv2.versiondata=Blob.valueOf('test file body 2');
            insert cv2;

            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;
            cdl.LinkedEntityId = expenseClaim.Id;
            cdl.ShareType = 'V';
            insert cdl;

            ContentDocumentLink cdl2 = new ContentDocumentLink();
            cdl2.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv2.Id].ContentDocumentId;
            cdl2.LinkedEntityId = ts.Id;
            cdl2.ShareType = 'V';
            insert cdl2;
        }
    }

    @isTest
    public static void givenInvoiceId_whenInitNursingItemisedController_thenGetInvoiceDetailSuccessfully() {
        Test.StartTest(); 
        tc9_et__Invoice__c invoice = [SELECT Id from tc9_et__Invoice__c LIMIT 1];

        PageReference pageRef = Page.NursingItemised;
        pageRef.getParameters().put('invoiceId', String.valueOf(invoice.Id));

        Test.setCurrentPage(pageRef);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(new List<tc9_et__Invoice__c>{invoice});
        NursingItemisedController controller = new NursingItemisedController(stdSetController);
        NursingItemisedData.ItemLine firstSub = controller.invoiceDatas[0].itemGroupsMap.values()[0].getFirstGroupItemLine();
        List<NursingItemisedData.ItemLine> followingSubs = controller.invoiceDatas[0].itemGroupsMap.values()[0].getFollowingGroupItemLines();
		System.assert(controller.invoiceDatas != null);
        firstSub.compareTo(firstSub);
        
        List<Apexpages.Message> msgs = ApexPages.getMessages();
        System.assertEquals(0, msgs.size());


		Test.StopTest();
    }

    @isTest
    public static void givenPrintId_whenInitNursingItemisedController_thenGetInvoiceDetailSuccessfully() {
        Test.StartTest(); 
        tc9_et__Invoice__c invoice = [SELECT Id from tc9_et__Invoice__c LIMIT 1];

        PageReference pageRef = Page.NursingItemised;
        pageRef.getParameters().put('printId', String.valueOf(invoice.Id));

        Test.setCurrentPage(pageRef);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(new List<tc9_et__Invoice__c>{invoice});
        NursingItemisedController controller = new NursingItemisedController(stdSetController);
		System.assert(controller.invoiceDatas != null);
        System.assert(controller.invoiceDatas[0].getInvoiceCalendarPeriodStartDate() != null);
        System.assert(controller.invoiceDatas[0].getInvoiceCalendarPeriodEndDate() != null);
        System.assert(controller.invoiceDatas[0].getPurchaseOrderNumber() != null);
        System.assert(controller.invoiceDatas[0].getItemGroups() != null);
        
        List<Apexpages.Message> msgs = ApexPages.getMessages();
        System.assertEquals(0, msgs.size());


		Test.StopTest();
    }

    @isTest
    public static void givenInvoiceIdIsBlank_whenInitNursingItemisedController_thenGetInvoiceDetailFailed() {
        Test.StartTest(); 
        tc9_et__Invoice__c invoice = [SELECT Id from tc9_et__Invoice__c LIMIT 1];

        PageReference pageRef = Page.NursingItemised;
        pageRef.getParameters().put('invoiceId', null);

        Test.setCurrentPage(pageRef);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(new List<tc9_et__Invoice__c>{invoice});
        NursingItemisedController controller = new NursingItemisedController(stdSetController);

        List<Apexpages.Message> msgs = ApexPages.getMessages();
        System.assertEquals(1, msgs.size());
		Test.StopTest();
    }
}