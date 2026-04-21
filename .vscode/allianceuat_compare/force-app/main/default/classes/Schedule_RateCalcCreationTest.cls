@isTest
public class Schedule_RateCalcCreationTest {
   
    @TestSetup
    public static void setup(){
        Contact con = new Contact(LastName = 'testEmployee');
        con.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Employee')?.getRecordTypeId();
        insert con;

        tc9_pr__Schedule__c schedule = new tc9_pr__Schedule__c();
        schedule.Name = 'testSchedule';
        schedule.tc9_pr__Split_Option__c = 'Per Calendar';
        schedule.tc9_pr__Period_Type__c = 'Weekly';
        insert schedule;

        Account acct = prepareAccount('testClient', 'Payee Cash', '1', schedule.Id, '4443332222');
        insert acct;

        tc9_pr__Payee__c payee = preparePayee(con.Id, acct.Id, schedule.Id);
        insert payee;

        tc9_pr__Assignment__c assignment = prepareAssignment(Date.newInstance(2022, 11, 10), Date.newInstance(2022, 12, 31), 'Employee', acct.Id, payee.Id, con.Id, schedule.Id);
        insert assignment;

        tc9_et__Rate_Calculator__c rcTemplate = new tc9_et__Rate_Calculator__c();
        rcTemplate.RecordTypeId = Schema.SObjectType.tc9_et__Rate_Calculator__c.getRecordTypeInfosByDeveloperName().get('Template')?.getRecordTypeId();
        rcTemplate.tc9_et__Rate_Calculator_Name__c = 'TEST RC TEMPLATE';
        rcTemplate.tc9_et__Status__c = 'Active';
        rcTemplate.tc9_et__Effective_Date__c = System.today().addDays(-10);
        rcTemplate.tc9_et__Expiry_Date__c = System.today().addDays(10);
        insert rcTemplate;

        tc9_et__Rate_Calculator__c rcEmpSpecific = new tc9_et__Rate_Calculator__c();
        rcEmpSpecific.RecordTypeId = Schema.SObjectType.tc9_et__Rate_Calculator__c.getRecordTypeInfosByDeveloperName().get('Employee_Specific')?.getRecordTypeId();
        rcEmpSpecific.tc9_et__Rate_Calculator_Name__c = 'TEST RC EMP SPECIFIC';
        rcEmpSpecific.tc9_et__Assignment__c = assignment.Id;
        rcEmpSpecific.tc9_et__Employee__c = con.Id;
        rcEmpSpecific.tc9_et__Effective_Date__c = System.today().addDays(-10);
        rcEmpSpecific.tc9_et__Expiry_Date__c = System.today().addDays(10);
        rcEmpSpecific.tc9_et__Parent_Rate_Calculator__c = rcTemplate.Id;
        rcEmpSpecific.tc9_et__Payee__c = payee.Id;
        insert rcEmpSpecific;

    }

    public static Account prepareAccount(String accName, String paymentMethod, String paymentDistributions, Id scheduleId, String phoneNum) {
        Account acc = new Account();
        acc.Name = accName;
        acc.tc9_pr__Available_Payment_Methods__c = paymentMethod;
        acc.tc9_pr__Maximum_Payment_Distributions__c = paymentDistributions;
        acc.tc9_pr__Schedule__c = scheduleId;
        acc.Phone = phoneNum;

        return acc;
    }

    public static tc9_pr__Payee__c preparePayee(Id contactId, Id accId, Id scheduleId) {
        tc9_pr__Payee__c payee = new tc9_pr__Payee__c();
        payee.tc9_pr__Employee__c = contactId;
        payee.tc9_pr__Payment_Entity__c = accId;
        payee.tc9_pr__Schedule__c = scheduleId;

        return payee;
    }
    private static tc9_pr__Assignment__c prepareAssignment(Date startDate, Date endDate,String recordTypeName, Id acctId, Id payeeId, Id contactId, Id scheduleId) {
        tc9_pr__Assignment__c assignment = new tc9_pr__Assignment__c();
        assignment.tc9_pr__Assignment_Start_Date__c = startDate;
        assignment.tc9_pr__Assignment_End_Date__c = endDate;
        assignment.RecordTypeId = Schema.SObjectType.tc9_pr__Assignment__c.getRecordTypeInfosByDeveloperName().get(recordTypeName)?.getRecordTypeId();
        assignment.tc9_pr__Client__c = acctId;
        assignment.tc9_pr__Payee__c = payeeId;
        assignment.tc9_pr__Employee__c = contactId;
        assignment.tc9_pr__Payment_Entity__c = acctId;
        assignment.tc9_pr__Schedule__c = scheduleId;

        return assignment;
    }

    @isTest
    public static void givenCreateRateCalculatorIsTrue_whenProcessRateCalcCreation_thenInvokeRateCalcCreationSuccessfully() {
        tc9_pr__Assignment__c assignment = [SELECT Id, Create_Rate_Calculator__c FROM tc9_pr__Assignment__c LIMIT 1];
        assignment.Create_Rate_Calculator__c = true;
        update assignment;

        Test.startTest();
        new Schedule_RateCalcCreation().execute(null);
        Test.stopTest();
    }
}