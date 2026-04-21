@isTest
public class SIM_AhpraIntegrationHandler_Test {

@testSetup
    static void setup() {
        // Insert hierarchy custom setting so getInstance() works
        Ahpra_Integration_Settings__c aSettings = new Ahpra_Integration_Settings__c(
            SetupOwnerId = UserInfo.getUserId(),  // important for Hierarchy CS
            Ahpra_Endpoint__c = 'https://test.endpoint.com',
            Ahpra_Username__c = 'testuser',
            Ahpra_Password__c = 'testpassword'
        );
        insert aSettings;
    }    

    // Mock HTTP response
    public class AhpraMockResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/soap+xml');
            res.setStatusCode(200);
            res.setBody(
                '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"' +
                ' xmlns:ns="http://ns.ahpra.gov.au/pie/xsd/frs/FindRegistrationMessages/2.0.0"' +
                ' xmlns:com="http://ns.ahpra.gov.au/pie/xsd/common/CommonCoreElements/2.0.0"' +
                ' xmlns:pre="http://ns.ahpra.gov.au/pie/xsd/frs/PractitionerRegistrationElements/2.0.0">' +
                '<soapenv:Header/>' +
                '<soapenv:Body>' +
                '<ns:FindRegistrationsResponse>' +

                // Audit Details
                '<ns:AuditDetails>' +
                '<com:QueryIdentifier>Q123456789</com:QueryIdentifier>' +
                '<com:PractitionerCount>1</com:PractitionerCount>' +
                '<com:ServiceMessagesCount>0</com:ServiceMessagesCount>' +
                '<com:TotalRecordsSearched>1</com:TotalRecordsSearched>' +
                '<com:TotalNumberOfRegistration>1</com:TotalNumberOfRegistration>' +
                '<com:SnapshotDate>2025-06-18</com:SnapshotDate>' +
                '</ns:AuditDetails>' +

                // Practitioner + Profession + Registration
                '<pre:ProfessionNumberReplay ProfessionNumber="MED0001155128">' +
                '<pre:Practitioner>' +
                '<pre:PractitionerIdentifier>PRAC001</pre:PractitionerIdentifier>' +
                '<pre:PractitionerName>' +
                '<pre:NameTitle>Dr</pre:NameTitle>' +
                '<pre:FamilyName>Smith</pre:FamilyName>' +
                '<pre:GivenName>Jane</pre:GivenName>' +
                '<pre:MiddleName>A</pre:MiddleName>' +
                '</pre:PractitionerName>' +
                '<pre:Demographics>' +
                '<pre:Gender>Female</pre:Gender>' +
                '</pre:Demographics>' +
                '<pre:Qualification>' +
                '<pre:QualificationTitle>MBBS</pre:QualificationTitle>' +
                '<pre:AwardingInstitution>University of Melbourne</pre:AwardingInstitution>' +
                '<pre:CountryQualificationObtained>Australia</pre:CountryQualificationObtained>' +
                '<pre:YearOfQualification>2010</pre:YearOfQualification>' +
                '</pre:Qualification>' +
                '<pre:Address>' +
                '<pre:AustralianLocality>Melbourne</pre:AustralianLocality>' +
                '<pre:AustralianPostcode>3000</pre:AustralianPostcode>' +
                '<pre:AustralianState>VIC</pre:AustralianState>' +
                '<pre:Country>Australia</pre:Country>' +
                '</pre:Address>' +
                '<pre:Profession>' +
                '<pre:ProfessionNumber>MED0001155128</pre:ProfessionNumber>' +
                '<pre:Profession>Medical Practitioner</pre:Profession>' +
                '<pre:ProfessionStartDate>2010-02-01</pre:ProfessionStartDate>' +
                '<pre:Registration>' +
                '<pre:RecordNumber>REC001</pre:RecordNumber>' +
                '<pre:RegistrationType>General</pre:RegistrationType>' +
                '<pre:RegistrationStatus>Registered</pre:RegistrationStatus>' +
                '<pre:RegistrationSubStatus>Active</pre:RegistrationSubStatus>' +
                '<pre:InitialRegistrationDate>2010-02-01</pre:InitialRegistrationDate>' +
                '<pre:RegistrationToDate>2026-02-01</pre:RegistrationToDate>' +
                '</pre:Registration>' +
                '<pre:Condition>' +
                '<pre:ConditionText>Under supervision</pre:ConditionText>' +
                '</pre:Condition>' +
                '</pre:Profession>' +
                '</pre:Practitioner>' +
                '</pre:ProfessionNumberReplay>' +

                '</ns:FindRegistrationsResponse>' +
                '</soapenv:Body>' +
                '</soapenv:Envelope>'
            );
            return res;
        }
    }

    @isTest
    static void testSendRequest_success() {
        // Create a contact with an AHPRA number
        Contact testContact = new Contact(
            FirstName = 'Jane',
            LastName = 'Smith',
            aa_AHPRA_Number__c = 'MED0001155128',
            Allow_Auto_Fetch_of_Ahpra_Details__c = true,
            Add_to_Ahpra_nightly_Batch_Job__c = true
        );
        insert testContact;

        // Register the mock response
        Test.setMock(HttpCalloutMock.class, new AhpraMockResponseGenerator());

        Test.startTest();
        List<List<String>> input = new List<List<String>>{
            new List<String>{ 'MED0001155128' }
        };
        List<SIM_AhpraIntegrationHandler.ahpraResponse> results =
            SIM_AhpraIntegrationHandler.sendRequest(input);
        Test.stopTest();
        // system.debug('Results: ' + results);

        // System.assertEquals(1, results.size());
        // System.assertEquals(200, results[0].resStatus);
    }

    @isTest
    static void testSendRequest_error500() {

        Test.setMock(HttpCalloutMock.class, new AhpraErrorMock());

        Test.startTest();
        List<List<String>> input = new List<List<String>>{
            new List<String>{ 'INVALID123' }
        };
        List<SIM_AhpraIntegrationHandler.ahpraResponse> results =
            SIM_AhpraIntegrationHandler.sendRequest(input);
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(500, results[0].resStatus);
        System.assertEquals('Internal Server Error', results[0].resMessage);
    }

    @isTest
    static void testSendRequest_calloutException() {

        Test.setMock(HttpCalloutMock.class, new CalloutExceptionMock());

        Test.startTest();
        List<List<String>> input = new List<List<String>>{
            new List<String>{ 'EXC123456' }
        };
        List<SIM_AhpraIntegrationHandler.ahpraResponse> results =
            SIM_AhpraIntegrationHandler.sendRequest(input);
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(501, results[0].resStatus);
        System.assert(results[0].resMessage.contains('AHPRA error'));
    }

    @isTest
    static void testBatchExecution() {

        // Create a contact with an AHPRA number
        Contact testContact = new Contact(
            FirstName = 'Jane',
            LastName = 'Smith',
            aa_AHPRA_Number__c = 'MED0001155128',
            Allow_Auto_Fetch_of_Ahpra_Details__c = true,
            Add_to_Ahpra_nightly_Batch_Job__c = true
        );
        insert testContact;

        List<Contact> conlist = [SELECT Id, aa_AHPRA_Number__c, aa_AHPRA_Number_2__c,
            aa_AHPRA_Number_3__c, Allow_Auto_Fetch_of_Ahpra_Details__c, 
            Add_to_Ahpra_nightly_Batch_Job__c, Ahpra_Last_Checked__c
            FROM Contact WHERE Allow_Auto_Fetch_of_Ahpra_Details__c = true 
            AND Add_to_Ahpra_nightly_Batch_Job__c = true
            AND Ahpra_Last_Checked__c != today 
            AND (aa_AHPRA_Number__c != null 
            OR aa_AHPRA_Number_2__c != null OR aa_AHPRA_Number_3__c != null)];

        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new AhpraMockResponseGenerator());

        Test.startTest();
        SIM_AhpraCandidateCheckBatch batch = new SIM_AhpraCandidateCheckBatch();
        Database.executeBatch(batch, 2); // small batch size for test
        Test.stopTest();

        // Verify updates
        List<Contact> updatedContacts = [SELECT Ahpra_Last_Checked__c FROM Contact];
        for (Contact c : updatedContacts) {
            System.assertEquals(Date.today(), c.Ahpra_Last_Checked__c, 'Contact should be updated with today’s date');
        }
    }
    
    // Error mock class for 500 response
    Public class AhpraErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setStatus('Internal Server Error');
            res.setBody('Server Error');
            return res;
        }
    }

    // Mock throwing exception
    Public class CalloutExceptionMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('Mock callout failure');
        }
    }

    @IsTest
    static void testScheduledBatchExecution() {
        Test.startTest();

        // Schedule the job
        String cron = '0 0 0 1 1 ? 2050'; // arbitrary future date
        String jobId = System.schedule('Test Scheduled Batch', cron, new SIM_AhpraCandidateCheckSchedulable());

        Test.stopTest();

        // Verify the job was scheduled
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                          FROM CronTrigger WHERE Id = :jobId];
        System.assertNotEquals(null, ct, 'Scheduler should have created a CronTrigger record');
        System.assertEquals('0 0 0 1 1 ? 2050', ct.CronExpression);
    }    
    
}