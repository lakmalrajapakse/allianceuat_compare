@isTest
private class SMSSenderTest {

    @isTest
    static void testSendSMS() {
        // Given phone number and message body
        String to = '1234567890';
        String body = 'Test SMS';
        String messageId = 'a9t9t000000xWv7AAE';

        // Mock SMSSettings for TextUs
        MsgMediaHttpMock mockHttp = new MsgMediaHttpMock();
        Test.setMock(HttpCalloutMock.class, mockHttp);

        // Test the sendSMS method
        Test.startTest();

        try {
            SMSSender.sendSMS(to, body, messageId);
            System.assert(true, 'No exception was thrown.');
        } catch (Exception e) {
            System.assert(false, 'An exception was thrown');
        }
        Test.stopTest();
    }

    private class MsgMediaHttpMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(202); // Simulate a successful response
        res.setBody('{"messages":[{"callback_url": "https://allianceaustralia--dev.sandbox.my.salesforce-sites.com/smsintegration/services/apexrest/MobileMessagingServiceStatusCallback", "delivery_report": true, "destination_number": "+447881825126", "format": "SMS", "message_expiry_timestamp": null, "message_flags": [] , "message_id": "5043771f-500d-45be-bd41-191de803b577", "metadata":{"salesforce_message_id": "a9t9t000000yVddAAE"}, "status": "queued"}]}');

        return res;
    }
    }
}