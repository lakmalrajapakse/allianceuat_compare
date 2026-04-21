public abstract class LeaveAccrualRevaluationBaseSetupTest {
    public static tc9_pr__Override_TC9P_Validation__c prepareSetting() {
        tc9_pr__Override_TC9P_Validation__c setting = new tc9_pr__Override_TC9P_Validation__c();
        setting.tc9_pr__OV_Suspension__c = true;
        setting.tc9_pr__OV_Allowance_Template__c = true;
        setting.tc9_pr__OV_Assignment__c = true;
        setting.tc9_pr__OV_Assignment_Cost__c = true;
        setting.tc9_pr__OV_Assignment_Rate__c = true;
        setting.tc9_pr__OV_Assignment_Schedule__c = true;
        setting.tc9_et__OV_Award_Classification_Level__c = true;
        setting.tc9_pr__Override_Calendar__c = true;
        setting.tc9_pr__Override_Calendar_Period__c = true;
        setting.tc9_pr__OV_Deduction_Template__c = true;
        setting.tc9_et__OV_Expense__c = true;
        setting.tc9_et__OV_Expense_Claim__c = true;
        setting.tc9_et__OV_Interpretation_Breakpoint__c = true;
        setting.tc9_et__OV_Interpretation_Rule__c = true;
        setting.tc9_et__OV_Invoice__c = true;
        setting.tc9_et__OV_Invoiceable_Fee__c = true;
        setting.tc9_et__OV_Invoice_Setting__c = true;
        setting.tc9_pr__OV_Leave_Rule__c = true;
        setting.tc9_pr__OV_Leave_Rule_Item__c = true;
        setting.tc9_eau__OV_Lodgement_AU__c = true;
        setting.tc9_eau__OV_Lodgement_Error_AU__c = true;
        setting.tc9_eau__OV_Lodgement_Item_AU__c = true;
        setting.tc9_et__OV_Mark_Up_Margin_Rate_Record__c = true;
        setting.tc9_et__OV_Minimum_Pay_Rate__c = true;
        setting.tc9_pr__OV_Pay_Advice__c = true;
        setting.tc9_pr__OV_Pay_Advice_Lines__c = true;
        setting.tc9_pr__OV_Pay_Batch__c = true;
        setting.tc9_pr__OV_Pay_Batch_Event__c = true;
        setting.tc9_pr__OV_Pay_Code__c = true;
        setting.tc9_pr__Override_Pay_Code_Junction__c = true;
        setting.tc9_pr__OV_Payee__c = true;
        setting.tc9_pr__OV_Payee_Aggregate__c = true;
        setting.tc9_pr__OV_Payee_Allowance_Record__c = true;
        setting.tc9_pr__OV_Payee_Deduction_Record__c = true;
        setting.tc9_pr__OV_Payee_Leave_Event__c = true;
        setting.tc9_pr__OV_Payee_Leave_Rule__c = true;
        setting.tc9_pr__OV_Payee_Opening_Balance__c = true;
        setting.tc9_pr__OV_Payee_Pay_Batch__c = true;
        setting.tc9_pr__OV_Payee_Withholding_Rule__c = true;
        setting.tc9_pr__OV_Payment_Detail__c = true;
        setting.tc9_pr__OV_Payment_File__c = true;
        setting.tc9_et__OV_Payment_Terms__c = true;
        setting.tc9_et__OV_Pay_Rate_Loading__c = true;
        setting.tc9_pr__OV_Pay_Transaction__c = true;
        setting.tc9_et__OV_Rate_Calculator_Junction__c = true;
        setting.tc9_et__OV_Rate_Calculator_Rate__c = true;
        setting.tc9_pr__OV_Schedule__c = true;
        setting.tc9_pr__OV_Schedule_Item__c = true;
        setting.tc9_et__OV_Timesheet__c = true;
        setting.tc9_et__OV_Timesheet_Entry__c = true;
        setting.tc9_et__OV_Timesheet_Item__c = true;    
        
        return setting;
    }

    public static String getRandomString(String rand) {
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = rand + String.valueOf(randomInt);
        
        return uniqueName;
    }
    
    public static User preparePortalUser(Profile myProfile, Contact con){
        String randString = getRandomString('test');
        
        User pUser = new User();
        
        pUser.ContactId = con.Id;
        pUser.Alias = randString.subString(5);
        pUser.Email = randString + '@test.com';
        pUser.EmailEncodingKey = 'UTF-8';
        pUser.FirstName = con.FirstName;
        pUser.LastName = con.LastName;
        pUser.LanguageLocaleKey = UserInfo.getLanguage();//'English';
        pUser.LocaleSidKey = 'en_AU';
        pUser.ProfileId = myProfile.Id;
        pUser.TimeZoneSidKey = 'Australia/Sydney';
        pUser.Username = randString + '@test.com';
        
        return pUser;
    }
    public static tc9_et__Interpretation_Rule__c prepareInterpretationRule(Decimal ordWeekly, Decimal minWeekly, Decimal minSunday, Decimal minSaturday, Decimal minPubHol, Boolean interpretation){
        tc9_et__Interpretation_Rule__c intRule  = new tc9_et__Interpretation_Rule__c();
        intRule.RecordTypeId = Schema.SObjectType.tc9_et__Interpretation_Rule__c.getRecordTypeInfosByDeveloperName().get('Hourly_Rates')?.getRecordTypeId();  
        intRule.tc9_et__Frequency_Standard_Hours__c             = ordWeekly;
        intRule.tc9_et__Minimum_Frequency_Paid_Hours__c         = minWeekly;
        intRule.tc9_et__Minimum_Sunday_Paid_Hours__c         = minSunday;
        intRule.tc9_et__Minimum_Saturday_Paid_Hours__c       = minSaturday;
        intRule.tc9_et__Minimum_Public_Holiday_Paid_Hours__c = minPubHol;
        intRule.tc9_et__Standard_Daily_Start_Time__c  = Time.newInstance(08,0,0,0);//'08:00';
        intRule.tc9_et__Standard_Daily_End_Time__c = Time.newInstance(17,0,0,0);//'17:00';
        intRule.tc9_et__Days_Frequency_Breakpoints_Apply__c = 'Monday;Tuesday;Wednesday;Thursday;Friday';
        intRule.tc9_et__Timesheet_Frequency__c = 'Weekly';
        intRule.tc9_et__Monday_Interpretation_Type__c = 'Standard Time with Time Breakpoints';
        intRule.tc9_et__Tuesday_Interpretation_Type__c = 'Standard Time with Time Breakpoints';
        intRule.tc9_et__Wednesday_Interpretation_Type__c = 'Standard Time with Time Breakpoints';
        intRule.tc9_et__Thursday_Interpretation_Type__c = 'Standard Time with Time Breakpoints';
        intRule.tc9_et__Friday_Interpretation_Type__c = 'Standard Time with Time Breakpoints';
        intRule.tc9_et__Saturday_Interpretation_Type__c = 'Standard Time with Time Breakpoints';
        intRule.tc9_et__Sunday_Interpretation_Type__c = 'Standard Time with Time Breakpoints';
        intRule.tc9_et__Public_Holiday_Interpretation_Type__c = 'Standard Time with Time Breakpoints';
        
        return intRule;
    }
    
    public static tc9_et__Payment_Terms__c preaprePaymentTerm(){
        tc9_et__Payment_Terms__c pterm    = new tc9_et__Payment_Terms__c();
        pterm.tc9_et__Due_From__c = 'Invoice Date';
        pterm.tc9_et__Days_From__c= 5;
        pterm.Name= 'Payterm';
        pterm.tc9_et__Payment_Terms_Description__c = 'Test';
        
        return pterm;
    }
    
    public static Account prepareClientAccount(Id locationId, String recType, Id scheduleId) {
        Account acc = new Account();
        acc.Name = 'Test Client Account';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(recType)?.getRecordTypeId();
        acc.BillingStreet   = 'Str';
        acc.BillingCity     = 'City';
        acc.BillingState    = 'State';
        acc.BillingPostalCode    = '645';
        acc.BillingCountry  = 'Australia';
        acc.tc9_et__Invoice_Group_By__c = 'Assignment';
        acc.tc9_pr__Available_Payment_Methods__c = 'Payee Australian Bank; Payee International Bank; Payee Cheque; Payee Cash;';
        acc.tc9_pr__Maximum_Payment_Distributions__c = '1';
        acc.tc9_pr__Schedule__c = scheduleId;
        acc.tc9_pr__Payment_Details_Complete__c = 'Yes';
        acc.tc9_pr__Maximum_Payment_Distributions__c = '5';
        //acc.State_Region__c = 'Victoria';
        //acc.Industry__c = 'B07000 - Oil and Gas Extraction';
        
        return acc;
    }
    
    public static Account prepareEmployeeAccount(Id locationId) {
        Account acc = new Account();
        acc.Name = 'Test Employee Account';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Client')?.getRecordTypeId();
        acc.BillingStreet   = 'Str';
        acc.BillingCity     = 'City';
        acc.BillingState    = 'State';
        acc.BillingPostalCode    = '645';
        acc.BillingCountry  = 'XX';
        acc.tc9_et__Invoice_Group_By__c = 'Assignment';
        acc.tc9_pr__Maximum_Payment_Distributions__c = '5';
        //acc.State_Region__c = 'Victoria';
        //acc.Industry__c = 'B07000 - Oil and Gas Extraction';
        
        return acc;
    }
    
    public static Contact prepareClientContact(Account acc) {
        Contact clientCon = new Contact();
        clientCon.Account = acc;
        clientCon.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Client_Contact')?.getRecordTypeId();
        clientCon.FirstName = 'Kylo Ren';
        clientCon.LastName = 'Solo';
        clientCon.Salutation = 'Mr';
        clientCon.Email = getRandomString('kylo')+'@test.com';
        clientCon.tc9_et__Timesheet_Approval_Request_Opt_Out__c = true;
        clientCon.tc9_et__Exp_Claim_Reminder_Notification_Opt_Out__c = true;
        clientCon.tc9_pr__Approver_Link_Token__c = 'mytoken';
        
        return clientCon;
    }
    
    public static Contact prepareEmployee(Account acc) {
        Contact con = new Contact();
        con.Account = acc;
        con.RecordTypeId  = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Employee')?.getRecordTypeId();
        con.FirstName = 'Daisy';
        con.LastName = 'Ridley';
        con.Salutation = 'Jedi';
        con.Email = getRandomString('Rey')+'@test.com';
        con.Birthdate = Date.today();
        con.AccountId = acc.Id;
        
        return con;
    }
    
    public static tc9_pr__Location__c prepareTaxLocation() {
        tc9_pr__Location__c loc = new tc9_pr__Location__c();
        loc.Name = 'testLocation';
        return  loc;
    }
    
    public static tc9_pr__Schedule__c prepareSchedule(String schName, String splitOption, String recTypeName) {
        tc9_pr__Schedule__c sc = new tc9_pr__Schedule__c();
        sc.Name = schName;
        sc.tc9_pr__Split_Option__c = 'No Split';//splitOption;
        sc.tc9_pr__Period_Type__c = 'Weekly';
        sc.RecordTypeId = Schema.SObjectType.tc9_pr__Schedule__c.getRecordTypeInfosByDeveloperName().get(recTypeName)?.getRecordTypeId();
        
        return sc;
    }
    
    public static tc9_pr__Assignment__c prepareAssignment(Id tsCalId, Id accId, Id conId, Id schId, Id calId, Id empId, Date startDate, Date endDate, Id awdMasterId, String recordTypeName, Id ptId, Id payeeId, Id schInvId, Id peId){
        tc9_pr__Assignment__c assignment = new tc9_pr__Assignment__c();
        assignment.tc9_et__Timesheet_Calendar__c = tsCalId;
        assignment.tc9_pr__Assignment_Start_Date__c = startDate;
        assignment.tc9_pr__Assignment_End_Date__c = endDate;
        assignment.tc9_pr__Assignment_Name__c = 'Test Assignment ' + recordTypeName;
        
        assignment.tc9_pr__Payee__c = payeeId;
        assignment.tc9_pr__Payment_Entity__c = peId;
        
        assignment.RecordTypeId = Schema.SObjectType.tc9_pr__Assignment__c.getRecordTypeInfosByDeveloperName().get(recordTypeName)?.getRecordTypeId();
        
        assignment.tc9_pr__Client__c = accId;
        assignment.tc9_et__Client_Hiring_Manager__c = conId;
        assignment.tc9_et__Invoice_To_Account__c = accId;
        assignment.tc9_et__Invoice_To_Contact__c = conId;
        assignment.tc9_et__Timesheet_Approver__c = conId;
        assignment.tc9_et__Alternative_TimeSheet_Approver__c = conId;
        assignment.tc9_pr__Schedule__c = schId;
        assignment.tc9_et__Interpretation_Rule__c = awdMasterId;
        
        assignment.tc9_et__Public_Holiday_Calendar__c = calId;
        assignment.tc9_pr__Employee__c = empId;
        
        assignment.tc9_et__Purchase_Order_Number__c = '123456';
        assignment.tc9_et__Invoice_Schedule__c = schInvId;
        
        assignment.tc9_et__Timesheet_Approver__c = conId;
        assignment.tc9_et__Expense_Claim_Approver__c = conId;
        assignment.tc9_pr__Leave_Approver__c = conId;
        
        return assignment;
    }
    
    public static tc9_pr__Payee__c preparePayee(Id scheduleId, Id conId, Id paymentEntityId, String earnerType) {
        tc9_pr__Payee__c payee = new tc9_pr__Payee__c();
        payee.tc9_pr__Employee__c = conId;
        payee.tc9_pr__Payroll_Start_Date__c = Date.today().addDays(-30);
        payee.tc9_pr__Payment_Entity__c = paymentEntityId;
        payee.tc9_pr__Payroll_System__c = '2cloudnine Payroll AUS';
        payee.tc9_pr__Earner_Type__c = earnerType;
        payee.tc9_pr__Pay_Advice_Delivery_Method__c = 'Email as PDF';
        payee.tc9_pr__Payroll_Id__c = '23456';
        payee.tc9_pr__Payment_Details_Complete__c = 'Yes';
        payee.tc9_pr__Primary_Record__c = true;
        
        return payee;
    }
    
    public static tc9_pr__Calendar__c preparePublicHolidayCalendar(Id schId, Id peId){
        tc9_pr__Calendar__c clndr = new tc9_pr__Calendar__c();
        clndr.Name = 'Australia - Vic';
        clndr.RecordTypeId =  Schema.SObjectType.tc9_pr__Calendar__c.getRecordTypeInfosByDeveloperName().get('Public_Holiday').getRecordTypeId();
        clndr.tc9_pr__Payment_Entity__c = peId;
        clndr.tc9_pr__Schedule__c = schId;
        clndr.tc9_pr__Start_Date__c = Date.today().addDays(-40);
        clndr.tc9_pr__End_Date__c = Date.today().addDays(40);
        clndr.tc9_pr__No_Days_Payment_Date_after_End_Date__c = 3;
        clndr.tc9_pr__No_Days_Payroll_Date_after_End_Date__c = 3;
        clndr.tc9_pr__Status__c = 'Active';
        
        return clndr;
    }
    
    public static tc9_pr__Calendar__c prepareTimesheetCalendar(Id schId, Id peId, Boolean incPH, Date fSDate, String tsFreq, String beFormat, String tsFormat, Id invSchId, Id ieId){
        tc9_pr__Calendar__c clndr = new tc9_pr__Calendar__c();
        clndr.Name = 'Timesheet Cal';
        clndr.RecordTypeId = Schema.SObjectType.tc9_pr__Calendar__c.getRecordTypeInfosByDeveloperName().get('Timesheet').getRecordTypeId();
        clndr.tc9_pr__Payment_Entity__c = peId;
        clndr.tc9_pr__Schedule__c = schId;
        clndr.tc9_pr__Start_Date__c = Date.today().addDays(-100);
        clndr.tc9_pr__End_Date__c = Date.today().addDays(+400);
        clndr.tc9_pr__No_Days_Payment_Date_after_End_Date__c = 3;
        clndr.tc9_pr__No_Days_Payroll_Date_after_End_Date__c = 3;
        clndr.tc9_pr__Status__c = 'Active';
        clndr.tc9_et__Include_Public_Holidays__c = incPH;
        clndr.tc9_et__Fortnightly_Start_Date__c = fSDate;
        clndr.tc9_et__Sunday__c = true;
        clndr.tc9_et__Monday__c = true;
        clndr.tc9_et__Tuesday__c = true;
        clndr.tc9_et__Wednesday__c = true;
        clndr.tc9_et__Thursday__c = true;
        clndr.tc9_et__Friday__c = true;
        clndr.tc9_et__Saturday__c = true;
        clndr.tc9_et__Weekly_Start_Day__c = 'Monday';
        clndr.tc9_et__Timesheet_Frequency__c = tsFreq;
        clndr.tc9_et__Split_Timesheets_Over_Months__c = true;
        clndr.tc9_et__Break_Entry_Format__c = beFormat;
        clndr.tc9_et__Timesheet_Entry_Format__c = tsFormat;
        clndr.tc9_et__Invoice_Schedule__c = invSchId;
        clndr.tc9_et__No_Days_Future_Timesheets_Visible__c = 1;
        clndr.tc9_et__Invoice_Entity__c = ieId;
        
        return clndr;
    }
    
    //add a holiday to the PH calendar
    // The Calendar, Start Date, End Date, Payroll Date and Payment Date fields must be populated
    public static tc9_pr__Calendar_Period__c prepareHoliday(Id calId, Date startDate, Date endDate) {
        tc9_pr__Calendar_Period__c calItem = new tc9_pr__Calendar_Period__c();
        calItem.tc9_pr__Calendar__c = calId;
        calItem.tc9_pr__Start_Date__c = startDate;
        calItem.tc9_pr__End_Date__c = endDate;
        calItem.tc9_pr__Payroll_Date__c = startDate;
        calItem.tc9_pr__Payment_Date__c = startDate;
        
        return calItem;
    }
    
    public static tc9_pr__Pay_Code__c preparePayCode(String recordType) {
        Id rtId = Schema.SObjectType.tc9_pr__Pay_Code__c.getRecordTypeInfosByDeveloperName().get(recordType)?.getRecordTypeId();
        tc9_pr__Pay_Code__c payCode = new tc9_pr__Pay_Code__c();
        payCode.Name = 'Test ' + recordType;
        payCode.tc9_pr__Description__c = recordType;
        payCode.tc9_pr__Pay_Advice_Description__c = recordType;
        payCode.RecordTypeId = rtId;
        payCode.tc9_pr__Pay_Rate_Multiplier__c = 1;
        payCode.tc9_pr__Contributes_to_OTE__c = true;
        payCode.tc9_pr__Pay_Advice_Description__c = 'Test Description';
        
        return payCode;
    }
    
    public static tc9_et__Timesheet__c prepareTimesheet(Id assId, Id empId, Id payeeId, Date startDate, Date endDate, String status){
        tc9_et__Timesheet__c ts = new tc9_et__Timesheet__c();
        ts.tc9_et__Assignment__c  = assId;
        ts.tc9_et__Employee__c  = empId;
        ts.tc9_et__Start_Date__c = startDate;
        ts.tc9_et__End_Date__c   = endDate;
        ts.tc9_et__Approval_Status__c = status;
        ts.tc9_et__Payee__c = payeeId;
        ts.tc9_et__Transaction_Creation_Stage__c= '1';
        
        return ts;
    }
    
    public static tc9_et__Timesheet_Entry__c prepareTimesheetEntry(Id tsId, Id assignmentId, Id payeeId, Id employeeId, Date startDate) {
        tc9_et__Timesheet_Entry__c tse = new tc9_et__Timesheet_Entry__c();
        tse.tc9_et__Timesheet__c = tsId;
        tse.tc9_et__Assignment__c = assignmentId;
        tse.tc9_et__Start_Time__c = Time.newInstance(9,0,0,0);
        tse.tc9_et__End_Time__c = Time.newInstance(18,0,0,0);
        tse.tc9_et__Start_Date__c = startDate;
        tse.tc9_et__Payee__c = payeeId;
        tse.tc9_et__Employee__c = employeeId;
        
        return tse;
    }
    
    public static tc9_et__Timesheet_Item__c prepareTimesheetAllowanceRecord(Id timesheetId, Id assId, Id payeeAlwId, Id payeeId, Id empId, Decimal qty) {
        Id tsAlwRecTypeId = Schema.SObjectType.tc9_et__Timesheet_Item__c.getRecordTypeInfosByDeveloperName().get('Allowance')?.getRecordTypeId();
        
        tc9_et__Timesheet_Item__c tsAllowanceRecord = new tc9_et__Timesheet_Item__c();
        tsAllowanceRecord.RecordTypeId = tsAlwRecTypeId;
        tsAllowanceRecord.tc9_et__Timesheet__c = timesheetId;
        tsAllowanceRecord.tc9_et__Employee__c = empId;
        tsAllowanceRecord.tc9_et__Payee__c = payeeId;
        tsAllowanceRecord.tc9_et__Assignment__c = assId;
        tsAllowanceRecord.tc9_et__Date_Incurred__c = System.today();
        tsAllowanceRecord.tc9_et__Quantity__c = qty;
        tsAllowanceRecord.tc9_et__Payee_Allowance_Record__c = payeeAlwId;
        
        return tsAllowanceRecord;
    }
    
    public static tc9_pr__Payee_Allowance_Record__c preparePayeeAllowanceRecord(Id payCodeId, Id payeeId, Id peId, Id empId, Id assignmentId) {
        tc9_pr__Payee_Allowance_Record__c par = new tc9_pr__Payee_Allowance_Record__c();
        par.tc9_pr__Allowance_Rate__c = 10;
        par.tc9_pr__Status__c = 'Active';
        par.tc9_pr__Pay_Code__c = payCodeId;
        par.tc9_pr__Payment_Entity__c = peId;
        par.tc9_pr__Payee__c = payeeId;
        par.tc9_pr__Effective_Date__c = System.today();
        par.tc9_pr__Allowance_Rate_Type__c = 'Amount';
        par.tc9_et__Available_on_Employee_Community__c = 'Yes';
        par.tc9_pr__Employee__c = empId;
        par.tc9_pr__Assignment__c = assignmentId;
        par.RecordTypeId = Schema.SObjectType.tc9_pr__Payee_Allowance_Record__c.getRecordTypeInfosByDeveloperName().get('Timesheet_Allowance')?.getRecordTypeId();
        
        return par;
    }
    
    public static tc9_et__Expense__c prepareTimesheetExpense(Id timesheetId, Boolean taxable, Id payCodeId){
        tc9_et__Expense__c exp = new tc9_et__Expense__c();
        exp.tc9_et__Timesheet__c = timesheetId;
        exp.tc9_et__Expense_Description__c = 'Test Expense ';
        exp.tc9_et__Expense_Total_Ex_Tax__c =  100.0;
        exp.tc9_et__Date_Incurred__c = Date.today();
        exp.tc9_et__Taxable__c = taxable;
        exp.tc9_et__Expense_Total_Tax__c = 10;
        exp.tc9_et__Pay_Code__c = payCodeId;
        exp.tc9_et__Submitted_Flag__c = true;
        
        return exp;
    }
    
    public static tc9_et__Expense_Claim__c prepareExpenseClaim(Id assId, Id payeeId, Id empId, String expStatus){
        tc9_et__Expense_Claim__c expClaim = new tc9_et__Expense_Claim__c();
        expClaim.tc9_et__Assignment__c = assId;
        expClaim.tc9_et__Employee__c = empId;
        expClaim.tc9_et__Claim_Date__c = Date.today();
        expClaim.tc9_et__Approval_Status__c = expStatus;
        expClaim.tc9_et__Transaction_Creation_Stage__c = '1';
        expClaim.tc9_et__Payee__c = payeeId;
        return expClaim;
    }
    
    public static tc9_pr__Leave_Rule__c prepareLeaveRule(String recordType, Id payCodeLeaveId, Id payCodeUnpaidId, Date startDate) {
        tc9_pr__Leave_Rule__c leaveRule = new tc9_pr__Leave_Rule__c();
        leaveRule.tc9_pr__Skip_Manager_Approval__c = 'No';
        leaveRule.tc9_pr__Available_in_Portal__c = 'Yes';
        leaveRule.tc9_pr__Effective_Date__c = startDate.addDays(-20);
        leaveRule.Name = recordType + ' Rule';
        leaveRule.tc9_pr__Pay_Code__c = payCodeLeaveId;
        leaveRule.tc9_pr__Unpaid_Pay_Code__c = payCodeUnpaidId;
        leaveRule.tc9_pr__Available_Pay_Rates__c = 'Standard Pay';
        leaveRule.tc9_pr__Allow_Pay_In_Advance__c = 'No';
        leaveRule.tc9_pr__Credit_Available_in_Portal__c = 'Yes';
        leaveRule.RecordTypeId = Schema.SObjectType.tc9_pr__Leave_Rule__c.getRecordTypeInfosByDeveloperName().get(recordType)?.getRecordTypeId();
        
        return leaveRule;
    }
    
    public static tc9_pr__Project_Code__c prepareProjectCode(String recordType, Id assId) {
        tc9_pr__Project_Code__c assPrjCode = new tc9_pr__Project_Code__c();
        assPrjCode.Name = 'Test ' + recordType +' PC';
        assPrjCode.tc9_pr__Assignment__c = assId;
        assPrjCode.tc9_pr__Status__c = 'Active';
        assPrjCode.RecordTypeId = Schema.SObjectType.tc9_pr__Project_Code__c.getRecordTypeInfosByDeveloperName()?.get(recordType)?.getRecordTypeId();

       	return assPrjCode;
    }
}