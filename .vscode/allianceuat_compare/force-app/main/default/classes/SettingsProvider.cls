public class SettingsProvider {
    @AuraEnabled(cacheable=true)
    // public static TextIUS_Settings__c getSettings() {
    //     return TextIUS_Settings__c.getInstance();
    // }

    public static Application_SMS_Configuration__mdt getSettings(String costCenter) {
        if (!Schema.sObjectType.Application_SMS_Configuration__mdt.isAccessible()) {
            throw new InsufficientAccessRightsException('User does not have read access to Application_SMS_Configuration__mdt');
        }
        System.debug('SettingsProvider costCenter: ' + costCenter);
        try {
            return [SELECT Account_SID__c, API_Endpoint__c, API_Site_Domain_URL__c, Authentication_Token__c, 
                           Default_Admin_Id__c, Default_Admin_Name__c, isActive__c, Provider_Name__c,
                           Sender_Phone_Number__c, Default_Greetings_Message__c, SMS_Cost_Center__c, 
                           Inbound_Header__c, Inbound_Token__c
                    FROM Application_SMS_Configuration__mdt
                    // WHERE SMS_Cost_Center__c = :costCenter
                    WHERE DeveloperName = :costCenter
                    LIMIT 1];
        } catch (Exception e) {
            System.debug('Exception thrown: ' + e.getMessage());
            throw new CustomSettingException('Error fetching SMS settings');
        }
    }

    public class InsufficientAccessRightsException extends Exception {}
    public class CustomSettingException extends Exception {}
}