/**
*   Class         :  TimesheetAdjustmentBatchTest
*   Description   :  Test class for Timesheet Adjustment
*   Author        :  Skie
*   CreateDate    :  01/07/2022

    Change History
    ******************************************************************************************************************************************
         SCRUM        ModifiedBy        Date            Requested By                           Description                              Tag
    ******************************************************************************************************************************************
        SC-33849    Benoit          26/07/2022            Ben                 Update TimesheetAdjustmentBatchTest Class to remove Fields
        C9D-126     Tew             11/05/2023            Ben                 Update TimesheetAdjustmentBatchTest to check TSI & EXP mapping.
**/

@isTest
public class TimesheetAdjustmentBatchTest
{
    @TestSetup
    static void setupData()
    {
        Timesheet_Adjustment_Setting__c setting = new Timesheet_Adjustment_Setting__c();
        setting.Timesheet_Adjustment_Batch_Size__c = 1;
        insert setting;

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
        insert tc9pSetting;

        Account client = new Account();        
        client.Name = 'Test';
        client.tc9_pr__Available_Payment_Methods__c = 'Payee Cash';
        client.tc9_pr__Maximum_Payment_Distributions__c = '1';
        insert client;

        Contact contact = new Contact();
        contact.LastName = 'Test';
        insert contact;
    
        tc9_pr__Calendar__c timesheetCalendar = new tc9_pr__Calendar__c();
        timesheetCalendar.RecordTypeId = Schema.SObjectType.tc9_pr__Calendar__c.getRecordTypeInfosByDeveloperName().get('Timesheet').getRecordTypeId();
        timesheetCalendar.tc9_et__Timesheet_Frequency__c = 'Monthly';
        timesheetCalendar.tc9_et__Timesheet_Entry_Format__c = 'Start/End Times';
        timesheetCalendar.tc9_et__Break_Entry_Format__c = 'Total Minutes';
        timesheetCalendar.tc9_et__Monday__c = true;        
        timesheetCalendar.tc9_pr__Status__c = 'Active';        
        insert timesheetCalendar;

        tc9_et__Timesheet__c timesheet = new tc9_et__Timesheet__c();
        timesheet.ScheduledJobProcessed__c = true;
        timesheet.tc9_et__Approval_Status__c = 'Approved';
        timesheet.tc9_et__Transaction_Creation_Stage__c = '2';
        timesheet.tc9_et__Approved_Rejected_By__c = contact.Id;
        timesheet.tc9_et__Approved_Rejected_Date__c = System.now();            
        timesheet.tc9_et__Approved_Rejected_on_Behalf_User__c = UserInfo.getUserId();
        timesheet.tc9_et__Submitted_Date__c = System.now();
        insert timesheet;        

        tc9_et__Timesheet_Item__c timesheetItem = new tc9_et__Timesheet_Item__c();
        timesheetItem.tc9_et__Timesheet__c = timesheet.Id;
        timesheetItem.tc9_et__Employee__c = contact.Id;
        timesheetItem.tc9_et__Quantity__c = 1;
        timesheetItem.tc9_et__Date_Pay_Transaction_Generated__c = System.now();
        insert timesheetItem;

        tc9_pr__Calendar__c timesheetCalendar2 = new tc9_pr__Calendar__c();
        timesheetCalendar2.RecordTypeId = Schema.SObjectType.tc9_pr__Calendar__c.getRecordTypeInfosByDeveloperName().get('Timesheet').getRecordTypeId();
        timesheetCalendar2.tc9_et__Timesheet_Frequency__c = 'Weekly';
        timesheetCalendar2.tc9_et__Timesheet_Entry_Format__c = 'Start/End Times';
        timesheetCalendar2.tc9_et__Break_Entry_Format__c = 'Total Minutes';
        timesheetCalendar2.tc9_et__Monday__c = true;        
        timesheetCalendar2.tc9_pr__Status__c = 'Active';        
        insert timesheetCalendar2;
        
        tc9_pr__Calendar__c timesheetCalendar3 = new tc9_pr__Calendar__c();
        timesheetCalendar3.RecordTypeId = Schema.SObjectType.tc9_pr__Calendar__c.getRecordTypeInfosByDeveloperName().get('Timesheet').getRecordTypeId();
        timesheetCalendar3.tc9_et__Timesheet_Frequency__c = 'Fortnightly';
        timesheetCalendar3.tc9_et__Timesheet_Entry_Format__c = 'Start/End Times';
        timesheetCalendar3.tc9_et__Break_Entry_Format__c = 'Total Minutes';
        timesheetCalendar3.tc9_et__Monday__c = true;        
        timesheetCalendar3.tc9_pr__Status__c = 'Active';        
        timesheetCalendar3.tc9_et__Fortnightly_Start_Date__c = System.today();
        insert timesheetCalendar3;

        tc9_et__Timesheet_Entry__c timesheetEntry = new tc9_et__Timesheet_Entry__c();
        timesheetEntry.tc9_et__Timesheet__c = timesheet.Id;
        //timesheetEntry.Shift__c = shift.Id;     
        timesheetEntry.tc9_et__Employee__c = contact.Id;
        insert timesheetEntry;

        tc9_et__Invoice_Item__c invoiceItem = new tc9_et__Invoice_Item__c();
        insert invoiceItem;

        tc9_pr__Pay_Transaction__c payTransaction = new tc9_pr__Pay_Transaction__c();
        payTransaction.Name = 'Test PT';
        payTransaction.tc9_et__Timesheet__c = timesheet.Id;
        payTransaction.tc9_et__Invoice_Item__c = invoiceItem.Id;
        payTransaction.tc9_pr__Quantity__c = 21.75;      
        insert payTransaction;  

        tc9_et__Expense__c exp = new tc9_et__Expense__c();
        exp.tc9_et__Timesheet__c = timesheet.Id;
        exp.tc9_et__Expense_Description__c = 'Test Expense ';
        exp.tc9_et__Date_Incurred__c = System.today();
        exp.tc9_et__Taxable__c = false;
        exp.tc9_et__Expense_Total_Tax__c = 0.0;
        exp.tc9_et__Expense_Total_Ex_Tax__c =  100.0;
        exp.tc9_et__Expense_Total_Inc_Tax__c =  100.0;
        insert exp;
    }

    @isTest
    static void givenApprovedTimesheet_whenProcessTimesheetAdjustmentBatch_thenUpdateTsiAndTseAndExpenseSuccessfully()
    {
        tc9_et__Timesheet__c timesheet = [SELECT Id, TS_Adjustment_Approval_Status__c, tc9_et__Approved_Rejected_By__c FROM tc9_et__Timesheet__c LIMIT 1];
        timesheet.TS_Adjustment_Approval_Status__c = 'Approved';
        update timesheet;
        
        Test.startTest();
        TimesheetAdjustmentBatch b = new TimesheetAdjustmentBatch();
        b.execute(null); 
        Test.stopTest();      
        List<tc9_pr__Pay_Transaction__c> pts = [SELECT Id FROM tc9_pr__Pay_Transaction__c];
        Assert.areEqual(2, pts.size(), '2 transactions should be returned');        

        List<tc9_et__Timesheet_Item__c> tsis = [SELECT Id, tc9_et__Approval_Flag__c, tc9_et__Approved_Rejected_By__c FROM tc9_et__Timesheet_Item__c];
        Assert.areEqual(true, tsis.get(0).tc9_et__Approval_Flag__c);        
        Assert.areEqual(timesheet.tc9_et__Approved_Rejected_By__c, tsis.get(0).tc9_et__Approved_Rejected_By__c);   

        List<tc9_et__Expense__c> exps = [SELECT Id, tc9_et__Approval_Flag__c, tc9_et__Approved_Rejected_By__c, 
                                        tc9_et__Submitted_Date__c, tc9_et__Submitted_Flag__c
                                        FROM tc9_et__Expense__c];
        Assert.areEqual(true, exps.get(0).tc9_et__Approval_Flag__c);        
        Assert.areEqual(timesheet.tc9_et__Approved_Rejected_By__c, exps.get(0).tc9_et__Approved_Rejected_By__c);   
         

        tc9_et__Timesheet__c utimesheet = [SELECT Id, Reversed_Count__c FROM tc9_et__Timesheet__c LIMIT 1];
        Assert.areEqual(1, utimesheet.Reversed_Count__c);
    }

    @isTest
    static void givenNewTimesheet_whenProcessTimesheetAdjustmentBatch_thenUpdateTsiAndTseAndExpenseSuccessfully()
    {
        tc9_et__Timesheet__c timesheet = [SELECT Id, TS_Adjustment_Approval_Status__c, tc9_et__Approved_Rejected_By__c FROM tc9_et__Timesheet__c LIMIT 1];
        timesheet.TS_Adjustment_Approval_Status__c = 'New';
        update timesheet;
        
        Test.startTest();
        TimesheetAdjustmentBatch b = new TimesheetAdjustmentBatch();
        b.execute(null); 
        Test.stopTest(); 

        List<tc9_pr__Pay_Transaction__c> pts = [SELECT Id FROM tc9_pr__Pay_Transaction__c];
        Assert.areEqual(2, pts.size(), '2 transactions should be returned');        

        List<tc9_et__Timesheet_Item__c> tsis = [SELECT Id, tc9_et__Approval_Flag__c, tc9_et__Approved_Rejected_By__c, tc9_et__Submitted_Date__c, tc9_et__Submitted_Flag__c
                                                FROM tc9_et__Timesheet_Item__c];
        Assert.areEqual(false, tsis.get(0).tc9_et__Approval_Flag__c);        
        Assert.areEqual(null, tsis.get(0).tc9_et__Approved_Rejected_By__c);   
        Assert.areEqual(null, tsis.get(0).tc9_et__Submitted_Date__c);        
        Assert.areEqual(false, tsis.get(0).tc9_et__Submitted_Flag__c);    

        List<tc9_et__Expense__c> exps = [SELECT Id, tc9_et__Approval_Flag__c, tc9_et__Approved_Rejected_By__c, 
                                        tc9_et__Submitted_Date__c, tc9_et__Submitted_Flag__c
                                        FROM tc9_et__Expense__c];
        Assert.areEqual(false, exps.get(0).tc9_et__Approval_Flag__c);        
        Assert.areEqual(null, exps.get(0).tc9_et__Approved_Rejected_By__c);   
        Assert.areEqual(false, exps.get(0).tc9_et__Submitted_Flag__c);  

        tc9_et__Timesheet__c utimesheet = [SELECT Id, Reversed_Count__c FROM tc9_et__Timesheet__c LIMIT 1];
        Assert.areEqual(1, utimesheet.Reversed_Count__c);
    }

    @isTest
    static void givenSubmittedTimesheet_whenProcessTimesheetAdjustmentBatch_thenUpdateTsiAndTseAndExpenseSuccessfully()
    {
        tc9_et__Timesheet__c timesheet = [SELECT Id, TS_Adjustment_Approval_Status__c, tc9_et__Approved_Rejected_By__c FROM tc9_et__Timesheet__c LIMIT 1];
        timesheet.TS_Adjustment_Approval_Status__c = 'Submitted';
        update timesheet;
        
        Test.startTest();
        TimesheetAdjustmentBatch b = new TimesheetAdjustmentBatch();
        b.execute(null); 
        Test.stopTest();      
        List<tc9_pr__Pay_Transaction__c> pts = [SELECT Id FROM tc9_pr__Pay_Transaction__c];
        Assert.areEqual(2, pts.size(), '2 transactions should be returned');        

        List<tc9_et__Timesheet_Item__c> tsis = [SELECT Id, tc9_et__Approval_Flag__c, tc9_et__Approved_Rejected_By__c, 
                                                tc9_et__Submitted_Date__c, tc9_et__Submitted_Flag__c
                                                FROM tc9_et__Timesheet_Item__c];
        Assert.areEqual(false, tsis.get(0).tc9_et__Approval_Flag__c);        
        Assert.areEqual(null, tsis.get(0).tc9_et__Approved_Rejected_By__c);   
        Assert.areEqual(true, tsis.get(0).tc9_et__Submitted_Flag__c);        

        List<tc9_et__Expense__c> exps = [SELECT Id, tc9_et__Approval_Flag__c, tc9_et__Approved_Rejected_By__c, 
                                        tc9_et__Submitted_Date__c, tc9_et__Submitted_Flag__c
                                        FROM tc9_et__Expense__c];
        Assert.areEqual(false, exps.get(0).tc9_et__Approval_Flag__c);        
        Assert.areEqual(null, exps.get(0).tc9_et__Approved_Rejected_By__c);   
        Assert.areEqual(true, exps.get(0).tc9_et__Submitted_Flag__c);        

        tc9_et__Timesheet__c utimesheet = [SELECT Id, Reversed_Count__c FROM tc9_et__Timesheet__c LIMIT 1];
        Assert.areEqual(1, utimesheet.Reversed_Count__c);
    }

    @isTest
    static void givenTestUpdatePtFail_whenProcessTimesheetAdjustmentBatch_thenRollbackAndCreateDebugLogs()
    {
        tc9_et__Timesheet__c timesheet = [SELECT Id, TS_Adjustment_Approval_Status__c, tc9_et__Approved_Rejected_By__c FROM tc9_et__Timesheet__c LIMIT 1];
        timesheet.TS_Adjustment_Approval_Status__c = 'Submitted';
        update timesheet;
        
        Test.startTest();
        TimesheetAdjustmentBatch b = new TimesheetAdjustmentBatch();
        b.isTestUpdatePtFail = true;
        Database.executeBatch(b, 200);
             
        Test.stopTest();      
        List<tc9_pr__Pay_Transaction__c> pts = [SELECT Id FROM tc9_pr__Pay_Transaction__c];
        Assert.areEqual(1, pts.size(), '1 transactions should be returned');        

        List<tc9_pr__Debug_Log__c> logs = [SELECT Id FROM tc9_pr__Debug_Log__c];
        Assert.areNotEqual(0, logs.size(), 'Debug logs must be created');
    }
}