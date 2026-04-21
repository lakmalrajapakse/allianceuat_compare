@isTest
public without sharing class SIM_SchedulerCustomScorer_Test {

    private static sirenum__Site__c site;
    private static sirenum__Rota__c rota;
    private static sirenum__Team__c team;
    private static Contact con;
    private static sirenum__Site__c site2;
    private static sirenum__Rota__c rota2;
    private static sirenum__Team__c team2;
    private static Contact con2;
    private static Account acc;
    private static sirenum__Payroll_Cycle__c paycycle;
    private static List<sirenum__Shift__c> testShifts = new List<sirenum__Shift__c>();
    private static List<Contact> testContacts = new List<Contact>();

    private static void createTestData() {
        //TEST RECORDS  
        site = new sirenum__Site__c(Name = 'test Site');
        insert site;
        rota = new sirenum__Rota__c(Name = 'test ROTA');
        insert rota;
        acc = new Account(Name = 'Test Account', TR1__Status__c = 'Live', tc9_pr__Available_Payment_Methods__c = 'Payee Australian Bank', tc9_pr__Maximum_Payment_Distributions__c = '1');
        insert acc;
        con = new Contact(FirstName = 'John', LastName = 'User', Email = 'test@sirenum.com', MobilePhone = '07583331473', AccountId = acc.Id);
        insert con;
        paycycle = new sirenum__Payroll_Cycle__c(Name = 'Sunday - Monday', sirenum__CyclePeriodUnits__c = 'Weeks', sirenum__periodLength__c = 1, sirenum__StartingDate__c = system.today());
        insert paycycle;
        
        //Secondary Records
        site2 = new sirenum__Site__c(Name = 'test Site2');
        insert site2;
        rota2 = new sirenum__Rota__c(Name = 'test ROTA2');
        insert rota2;
        con2 = new Contact(FirstName = 'Jane', LastName = 'OtherUser', Email = 'test@sirenum.com', MobilePhone = '07583331473', AccountId = acc.Id);
        insert con2;

        testContacts.add(con);
        testContacts.add(con2);

        Date startDate = Date.today().addDays(5);
        Date endDate = Date.today().addDays(10);
        DateTime testDateTime = dateTime.newInstance(startDate.year(), startDate.month(), startDate.day(), 9, 0, 0);

        testShifts = new List<sirenum__Shift__c> {
            new sirenum__Shift__c(
                sirenum__Scheduled_Start_Time__c = testDateTime,
                sirenum__Actual_Start_Time__c = testDateTime,
                sirenum__Scheduled_End_Time__c = testDateTime.addHours(8),
                sirenum__Cancelled__c = false
            ),
            new sirenum__Shift__c(
                sirenum__Scheduled_Start_Time__c = testDateTime.addDays(1),
                sirenum__Actual_Start_Time__c = testDateTime.addDays(1),
                sirenum__Scheduled_End_Time__c = testDateTime.addDays(1).addHours(8),
                sirenum__Cancelled__c = false,
                sirenum__Contact__c = con.Id
            )
        };
        insert testShifts;    
        
        sirenum__Employee_Request__c employeeRequestRecord = new sirenum__Employee_Request__c(
            sirenum__Type__c = Constants.EMPLOYEE_REQUEST_AM_AVAILABLE,
            sirenum__Local_Start_Date__c = testDateTime.date(),
            sirenum__Contact__c = con.Id
        );
        insert employeeRequestRecord;
        
    }

    @IsTest
    static void testScoreWorkers() {
       
        createTestData();

        system.debug(testShifts);
        system.debug(testContacts);

        sirenum.WorkerSearchScorerContext context =
        new sirenum.WorkerSearchScorerContextBuilder()
            .setShiftTemplates(testShifts)
            .setWorkers(testContacts)
            .build();

        system.debug(context);
        
        
        // Instantiate the class and call the scoring method
        SIM_SchedulerCustomScorer scorer = new SIM_SchedulerCustomScorer();
        List<sirenum.WorkerSearchScore> scores = scorer.scoreWorkers(context);            
        system.debug('SPC scores');
        

    }

    
    



}