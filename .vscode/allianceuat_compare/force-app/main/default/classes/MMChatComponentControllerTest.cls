@isTest
private class MMChatComponentControllerTest {

    // Helper method to create a test contact
    private static Contact createTestContact() {
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact', 
        Email = 'example@example.com', MobilePhone = '+61481494782');
        insert testContact;
        return testContact;
    }

    // Helper method to create test SMS messages for a contact
    private static List<MobileMessaging_SMS_Message__c> createTestMessages(Contact testContact, Integer count) {
        List<MobileMessaging_SMS_Message__c> messages = new List<MobileMessaging_SMS_Message__c>();
        for (Integer i = 0; i < count; i++) {
            try {
                messages.add(new MobileMessaging_SMS_Message__c(
                    Contact__c = testContact.Id,
                    Short_Message__c = 'Test Message ' + i,
                    Direction__c   = 'Inbound',
                    Source__c      = 'SMS',
                    Status__c      = 'Received',
                    Message_Content__c = 'Test Message ' + i
                                    ));
                
            } catch (Exception e) {
                System.debug('Exception: ' + e.getMessage());
                
            }
           
        }
        insert messages;
        return messages;
    }

    @isTest static void testGetPastMessages() {
        //  create a test contact and associated messages
        Contact testContact = createTestContact();
        List<MobileMessaging_SMS_Message__c> testMessages = createTestMessages(testContact, 3);

        // Act - retrieve past messages using the controller method
        Test.startTest();
        List<MobileMessagingChatComponentController.MessageWrapper> retrievedMessages = (List<MobileMessagingChatComponentController.MessageWrapper>)MobileMessagingChatComponentController.getPastMessages(testContact.Id);
        Test.stopTest();

        // Assert - check if the correct number of messages is retrieved
        System.assertEquals(3, retrievedMessages.size(), 'There should be 3 messages retrieved for the contact.');

        // Additional assertions could be performed here to verify the content of the messages
    }

    @isTest 
    static void testGetPastMessages_fail() {
        Contact testContact = createTestContact();
        List<MobileMessaging_SMS_Message__c> testMessages = createTestMessages(testContact, 3);

        Test.startTest();
        try{
            List<MobileMessagingChatComponentController.MessageWrapper> retrievedMessages = (List<MobileMessagingChatComponentController.MessageWrapper>)MobileMessagingChatComponentController.getPastMessages(null);
        } catch (Exception e){
            System.Assert.isTrue(e != null, 'An exception should have been thrown.');
        }
        Test.stopTest();
    }

    // we would also need to write a test method for createNewMessage if it exists in our controller
    @isTest 
    static void createNewMessage_valid() {
        Contact testContact = createTestContact();
        String messageBody = 'Test Message';
        String newMessageType = 'outbound';

        Test.startTest();
        MobileMessagingChatComponentController.MessageWrapper message = MobileMessagingChatComponentController.createNewMessage(testContact.Id, messageBody, newMessageType);
        System.debug('MMChatComponentControllerTest message: ' + message);
        Test.stopTest();

        System.assertEquals('Test Message', message.messageContent, 'Message created.');
    }

    @isTest 
    static void createNewMessage_invalidNoContact() {
        Contact testContact = createTestContact();
        String messageBody = 'Test Message';
        String newMessageType = 'outbound';

        Test.startTest();
        
        try{
            MobileMessagingChatComponentController.MessageWrapper message = MobileMessagingChatComponentController.createNewMessage(null, messageBody, newMessageType);
        } catch (Exception e){
            System.Assert.isTrue(e != null, 'An exception should have been thrown.');
        }

         try{
            MobileMessagingChatComponentController.MessageWrapper message = MobileMessagingChatComponentController.createNewMessage(testContact.Id, '', newMessageType);
        } catch (Exception e){
            System.Assert.isTrue(e != null, 'An exception should have been thrown.');
        }

         try{
            MobileMessagingChatComponentController.MessageWrapper message = MobileMessagingChatComponentController.createNewMessage(testContact.Id, messageBody, '');
        } catch (Exception e){
            System.Assert.isTrue(e != null, 'An exception should have been thrown.');
        }
        Test.stopTest();

    }
}