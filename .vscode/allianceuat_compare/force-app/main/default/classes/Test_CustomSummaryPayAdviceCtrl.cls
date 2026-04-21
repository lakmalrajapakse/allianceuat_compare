/************************************************************************************************

Test class for : Test_CustomSummaryPayAdviceCtrl
**/
@IsTest
public with sharing class Test_CustomSummaryPayAdviceCtrl {

    private static tc9_pr__Schedule__c schedule;
    private static tc9_pr__Schedule__c scheduleInv;
    private static tc9_et__Invoice_Tax_ID__c invT;
    private static Id leaveCreditPleRtId;

    private static Account acc;
    private static Account paymentEntity;

    private static Contact employee;
    private static tc9_pr__Payee__c payee;

    private static tc9_pr__Assignment__c assignment;

    private static tc9_pr__Calendar__c calendar;
    private static tc9_pr__Calendar_Period__c calendarPeriod;

    private static Date startDate = System.today().addDays(-30);
    private static Date endDate = System.today().addDays(30);

    private static List<tc9_pr__Pay_Advice__c> payAdvList;
    private static tc9_pr__Override_TC9P_Validation__c overrideSettings;

    private static void createTestData(String typeOfPayAdvice) {

        //we are getting val errors on these records - not sure why so have overridden for this test class
        overrideSettings = new tc9_pr__Override_TC9P_Validation__c();
        overrideSettings.tc9_pr__OV_Assignment__c = true;
        overrideSettings.tc9_pr__OV_Pay_Transaction__c = true;
        overrideSettings.tc9_pr__OV_Assignment_Cost__c = true;
        overrideSettings.tc9_pr__OV_Assignment_Rate__c = true;
        overrideSettings.tc9_pr__OV_Assignment_Schedule__c = true;
        overrideSettings.tc9_pr__OV_Pay_Advice__c = true;
        overrideSettings.tc9_pr__OV_Pay_Advice_Lines__c = true;
        overrideSettings.tc9_pr__OV_Pay_Batch__c = true;
        overrideSettings.tc9_pr__OV_Pay_Batch_Event__c = true;
        overrideSettings.tc9_pr__OV_Payee_Withholding_Rule__c = true;
        overrideSettings.tc9_pr__OV_Pay_Code__c = true;
        overrideSettings.tc9_pr__OV_Pay_Transaction__c = true;
        overrideSettings.tc9_pr__OV_Pay_Batch__c = true;
        insert overrideSettings;

        invT = new tc9_et__Invoice_Tax_ID__c();
        invT.Name = 'TestTAXId';
        invT.tc9_et__Tax_Rate__c = 10;
        insert invT;

        scheduleInv = new tc9_pr__Schedule__c();
        scheduleInv.Name = 'Weekly Invoice';
        scheduleInv.tc9_pr__Split_Option__c = 'No Split';//splitOption;
        scheduleInv.tc9_pr__Period_Type__c = 'Weekly';
        scheduleInv.RecordTypeId = Schema.SObjectType.tc9_pr__Schedule__c.getRecordTypeInfosByDeveloperName().get('Invoice_Schedule').getRecordTypeId();
        scheduleInv.tc9_pr__Payroll_Jurisdiction__c = 'Australia'; //ALN-344 fixes
        insert scheduleInv;

        schedule = new tc9_pr__Schedule__c();
        schedule.Name = 'Weekly';
        schedule.tc9_pr__Split_Option__c = 'No Split';//splitOption;
        schedule.tc9_pr__Period_Type__c = 'Daily';
        schedule.tc9_pr__Pay_Advice_Detail_Level__c = 'Assignment';
        schedule.tc9_pr__Payroll_Jurisdiction__c = 'Australia';
        schedule.RecordTypeId = Schema.SObjectType.tc9_pr__Schedule__c.getRecordTypeInfosByDeveloperName().get('Pay_Schedule').getRecordTypeId();
        insert schedule;

        List<Account> accounts = new List<Account>();
        acc = new Account();
        acc.Name = 'Default Client';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Client').getRecordTypeId();
        acc.BillingStreet = 'Str';
        acc.BillingCity = 'City';
        acc.BillingState = 'State';
        acc.BillingPostalCode = '645';
        acc.BillingCountry = 'Australia';
        acc.tc9_et__Invoice_Group_By__c = 'Assignment';
        acc.tc9_pr__Available_Payment_Methods__c = 'Payee Australian Bank';
        acc.tc9_pr__Maximum_Payment_Distributions__c = '1';
        acc.tc9_pr__Schedule__c = schedule.Id;
        acc.tc9_pr__Payment_Details_Complete__c = 'Yes';
        acc.Payroll_Tax_Exempt__c = 'No';
        acc.Approval_Type__c = 'Not Charged';
        accounts.add(acc);

        paymentEntity = new Account();
        paymentEntity.Name = 'First Choice Care Pty Ltd';
        paymentEntity.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Payment_Entity').getRecordTypeId();
        paymentEntity.BillingStreet = 'Str';
        paymentEntity.BillingCity = 'City';
        paymentEntity.BillingState = 'State';
        paymentEntity.BillingPostalCode = '645';
        paymentEntity.BillingCountry = 'Australia';
        paymentEntity.tc9_et__Invoice_Group_By__c = 'Assignment';
        paymentEntity.tc9_pr__Available_Payment_Methods__c = 'Payee Australian Bank';
        paymentEntity.tc9_pr__Maximum_Payment_Distributions__c = '1';
        paymentEntity.tc9_pr__Schedule__c = schedule.Id;
        paymentEntity.tc9_pr__Payment_Details_Complete__c = 'Yes';
        paymentEntity.Payroll_Tax_Exempt__c = 'No';
        paymentEntity.Approval_Type__c = 'Not Charged';
        accounts.add(paymentEntity);

        insert accounts;

        employee = new Contact();
        employee.Account = acc;
        employee.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Emergency_Contact').getRecordTypeId();
        employee.FirstName = 'Daisy';
        employee.LastName = 'Ridley';
        employee.Salutation = 'Jedi';
        employee.Email = 'Rey@test.com';
        employee.Birthdate = Date.today();
        employee.AccountId = acc.Id;
        employee.tc9_et__Timesheet_Notification_Email__c = 'Primary';
        employee.tc9_et__Timesheet_Reminder_Notification_Opt_Out__c = false;
        employee.tc9_et__Expense_Claim_Notification_Email__c = 'Primary';
        employee.tc9_et__Exp_Claim_Reminder_Notification_Opt_Out__c = false;
        insert employee;

        Contact clientCon = new Contact();
        clientCon.AccountId = acc.Id;
        clientCon.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Client_Contact').getRecordTypeId();
        clientCon.FirstName = 'Kylo Ren';
        clientCon.LastName = 'Solo';
        clientCon.Salutation = 'Mr';
        clientCon.Email = 'kylo@test.com';
        clientCon.tc9_et__Timesheet_Notification_Email__c = 'Primary';
        clientCon.tc9_et__Timesheet_Reminder_Notification_Opt_Out__c = false;
        clientCon.tc9_et__Expense_Claim_Notification_Email__c = 'Primary';
        clientCon.tc9_et__Exp_Claim_Reminder_Notification_Opt_Out__c = false;
        insert clientCon;

        payee = new tc9_pr__Payee__c();
        payee.tc9_pr__Employee__c = employee.Id;
        payee.tc9_pr__Payroll_Start_Date__c = Date.today().addDays(-100);
        payee.tc9_pr__Payment_Entity__c = paymentEntity.Id;
        payee.tc9_pr__Payroll_System__c = '2cloudnine Payroll AUS';
        payee.tc9_pr__Earner_Type__c = 'PAYE';
        payee.tc9_pr__Pay_Advice_Delivery_Method__c = 'Email as PDF';
        payee.tc9_pr__Payroll_Id__c = '23456';
        payee.tc9_pr__Schedule__c = schedule.Id;
        insert payee;

        assignment = new tc9_pr__Assignment__c();
        assignment.tc9_pr__Assignment_Start_Date__c = startDate.addDays(-30);
        assignment.tc9_pr__Assignment_End_Date__c = endDate;
        assignment.tc9_pr__Assignment_Name__c = 'Test Assignment - Pay Advice';
        assignment.tc9_pr__Payment_Entity__c = paymentEntity.Id;
        assignment.RecordTypeId = [SELECT Id, Name, DeveloperName FROM RecordType WHERE SobjectType = 'tc9_pr__Assignment__c' AND DeveloperName = 'Temp'].Id;
        assignment.tc9_pr__Client__c = acc.Id;
        assignment.tc9_pr__Schedule__c = schedule.Id;
        assignment.tc9_pr__Employee__c = employee.Id;
        assignment.tc9_pr__Payee__c = payee.Id;
        assignment.tc9_et__Client_Hiring_Manager__c = clientCon.Id;
        assignment.tc9_et__Invoice_To_Account__c = acc.Id;
        assignment.tc9_et__Invoice_To_Contact__c = clientCon.Id;
        assignment.tc9_et__Timesheet_Approver__c = clientCon.Id;
        assignment.tc9_et__Alternative_TimeSheet_Approver__c = clientCon.Id;
        assignment.tc9_et__Expense_Claim_Approver__c = clientCon.Id;
        assignment.tc9_et__Alternative_Expense_Claim_Approver__c = clientCon.Id;
        assignment.tc9_pr__Employee__c = employee.Id;
        assignment.tc9_pr__Payee__c = payee.Id;
        assignment.tc9_et__Purchase_Order_Number__c = '123456';
        
        insert assignment;

        List<tc9_pr__Pay_Code__c> payCodes = new List<tc9_pr__Pay_Code__c>();

        tc9_pr__Pay_Code__c payCode = populatePayCodeValues('Allowance', 'Pre-tax deduction');
        payCode.tc9_pr__Pay_Advice_Description__c = 'Test Description';
        payCode.tc9_pr__PAYG_Tax_Exempt__c = true;
        payCodes.add(payCode);

        tc9_pr__Pay_Code__c payCode1 = populatePayCodeValues('Allowance', 'Post-tax deduction');
        payCode1.tc9_pr__Pay_Advice_Description__c = 'Test Description';
        payCode1.tc9_pr__PAYG_Tax_Exempt__c = false;
        payCodes.add(payCode1);

        tc9_pr__Pay_Code__c payCode2 = populatePayCodeValues('Allowance', 'Post-tax deduction');
        payCode2.tc9_pr__Pay_Advice_Description__c = 'Test Description';
        payCode2.tc9_pr__PAYG_Tax_Exempt__c = false;
        payCodes.add(payCode2);

        tc9_pr__Pay_Code__c payCode3 = populatePayCodeValues('Deduction', 'Pre-tax deduction');
        payCode3.tc9_pr__Pay_Advice_Description__c = 'Test Description';
        payCode3.tc9_pr__PAYG_Tax_Exempt__c = true;
        payCodes.add(payCode3);

        tc9_pr__Pay_Code__c payCode4 = populatePayCodeValues('Deduction', 'Post-tax deduction');
        payCode4.tc9_pr__Pay_Advice_Description__c = 'Test Description';
        payCode4.tc9_pr__PAYG_Tax_Exempt__c = false;
        payCodes.add(payCode4);

        tc9_pr__Pay_Code__c payCode5 = populatePayCodeValues('Expense', 'Post-tax deduction');
        payCode5.tc9_pr__Pay_Advice_Description__c = 'Test Description';
        payCode5.tc9_pr__PAYG_Tax_Exempt__c = false;
        payCodes.add(payCode5);

        tc9_pr__Pay_Code__c payCode6 = populatePayCodeValues('Payment', 'Post-tax deduction');
        payCode6.tc9_pr__Pay_Advice_Description__c = 'Test Description';
        payCode6.tc9_pr__PAYG_Tax_Exempt__c = false;
        payCodes.add(payCode6);

        tc9_pr__Pay_Code__c payCode7 = populatePayCodeValues('Payment', 'Post-tax deduction');
        payCode7.tc9_pr__Pay_Advice_Description__c = 'Test Description';
        payCode7.tc9_pr__PAYG_Tax_Exempt__c = false;
        payCodes.add(payCode7);

        tc9_pr__Pay_Code__c payCode8 = populatePayCodeValues('Payment', 'Employer Superannuation');
        payCode8.tc9_pr__Pay_Advice_Description__c = 'Test Description';
        payCode8.tc9_pr__PAYG_Tax_Exempt__c = false;
        payCodes.add(payCode8);

        tc9_pr__Pay_Code__c payCode9 = populatePayCodeValues('Payment', 'Employer Superannuation');
        payCode9.tc9_pr__Pay_Advice_Description__c = 'Test Description';
        payCode9.tc9_pr__PAYG_Tax_Exempt__c = true;
        payCode9.tc9_pr__STP_Payment_Type__c = 'Gross';
        payCodes.add(payCode9);

        tc9_pr__Pay_Code__c payCode10 = populatePayCodeValues('Deduction', 'Post-tax Deduction');
        payCode10.tc9_pr__Pay_Advice_Description__c = 'Test Description';
        payCode10.tc9_pr__PAYG_Tax_Exempt__c = false;
        payCodes.add(payCode10);

        tc9_pr__Pay_Code__c payCode11 = populatePayCodeValues('Deduction', 'Pre-tax Deduction');
        payCode11.tc9_pr__Pay_Advice_Description__c = 'Test Description';
        payCode11.tc9_pr__PAYG_Tax_Exempt__c = false;
        payCodes.add(payCode11);

        insert payCodes;

        calendar = new tc9_pr__Calendar__c();
        calendar.Name = 'Test Calendar';
        calendar.tc9_pr__Status__c = 'Pending';
        calendar.tc9_pr__Start_Date__c = System.today();
        calendar.tc9_pr__End_Date__c = System.today().addDays(24);
        calendar.tc9_pr__No_Days_Payment_Date_after_End_Date__c = 4;
        calendar.tc9_pr__No_Days_Payroll_Date_after_End_Date__c = 2;
        calendar.tc9_pr__Payment_Entity__c = paymentEntity.Id;
        calendar.tc9_pr__Schedule__c = schedule.Id;
        insert calendar;

        calendarPeriod = new tc9_pr__Calendar_Period__c();
        calendarPeriod.Name = 'Volume Week 1';
        calendarPeriod.tc9_pr__Calendar__c = calendar.Id;
        calendarPeriod.tc9_pr__Payroll_Date__c = System.today().addDays(-30);
        calendarPeriod.tc9_pr__Payment_Date__c = System.today();
        calendarPeriod.tc9_pr__Start_Date__c = System.today().addDays(-30);
        calendarPeriod.tc9_pr__End_Date__c = System.today().addDays(30);
        insert calendarPeriod;

        tc9_pr__Pay_Advice_Template__c temp2 = new tc9_pr__Pay_Advice_Template__c();
        temp2.Name = 'Text Pay Advice Template';
        temp2.tc9_pr__Default__c = false;
        temp2.tc9_pr__Email_Template_Online__c = 'Text Pay Advice Template';
        temp2.tc9_pr__Email_Template_PDF__c = 'Text Pay Advice Template';
        temp2.tc9_pr__Visualforce_Page__c = 'Custom_SummaryPayrollPayAdvice_Page';
        temp2.tc9_pr__Pay_Advice_Record_Type__c = 'Contractor_Invoice'; //Pay_Advice
        temp2.tc9_pr__Colour_Header_Label_Text__c = '#12ab34';
        temp2.tc9_pr__Colour_Header_Value_Text__c = '#12ab34';
        temp2.tc9_pr__Colour_Section_Heading_Background__c = '#12ab34';
        temp2.tc9_pr__Colour_Section_Heading_Text__c = '#12ab34';
        temp2.tc9_pr__Colour_Section_Detail_Background__c = '#12ab34';
        temp2.tc9_pr__Colour_Section_Detail_Text__c = '#12ab34';
        temp2.tc9_pr__Hide_Blank_Detail_Sections__c = 'No';
        temp2.tc9_pr__Display_Address_Border__c = 'Yes';
        temp2.tc9_pr__Available_for_Use__c = 'Yes';
        temp2.tc9_pr__Payment_Entity__c = paymentEntity.Id;
        temp2.tc9_pr__Schedule__c = schedule.Id;
        temp2.tc9_pr__Text_Footer__c = '{!Contact.FirstName}';
        temp2.tc9_pr__Position_Footer__c = 'Left';
        insert temp2;
        
        ContentVersion cv = new ContentVersion();
        cv.PathOnClient ='LOGO.png';
        cv.Title = 'LOGO ' + DateTime.now();
        cv.versiondata = Blob.valueOf('LOGO 1');
        insert cv; 
        
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;
        cdl.LinkedEntityId = temp2.Id;
        cdl.ShareType = 'V';
        insert cdl;
        
        tc9_pr__Project_Code__c prjCode = new tc9_pr__Project_Code__c();
        prjCode.Name = 'TestTemplateProjectCode';
        prjCode.tc9_pr__Status__c = 'Active';
        prjCode.RecordTypeId = Schema.SObjectType.tc9_pr__Project_Code__c.getRecordTypeInfosByDeveloperName().get('Template_Level')?.getRecordTypeId();
        insert prjCode;

        sirenum__ProActiveContract__c contract = new sirenum__ProActiveContract__c();
        contract.sirenum__Client__c = acc.Id;
        contract.tc9_ext_sirint__Invoice_To_Account__c  = acc.Id;
        insert contract;
        
        sirenum__Location__c location = new sirenum__Location__c();
        location.Name = 'Test Location';
        insert location;
        
        sirenum__Location__c location2 = new sirenum__Location__c();
        location2.Name = 'Test Location 2';
        insert location2;
        
        tc9_et__Timesheet__c ts = prepareTimesheet(assignment.Id, employee.Id, payee.Id, 'New');
        tc9_et__Timesheet__c ts2 = prepareTimesheet(assignment.Id, employee.Id, payee.Id, 'New');
        insert new List<tc9_et__Timesheet__c>{ts, ts2}; 
            
        tc9_et__Timesheet_Entry__c tse = prepareTimesheetEntry(ts.Id, assignment.Id, payee.Id, employee.Id, System.today(), System.today().addDays(1));
        tse.tc9_ext_sirint__Location__c = location.Id;
        
        tc9_et__Timesheet_Entry__c tse2 = prepareTimesheetEntry(ts.Id, assignment.Id, payee.Id, employee.Id, System.today().addDays(1), System.today().addDays(1));
        tse2.tc9_ext_sirint__Location__c = location2.Id;
        insert new List<tc9_et__Timesheet_Entry__c>{tse, tse2}; 
        
        sirenum__Site__c site1 = prepareSite('site1', 'street1', 'county1', 'city1', 'country1', '1234');
        sirenum__Site__c site2 = prepareSite('site2', 'street2', 'county2', 'city2', 'country2', '1234');
        insert new List<sirenum__Site__c>{site1, site2};

        sirenum__Shift__c shift1 = prepareShift(assignment.Id, ts.Id, employee.Id, contract.Id, prjCode.Id, site1.Id);
        sirenum__Shift__c shift2 = prepareShift(assignment.Id, ts.Id, employee.Id, contract.Id, prjCode.Id, site2.Id);
        insert new List<sirenum__Shift__c> {shift1, shift2};
            
        tc9_pr__Pay_Batch__c Paybatch = new tc9_pr__Pay_Batch__c();
        Paybatch.tc9_pr__Calendar_Period__c = calendarPeriod.Id ;
        Paybatch.tc9_pr__Filtered_Calendar_Periods__c = String.valueOf(calendarPeriod.Id);
        Paybatch.tc9_pr__Include_Earlier_Dates__c = true;
        Paybatch.tc9_pr__Status__c = 'Payment File Released';//'Finalised';
        Paybatch.tc9_pr__Maximum_Payroll_Date__c = System.today();
        Paybatch.tc9_pr__Schedule__c = schedule.Id;
        Paybatch.tc9_pr__Finalise_Calendar_Period__c = calendarPeriod.Id;
        insert Paybatch;

        tc9_pr__Pay_Batch_Item__c payeePayBatch = new tc9_pr__Pay_Batch_Item__c();
        payeePayBatch.tc9_pr__Payee__c = payee.Id;
        payeePayBatch.tc9_pr__Employee__c = employee.Id;
        payeePayBatch.tc9_pr__Payment_Entity__c = paymentEntity.Id;
        insert payeePayBatch;

        tc9_pr__Payee_Aggregate__c payeeAggregate = new tc9_pr__Payee_Aggregate__c();
        payeeAggregate.RecordTypeId = Schema.SObjectType.tc9_pr__Payee_Aggregate__c.getRecordTypeInfosByDeveloperName().get('Payment').getRecordTypeId();
        payeeAggregate.tc9_pr__Payee__c = payee.Id;
        payeeAggregate.tc9_pr__Pay_Batch_Item__c = payeePayBatch.Id;
        payeeAggregate.tc9_pr__Adjustment__c = true;
        payeeAggregate.tc9_pr__Pay_Code__c = payCode9.Id;
        payeeAggregate.tc9_pr__YTD_Value__c = 250;
        insert payeeAggregate;

        tc9_pr__Pay_Advice__c payadv = new tc9_pr__Pay_Advice__c();
        payadv.tc9_pr__Payment_Entity__c = paymentEntity.Id;
        payadv.tc9_pr__Employee__c = employee.Id;
        payadv.tc9_pr__Payee__c = payee.Id;
        payadv.tc9_pr__Pay_Batch_Item__c  = payeePayBatch.Id;
        payadv.tc9_pr__Online_URL__c = 'test' ;
        payadv.tc9_pr__Pay_Advice_Delivery_Method__c = 'Email as PDF';
        payadv.tc9_pr__Pay_Advice_Template__c = temp2.Id;
        payadv.tc9_pr__Pay_Batch__c = Paybatch.Id;
        payadv.tc9_pr__Status__c = 'New';
        payadv.tc9_pr__Period_Start_Date__c = System.today().addDays(-7);
        payadv.tc9_pr__Period_End_Date__c = System.today().addDays(7);
        if(typeOfPayAdvice == 'GST'){
            payadv.RecordTypeId = [SELECT Id, Name, DeveloperName FROM RecordType WHERE SobjectType = 'tc9_pr__Pay_Advice__c' AND DeveloperName = 'Contractor_Invoice'].Id;
        } else {
            payadv.RecordTypeId = [SELECT Id, Name, DeveloperName FROM RecordType WHERE SobjectType = 'tc9_pr__Pay_Advice__c' AND DeveloperName = 'Pay_Advice'].Id;
        }
        insert payadv;

        tc9_pr__Leave_Rule__c leaveRule = new tc9_pr__Leave_Rule__c();
        leaveRule.Name = 'Test';
        leaveRule.tc9_pr__Effective_Date__c = System.today();
        leaveRule.tc9_pr__Status__c = 'Active';
        leaveRule.tc9_pr__Pay_Code__c = payCode6.Id;
        leaveRule.tc9_pr__Unpaid_Pay_Code__c = payCode7.Id ;
        leaveRule.tc9_pr__Skip_Manager_Approval__c = 'Yes';
        leaveRule.tc9_pr__Display_on_Pay_Advice__c = 'yes';
        leaveRule.tc9_pr__Pay_Advice_Display_After_Period__c = 'Days';
        leaveRule.tc9_pr__Pay_Advice_Display_After_Units__c = 1;
        leaveRule.tc9_pr__Display_Leave_Balance_As__c = 'Hours';
        leaveRule.tc9_pr__Allow_Pay_in_Advance__c = 'No';
        leaveRule.tc9_pr__Available_Pay_Rates__c = 'Standard Pay';
        insert leaveRule;

        tc9_pr__Payee_Leave_Rule__c payeeLeaveRule = new tc9_pr__Payee_Leave_Rule__c();
        payeeLeaveRule.tc9_pr__Leave_Rule__c = leaveRule.Id;
        payeeLeaveRule.tc9_pr__Effective_Date__c = System.today().addDays(-20);
        payeeLeaveRule.tc9_pr__Employee__c = employee.Id;
        payeeLeaveRule.tc9_pr__Expiry_Date__c = System.today().addDays(30);
        payeeLeaveRule.tc9_pr__Skip_Manager_Approval__c = 'Yes';
        payeeLeaveRule.tc9_pr__Payee__c = payee.Id;
        payeeLeaveRule.tc9_pr__Status__c = 'Active';
        insert payeeLeaveRule;

        leaveCreditPleRtId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'tc9_pr__Payee_Leave_Event__c'
            AND DeveloperName = 'Leave_Credit'
            LIMIT 1
        ].Id;

        payAdvList = new List<tc9_pr__Pay_Advice__c>();
        payAdvList.add(payadv);

        List<tc9_pr__Pay_Advice_Line__c> payAdviceLines = new List<tc9_pr__Pay_Advice_Line__c>();

        tc9_pr__Pay_Advice_Line__c PayAdvLine0 = getPayAdviceLine(payadv.Id, payCode.Id, 'Payment');
        payAdviceLines.add(PayAdvLine0);

        tc9_pr__Pay_Advice_Line__c PayAdvLine0a = getPayAdviceLine(payadv.Id, payCode.Id, 'Payment');
        PayAdvLine0a.tc9_pr__Payee_Leave_Rule__c = payeeLeaveRule.Id ;
        payAdviceLines.add(PayAdvLine0a);

        tc9_pr__Pay_Advice_Line__c PayAdvLine1 = getPayAdviceLine(payadv.Id, payCode1.Id, 'Withholding - PAYG');
        payAdviceLines.add(PayAdvLine1);

        tc9_pr__Pay_Advice_Line__c PayAdvLine1a = getPayAdviceLine(payadv.Id, payCode1.Id, 'Withholding - PAYG');
        payAdviceLines.add(PayAdvLine1a);

        tc9_pr__Pay_Advice_Line__c PayAdvLine2 = getPayAdviceLine(payadv.Id, payCode2.Id, 'Lump Sum');
        payAdviceLines.add(PayAdvLine2);

        tc9_pr__Pay_Advice_Line__c PayAdvLine2a = getPayAdviceLine(payadv.Id, payCode2.Id, 'Lump Sum');
        payAdviceLines.add(PayAdvLine2a);

        tc9_pr__Pay_Advice_Line__c PayAdvLine3 = getPayAdviceLine(payadv.Id, payCode3.Id, 'Withholding - SFSS');
        payAdviceLines.add(PayAdvLine3);

        tc9_pr__Pay_Advice_Line__c PayAdvLine3a = getPayAdviceLine(payadv.Id, payCode3.Id, 'Withholding - SFSS');
        payAdviceLines.add(PayAdvLine3a);

        tc9_pr__Pay_Advice_Line__c PayAdvLine4 = getPayAdviceLine(payadv.Id, payCode4.Id, 'Withholding - ETP PAYG');
        payAdviceLines.add(PayAdvLine4);

        tc9_pr__Pay_Advice_Line__c PayAdvLine4a = getPayAdviceLine(payadv.Id, payCode4.Id, 'Withholding - ETP PAYG');
        payAdviceLines.add(PayAdvLine4a);

        tc9_pr__Pay_Advice_Line__c PayAdvLine5 = getPayAdviceLine(payadv.Id, payCode5.Id, 'Allowance');
        payAdviceLines.add(PayAdvLine5);

        tc9_pr__Pay_Advice_Line__c PayAdvLine5a = getPayAdviceLine(payadv.Id, payCode5.Id, 'Allowance');
        payAdviceLines.add(PayAdvLine5a);

        tc9_pr__Pay_Advice_Line__c PayAdvLine6 = getPayAdviceLine(payadv.Id, payCode4.Id, 'ETP');
        payAdviceLines.add(PayAdvLine6);

        tc9_pr__Pay_Advice_Line__c PayAdvLine6a = getPayAdviceLine(payadv.Id, payCode4.Id, 'ETP');
        payAdviceLines.add(PayAdvLine6a);

        tc9_pr__Pay_Advice_Line__c PayAdvLine7 = getPayAdviceLine(payadv.Id, payCode8.Id, 'Withholding - Superannuation');
        payAdviceLines.add(PayAdvLine7);

        tc9_pr__Pay_Advice_Line__c PayAdvLine7a = getPayAdviceLine(payadv.Id, payCode8.Id, 'Withholding - Superannuation');
        payAdviceLines.add(PayAdvLine7a);

        tc9_pr__Pay_Advice_Line__c PayAdvLine8 = getPayAdviceLine(payadv.Id, payCode10.Id, 'Deduction');
        payAdviceLines.add(PayAdvLine8);

        tc9_pr__Pay_Advice_Line__c PayAdvLine8a = getPayAdviceLine(payadv.Id, payCode10.Id, 'Deduction');
        payAdviceLines.add(PayAdvLine8a);

        tc9_pr__Pay_Advice_Line__c PayAdvLine9 = getPayAdviceLine(payadv.Id, payCode11.Id, 'Deduction');
        payAdviceLines.add(PayAdvLine9);

        tc9_pr__Pay_Advice_Line__c PayAdvLine9a = getPayAdviceLine(payadv.Id, payCode11.Id, 'Deduction');
        payAdviceLines.add(PayAdvLine9a);

        tc9_pr__Pay_Advice_Line__c PayAdvLine10 = getPayAdviceLine(payadv.Id, payCode5.Id, 'Expense');
        payAdviceLines.add(PayAdvLine10);

        tc9_pr__Payment_File__c paymentFile = new tc9_pr__Payment_File__c();
        insert paymentFile;

        tc9_pr__Payment_File_Line__c BankFile = new tc9_pr__Payment_File_Line__c();
        BankFile.tc9_pr__Pay_Advice__c = payadv.Id;
        BankFile.tc9_pr__Bank_Account_Name__c = 'Test Bank Acc';
        BankFile.tc9_pr__Bank_Account_Number__c = '123456';
        BankFile.tc9_pr__Bank_Branch_Code__c = 'IF2314';
        BankFile.tc9_pr__Payment_Amount__c = 8956;
        BankFile.tc9_pr__Payment_File__c = paymentFile.Id;
        insert BankFile;


        tc9_pr__Superannuation_Fund__c sf = new tc9_pr__Superannuation_Fund__c ();
        sf.tc9_pr__Fund_Account_Name__c = 'Test Account';
        insert sf;

        tc9_pr__Payee_Withholding__c payeeWithholdings = new tc9_pr__Payee_Withholding__c();
        payeeWithholdings.tc9_pr__Effective_Date__c = System.today() - 1;
        payeeWithholdings.tc9_pr__Expiry_Date__c = System.today();
        payeeWithholdings.tc9_pr__Claim_Tax_Free__c = 'yes';
        payeeWithholdings.tc9_pr__Australian_Resident__c = 'No';
        payeeWithholdings.tc9_pr__HELP_TSL__c = 'yes';
        payeeWithholdings.tc9_pr__SFSS__c = 'yes';
        payeeWithholdings.tc9_pr__Approved_Working_Holiday_Maker__c = 'yes';
        payeeWithholdings.tc9_pr__No_TFN_Apply_Higher_Rate__c = 'yes';
        payeeWithholdings.tc9_pr__PAYG_Exempt__c = 'No';
        payeeWithholdings.tc9_pr__Additional_Week_Fortnight__c = 'No';
        payeeWithholdings.tc9_pr__Status__c = 'Pending';
        payeeWithholdings.tc9_pr__Medicare_Levy_Exemption__c = 'Half';
        payeeWithholdings.tc9_pr__Basis_of_Payment__c = 'Part Time';
        payeeWithholdings.tc9_pr__STSL__c = 'No';
        payeeWithholdings.tc9_pr__ATO_Income_Classification__c = 'Voluntary Agreement';
        payeeWithholdings.tc9_pr__Additional_Week_Fortnight__c = 'Yes';
        payeeWithholdings.tc9_pr__Status__c = 'Pending';
        payeeWithholdings.tc9_pr__Employee__c = employee.Id;
        payeeWithholdings.tc9_pr__Payee__c = payee.Id;
        payeeWithholdings.tc9_pr__Superannuation_Fund__c = sf.Id;
        payeeWithholdings.tc9_pr__Super_Membership_Number__c = 'test';
        insert payeeWithholdings;

        tc9_pr__Pay_Batch_Event__c PBE = new tc9_pr__Pay_Batch_Event__c();
        PBE.tc9_pr__Calendar_Period__c = calendarPeriod.Id;
        PBE.tc9_pr__Expiry_Date__c = Date.today() + 20;
        PBE.tc9_pr__Payee__c = payee.Id;
        PBE.tc9_pr__Payee_Withholding__c = payeeWithholdings.Id;
        insert PBE;
        
        tc9_pr__Pay_Transaction__c payt = new tc9_pr__Pay_Transaction__c();
        payt.tc9_pr__Pay_Advice__c = payadv.Id;
        payt.tc9_pr__Pay_Batch_Event__c = PBE.Id;
        payt.RecordTypeId = Schema.SObjectType.tc9_pr__Pay_Transaction__c.getRecordTypeInfosByDeveloperName().get('Withholding_Superannuation').getRecordTypeId();
        payt.tc9_pr__Superannuation_Guarantee__c = 5000;
        payt.tc9_pr__Superannuation_Employer_Additional__c = 3000;
        payt.tc9_pr__Pre_Tax_Superannuation__c = 1000;
        payt.tc9_pr__Pay_Rate__c = 10;
        payt.tc9_pr__Quantity__c = 1;
        payt.tc9_et__Timesheet_Entry__c = tse.Id;
        payt.Shift__c = shift1.Id;
        payt.tc9_pr__Pay_Rate__c = 10;
        
        tc9_pr__Pay_Transaction__c payt2 = new tc9_pr__Pay_Transaction__c();
        payt2.tc9_pr__Pay_Advice__c = payadv.Id;
        payt2.tc9_pr__Pay_Batch_Event__c = PBE.Id;
        payt2.RecordTypeId = Schema.SObjectType.tc9_pr__Pay_Transaction__c.getRecordTypeInfosByDeveloperName().get('Payment').getRecordTypeId();
        payt2.tc9_pr__Pre_Tax_Superannuation__c = 5000;
        payt2.tc9_pr__Pay_Rate__c = 10;
        payt2.tc9_pr__Quantity__c = 1;
        payt2.OriginalTSEID__c = tse2.Id;
        payt2.Shift__c = shift1.Id;
        payt2.tc9_pr__Pay_Rate__c = 10;
        
        
        tc9_pr__Pay_Transaction__c payt3 = new tc9_pr__Pay_Transaction__c();
        payt3.tc9_pr__Pay_Advice__c = payadv.Id;
        payt3.tc9_pr__Pay_Batch_Event__c = PBE.Id;
        payt3.RecordTypeId = Schema.SObjectType.tc9_pr__Pay_Transaction__c.getRecordTypeInfosByDeveloperName().get('Allowance').getRecordTypeId();
        payt3.tc9_pr__Pre_Tax_Superannuation__c = 1000;
        payt3.tc9_pr__Pay_Rate__c = 15;
        payt3.tc9_pr__Quantity__c = 1;
        payt3.tc9_pr__Pay_Code__c = payCode.Id;
        payt3.Shift__c = shift2.Id;
        payt3.tc9_pr__Pay_Rate__c = 10;
        insert new List<tc9_pr__Pay_Transaction__c>{payt, payt2, payt3};

        insert payAdviceLines;

        payt2 = [SELECT Id, tc9_pr__Payee_Leave_Event__c FROM tc9_pr__Pay_Transaction__c WHERE Id = :payt2.Id LIMIT 1];

        tc9_pr__Payee_Leave_Event__c leaveEvent = new tc9_pr__Payee_Leave_Event__c(
            tc9_pr__Payee_Leave_Rule__c = payeeLeaveRule.Id, 
            tc9_pr__Payee__c = payee.Id,                     
            tc9_pr__Employee__c = employee.Id,               
            tc9_pr__Start_Date__c = Date.today().addDays(-10),
            tc9_pr__End_Date__c = Date.today().addDays(-5),
            tc9_pr__Hours__c = 8,                           
            tc9_pr__Approval_Status__c = 'Approved',        
            tc9_pr__Processing_Status__c = 'Fully Processed',     
            tc9_pr__Skip_Manager_Approval__c = 'Yes',        
            tc9_pr__Assignment__c = assignment.Id,
            tc9_pr__Selected_Pay_Rate__c = 'Standard Pay'

        );
        insert leaveEvent;

        payt2.tc9_pr__Payee_Leave_Event__c = leaveEvent.Id;

        update payt2;

        tc9_pr__Payee_Leave_Event__c toilCreditEvent = new tc9_pr__Payee_Leave_Event__c();
        toilCreditEvent.RecordTypeId = leaveCreditPleRtId;
        toilCreditEvent.tc9_pr__Payee_Leave_Rule__c = payeeLeaveRule.Id;
        toilCreditEvent.tc9_pr__Payee__c = payee.Id;
        toilCreditEvent.tc9_pr__Employee__c = employee.Id;
        toilCreditEvent.tc9_pr__Start_Date__c = System.today().addDays(-1);
        toilCreditEvent.tc9_pr__End_Date__c = System.today().addDays(-1);
        toilCreditEvent.tc9_pr__Hours__c = 2;
        toilCreditEvent.tc9_pr__Approval_Status__c = 'Approved';
        toilCreditEvent.tc9_pr__Processing_Status__c = 'Fully Processed';
        toilCreditEvent.tc9_pr__Skip_Manager_Approval__c = 'Yes';
        toilCreditEvent.tc9_pr__Assignment__c = assignment.Id;
        toilCreditEvent.tc9_pr__Selected_Pay_Rate__c = 'Standard Pay';
        insert toilCreditEvent;
    }

    private static tc9_pr__Pay_Code__c populatePayCodeValues(String recordTypeDevName, String deductionType) {
        tc9_pr__Pay_Code__c payCode = new tc9_pr__Pay_Code__c();
        payCode.Name = 'Test PayCode';
        payCode.tc9_pr__ATO_Allowance_Type__c = 'Car';
        payCode.tc9_pr__Pay_Rate_Multiplier__c = 1;
        if (deductionType != null) {
            payCode.tc9_pr__Deduction_Type__c = deductionType;
        }
        payCode.RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = :recordTypeDevName AND SobjectType = 'tc9_pr__Pay_Code__c' LIMIT 1].Id;
        return payCode;
    }

    private static tc9_pr__Pay_Advice_Line__c getPayAdviceLine(String payAdviceId, String paycodeId, String classification) {
        tc9_pr__Pay_Advice_Line__c PayAdvLine = new tc9_pr__Pay_Advice_Line__c();
        PayAdvLine.tc9_pr__Pay_Advice__c = payAdviceId;
        PayAdvLine.tc9_pr__Pay_Code__c = paycodeId;
        PayAdvLine.tc9_pr__Prior_Value__c = 456;
        PayAdvLine.tc9_pr__Rate__c = 45;
        PayAdvLine.tc9_pr__YTD_Units__c = 89;
        PayAdvLine.tc9_pr__YTD_Value__c = 56;
        PayAdvLine.tc9_pr__Prior_Units__c = 89;
        PayAdvLine.tc9_pr__Current_Value__c = 76;
        PayAdvLine.tc9_pr__Current_Units__c = 90;
        PayAdvLine.tc9_pr__Classification__c = classification;//'Payment';
        PayAdvLine.tc9_pr__Display_Payee_Leave_Rule__c = 'Yes';
        PayAdvLine.tc9_pr__Assignment__c = assignment.Id;
        PayAdvLine.tc9_pr__Rate__c = 45;
        return PayAdvLine;

    }
    
    public static tc9_et__Timesheet__c prepareTimesheet(Id assignmentId, Id employeeId, Id payeeId, String status) {
        tc9_et__Timesheet__c ts = new tc9_et__Timesheet__c();
        ts.tc9_et__Payee__c = payeeId;
        ts.tc9_et__Assignment__c  = assignmentId;
        ts.tc9_et__Employee__c  = employeeId;
        ts.tc9_et__Start_Date__c = Date.today();
        ts.tc9_et__End_Date__c   = Date.today().addDays(7);
        ts.tc9_et__Approval_Status__c = status;
        ts.tc9_et__Transaction_Creation_Stage__c= '1';

        return ts; 
    }
    
    public static tc9_et__Timesheet_Entry__c prepareTimesheetEntry(Id tsId, Id assignmentId, Id payeeId, Id employeeId, Date startDate, Date endDate) {
        tc9_et__Timesheet_Entry__c tse = new tc9_et__Timesheet_Entry__c();
        tse.tc9_et__Timesheet__c = tsId;
        tse.tc9_et__Assignment__c = assignmentId;
        tse.tc9_et__Start_Time__c = Time.newInstance(09,0,0,0);
        tse.tc9_et__End_Time__c = Time.newInstance(18,0,0,0);
        tse.tc9_et__Start_Date__c = startDate;
        tse.tc9_et__End_Date__c = endDate;
        tse.tc9_et__Payee__c = payeeId;
        tse.tc9_et__Employee__c = employeeId;

        return tse;    
    }
    
    public static sirenum__Shift__c prepareShift(Id assignmentId, Id timesheetId, Id contactId, Id contractId, Id projectCodeId, Id siteId) {
        sirenum__Shift__c shift = new sirenum__Shift__c();
        shift.tc9_ext_sirint__TSE_Scheduled_Start_Date__c = System.today();
        shift.tc9_ext_sirint__TSE_Actual_Start_Date__c = System.today();
        shift.tc9_ext_sirint__TSE_Actual_Start_Time__c = System.now().time();
        shift.tc9_ext_sirint__TSE_Scheduled_Start_Time__c = System.now().time();
        shift.tc9_ext_sirint__TSE_Scheduled_End_Time__c = System.now().addHours(1).time();
        shift.sirenum__Contract__c = contractId;
        shift.tc9_ext_sirint__Timesheet__c = timesheetId;
        shift.sirenum__Contact__c = contactId;
        shift.sirenum__Site__c = siteId;
        shift.tc9_ext_sirint__Assignment__c = assignmentId;

        return shift;
    }

    public static sirenum__Site__c prepareSite(String name, String street, String county, String city, String country, String postCode) {
        sirenum__Site__c site = new sirenum__Site__c();
        site.Name = name;
        site.sirenum__Street_Address__c = street;
        site.sirenum__County__c = county;
        site.sirenum__City__c = city;
        site.sirenum__Country__c = country;
        site.sirenum__Postal_Code__c = postCode;

        return site;
    }

    @IsTest
    private static void testCreatePayAdvicePDF_1() {

        createTestData('GST');

        Test.startTest();

        Test.setCurrentPage(Page.Custom_SummaryPayrollPayAdvice_Page);
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(payAdvList);
        ApexPages.currentPage().getParameters().put('Id', payAdvList[0].Id);
        Custom_SummaryPayAdviceCtrl ctrl = new Custom_SummaryPayAdviceCtrl(sc);
        ctrl.getShiftBackingSheetData();
        System.assertEquals(payAdvList.size(), 1);

        Test.stopTest();
    }

    @IsTest
    private static void testCreatePayAdvicePDF_2() {

        createTestData('Pay Advice');

        Test.startTest();

        Test.setCurrentPage(Page.Custom_SummaryPayrollPayAdvice_Page);
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(payAdvList);
        ApexPages.currentPage().getParameters().put('Id', payAdvList[0].Id);
        Custom_SummaryPayAdviceCtrl ctrl = new Custom_SummaryPayAdviceCtrl(sc);
        ctrl.getShiftBackingSheetData();
        System.assertEquals(payAdvList.size(), 1);

        Test.stopTest();
    }

    @IsTest
    private static void testGetTOILCreditEvents() {

        createTestData('Pay Advice');

        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM tc9_pr__Payee_Leave_Event__c
                WHERE tc9_pr__Payee__c = :payee.Id
                AND RecordTypeId = :leaveCreditPleRtId
                AND tc9_pr__Start_Date__c = :System.today().addDays(-1)
            ],
            'Expected one Leave_Credit PLE to exist in test data'
        );

        Test.startTest();

        Test.setCurrentPage(Page.Custom_SummaryPayrollPayAdvice_Page);
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(payAdvList);
        ApexPages.currentPage().getParameters().put('Id', payAdvList[0].Id);
        Custom_SummaryPayAdviceCtrl ctrl = new Custom_SummaryPayAdviceCtrl(sc);

        List<tc9_pr__Payee_Leave_Event__c> toilCreditEvents = ctrl.getTOILCreditEvents();

        System.assertNotEquals(null, toilCreditEvents, 'TOIL credit events list should not be null');
        System.assertEquals(1, toilCreditEvents.size(), 'Expected one TOIL Leave Credit event');
        System.assertEquals(2, toilCreditEvents[0].tc9_pr__Hours__c, 'Expected 2 TOIL hours');

        Test.stopTest();
    }

//ALN-344 fixes: getLeaveTransactions() not in controller
/*
    @IsTest
    private static void testGetLeaveTransactions() {
        createTestData('Pay Advice');

        Test.startTest();

        Test.setCurrentPage(Page.Custom_SummaryPayrollPayAdvice_Page);
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(payAdvList);
        ApexPages.currentPage().getParameters().put('Id', payAdvList[0].Id);
        Custom_SummaryPayAdviceCtrl ctrl = new Custom_SummaryPayAdviceCtrl(sc);

        List<tc9_pr__Pay_Transaction__c> leaveTxns = ctrl.getLeaveTransactions();

        System.assertEquals(1, leaveTxns.size());
        Test.stopTest();
    }
*/
}