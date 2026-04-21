@isTest
private class AttachEmailToObjectTest {

@isTest
    static void testAttachEmailLead() {

        VMS_Shift_Error__c shiftError = new VMS_Shift_Error__c(
            VMS_Source__c = 'Emprevo',
            External_Shift_ID__c = 'TestShift1234', 
            VMS_Shift_URL__c = 'www.emprevotest.com',
            VMS_Shift_Info__c = 'Shift Info'//,
            // Error_Type__c = request.errorType,
            // Error_Message__c = request.errorMessage,
        );
        insert shiftError;
        
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.toAddresses = new String[] {'1218_Test@testemail.1218global.com'};
        email.subject = 'Test Subject';
        email.plainTextBody = 'Test Email Body';
        email.htmlBody = 'Test Email Body';
        
        Test.startTest();
        AttachEmailToObject.attachEmail(email, shiftError.Id);
        Test.stopTest();

        List<EmailMessage> emails = [SELECT Id, RelatedToId FROM EmailMessage WHERE RelatedToId = :shiftError.Id];
        System.assertEquals(1, emails.size(), 'Number of emails should be 1');
        System.assertEquals(shiftError.Id, emails[0].RelatedToId, 'Email should be associated with Lead');
    }
}