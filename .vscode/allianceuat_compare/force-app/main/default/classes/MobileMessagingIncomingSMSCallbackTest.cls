@isTest
private class MobileMessagingIncomingSMSCallbackTest {
    static List<MobileMessaging_SMS_Message__c> messages = new List<MobileMessaging_SMS_Message__c>();

    // Helper method to create a test contact with a mobile phone number
    private static Contact createTestContact(String mobilePhone) {
        Contact testContact = new Contact(LastName = 'TestContact', MobilePhone = mobilePhone);
        insert testContact;
        return testContact;
    }

    private static List<MobileMessaging_SMS_Message__c> createData(Contact cont){
        List<MobileMessaging_SMS_Message__c> messages = new List<MobileMessaging_SMS_Message__c>{
            new MobileMessaging_SMS_Message__c(
                Contact__c = cont.Id,
                Message_Content__c = 'Test Message',
                Short_Message__c = 'Test Message',
                Status__c = 'queued',
                Direction__c = 'outbound',
                // Remote_Message_ID__c = 'test',
                Source__c = 'Contact',
                Sender__c =  UserInfo.getUserId(),
                Sender_Name__c = 'Test Sender'
            )
        };
        insert messages;
        return messages;
            
    }

    @testSetup
    static void setup() {
    //     String costCenter = 'Alliance Test One';
    //     Application_SMS_Configuration__mdt settings = SettingsProvider.getSettings(costCenter);
    Branch__c branch = new Branch__c(City__c = 'Adelaide', Branch_Name__c = 'Adelaide Allocations', Branch_Code__c = '1');
        insert branch;

        Cost_Center__c costCenter = new Cost_Center__c(
            Name = 'Alliance Test One', 
            Branch__c = branch.Id, 
            SMS_Cost_Center__c = 'Alliance_Nurse_Allocations', 
            Team__c = 'Allocations', 
            Public_Group__c = 'Adelaide_Nursing_Allocations');
        insert costCenter;

        Cost_Center_User__c costCenterUser = new Cost_Center_User__c(Cost_Center__c = costCenter.Id, User__c = UserInfo.getUserId(), Is_Primary__c = true);
        insert costCenterUser;
    }


    @isTest static void testHandleMessage() {
        //  create a test contact with a specific phone number
        String testPhone = '+61434567890';
        Contact testContact = createTestContact(testPhone);
        List<MobileMessaging_SMS_Message__c> messages = createData(testContact);
        // String costCenter = 'Alliance Test One';
        SMSSettings settings = SMSSettings.getInstance();

        // Simulate incoming SMS message data
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'POST';
        // req.requestURI = 'https://allianceaustralia--dev.sandbox.my.salesforce-sites.com/smsintegration/services/apexrest/MobileMessagingIncomingSMS/';
        req.requestURI = '/services/apexrest/MobileMessagingIncomingSMS';
        // req.addHeader('x-messagemedia-auth', 'TWVzc2FnZU1lZGlhIEluYm91bmQgVG');
        req.addHeader('x-messagemedia-auth', settings.inboundToken);
        // req.addParameter('metadata_sf_id', 'a9t9t000000yVddAAE');
        // // req.addParameter('messageIdMM', 'BBB');
        // req.addParameter('message_id', 'BBB');
        // req.addParameter('reply_id', 'CCC');
        // req.addParameter('source_address', '+61434567890');
        // req.addParameter('destination_address', '+61445678901');
        // req.addParameter('message_content', 'Hello, this is a test message.');
        // req.addParameter('reply_content', 'This is the reply');

        // String jsonPayload='{"messages":[{"callback_url": "https://allianceaustralia--dev.sandbox.my.salesforce-sites.com/smsintegration/services/apexrest/MobileMessagingServiceStatusCallback", "delivery_report": true, "destination_number": "+1234567890", "format": "SMS", "message_expiry_timestamp": null, "message_flags": [] , "message_id": "5043771f-500d-45be-bd41-191de803b577", "metadata":{"salesforce_message_id": "a9t9t000000yVddAAE"}, "status": "queued"}]}';
        // String jsonPayload='{"metadata_sf_id": "a9t9t000000yVddAAE", "message_id": messages[0].Id, "reply_id": "CCC", "source_address": "+61434567890", "destination_address": "+61445678901", "message_content": "Hello, this is a test message.", "reply_content": "This is the reply"}';
        String jsonPayload='{"metadata_sf_id": "';
        jsonPayload+= messages[0].Id;
        jsonPayload+= '", "message_id": "491296d9-8077-46ec-8114-4eb4cf91d0e6", "reply_id": "CCC", "source_address": "+61434567890", "destination_address": "+61445678901", "message_content": "Hello, this is a test message.", "reply_content": "This is the reply"}';
        
        req.requestBody = Blob.valueof(jsonPayload); 

        // system.debug('MobileMessagingServiceStatusCallback req.requestBody: ' + req.requestBody.toString());

        // Set the simulated request in the RestContext
        RestContext.request = req;
        RestContext.response = res;
        // Set up the mock HTTP response generator
        // Test.setMock(HttpCalloutMock.class, new MobileMessagingServiceMock());

        // Act - call the method to handle the incoming message
        Test.startTest();
        MobileMessagingIncomingSMSCallback.handleMessage();
        Test.stopTest();

        // Assert - verify a new SMS message record was created and linked to the contact
        // List<MobileMessaging_SMS_Message__c> smsMessages = [SELECT Id, Contact__c FROM MobileMessaging_SMS_Message__c WHERE Contact__c = :testContact.Id];
        // System.assertEquals(1, smsMessages.size(), 'One SMS message should be created.');
        // System.assertEquals(testContact.Id, smsMessages[0].Contact__c, 'The SMS message should be linked to the test contact.');

        // Assert - verify the response contains empty TwiML
        // System.assertEquals('<?xml version="1.0" encoding="UTF-8"?><Response/>', res.responseBody.toString(), 'The response body should contain empty TwiML.');
    }

    @isTest static void testHandleErrorMessage() {
        //  create a test contact with a specific phone number
        String testPhone = '+61434567890';
        Contact testContact = createTestContact(testPhone);
        List<MobileMessaging_SMS_Message__c> messages = createData(testContact);
        SMSSettings settings = SMSSettings.getInstance();

        // Simulate incoming SMS message data
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'POST';
        // req.requestURI = 'https://allianceaustralia--dev.sandbox.my.salesforce-sites.com/smsintegration/services/apexrest/MobileMessagingIncomingSMS/';
        req.requestURI = '/services/apexrest/MobileMessagingIncomingSMS';
        req.addHeader('x-messagemedia-auth', settings.inboundToken);
        String jsonPayload='{"metadata_sf_id": ';
        jsonPayload+= messages[0].Id;
        // jsonPayload+= '", "message_id": "491296d9-8077-46ec-8114-4eb4cf91d0e6", "reply_id": "CCC", "source_address": "+61434567890", "destination_address": "+61445678901", "message_content": "Hello, this is a test message.", "reply_content": "This is the reply"}';
        // jsonPayload+= '", "message_id": "491296d9-8077-46ec-8114-4eb4cf91d0e6", "reply_id": "CCC", "source_address": "+61999999999", "destination_address": "+61445678901", "message_content": "Hello, this is a test message.", "reply_content": "This is the reply"}';
        
        req.requestBody = Blob.valueof(jsonPayload); 

        // Set the simulated request in the RestContext
        RestContext.request = req;
        RestContext.response = res;
        // Set up the mock HTTP response generator
        // Test.setMock(HttpCalloutMock.class, new MobileMessagingServiceMock());

        // Act - call the method to handle the incoming message
        Test.startTest();
        MobileMessagingIncomingSMSCallback.handleMessage();
        Test.stopTest();

        // Assert - verify a new SMS message record was created and linked to the contact
        // List<MobileMessaging_SMS_Message__c> smsMessages = [SELECT Id, Contact__c FROM MobileMessaging_SMS_Message__c WHERE Contact__c = :testContact.Id];
        // System.assertEquals(1, smsMessages.size(), 'One SMS message should be created.');
        // System.assertEquals(testContact.Id, smsMessages[0].Contact__c, 'The SMS message should be linked to the test contact.');

        // Assert - verify the response contains empty TwiML
        // System.assertEquals('<?xml version="1.0" encoding="UTF-8"?><Response/>', res.responseBody.toString(), 'The response body should contain empty TwiML.');
    }

    // Additional tests might be needed if there are other branches or logic in the handleMessage method.
    private class MobileMessagingServiceMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(202); // Simulate a successful response
            res.setBody('{"messages":[{"callback_url": "https://allianceaustralia--dev.sandbox.my.salesforce-sites.com/smsintegration/services/apexrest/MobileMessagingServiceStatusCallback", "delivery_report": true, "destination_number": "+1234567890", "format": "SMS", "message_expiry_timestamp": null, "message_flags": [] , "message_id": "5043771f-500d-45be-bd41-191de803b577", "metadata":{"salesforce_message_id": "a9t9t000000yVddAAE"}, "status": "queued"}]}');
            return res;
        }
    }

    private class MobileMessagingServiceErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(202); // Simulate a successful response
            res.setBody('{"messages":[{"callback_url": "https://allianceaustralia--dev.sandbox.my.salesforce-sites.com/smsintegration/services/apexrest/MobileMessagingServiceStatusCallback", "delivery_report": true, "destination_number": "+1234567890", "format": "SMS", "message_expiry_timestamp": null, "message_flags": [] , "message_id": "5043771f-500d-45be-bd41-191de803b577", "metadata":{"salesforce_message_id": "a9t9t000000yVddAAE"}, "status": "queued"}]}');
            return res;
        }
    }
}