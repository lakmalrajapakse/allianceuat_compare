@isTest
private class SMSMessageTriggerHandlerTest {
    
    // Helper method to create test contacts
    private static List<Contact> createTestContacts(Integer numContacts) {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < numContacts; i++) {
            contacts.add(new Contact(
                FirstName = 'TestContact' + i,
                LastName = 'LastName' + i,
                MobilePhone = '+6143456789' + i,
				//tc9_et__Timesheet_Notification_Email__c = 'Primary', 
            	email='abc' + i + '@abc.com'
            ));
        }
        return contacts;
    }

    // Helper method to create test SMS messages with placeholders
    private static List<MobileMessaging_SMS_Message__c> createTestSMSMessages(List<Contact> contacts) {
        List<MobileMessaging_SMS_Message__c> messages = new List<MobileMessaging_SMS_Message__c>();
        for (Contact contact : contacts) {
            messages.add(new MobileMessaging_SMS_Message__c(
                Contact__c = contact.Id,
                Message_Content__c = 'Hello <firstname>, our appointment is coming up.',
                Source__c = 'Test'
            ));
        }
        return messages;
    }

    private static List<MobileMessaging_SMS_Message__c> createTestSMSMessages_PIN(List<Contact> contacts) {
        List<MobileMessaging_SMS_Message__c> messages = new List<MobileMessaging_SMS_Message__c>();
        for (Contact contact : contacts) {
            messages.add(new MobileMessaging_SMS_Message__c(
                // Contact__c = '',
                Message_Content__c = 'SMS Pin Number Test.',
                Source__c = 'SMSTempPIN',
                TempMobilePhone__c = '+61487654321'
            ));
        }
        return messages;
    }

    @TestSetup
    static void setup() {
        // Insert test contacts
        // List<Contact> testContacts = createTestContacts(50);
        List<Contact> testContacts = createTestContacts(5);
        insert testContacts;

        // Insert test SMS messages linked to the contacts
        List<MobileMessaging_SMS_Message__c> testMessages = createTestSMSMessages(testContacts);
        // Do not insert here as we will do so within the test methods to trigger the before insert actions
    }

    @isTest
    static void testBeforeInsert() {
        // Start the test context
        Test.startTest();

        // Query for test contacts and messages
        List<Contact> contacts = [SELECT Id, FirstName FROM Contact];
        List<MobileMessaging_SMS_Message__c> messages = createTestSMSMessages(contacts);

        // Perform the before insert trigger action by inserting the messages
        insert messages;

        // Stop the test context
        Test.stopTest();

        // Assert that placeholders are replaced with Contact first names
        for (MobileMessaging_SMS_Message__c message : [SELECT Message_Content__c FROM MobileMessaging_SMS_Message__c]) {
            System.assert(message.Message_Content__c.contains('TestContact'), 'The placeholder should be replaced with the contact\'s first name.');
        }
    }

    @isTest
    static void testAfterInsert() {
        // Query for test contacts
        List<Contact> contacts = [SELECT Id, FirstName FROM Contact];
        
        // Prepare messages for after insert
        List<MobileMessaging_SMS_Message__c> messages = createTestSMSMessages(contacts);

        // Start the test context
        Test.startTest();

        // Perform the after insert trigger action by inserting the messages
        insert messages;

        // Stop the test context
        Test.stopTest();

        // Assert that SMS Message Queue records are created and linked to the SMS messages
        for (MobileMessaging_SMS_Message__c message : [SELECT Id, Message_Content__c FROM MobileMessaging_SMS_Message__c]) {
            List<SMS_Message_Queue__c> queueItems = [SELECT Id, Message_Record_Id__c FROM SMS_Message_Queue__c WHERE Message_Record_Id__c = :message.Id];
            System.assertEquals(1, queueItems.size(), 'There should be one queue item per SMS message.');
            System.assertEquals(message.Id, queueItems[0].Message_Record_Id__c, 'The queue item should be linked to the correct SMS message.');
        }
    }
       @isTest
    static void testAfterInsert_SMSTempPIN() {
        // Query for test contacts
        List<Contact> contacts = [SELECT Id, FirstName FROM Contact LIMIT 1];
        system.debug('SMSMessageTriggerHandlerTest contacts: ' + contacts);
        
        // Prepare messages for after insert
        List<MobileMessaging_SMS_Message__c> messages = createTestSMSMessages_PIN(contacts);
        system.debug('SMSMessageTriggerHandlerTest messages: ' + messages);

        // Start the test context
        Test.startTest();
        system.debug('SMSMessageTriggerHandlerTest startTest');
        // Perform the after insert trigger action by inserting the messages
        insert messages;
        system.debug('SMSMessageTriggerHandlerTest stopTest');
        // Stop the test context
        Test.stopTest();

        // Assert that SMS Message Queue records are created and linked to the SMS messages
        List<MobileMessaging_SMS_Message__c> messagesPIN = [SELECT Id, Message_Content__c, Source__c FROM MobileMessaging_SMS_Message__c LIMIT 1];
        system.debug('SMSMessageTriggerHandlerTest messagesPIN: ' + messagesPIN);
        System.assertEquals(messagesPIN[0].Source__c, 'SMSTempPIN', 'Source should be SMSTempPIN');
    }
}