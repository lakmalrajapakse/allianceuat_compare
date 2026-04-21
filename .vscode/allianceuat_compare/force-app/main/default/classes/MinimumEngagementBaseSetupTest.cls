/**
 * @description MinimumEngagementBaseSetupTest
 */
@SuppressWarnings('PMD.AvoidDebugStatements, PMD.ExcessiveParameterList')
public abstract class MinimumEngagementBaseSetupTest {

    /**
     * @description Prepare Paycode
     * @return tc9_pr__Pay_Code__c
     */
    public static tc9_pr__Pay_Code__c  preparePaycode() {
        tc9_pr__Pay_Code__c paycode = new tc9_pr__Pay_Code__c();
        paycode.Name = 'testPaycode';
        paycode.tc9_pr__Description__c = 'testPaycode Desc';
        paycode.tc9_pr__Pay_Advice_Description__c = 'TestPaycode Advice';
        paycode.tc9_pr__Pay_Rate_Multiplier__c = 12;
        paycode.tc9_et__Invoice_Taxable__c = 'Yes';
        paycode.tc9_pr__ATO_Income_Classification__c = 'Not Reportable';

        return paycode;
    }

    /**
     * @description Prepare Account
     * @param accName
     * @param paymentMethod
     * @param paymentDistributions
     * @param scheduleId
     * @param phoneNum
     * @param recordType
     * @return Account
     */
    public static Account prepareAccount(String accName, String paymentMethod, String paymentDistributions, Id scheduleId, String phoneNum, String recordType) {
        Account acc = new Account();
        acc.Name = accName;
        acc.tc9_pr__Available_Payment_Methods__c = paymentMethod;
        acc.tc9_pr__Maximum_Payment_Distributions__c = paymentDistributions;
        acc.tc9_pr__Schedule__c = scheduleId;
        acc.Phone = phoneNum;
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(recordType)?.getRecordTypeId();

        return acc;
    }

    /**
     * @description Prepare Payee
     * @param contactId
     * @param paymentEntityId
     * @param scheduleId
     * @return Payee
     */
    public static tc9_pr__Payee__c preparePayee(Id contactId, Id paymentEntityId, Id scheduleId) {
        tc9_pr__Payee__c payee = new tc9_pr__Payee__c();
        payee.tc9_pr__Employee__c = contactId;
        payee.tc9_pr__Payment_Entity__c = paymentEntityId;
        payee.tc9_pr__Schedule__c = scheduleId;

        return payee;
    }
    
    /**
     * @description Prepare Assignment
     * @param startDate
     * @param endDate
     * @param recordTypeName
     * @param clientId
     * @param payEnId
     * @param payeeId
     * @param contactId
     * @param scheduleId
     * @param tsCalId
     * @return Assignment
     */
    public static tc9_pr__Assignment__c prepareAssignment(Date startDate, Date endDate,String recordTypeName, Id clientId, Id payEnId, Id payeeId, Id contactId, Id scheduleId, Id tsCalId) {
        tc9_pr__Assignment__c assignment = new tc9_pr__Assignment__c();
        assignment.tc9_pr__Assignment_Start_Date__c = startDate;
        assignment.tc9_pr__Assignment_End_Date__c = endDate;
        assignment.RecordTypeId = Schema.SObjectType.tc9_pr__Assignment__c.getRecordTypeInfosByDeveloperName().get(recordTypeName)?.getRecordTypeId();
        assignment.tc9_pr__Client__c = clientId;
        assignment.tc9_pr__Payee__c = payeeId;
        assignment.tc9_pr__Employee__c = contactId;
        assignment.tc9_pr__Payment_Entity__c = payEnId;
        assignment.tc9_pr__Schedule__c = scheduleId;
        assignment.tc9_et__Timesheet_Calendar__c = tsCalId;

        return assignment;
    }

     /**
     * @description Prepare Schedule
     * @param schName
     * @param splitOption
     * @param recTypeName
     * @return Schedule
     */
    public static tc9_pr__Schedule__c prepareSchedule(String schName, String splitOption, String recTypeName) {
        tc9_pr__Schedule__c sc = new tc9_pr__Schedule__c();
        sc.Name = schName;
        sc.tc9_pr__Split_Option__c = 'No Split';//splitOption;
        sc.tc9_pr__Period_Type__c = 'Weekly';
        sc.RecordTypeId = Schema.SObjectType.tc9_pr__Schedule__c.getRecordTypeInfosByDeveloperName().get(recTypeName)?.getRecordTypeId();
        
        return sc;
    }

     /**
     * @description Prepare Calendar
     * @param schId
     * @param peId
     * @param incPH
     * @param fSDate
     * @param tsFreq
     * @param beFormat
     * @param tsFormat
     * @param invSchId
     * @param ieId
     * @return Calendar
     */
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
        clndr.tc9_et__Invoice_Entity__c = ieId;

        return clndr;
    }

     /**
     * @description Prepare Pay Transaction
     * @param recordType
     * @param tseId
     * @param payeeId
     * @param paycodeId
     * @param assignmentId
     * @param payRate
     * @param quantity
     * @return Pay Transaction
     */
    public static tc9_pr__Pay_Transaction__c preparePayTransaction(String recordType, Id tseId, Id payeeId, Id paycodeId, Id assignmentId, Double payRate, Double quantity) {
        tc9_pr__Pay_Transaction__c pt = new tc9_pr__Pay_Transaction__c();
        pt.RecordTypeId = Schema.SObjectType.tc9_pr__Pay_Transaction__c.getRecordTypeInfosByDeveloperName().get(recordType).getRecordTypeId();
        pt.tc9_et__Timesheet_Entry__c = tseId;
        pt.tc9_pr__Payee__c = payeeId;
        pt.tc9_pr__Pay_Code__c = paycodeId;
        pt.tc9_pr__Assignment__c = assignmentId;
        pt.tc9_pr__Pay_Rate__c = payRate;
        pt.tc9_pr__Quantity__c = quantity;
        pt.tc9_et__Invoice_Taxable__c = 'Yes';

        return pt;
    }

     /**
     * @description Prepare Custom Rule
     * @param interRuleId
     * @param type
     * @param maxUplift
     * @param minUplift
     * @param gapExclude
     * @param hourUplift
     * @return Custom Rule
     */
    public static Custom_Rule__c prepareCustomRule(Id interRuleId, String type, Decimal maxUplift, Decimal minUplift, Decimal gapExclude, Decimal hourUplift) {
        Custom_Rule__c customRule = new Custom_Rule__c();
        customRule.RecordTypeId = Schema.SObjectType.Custom_Rule__c.getRecordTypeInfosByDeveloperName().get('Interpretation').getRecordTypeId();
        customRule.Interpretation_Type__c = type;
        customRule.Timesheet_Activities_to_Include__c = 'Sleepover';
        customRule.Interpretation_Rule__c = interRuleId;
        customRule.Maximum_Hours_to_Uplift__c = maxUplift;
        customRule.Minimum_Hours_to_Uplift__c = minUplift;
        customRule.TS_Entry_Gap_to_Exclude__c = gapExclude;
        customRule.TS_Entry_Hours_to_Uplift__c = hourUplift;

        return customRule;
    }

     /**
     * @description Prepare Timesheet
     * @param assId
     * @param empId
     * @param payeeId
     * @param startDate
     * @param endDate
     * @param status
     * @return Timesheet
     */
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

     /**
     * @description Prepare Timesheet Entry
     * @param timesheetId
     * @param contactId
     * @param assignmentId
     * @param payeeId
     * @param workDate
     * @param startTime
     * @param endTime
     * @return Timesheet Entry
     */
    public static tc9_et__Timesheet_Entry__c prepareTimesheetEntry(Id timesheetId, Id contactId, Id assignmentId, Id payeeId, Date workDate, Time startTime, Time endTime) {
        tc9_et__Timesheet_Entry__c tse = new tc9_et__Timesheet_Entry__c();
        tse.tc9_et__Timesheet__c = timesheetId;
        tse.tc9_et__Employee__c = contactId;
        tse.tc9_et__Assignment__c = assignmentId;
        tse.tc9_et__Payee__c = payeeId;
        tse.tc9_et__Start_Date__c = workDate;
        tse.tc9_et__End_Date__c = workDate;
        tse.tc9_et__Start_Time__c = startTime;
        tse.tc9_et__End_Time__c = endTime;

        return tse;
    }
}