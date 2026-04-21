@isTest
private class X1218_CreateBHConnectUserTest {

    static Account acc;
    static Account invAcc;
    static Contact con;
    static Contact clientContact;
    static TR1__Application_V2__c testApplication;

    @testSetup
    static void setupTestData() {
        

        Branch__c branch = new Branch__c(Branch_Name__c = 'Test Branch', Branch_Code__c = 'TST', City__c = 'Test City');
        insert branch;

        acc = SIM_TestDataFactory.genTestAccount('Candidate Pool', 'Client', false);
        acc.Payroll_Tax_Exempt__c = 'No';
        acc.Approval_Type__c = 'Not Charged';
        insert acc;
        invAcc = SIM_TestDataFactory.genTestAccount('invoice entity', 'Client', false);
        invAcc.Payroll_Tax_Exempt__c = 'No';
        invAcc.Approval_Type__c = 'Not Charged';
        insert invAcc;        

        // NOTE set contact as client contact instead of candidate because of unknown validation rule
        // con = SIM_TestDataFactory.genTestContact('Ridge', acc, 'Client Contact', true);
        Id contactRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Candidate').getRecordTypeId();

        con = new Contact(FirstName = 'tot', LastName = 'brown', AccountId = acc.Id, RecordTypeId = contactRT, tc9_et__Timesheet_Notification_Email__c = 'Primary', email='abc@abc.com');
        clientContact = new Contact(FirstName = 'Ridge2', LastName = 'grwon', AccountId = acc.Id, RecordTypeId = contactRT, tc9_et__Timesheet_Notification_Email__c = 'Primary', email='abc@abc.com');
        insert new List<Contact> {con, clientContact};        
        update con;

        // Create a Job
        Id jobRT = Schema.SObjectType.TR1__Job__c.getRecordTypeInfosByName().get('Sourcing Role').getRecordTypeId();
        TR1__Job__c testJob = new TR1__Job__c();
        testJob.Name = 'Test Job';
        testJob.RecordTypeId = jobRT;
        testJob.Branch__c = branch.Id;
        insert testJob;
        
        // Create an Application with an Applicant
        testApplication = new TR1__Application_V2__c(TR1__Applicant__c=con.Id, TR1__Job__c=testJob.Id);
        insert testApplication;
        system.debug(testApplication);  
        
    }
    
    @isTest
    static void testProcessSubStatus() {

        testApplication = [SELECT Id, TR1__Applicant__c FROM TR1__Application_V2__c LIMIT 1];
        system.debug(testApplication);

        Test.startTest();
        // Create Sub Status
        TR1__Sub_Status__c testSubStatus = new TR1__Sub_Status__c(
            TR1__Value__c = 'BH_Connect',
            TR1__ATS_Stage__c = 'Contracting',
            TR1__Is_Active__c = true,
            TR1__Application__c = testApplication.Id
        );
        insert testSubStatus;        

        User createdUser = [SELECT Id, ContactId FROM User WHERE Contact.Email = 'abc@abc.com' LIMIT 1];
        System.assertNotEquals(null, createdUser, 'User Created');
        Test.stopTest();

    }
}