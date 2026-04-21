/**
 * Created Date: 02/02/23.
 * Author: Tew
 * Purpose: Test Class for MinimumEngagementService
 *
 * Change History
    ******************************************************************************************************************************************
         SCRUM        ModifiedBy        Date            Requested By                           Description                              Tag
    ******************************************************************************************************************************************
         C9D-107       Tew             02/02/23          Ben Albani             Minimum Engagement invocable method
 */

 /**
 * @description MinimumEngagementTest
 */
@isTest
public class MinimumEngagementTest extends MinimumEngagementBaseSetupTest {
    
     /**
     * @description setup
     */
    @TestSetup
    public static void setup(){
        Date startDate = System.today().addDays(-10);
        Date endDate = System.today().addDays(10);

        tc9_et__Interpretation_Rule__c interRule = new tc9_et__Interpretation_Rule__c();
        interRule.RecordTypeId = Schema.SObjectType.tc9_et__Interpretation_Rule__c.getRecordTypeInfosByDeveloperName().get('Interpretation_Variation_Rule')?.getRecordTypeId();
        interRule.Name = 'Test Interpretation rule';
        insert interRule;

        tc9_pr__Pay_Code__c payCode = preparePaycode();
        payCode.Name = 'PAY_CODE';
        insert payCode;

        Contact con = new Contact(LastName = 'testEmployee');
        con.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Employee')?.getRecordTypeId();
        insert con;

        //ALN-344: Fixes
        /*
        tc9_pr__Schedule__c schedule = prepareSchedule('Weekly','W','Pay_Schedule');
        tc9_pr__Schedule__c scheduleInv = prepareSchedule('Weekly','W','Invoice_Schedule');
        List<tc9_pr__Schedule__c> schList = new List<tc9_pr__Schedule__c>{schedule, scheduleInv};
        insert schList;
        */
        
        tc9_pr__Schedule__c schedule = prepareSchedule('Weekly','W','Pay_Schedule');
        tc9_pr__Schedule__c scheduleInv = prepareSchedule('Weekly','W','Invoice_Schedule');
        
        //Set required field to avoid validation error
        schedule.tc9_pr__Payroll_Jurisdiction__c = 'Australia';
        scheduleInv.tc9_pr__Payroll_Jurisdiction__c = 'Australia';
        
        insert new List<tc9_pr__Schedule__c>{schedule, scheduleInv};  
        
        Account invoiceEntity = prepareAccount('testInvoiceEntity', 'Payee Cash', '1', schedule.Id, '4443332222', 'Invoice_Entity');
        insert invoiceEntity;

        Account paymentEntity = prepareAccount('testPaymentEntity', 'Payee Cash', '1', schedule.Id, '4443332222', 'Payment_Entity');
        insert paymentEntity;
        
        tc9_pr__Calendar__c tsCal = prepareTimesheetCalendar(schedule.Id, paymentEntity.Id, true, startDate, 'Weekly', 'Start/End Times', 'Start/End Times', scheduleInv.Id, invoiceEntity.Id);
        insert tsCal;

        Account client = prepareAccount('testClient', 'Payee Cash', '1', schedule.Id, '4443332222', 'Client');
        client.tc9_et__Default_Invoice_Schedule__c = scheduleInv.Id;
        client.tc9_pr__Schedule__c = schedule.Id;
        //ALN-344: Fixes
        client.Payroll_Tax_Exempt__c = 'No';
        client.Approval_Type__c = 'Not Charged';
        insert client;

        tc9_pr__Payee__c payee = preparePayee(con.Id, paymentEntity.Id, schedule.Id);
        insert payee;

        tc9_pr__Assignment__c assignment = prepareAssignment(startDate, endDate, 'Employee', client.Id, paymentEntity.Id, payee.Id, con.Id, schedule.Id, tsCal.Id);
        insert assignment;

        tc9_et__Timesheet__c tsNew = prepareTimesheet(assignment.Id, con.Id, payee.Id, Date.today(), Date.today().addDays(7), 'New');
        tsNew.tc9_et__Interpretation_Rule__c = interRule.Id;
        insert tsNew;
    }

    @isTest
    public static void givenOnePayTransactionWhenprocessMinimumEngagementThenUpliftHoursSuccessfully() {
        tc9_et__Timesheet__c timesheet = [SELECT Id FROM tc9_et__Timesheet__c LIMIT 1];
        tc9_pr__Assignment__c assignment = [SELECT Id FROM tc9_pr__Assignment__c LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        tc9_pr__Payee__c payee = [SELECT Id FROM tc9_pr__Payee__c LIMIT 1];
        tc9_pr__Pay_Code__c payCode = [SELECT Id FROM tc9_pr__Pay_Code__c LIMIT 1];
        tc9_et__Interpretation_Rule__c interRule = [SELECT Id FROM tc9_et__Interpretation_Rule__c WHERE Name = 'Test Interpretation rule'];

        Test.startTest();
        Custom_Rule__c customRule = prepareCustomRule(interRule.Id, 'Minimum Engagement', 3, 0, 60, 1);
        insert customRule;

        Time stTime = Time.newInstance(9, 0, 0, 0);
        Time endTime = Time.newInstance(10, 0, 0, 0);
        tc9_et__Timesheet_Entry__c tse = prepareTimesheetEntry(timesheet.Id, con.Id, assignment.Id, payee.Id, System.today(), stTime, endTime);
        insert tse;

        tc9_pr__Pay_Transaction__c payTrnLoading = preparePayTransaction('Payment', tse.Id, payee.Id, payCode.Id, assignment.Id, 100, 1);
        payTrnLoading.tc9_et__Interpretation_Category__c = 'Loading';

        tc9_pr__Pay_Transaction__c highestPayTrn = preparePayTransaction('Payment', tse.Id, payee.Id, payCode.Id, assignment.Id, 500, 1);

        tc9_pr__Pay_Transaction__c highestPayTrn2 = preparePayTransaction('Payment', tse.Id, payee.Id, payCode.Id, assignment.Id, 800, 1);

        List<tc9_pr__Pay_Transaction__c> payTrns = new List<tc9_pr__Pay_Transaction__c>{payTrnLoading, highestPayTrn, highestPayTrn2};
        insert payTrns;

        MinimumEngagementService.process(new List<Id>{timesheet.Id});

        Test.stopTest();

        List<tc9_pr__Pay_Transaction__c> newPayTrns = [SELECT Id FROM tc9_pr__Pay_Transaction__c WHERE Id NOT IN :payTrns];
        System.assertEquals(2, newPayTrns.size(), 'There should be 2 Pay Transaction Records');
    }

    @isTest
    public static void givenGapBetweenPayTransactionIsEnoughWhenprocessMinimumEngagementThenUpliftHoursSuccessfully() {
        tc9_et__Timesheet__c timesheet = [SELECT Id FROM tc9_et__Timesheet__c LIMIT 1];
        tc9_pr__Assignment__c assignment = [SELECT Id FROM tc9_pr__Assignment__c LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        tc9_pr__Payee__c payee = [SELECT Id FROM tc9_pr__Payee__c LIMIT 1];
        tc9_pr__Pay_Code__c payCode = [SELECT Id FROM tc9_pr__Pay_Code__c LIMIT 1];
        tc9_et__Interpretation_Rule__c interRule = [SELECT Id FROM tc9_et__Interpretation_Rule__c WHERE Name = 'Test Interpretation rule'];

        Test.startTest();
        Custom_Rule__c customRule = prepareCustomRule(interRule.Id, 'Minimum Engagement', 3, 0, 60, 1);
        insert customRule;

        Time stTime = Time.newInstance(9, 0, 0, 0);
        Time endTime = Time.newInstance(10, 0, 0, 0);
        tc9_et__Timesheet_Entry__c tse = prepareTimesheetEntry(timesheet.Id, con.Id, assignment.Id, payee.Id, System.today(), stTime, endTime);
        insert tse;

        Time stTime2 = Time.newInstance(15, 0, 0, 0);
        Time endTime2 = Time.newInstance(18, 0, 0, 0);
        tc9_et__Timesheet_Entry__c tse2 = prepareTimesheetEntry(timesheet.Id, con.Id, assignment.Id, payee.Id, System.today(), stTime2, endTime2);
        insert tse2;

        tc9_pr__Pay_Transaction__c payTrnLoading = preparePayTransaction('Payment', tse.Id, payee.Id, payCode.Id, assignment.Id, 100, 1);
        payTrnLoading.tc9_et__Interpretation_Category__c = 'Loading';

        tc9_pr__Pay_Transaction__c highestPayTrn = preparePayTransaction('Payment', tse.Id, payee.Id, payCode.Id, assignment.Id, 500, 1);

        tc9_pr__Pay_Transaction__c highestPayTrn2 = preparePayTransaction('Payment', tse.Id, payee.Id, payCode.Id, assignment.Id, 800, 1);

        List<tc9_pr__Pay_Transaction__c> payTrns = new List<tc9_pr__Pay_Transaction__c>{payTrnLoading, highestPayTrn, highestPayTrn2};
        insert payTrns;

        MinimumEngagementService.process(new List<Id>{timesheet.Id});

        Test.stopTest();

        List<tc9_pr__Pay_Transaction__c> newPayTrns = [SELECT Id FROM tc9_pr__Pay_Transaction__c WHERE Id NOT IN :payTrns];
        System.assertEquals(2, newPayTrns.size(), 'There should be 2 Pay Transaction Records');
    }

    @isTest
    public static void givenGapBetweenPayTransactionIsNotEnoughWhenprocessMinimumEngagementThenDoNotUpliftHours() {
        tc9_et__Timesheet__c timesheet = [SELECT Id FROM tc9_et__Timesheet__c LIMIT 1];
        tc9_pr__Assignment__c assignment = [SELECT Id FROM tc9_pr__Assignment__c LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        tc9_pr__Payee__c payee = [SELECT Id FROM tc9_pr__Payee__c LIMIT 1];
        tc9_pr__Pay_Code__c payCode = [SELECT Id FROM tc9_pr__Pay_Code__c LIMIT 1];
        tc9_et__Interpretation_Rule__c interRule = [SELECT Id FROM tc9_et__Interpretation_Rule__c WHERE Name = 'Test Interpretation rule'];

        Test.startTest();
        Custom_Rule__c customRule = prepareCustomRule(interRule.Id, 'Minimum Engagement', 3, 0, 60, 1);
        insert customRule;

        Time stTime = Time.newInstance(9, 0, 0, 0);
        Time endTime = Time.newInstance(10, 0, 0, 0);
        tc9_et__Timesheet_Entry__c tse = prepareTimesheetEntry(timesheet.Id, con.Id, assignment.Id, payee.Id, System.today(), stTime, endTime);
        insert tse;

        Time stTime2 = Time.newInstance(10, 30, 0, 0);
        Time endTime2 = Time.newInstance(12, 0, 0, 0);
        tc9_et__Timesheet_Entry__c tse2 = prepareTimesheetEntry(timesheet.Id, con.Id, assignment.Id, payee.Id, System.today(), stTime2, endTime2);
        insert tse2;

        tc9_pr__Pay_Transaction__c payTrnLoading = preparePayTransaction('Payment', tse.Id, payee.Id, payCode.Id, assignment.Id, 100, 1);
        payTrnLoading.tc9_et__Interpretation_Category__c = 'Loading';

        tc9_pr__Pay_Transaction__c highestPayTrn = preparePayTransaction('Payment', tse.Id, payee.Id, payCode.Id, assignment.Id, 500, 1);

        tc9_pr__Pay_Transaction__c highestPayTrn2 = preparePayTransaction('Payment', tse.Id, payee.Id, payCode.Id, assignment.Id, 800, 1);

        List<tc9_pr__Pay_Transaction__c> payTrns = new List<tc9_pr__Pay_Transaction__c>{payTrnLoading, highestPayTrn, highestPayTrn2};
        insert payTrns;

        MinimumEngagementService.process(new List<Id>{timesheet.Id});

        Test.stopTest();

        List<tc9_pr__Pay_Transaction__c> newPayTrns = [SELECT Id FROM tc9_pr__Pay_Transaction__c WHERE Id NOT IN :payTrns];
        System.assertEquals(0, newPayTrns.size(), 'There should be no Pay Transaction Records');
    }

    @isTest
    public static void givenGapBetweenPayTransactionIsEnoughAndLoadingPayTransactionWasDuplicatedWhenprocessMinimumEngagementThenUpliftHoursOnlyUniquePayCodeSuccessfully() {
        tc9_et__Timesheet__c timesheet = [SELECT Id FROM tc9_et__Timesheet__c LIMIT 1];
        tc9_pr__Assignment__c assignment = [SELECT Id FROM tc9_pr__Assignment__c LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        tc9_pr__Payee__c payee = [SELECT Id FROM tc9_pr__Payee__c LIMIT 1];
        tc9_pr__Pay_Code__c payCode = [SELECT Id FROM tc9_pr__Pay_Code__c LIMIT 1];
        tc9_et__Interpretation_Rule__c interRule = [SELECT Id FROM tc9_et__Interpretation_Rule__c WHERE Name = 'Test Interpretation rule'];

        Test.startTest();
        Custom_Rule__c customRule = prepareCustomRule(interRule.Id, 'Minimum Engagement', 3, 0, 60, 1);
        insert customRule;

        Time stTime = Time.newInstance(9, 0, 0, 0);
        Time endTime = Time.newInstance(10, 0, 0, 0);
        tc9_et__Timesheet_Entry__c tse = prepareTimesheetEntry(timesheet.Id, con.Id, assignment.Id, payee.Id, System.today(), stTime, endTime);
        insert tse;

        Time stTime2 = Time.newInstance(15, 0, 0, 0);
        Time endTime2 = Time.newInstance(18, 0, 0, 0);
        tc9_et__Timesheet_Entry__c tse2 = prepareTimesheetEntry(timesheet.Id, con.Id, assignment.Id, payee.Id, System.today(), stTime2, endTime2);
        insert tse2;

        tc9_pr__Pay_Transaction__c payTrnLoading = preparePayTransaction('Payment', tse.Id, payee.Id, payCode.Id, assignment.Id, 100, 1);
        payTrnLoading.tc9_et__Interpretation_Category__c = 'Loading';

        tc9_pr__Pay_Transaction__c payTrnLoading2 = preparePayTransaction('Payment', tse.Id, payee.Id, payCode.Id, assignment.Id, 150, 2);
        payTrnLoading2.tc9_et__Interpretation_Category__c = 'Loading';

        tc9_pr__Pay_Transaction__c highestPayTrn = preparePayTransaction('Payment', tse.Id, payee.Id, payCode.Id, assignment.Id, 500, 1);

        tc9_pr__Pay_Transaction__c highestPayTrn2 = preparePayTransaction('Payment', tse.Id, payee.Id, payCode.Id, assignment.Id, 800, 1);

        List<tc9_pr__Pay_Transaction__c> payTrns = new List<tc9_pr__Pay_Transaction__c>{payTrnLoading, payTrnLoading2, highestPayTrn, highestPayTrn2};
        insert payTrns;

        MinimumEngagementService.process(new List<Id>{timesheet.Id});

        Test.stopTest();

        List<tc9_pr__Pay_Transaction__c> newPayTrns = [SELECT Id FROM tc9_pr__Pay_Transaction__c WHERE Id NOT IN :payTrns];
        System.assertEquals(2, newPayTrns.size(), 'There should be 2 Pay Transaction Records');
    }

    @isTest
    public static void givenCustomRulesWithDifferentSettingsWhenprocessMinimumEngagementThenTSEWillUseCustomRuleByItsOwnCriteriaSuccessfully() {
        tc9_et__Timesheet__c timesheet = [SELECT Id FROM tc9_et__Timesheet__c LIMIT 1];
        tc9_pr__Assignment__c assignment = [SELECT Id FROM tc9_pr__Assignment__c LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        tc9_pr__Payee__c payee = [SELECT Id FROM tc9_pr__Payee__c LIMIT 1];
        tc9_pr__Pay_Code__c payCode = [SELECT Id FROM tc9_pr__Pay_Code__c LIMIT 1];
        tc9_et__Interpretation_Rule__c interRule = [SELECT Id FROM tc9_et__Interpretation_Rule__c WHERE Name = 'Test Interpretation rule'];

        Test.startTest();

        Custom_Rule__c customRule = prepareCustomRule(interRule.Id, 'Minimum Engagement', 1, 0, 60, 1);
        insert customRule;

        Custom_Rule__c customRule2 = prepareCustomRule(interRule.Id, 'Minimum Engagement', 12, 4, 70, 2);
        insert customRule2;

        Time stTime = Time.newInstance(9, 0, 0, 0);
        Time endTime = Time.newInstance(10, 0, 0, 0);
        tc9_et__Timesheet_Entry__c tse = prepareTimesheetEntry(timesheet.Id, con.Id, assignment.Id, payee.Id, System.today(), stTime, endTime);
        insert tse;

        Time stTime2 = Time.newInstance(15, 0, 0, 0);
        Time endTime2 = Time.newInstance(18, 0, 0, 0);
        tc9_et__Timesheet_Entry__c tse2 = prepareTimesheetEntry(timesheet.Id, con.Id, assignment.Id, payee.Id, System.today(), stTime2, endTime2);
        tse2.tc9_et__Total_Hours__c = 5;
        insert tse2;

        tc9_pr__Pay_Transaction__c payTrnLoading = preparePayTransaction('Payment', tse.Id, payee.Id, payCode.Id, assignment.Id, 100, 1);
        payTrnLoading.tc9_et__Interpretation_Category__c = 'Loading';

        tc9_pr__Pay_Transaction__c payTrnLoading2 = preparePayTransaction('Payment', tse.Id, payee.Id, payCode.Id, assignment.Id, 150, 2);
        payTrnLoading2.tc9_et__Interpretation_Category__c = 'Loading';

        tc9_pr__Pay_Transaction__c highestPayTrn = preparePayTransaction('Payment', tse.Id, payee.Id, payCode.Id, assignment.Id, 500, 1);

        tc9_pr__Pay_Transaction__c highestPayTrn2 = preparePayTransaction('Payment', tse.Id, payee.Id, payCode.Id, assignment.Id, 800, 1);

        List<tc9_pr__Pay_Transaction__c> payTrns = new List<tc9_pr__Pay_Transaction__c>{payTrnLoading, payTrnLoading2, highestPayTrn, highestPayTrn2};
        insert payTrns;

        MinimumEngagementService.process(new List<Id>{timesheet.Id});

        Test.stopTest();

        List<tc9_pr__Pay_Transaction__c> newPayTrns = [SELECT Id FROM tc9_pr__Pay_Transaction__c WHERE Id NOT IN :payTrns];
        System.assertEquals(2, newPayTrns.size(), 'There should be 2 Pay Transaction Records');
    }
}