/**
 * MassMessageSettingsUtil
 * This utility class provides access to the organization's mass messaging settings.
 * It serves as a centralized point to retrieve configurations for the Mass_Message_Manager__c custom setting.
 * This allows other components in the system to operate based on the current settings without directly querying them.
 *
 * Usage:
 * - Call getSettings() to fetch the current Mass_Message_Manager__c instance containing the settings.
 * - Use the returned settings object to determine the application behavior in various messaging scenarios.
 *
 * Created by: Issam Alameh
 * Role: Technical Consultant
 * Company: 1218 Global
 * Email: issam.alameh@1218global.com
 * LinkedIn: https://www.linkedin.com/in/issam
 * Created on: 
 * Last modified on: 14 Jan 2024 at 11:29:21 am AEST (Melbourne, Australia)
 *
 * Example:
 * Mass_Message_Manager__c settings = MassMessageSettingsUtil.getSettings();
 */

 public with sharing class MassMessageSettingsUtil {
    
    /**
     * Retrieves the current settings from the Mass_Message_Manager__c custom setting.
     * This method accesses a singleton instance of the custom setting which holds the configuration
     * for mass messaging features across the organization.
     *
     * @return Mass_Message_Manager__c The current settings instance for mass messaging.
     */
    public static Mass_Message_Manager__c getSettings() {
        // Fetch the singleton instance of Mass_Message_Manager__c from the org's custom settings
        Mass_Message_Manager__c settings = Mass_Message_Manager__c.getInstance();
        return settings;
    }
}