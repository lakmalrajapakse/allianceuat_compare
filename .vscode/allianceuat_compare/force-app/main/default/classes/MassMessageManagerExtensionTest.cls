@isTest
private class MassMessageManagerExtensionTest {

    // Helper method to create test records and simulate selection in a list view
    private static List<Contact> createTestContact() {
        // Create and insert test records
        List<Contact> testContacts = new List<Contact>{
            new Contact(FirstName='Test', LastName = 'Contact 1', MobilePhone='1234567890'),
            new Contact(FirstName='Test', LastName = 'Contact 2', MobilePhone='0987654321')
            // Add more test records as needed
        };
        insert testContacts;
        return testContacts;
    }

    // Helper method to simulate the StandardSetController with selected records
    private static ApexPages.StandardSetController simulateStandardSetController(List<Contact> contacts) {
        // Simulate record selection in a list view by passing the test records to the StandardSetController
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(contacts);
        ssc.setSelected(contacts);
        return ssc;
    }

    // Test the constructor with selected records
    @isTest static void testConstructorWithSelectedRecords() {
        // Setup - Create test contacts and simulate the StandardSetController with selected records
        List<Contact> testContact = createTestContact();
        ApexPages.StandardSetController ssc = simulateStandardSetController(testContact);

        // Execute - Instantiate the extension with the simulated controller
        MassMessageManagerExtension extension = new MassMessageManagerExtension(ssc);

        // Verify - The selectedRecordIds should contain the IDs of the inserted Contact, separated by commas
        String expectedIds = '';
        for (Contact con : testContact) {
            expectedIds += con.Id;
            expectedIds += ',';
        }
        expectedIds = expectedIds.substring(0, expectedIds.length() - 1); // Remove the trailing comma

        System.assertEquals(expectedIds, extension.selectedRecordIds, 'The selectedRecordIds should match the expected value');
    }

    // Test the constructor with no selected records
    @isTest static void testConstructorWithNoSelectedRecords() {
        // Setup - Create a StandardSetController with no selected records
        List<Contact> emptyContactsList = new List<Contact>(); // Empty list of contacts
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(emptyContactsList);

        // Execute - Instantiate the extension with the simulated controller
        MassMessageManagerExtension extension = new MassMessageManagerExtension(ssc);

        // Verify - The selectedRecordIds should be null or empty as no records were selected
        System.assert(String.isEmpty(extension.selectedRecordIds), 'The selectedRecordIds should be empty or null');
    }
}