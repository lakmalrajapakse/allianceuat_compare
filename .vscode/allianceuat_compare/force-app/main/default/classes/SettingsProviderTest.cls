@isTest
private class SettingsProviderTest {

    @isTest
    static void settingsProvider_success() {  
        // String costCenter = 'Alliance Test One';
        // DEV
        // String costCenter = 'Alliance_Nurse_Test';
        // UAT
        String costCenter = 'Alliance_Nurse_Allocations';
        // String costCenter = 'Test_SMS_Metadata';
        
        Test.startTest();
        Application_SMS_Configuration__mdt settings = SettingsProvider.getSettings(costCenter);
        Test.stopTest();
    }

    @isTest
    static void settingsProvider_error() {
        String costCenter = 'Incorrect';
        Boolean exceptionCaught = false;
        Test.startTest();
        try{
            Application_SMS_Configuration__mdt settings = SettingsProvider.getSettings(costCenter);
        } catch(Exception e){
            exceptionCaught = true;
        }
        Test.stopTest();
        System.Assert.isTrue(exceptionCaught, 'Didn\'t catch the expected exception');
    }

    @testSetup
    static void setupData() {
        // Insert test data for Contact, CustomNotificationType, and TextIUS_Settings__c
        // Application_SMS_Configuration__mdt smsMetadata = new Application_SMS_Configuration__mdt (
        //     DeveloperName = 'Test_SMS_Metadata',
        //     Label = 'Test Config',
        //     Account_SID__c = 'test_sid',
        //     Authentication_Token__c = 'test_token',
        //     Sender_Phone_Number__c = '+15005550006', // This is a magic number for testing purposes
        //     API_Endpoint__c = 'https://test.endpoint.com',
        //     API_Site_Domain_URL__c = 'https://test.callback.com'//,
        //     // IsActive__c = true
        // );
        // insert smsMetadata;

        Contact testContact = new Contact(FirstName = 'John', LastName = 'Doe', Phone = '1234567890',email='test332255@emailtest.com');
        insert testContact;

        Branch__c branch = new Branch__c(City__c = 'Adelaide', Branch_Name__c = 'Adelaide Allocations', Branch_Code__c = '1');
        insert branch;

        Cost_Center__c costCenter = new Cost_Center__c(
            Name = 'Alliance Test One', 
            Branch__c = branch.Id, 
            // SMS_Cost_Center__c = 'Test_SMS_Metadata', 
            SMS_Cost_Center__c = 'Alliance_Nurse_Allocations', 
            Team__c = 'Allocations', 
            Public_Group__c = 'Adelaide_Nursing_Allocations');
        insert costCenter;

        Cost_Center_User__c costCenterUser = new Cost_Center_User__c(Cost_Center__c = costCenter.Id, User__c = UserInfo.getUserId(), Is_Primary__c = true);
        insert costCenterUser;


        // Mock settings for TextIUS_Settings__c

        SMSSettings settings = SMSSettings.getInstance();

    }
}