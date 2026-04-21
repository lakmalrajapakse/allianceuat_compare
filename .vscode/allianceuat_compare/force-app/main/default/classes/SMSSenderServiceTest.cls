@isTest
private class SMSSenderServiceTest {

    @testSetup
    static void setup() {
        // String costCenter = 'Alliance Test One';
        String costCenter = 'Alliance UAT Allocations';
        Application_SMS_Configuration__mdt settings = SettingsProvider.getSettings(costCenter);
    }

    @isTest
    static void testSendSMS_UnsupportedProvider() {
        // Mock SMSSettings for an unsupported provider
        MsgMediaHttpMock mockHttp = new MsgMediaHttpMock();
        Test.setMock(HttpCalloutMock.class, mockHttp);

        // Create instance of SMSSenderService
        SMSSenderService smsService = new SMSSenderService();

        // Test sending SMS with unsupported provider
        Test.startTest();
        smsService.sendSMS('1234567890', 'Test SMS with unsupported provider',  'a9t9t000000xWv7AAE');
        Test.stopTest();

        // Verify the behavior
        // Check debug logs or other assertions as needed
    }

    private class MsgMediaHttpMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(202); // Simulate a successful response
            // res.setBody('{"sid": "SMXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", "status": "queued"}');
            // res.setBody('{messages=({callback_url=https://allianceaustralia--dev.sandbox.my.salesforce-sites.com/smsintegration/services/apexrest/MobileMessagingServiceStatusCallback, delivery_report=true, destination_number=+447881825126, format=SMS, message_expiry_timestamp=null, message_flags=() , message_id=5043771f-500d-45be-bd41-191de803b577})}');
            
            // res.setBody('{"messages"=({callback_url=https://allianceaustralia--dev.sandbox.my.salesforce-sites.com/smsintegration/services/apexrest/MobileMessagingServiceStatusCallback, delivery_report=true, destination_number=+447881825126, format=SMS, message_expiry_timestamp=null, message_flags=() , message_id=5043771f-500d-45be-bd41-191de803b577})}');
           
            res.setBody('{"messages":[{"callback_url": "https://allianceaustralia--dev.sandbox.my.salesforce-sites.com/smsintegration/services/apexrest/MobileMessagingServiceStatusCallback", "delivery_report": true, "destination_number": "+447881825126", "format": "SMS", "message_expiry_timestamp": "null", "message_flags": [] , "message_id": "5043771f-500d-45be-bd41-191de803b577", "metadata":{"salesforce_message_id": "a9t9t000000yVddAAE"}, "status": "queued"}]}');
            // res.setBody('{"callback_url": "https://allianceaustralia--dev.sandbox.my.salesforce-sites.com/smsintegration/services/apexrest/MobileMessagingServiceStatusCallback", "delivery_report": "true", "destination_number": "+447881825126", "format": "SMS", "message_expiry_timestamp": "null", "message_flags": "()" , "message_id": "5043771f-500d-45be-bd41-191de803b577"}');
            

            // 18:31:52.22 (274506235)|USER_DEBUG|[6]|ERROR|SMSResponse responseMap: {messages=({callback_url=https://allianceaustralia--dev.sandbox.my.salesforce-sites.com/smsintegration/services/apexrest/MobileMessagingServiceStatusCallback/, content=Prad - test message from Salesforce, so I can debug it., delivery_report=true, destination_number=+61450779840, format=SMS, media=null, message_expiry_timestamp=null, message_flags=(), message_id=491296d9-8077-46ec-8114-4eb4cf91d0e6, metadata=null, ...})}
            // 12:22:57.0 (7882088)|USER_DEBUG|[33]|DEBUG|MobileMessagingServiceStatusCallback reqBody: {callback_url=https://allianceaustralia--dev.sandbox.my.salesforce-sites.com/smsintegration/services/apexrest/MobileMessagingServiceStatusCallback, 
            // date_received=2024-11-15T12:22:57.133Z, delay=0, delivery_report_id=21630deb-2419-4b73-904a-a641b47bd2dd, error_code=101, message_id=db100abc-7a61-4113-aba4-69f00cc31992, 
            // metadata={salesforce_message_id=a9t9t000000yVddAAE}, original_text=12:22, source_number=+447881825126, status=enroute, ...}

            return res;
        }
    }
}