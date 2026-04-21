@isTest
public with sharing class SkieSplitJournalTest {

    @TestSetup
    public static void setup(){
        insert buildOverrideSetting();

        Account acc = new Account(
            Name='Test Acc', 
            tc9_pr__ABN__c='50916241108',
            tc9_pr__Available_Payment_Methods__c='Payee International Bank', 
            tc9_pr__Maximum_Payment_Distributions__c='1'
       	);
        insert acc;

        Contact cont = new Contact(LastName='Test Contact', AccountId=acc.Id);
        insert cont;

        Account accountPaymentEntity = new Account();
        accountPaymentEntity.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Payment_Entity').getRecordTypeId();
        accountPaymentEntity.Name = 'Test Payment Entity';        
        accountPaymentEntity.tc9_pr__Available_Payment_Methods__c = 'Payee International Bank';
        accountPaymentEntity.tc9_pr__Maximum_Payment_Distributions__c = '2';
        accountPaymentEntity.tc9_pr__ABN__c='50916241108';
        insert accountPaymentEntity;

        tc9_pr__Pay_Batch__c pb = new tc9_pr__Pay_Batch__c(tc9_pr__Payment_Date__c=Date.newInstance(2024, 01, 21), tc9_pr__Status__c='Uncalculated',tc9_pr__Payment_Entity__c=acc.Id, tc9_pr__Total_Gross__c = 10000);
        insert pb;

        tc9_pr__Location__c location = new tc9_pr__Location__c();
        location.WorkCover_Industry_Classification__c = 'test';
        location.Name = 'location1';
        insert location;

        Contact employee = new Contact();
        employee.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Client_Contact').getRecordTypeId();
        employee.LastName = 'emp';
        insert employee;

        tc9_pr__Payee__c payee1 = new tc9_pr__Payee__c();
        payee1.tc9_pr__Employee__c = employee.Id;
        payee1.tc9_pr__Earner_Type__c = 'PAYG';
        payee1.tc9_pr__Primary_Location__c  = location.Id;
        payee1.tc9_pr__Payment_Entity__c = accountPaymentEntity.Id;   
        insert payee1;

        tc9_pr__Pay_Batch_Item__c payeePayBatch1 = new tc9_pr__Pay_Batch_Item__c();
        payeePayBatch1.tc9_pr__Pay_Batch__c = pb.Id;
        payeePayBatch1.tc9_pr__Employee__c = employee.Id;
        payeePayBatch1.tc9_pr__Status__c = 'Uncalculated';
        payeePayBatch1.tc9_pr__Payee__c = payee1.Id;
        payeePayBatch1.tc9_pr__Taxable_Earnings__c = 1000;
        insert payeePayBatch1;

        tc9_bgl__Acc_System_Setup__c setup = new tc9_bgl__Acc_System_Setup__c();
        setup.Name = 'Test - Accounting Profile';
        setup.tc9_bgl__Payroll_System__c = '2cloudnine Payroll AUS';
        setup.tc9_bgl__Active_Inactive__c = true;
        setup.Split_Workcover_by_State__c = true;
        setup.Split_Payroll_Tax_by_State__c = true;
        insert setup;

        tc9_bgl__Acc_Payment_Entity__c paymentEntityDefault = new tc9_bgl__Acc_Payment_Entity__c();
        paymentEntityDefault.tc9_bgl__Payment_Entity__c = acc.Id;
        // paymentEntityDefault.acc.Id = setup.Id;
        insert paymentEntityDefault;

        tc9_bgl__Acc_Payroll_Journal__c journal = new tc9_bgl__Acc_Payroll_Journal__c();
        journal.tc9_bgl__Journal_Type__c = 'Cost of Payroll';
        journal.tc9_bgl__Journal_Date__c = System.today();
        journal.tc9_bgl__Pay_Batch__c = pb.Id;
        journal.tc9_bgl__Accounting_System__c = setup.Id;
        insert journal;

        tc9_pr__Pay_Code__c payCode = new tc9_pr__Pay_Code__c();
        payCode.Name = 'Test Payment';
        payCode.tc9_pr__Description__c = 'Payment';
        payCode.tc9_pr__Pay_Advice_Description__c = 'Payment';
        payCode.RecordTypeId = Schema.SObjectType.tc9_pr__Pay_Code__c.getRecordTypeInfosByDeveloperName().get('Payment')?.getRecordTypeId();
        payCode.tc9_pr__Pay_Rate_Multiplier__c = 1;
        payCode.tc9_pr__Contributes_to_OTE__c = true;
        payCode.tc9_pr__WorkCover_Reportable__c = true;
        payCode.tc9_pr__Pay_Advice_Description__c = 'Test Description';
        payCode.tc9_pr__AU_Payroll_Tax_Reportable__c = true;
        insert payCode;
        
        tc9_pr__Calendar__c timesheetCalendar = new tc9_pr__Calendar__c();
        timesheetCalendar.RecordTypeId = Schema.SObjectType.tc9_pr__Calendar__c.getRecordTypeInfosByDeveloperName().get('Timesheet').getRecordTypeId();
        timesheetCalendar.tc9_et__Timesheet_Frequency__c = 'Monthly';
        timesheetCalendar.tc9_et__Timesheet_Entry_Format__c = 'Start/End Times';
        timesheetCalendar.tc9_et__Break_Entry_Format__c = 'Total Minutes';
        timesheetCalendar.tc9_et__Monday__c = true;        
        timesheetCalendar.tc9_pr__Status__c = 'Active';        
        insert timesheetCalendar;

        Contact approver = new Contact();
        approver.LastName = 'Test Approver';
        insert approver;  

        Account invoiceEntity = new Account();
        invoiceEntity.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Invoice_Entity').getRecordTypeId();
        invoiceEntity.Name = 'Test Invoice Entity';
        invoiceEntity.tc9_pr__ABN__c='50916241108';

        tc9_pr__Schedule__c schedule = new tc9_pr__Schedule__c();
        schedule.Name = 'Test Schedule';
        schedule.tc9_pr__Split_Option__c = 'Per Calendar';
        schedule.tc9_pr__Period_Type__c = 'Monthly';
        insert schedule;

        Account client = new Account();
        client.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Client').getRecordTypeId();
        client.Name = 'Test Client';
        client.tc9_pr__Schedule__c = schedule.Id;
        client.tc9_et__Invoice_Contact__c = approver.Id;     
        client.Default_Invoice_Entity__c = invoiceEntity.Id;
        client.tc9_pr__ABN__c='50916241108';
        client.Payroll_Tax_Exempt__c = 'No';
        client.Approval_Type__c = 'Not Charged';
        insert client;  

        tc9_pr__Project_Code__c prjCode = new tc9_pr__Project_Code__c();
        prjCode.Name = 'TestProjectCode';
        prjCode.tc9_pr__Client__c = client.Id;
        prjCode.tc9_pr__Status__c = 'Active';
        prjCode.RecordTypeId = Schema.SObjectType.tc9_pr__Project_Code__c.getRecordTypeInfosByDeveloperName().get('Client_Level')?.getRecordTypeId();
        insert prjCode;

        tc9_pr__Assignment__c assignment = new tc9_pr__Assignment__c();
        assignment.RecordTypeId = Schema.SObjectType.tc9_pr__Assignment__c.getRecordTypeInfosByDeveloperName().get('Temp').getRecordTypeId();
        assignment.tc9_pr__Client__c = client.Id;
        assignment.tc9_et__Timesheet_Approver__c = approver.Id;
        assignment.tc9_pr__Assignment_Start_Date__c = System.today().addDays(-3);
        assignment.tc9_pr__Assignment_End_Date__c = System.today().addDays(3);
        assignment.tc9_et__Invoice_To_Contact__c = approver.Id;
        assignment.tc9_pr__Employee__c = employee.Id;
        assignment.tc9_pr__Payee__c = payee1.Id;
        assignment.tc9_pr__Payment_Entity__c = accountPaymentEntity.Id;
        assignment.tc9_et__Invoice_To_Account__c = client.Id;
        insert assignment;

        tc9_pr__Calendar__c holidayCalendar = new tc9_pr__Calendar__c();
        holidayCalendar.RecordTypeId = Schema.SObjectType.tc9_pr__Calendar__c.getRecordTypeInfosByDeveloperName().get('Public_Holiday').getRecordTypeId();
        holidayCalendar.Name = 'Test Public Holiday Calendar';
        insert holidayCalendar;

        tc9_et__Payment_Terms__c paymentTerms = new tc9_et__Payment_Terms__c();
        paymentTerms.Name = 'Test Payment Terms';
        insert paymentTerms;

        tc9_et__Timesheet__c timesheet = new tc9_et__Timesheet__c();
        timesheet.ScheduledJobProcessed__c = true;
        timesheet.tc9_et__Approval_Status__c = 'Approved';
        timesheet.tc9_et__Transaction_Creation_Stage__c = '2';
        timesheet.tc9_et__Approved_Rejected_By__c = approver.Id;
        timesheet.tc9_et__Approved_Rejected_Date__c = System.now();            
        timesheet.tc9_et__Approved_Rejected_on_Behalf_User__c = UserInfo.getUserId();
        timesheet.tc9_et__Submitted_Date__c = System.now();
        insert timesheet;      
        
        tc9_et__Invoice_Item__c invoiceItem = new tc9_et__Invoice_Item__c();
        insert invoiceItem;

        tc9_pr__Pay_Transaction__c payTransaction = new tc9_pr__Pay_Transaction__c();
        payTransaction.Name = 'Test PT';
        payTransaction.tc9_et__Timesheet__c = timesheet.Id;
        payTransaction.tc9_et__Invoice_Item__c = invoiceItem.Id;
        payTransaction.tc9_pr__Assignment__c = assignment.Id;
        payTransaction.tc9_pr__Pay_Code__c = payCode.Id;
        payTransaction.tc9_pr__Pay_Rate__c = 55;
        payTransaction.tc9_pr__Leave_Rate_Multiplier__c = 0.15;
        payTransaction.tc9_pr__Quantity__c = 10;      
        payTransaction.tc9_pr__Entry_Date__c = System.today();
        insert payTransaction;  

        tc9_pr__Pay_Transaction__c payTransaction2 = new tc9_pr__Pay_Transaction__c();
        payTransaction2.Name = 'Test PT 2';
        payTransaction2.tc9_et__Timesheet__c = timesheet.Id;
        payTransaction2.tc9_et__Invoice_Item__c = invoiceItem.Id;
        payTransaction2.tc9_pr__Assignment__c = assignment.Id;
        payTransaction2.tc9_pr__Pay_Code__c = payCode.Id;
        payTransaction2.tc9_pr__Pay_Rate__c = 55;
        payTransaction2.tc9_pr__Leave_Rate_Multiplier__c = 0.15;
        payTransaction2.tc9_pr__Quantity__c = 20;      
        payTransaction2.tc9_pr__Pay_Multiplier__c = -1;
        payTransaction2.tc9_pr__Entry_Date__c = System.today();
        payTransaction2.tc9_pr__Superannuation_Guarantee__c = -100;
        insert payTransaction2;  

        system.debug('tc9_pr__Pay_Transaction__c  >  '  + [select id, tc9_pr__Pay_Total__c from tc9_pr__Pay_Transaction__c]);
    }

    @isTest 
    public static void givenPayrollJournalWithoutPayTransactionDistributions_whenUpdateFlag_thenProcessStops() {
        Test.startTest();
        tc9_bgl__Acc_Payroll_Journal__c journal = [SELECT Id, Trigger_Splits__c FROM tc9_bgl__Acc_Payroll_Journal__c LIMIT 1];
        journal.Trigger_Splits__c = true;
        update journal;
        Test.stopTest();
    }

    @isTest 
    public static void givenPayTransactionDistribution_whenTriggerActivated_thenCrateJournalLineSuccessfully() {
        tc9_pr__Pay_Batch__c pb = [SELECT Id FROM tc9_pr__Pay_Batch__c pb LIMIT 1];
        tc9_pr__Pay_Transaction__c payTransaction = [SELECT Id FROM tc9_pr__Pay_Transaction__c WHERE tc9_pr__Superannuation_Guarantee__c = null LIMIT 1];
        tc9_pr__Pay_Transaction__c payTransaction2 = [SELECT Id FROM tc9_pr__Pay_Transaction__c WHERE tc9_pr__Superannuation_Guarantee__c != null LIMIT 1];
        tc9_pr__Pay_Transaction_Distribution__c ptd = new tc9_pr__Pay_Transaction_Distribution__c();
        ptd.tc9_pr__Pay_Batch__c = pb.Id;
        ptd.tc9_pr__Payroll_Tax_Rate__c = 5.4;
        ptd.tc9_pr__WorkCover_Rate__c = 2.0;
        ptd.tc9_pr__Pay_Transaction__c = payTransaction.Id;
        insert ptd;
        
        tc9_pr__Pay_Transaction_Distribution__c ptd2 = new tc9_pr__Pay_Transaction_Distribution__c();
        ptd2.tc9_pr__Pay_Batch__c = pb.Id;
        ptd2.tc9_pr__Payroll_Tax_Rate__c = 5.4;
        ptd2.tc9_pr__WorkCover_Rate__c = 2.0;
        ptd2.tc9_pr__Pay_Transaction__c = payTransaction.Id;
        insert ptd2;
        
        tc9_pr__Pay_Transaction_Distribution__c ptd3 = new tc9_pr__Pay_Transaction_Distribution__c();
        ptd3.tc9_pr__Pay_Batch__c = pb.Id;
        ptd3.tc9_pr__Payroll_Tax_Rate__c = -100;
        ptd3.tc9_pr__Pay_Transaction__c = payTransaction2.Id;
        ptd3.tc9_pr__AU_Payroll_Oncosts__c = ptd2.Id;
        insert ptd3;

        Test.startTest();
        tc9_bgl__Acc_Payroll_Journal__c journal = [SELECT Id, Trigger_Splits__c FROM tc9_bgl__Acc_Payroll_Journal__c LIMIT 1];
        journal.Trigger_Splits__c = true;
        update journal;
        Test.stopTest();
        List<tc9_bgl__Acc_Payroll_Journal_Lines__c> jls = [SELECT Id FROM tc9_bgl__Acc_Payroll_Journal_Lines__c];
        Assert.areEqual(4, jls.size(), '2 workcover, 2 payroll tax');
    }

    public static tc9_pr__Override_TC9P_Validation__c buildOverrideSetting() {
        tc9_pr__Override_TC9P_Validation__c tc9pSetting = new tc9_pr__Override_TC9P_Validation__c();
        tc9pSetting.tc9_pr__OV_Suspension__c = true;
        tc9pSetting.tc9_pr__OV_Allowance_Template__c = true;
        tc9pSetting.tc9_pr__OV_Assignment__c = true;
        tc9pSetting.tc9_pr__OV_Assignment_Cost__c = true;
        tc9pSetting.tc9_pr__OV_Assignment_Rate__c = true;
        tc9pSetting.tc9_pr__OV_Assignment_Schedule__c = true;
        tc9pSetting.tc9_et__OV_Award_Classification_Level__c = true;
        tc9pSetting.tc9_pr__Override_Calendar__c = true;
        tc9pSetting.tc9_pr__Override_Calendar_Period__c = true;
        tc9pSetting.tc9_pr__OV_Deduction_Template__c = true;
        tc9pSetting.tc9_et__OV_Expense__c = true;
        tc9pSetting.tc9_et__OV_Expense_Claim__c = true;
        tc9pSetting.tc9_et__OV_Interpretation_Breakpoint__c = true;
        tc9pSetting.tc9_et__OV_Interpretation_Rule__c = true;
        tc9pSetting.tc9_et__OV_Invoice__c = true;
        tc9pSetting.tc9_et__OV_Invoiceable_Fee__c = true;
        tc9pSetting.tc9_et__OV_Invoice_Setting__c = true;
        tc9pSetting.tc9_pr__OV_Leave_Rule__c = true;
        tc9pSetting.tc9_pr__OV_Leave_Rule_Item__c = true;
        tc9pSetting.tc9_eau__OV_Lodgement_AU__c = true;
        tc9pSetting.tc9_eau__OV_Lodgement_Error_AU__c = true;
        tc9pSetting.tc9_eau__OV_Lodgement_Item_AU__c = true;
        tc9pSetting.tc9_et__OV_Mark_Up_Margin_Rate_Record__c = true;
        tc9pSetting.tc9_et__OV_Minimum_Pay_Rate__c = true;
        tc9pSetting.tc9_pr__OV_Pay_Advice__c = true;
        tc9pSetting.tc9_pr__OV_Pay_Advice_Lines__c = true;
        tc9pSetting.tc9_pr__OV_Pay_Batch__c = true;
        tc9pSetting.tc9_pr__OV_Pay_Batch_Event__c = true;
        tc9pSetting.tc9_pr__OV_Pay_Code__c = true;
        tc9pSetting.tc9_pr__Override_Pay_Code_Junction__c = true;
        tc9pSetting.tc9_pr__OV_Payee__c = true;
        tc9pSetting.tc9_pr__OV_Payee_Aggregate__c = true;
        tc9pSetting.tc9_pr__OV_Payee_Allowance_Record__c = true;
        tc9pSetting.tc9_pr__OV_Payee_Deduction_Record__c = true;
        tc9pSetting.tc9_pr__OV_Payee_Leave_Event__c = true;
        tc9pSetting.tc9_pr__OV_Payee_Leave_Rule__c = true;
        tc9pSetting.tc9_pr__OV_Payee_Opening_Balance__c = true;
        tc9pSetting.tc9_pr__OV_Payee_Pay_Batch__c = true;
        tc9pSetting.tc9_pr__OV_Payee_Withholding_Rule__c = true;
        tc9pSetting.tc9_pr__OV_Payment_Detail__c = true;
        tc9pSetting.tc9_pr__OV_Payment_File__c = true;
        tc9pSetting.tc9_et__OV_Payment_Terms__c = true;
        tc9pSetting.tc9_et__OV_Pay_Rate_Loading__c = true;
        tc9pSetting.tc9_pr__OV_Pay_Transaction__c = true;
        tc9pSetting.tc9_et__OV_Rate_Calculator_Junction__c = true;
        tc9pSetting.tc9_et__OV_Rate_Calculator_Rate__c = true;
        tc9pSetting.tc9_pr__OV_Schedule__c = true;
        tc9pSetting.tc9_pr__OV_Schedule_Item__c = true;
        tc9pSetting.tc9_et__OV_Timesheet__c = true;
        tc9pSetting.tc9_et__OV_Timesheet_Entry__c = true;
        tc9pSetting.tc9_et__OV_Timesheet_Item__c = true;   
        return tc9pSetting;
    }
}