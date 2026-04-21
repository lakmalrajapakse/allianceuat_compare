@isTest
private class MassMessageSettingsUtilTest {
    
    // Helper method to create a Mass_Message_Manager__c instance for tests
    private static void createTestMassMessageSettings() {
        Mass_Message_Manager__c settings = new Mass_Message_Manager__c();
        // Set any fields on the settings as necessary for our tests
        // ...
        insert settings;
    }

    // Test the getSettings method to ensure it retrieves the settings correctly
    @isTest static void testGetSettings() {
        // Set up test data
        createTestMassMessageSettings();

        Test.startTest();
        // Call the method under test
        Mass_Message_Manager__c settings = MassMessageSettingsUtil.getSettings();
        Test.stopTest();

        // Verify that the settings are retrieved
        System.assertNotEquals(null, settings, 'The settings should not be null.');

        // If there are specific fields we expect to be set on the settings object,
        // we can add assertions here to verify those field values
        // System.assertEquals(expectedValue, settings.SomeField__c, 'The field should have the expected value.');
    }
}