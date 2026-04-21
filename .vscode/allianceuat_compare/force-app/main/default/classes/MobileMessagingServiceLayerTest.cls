@isTest
private class MobileMessagingServiceLayerTest {

    // Helper method to create a mock configuration for the messaging service
    private static void createMockMobileMessagingConfig() {
        Application_SMS_Configuration__mdt mockConfig = new Application_SMS_Configuration__mdt(
            DeveloperName = 'Test_Config',
            Label = 'Test Config',
            Account_SID__c = 'test_sid',
            Authentication_Token__c = 'test_token',
            Sender_Phone_Number__c = '+15005550006', // This is a magic number for testing purposes
            API_Endpoint__c = 'https://test.endpoint.com',
            API_Site_Domain_URL__c = 'https://test.callback.com'//,
            // IsActive__c = true
        );
    }

    // Method to simulate the response from the external service
    @isTest static void mockHttpResponse() {
        // Create mock configuration data
        // createMockMobileMessagingConfig();

        // Set up the mock HTTP response generator
        Test.setMock(HttpCalloutMock.class, new MobileMessagingServiceMock());

        // Call the method to test, which will invoke the mock response
        Test.startTest();
        MobileMessagingServiceLayer.sendSMSAsync('+1234567890', 'Test message', 'a1Sxx0000001gWE', 'a1Sxx0000001gWE', 'a9t9t000000xWv7AAE'); //added value to make it deploy
        Test.stopTest();

        // Perform assertions or further logic as necessary
        // Note: Since @future methods are executed after Test.stopTest(),
        // any assertions related to the future method's execution should be here.
    }

    // Inner class to implement the HttpCalloutMock interface
    private class MobileMessagingServiceMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(202); // Simulate a successful response
            res.setBody('{"messages":[{"callback_url": "https://allianceaustralia--dev.sandbox.my.salesforce-sites.com/smsintegration/services/apexrest/MobileMessagingServiceStatusCallback", "delivery_report": true, "destination_number": "+447881825126", "format": "SMS", "message_expiry_timestamp": null, "message_flags": [] , "message_id": "5043771f-500d-45be-bd41-191de803b577", "metadata":{"salesforce_message_id": "a9t9t000000yVddAAE"}, "status": "queued"}]}');
            return res;
        }
    }
}