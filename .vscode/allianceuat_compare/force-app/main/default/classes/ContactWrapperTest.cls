@isTest
private class ContactWrapperTest {

    // Utility method to create a test Contact record
    private static Contact createTestContact() {
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'testcontact@example.com',
            Phone = '1234567890'
        );
        insert testContact;
        return testContact;
    }

    // Test the constructor and the properties initialization
    @isTest static void testContactWrapperInitialization() {
        // Create a test contact record
        Contact testContact = createTestContact();

        // Initialize the ContactWrapper
        ContactWrapper wrapper = new ContactWrapper(
            testContact,
            true, // smsStatus
            true, // emailStatus
            true, // pushStatus
            false, // sendSMSDefault
            false, // sendEmailDefault
            false  // sendPushDefault
        );

        // Assert that the contact is set correctly
        System.assertEquals(testContact, wrapper.contact, 'The contact should be set correctly in the wrapper.');

        // Assert that the flags are set correctly based on the constructor parameters
        System.assertEquals(true, wrapper.sendSMSDisabled, 'The sendSMSDisabled flag should be true.');
        System.assertEquals(true, wrapper.sendEmailDisabled, 'The sendEmailDisabled flag should be true.');
        System.assertEquals(true, wrapper.sendPushDisabled, 'The sendPushDisabled flag should be true.');
        
        System.assertEquals(false, wrapper.sendSMS, 'The sendSMS flag should be false.');
        System.assertEquals(false, wrapper.sendEmail, 'The sendEmail flag should be false.');
        System.assertEquals(false, wrapper.sendPush, 'The sendPush flag should be false.');
        // Assert default properties are initialized correctly
        System.assertEquals(null, wrapper.status, 'Status should be null by default.');
        // System.assertEquals(null, wrapper.conId, 'conId should be null by default.');
        // System.assertEquals(null, wrapper.type, 'Type should be null by default.');
        // System.assertEquals(null, wrapper.result, 'Result should be null by default.');
        // System.assertEquals(null, wrapper.message, 'Message should be null by default.');
    }

    // Additional tests can be written to cover more scenarios,
    // such as changing flags after initialization and ensuring they are set correctly,
    // or testing any methods that may be added to the ContactWrapper class.
}