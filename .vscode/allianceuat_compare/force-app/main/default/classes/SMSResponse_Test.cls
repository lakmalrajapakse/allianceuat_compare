@isTest
public class SMSResponse_Test {
    
    @isTest
    static void testSuccessResponse() {
        // Mock a successful HTTP response
        // String successResponseBody = '{"@type":"Message"}';
        String successResponseBody = '{"StatusCode":"202"}';
        System.HttpResponse mockHttpResponse = new System.HttpResponse();
        mockHttpResponse.setBody(successResponseBody);
        mockHttpResponse.setStatusCode(202);
        
        // Instantiate SMSResponse with mock response
        Test.startTest();
        SMSResponse smsResponse = new SMSResponse(mockHttpResponse);
        Test.stopTest();      
        
        // Assert that the response is successful
        System.assert(smsResponse.isSuccess(), 'The response should indicate success.');
        System.assertEquals(null, smsResponse.getErrorTitle(), 'There should be no error title in a success response.');
        System.assertEquals(null, smsResponse.getErrorDetail(), 'There should be no error detail in a success response.');
    }
    
    @isTest
    static void testErrorResponse() {
        // Mock an error HTTP response
        String errorResponseBody = '{"title":"Error Title","detail":"Error details."}';
        System.HttpResponse mockHttpResponse = new System.HttpResponse();
        mockHttpResponse.setBody(errorResponseBody);
        
        // Instantiate SMSResponse with mock response
        Test.startTest();
        SMSResponse smsResponse = new SMSResponse(mockHttpResponse);
        Test.stopTest();        

        System.assertEquals('Error Title', smsResponse.getErrorTitle(), 'The error title should be "Error Title".');
        System.assertEquals('Error details.', smsResponse.getErrorDetail(), 'The error detail should be "Error details.".');
    }
    
    @isTest
    static void testMalformedJsonResponse() {
        // Mock a malformed JSON HTTP response
        String malformedJsonResponseBody = 'invalid json';
        System.HttpResponse mockHttpResponse = new System.HttpResponse();
        Test.startTest();
        // Expecting the constructor to throw an SMSSendException
        try {
            SMSResponse smsResponse = new SMSResponse(mockHttpResponse);
            System.assert(false, 'An exception should have been thrown due to malformed JSON.');
        } catch (SMSSendException e) {
            System.assert(e.getMessage().startsWith('Failed to parse JSON response'), 'Exception message should indicate JSON parsing failure.');
        }
        Test.stopTest();
        
        
    }

    @isTest
    static void testSuccessResponse_SMS() {

    // SMSResponse:[messageMediaResponse=SMSResponseMM:[messages=(Messages:[
    // callback_url=https://allianceaustralia--dev.sandbox.my.salesforce-sites.com/smsintegration/services/apexrest/MobileMessagingServiceStatusCallback, 
    // delivery_report=true, destination_number=+447881825126, format=SMS, message_expiry_timestamp=null, message_flags=(), message_id=5043771f-500d-45be-bd41-191de803b577, 
    // metadata=Metadata:[salesforce_message_id=a9t9t000000yVddAAE], status=queued])], responseM

        // Mock a successful HTTP response
        // String successResponseBody = '{"@type":"Message"}';

        String successResponseBody='{"messages":[{"callback_url": "https://allianceaustralia--dev.sandbox.my.salesforce-sites.com/smsintegration/services/apexrest/MobileMessagingServiceStatusCallback",'; 
        successResponseBody+=' "delivery_report": true, "destination_number": "+1234567890", "format": "SMS", "message_expiry_timestamp": "2025-07-15T09:16:29.052Z",';
        successResponseBody+=' "message_flags": [] , "message_id": "5043771f-500d-45be-bd41-191de803b577", "metadata":{"salesforce_message_id": "a9t9t000000yVddAAE"}, "status": "queued"}]}';

        // String successResponseBody='{"messages":[{"Messages":[{"callback_url": "https://allianceaustralia--dev.sandbox.my.salesforce-sites.com/smsintegration/services/apexrest/MobileMessagingServiceStatusCallback",'; 
        // successResponseBody+=' "delivery_report": true, "destination_number": "+1234567890", "format": "SMS", "message_expiry_timestamp": "2025-07-15T09:16:29.052Z",';
        // successResponseBody+=' "message_flags": [] , "message_id": "5043771f-500d-45be-bd41-191de803b577", "metadata":{"salesforce_message_id": "a9t9t000000yVddAAE"}, "status": "queued"}]}]}';

        System.HttpResponse mockHttpResponse = new System.HttpResponse();
        mockHttpResponse.setBody(successResponseBody);
        mockHttpResponse.setStatusCode(202);
        
        // Instantiate SMSResponse with mock response
        Test.startTest();
        SMSResponse smsResponse = new SMSResponse(mockHttpResponse);
        Test.stopTest();

        System.debug(LOGGINGLEVEL.ERROR, 'SMSResponse_Test smsResponse: ' + smsResponse);
        // System.debug(LOGGINGLEVEL.ERROR, 'SMSResponse_Test smsResponse.keySet(): ' + smsResponse.keySet());
        // System.debug(LOGGINGLEVEL.ERROR, 'SMSResponse_Test smsResponse.values(): ' + smsResponse.values());

        // System.debug(LOGGINGLEVEL.ERROR, 'SMSResponse_Test smsResponse.isSuccess(): ' + smsResponse.isSuccess());
        // // System.debug(LOGGINGLEVEL.ERROR, 'SMSResponse_Test smsResponse.getMessages(): ' + smsResponse.getMessages());
        // System.debug(LOGGINGLEVEL.ERROR, 'SMSResponse_Test smsResponse.getMMSMSMessage(): ' + smsResponse.getMMSMSMessage());
        // System.debug(LOGGINGLEVEL.ERROR, 'SMSResponse_Test smsResponse.getErrorTitle(): ' + smsResponse.getErrorTitle());
        // System.debug(LOGGINGLEVEL.ERROR, 'SMSResponse_Test smsResponse.getErrorDetail(): ' + smsResponse.getErrorDetail());

        // Assert that the response is successful
        System.assert(smsResponse.isSuccess(), 'The response should indicate success.');
        System.assertEquals('5043771f-500d-45be-bd41-191de803b577', smsResponse.getMMSMSMessage(), 'There should be no error title in a success response.');
        System.assertEquals(null, smsResponse.getErrorTitle(), 'There should be no error title in a success response.');
        System.assertEquals(null, smsResponse.getErrorDetail(), 'There should be no error detail in a success response.');
    }

    private class MobileMessagingServiceMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(202); // Simulate a successful response
            res.setBody('{"messages":[{"callback_url": "https://allianceaustralia--dev.sandbox.my.salesforce-sites.com/smsintegration/services/apexrest/MobileMessagingServiceStatusCallback", "delivery_report": true, "destination_number": "+1234567890", "format": "SMS", "message_expiry_timestamp": null, "message_flags": [] , "message_id": "5043771f-500d-45be-bd41-191de803b577", "metadata":{"salesforce_message_id": "a9t9t000000yVddAAE"}, "status": "queued"}]}');
            return res;
        }
    }
}