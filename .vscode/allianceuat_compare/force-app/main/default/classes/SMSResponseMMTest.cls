@isTest
private class SMSResponseMMTest {

    @isTest
    static void testSMSResponseMM() {
        // TO DO: implement unit test
        SMSResponseMM smsResponse = new SMSResponseMM();

        List<SMSResponseMM.Messages> messages = new list<SMSResponseMM.Messages>();
        SMSResponseMM.Messages message = new SMSResponseMM.Messages();
        
        Test.startTest();
        message.format = 'SMS';
        message.message_expiry_timestamp = '2025-07-15T09:16:29.052Z';
        message.message_flags = new List<String>{'Test 1', 'Test 2'};
        message.message_id = 'testAA';
        message.delivery_report = true;
        message.callback_url = 'https://allianceaustralia--dev.sandbox.my.salesforce-sites.com/smsintegration/services/apexrest/MobileMessagingServiceStatusCallback';
        message.status = 'delivered';
        message.destination_number = '+447880139490';
        message.message_flags = new List<String>{'Test 1', 'Test 2'};
        message.metadata = new SMSResponseMM.Metadata();
        message.metadata.salesforce_message_id = 'testSFId';
        messages.add(message);
        Test.stopTest();
        
        System.assertEquals('testAA', message.message_id, 'message_id not set');
        System.assertEquals('SMS', message.format, 'format not set');
        System.assertEquals('testSFId', message.metadata.salesforce_message_id, 'salesforce_message_id not set');
        
    }
}