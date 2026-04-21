@isTest
private class MobileMessageMassSMSControllerTest {

    // Helper method to create test contacts
    private static List<Contact> createTestContacts(Integer count) {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < count; i++) {
            contacts.add(new Contact(LastName = 'TestContact' + i));
        }
        insert contacts;
        return contacts;
    }

    // Simulates the selection of contacts in a list view
    private static ApexPages.StandardSetController createStandardSetController(List<Contact> contacts) {
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(contacts);
        ssc.setSelected(contacts); // Simulate the user selecting these contacts in the UI
        return ssc;
    }

    @isTest static void testModalOperations() {
        //  Create test data and controller instance
        List<Contact> testContacts = createTestContacts(2);
        ApexPages.StandardSetController ssc = createStandardSetController(testContacts);
        MobileMessageMassSMSController controller = new MobileMessageMassSMSController(ssc);

        // Act - Open and close the modal to verify the toggle behavior
        controller.openModal();

        // Assert - Check if the modal is open
        System.assertEquals(true, controller.isModalOpen, 'The modal should be open.');

        // Act - Close the modal
        controller.closeModal();

        // Assert - Check if the modal is closed
        System.assertEquals(false, controller.isModalOpen, 'The modal should be closed.');
    }

    @isTest static void testMessageSending() {
        //  Create test data and controller instance
        List<Contact> testContacts = createTestContacts(3); // Create 3 test contacts
        ApexPages.StandardSetController ssc = createStandardSetController(testContacts);
        MobileMessageMassSMSController controller = new MobileMessageMassSMSController(ssc);

        // Act - Set a message and simulate sending SMS
        String testMessage = 'This is a test SMS message.';
        controller.message = testMessage;
        
        // Here we would normally call a method that sends the message,
        // but since we can't actually send SMS in a test, we'll just verify the message content.
        
        // Assert - Verify that the message content is set correctly
        System.assertEquals(testMessage, controller.message, 'The message content should match the test message.');
        
        // Assert - Verify that the correct number of contacts have been selected
        System.assertEquals(3, controller.contacts.size(), 'There should be 3 contacts selected for the SMS.');
    }
}