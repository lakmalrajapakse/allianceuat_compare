/**
 * MobileMessagingCreatePushTopic
 * This class is designed to facilitate the creation of a PushTopic for Salesforce Streaming API.
 * The PushTopic will enable real-time notifications for changes to the MobileMessaging_SMS_Message__c records.
 *
 * Usage:
 * - This utility class should be invoked to initialize the PushTopic upon setup or when updates are required.
 * - The created PushTopic will allow subscribers to receive notifications for create, update, delete,
 *   and undelete operations on the MobileMessaging_SMS_Message__c object fields referenced in the SOQL query.
 *
 * Created by: Issam Alameh
 * Role: Technical Consultant
 * Company: 1218 Global
 * Email: issam.alameh@1218global.com
 * LinkedIn: https://www.linkedin.com/in/issam
 * Creation Date: [Specify Creation Date Here]
 * Last Modified: 14 Jan 2024
 */
public class MobileMessagingCreatePushTopic {
    
    /**
     * Method to create a PushTopic for mobile messaging.
     * It sets up the necessary configuration for the PushTopic and inserts it into Salesforce.
     */
    public static void createMobileMessageSMSPushTopic() {
        // Instantiate a new PushTopic object.
        PushTopic pushTopic = new PushTopic();
        
        // Set the name of the PushTopic. This is used by clients to subscribe to the topic.
        pushTopic.Name = 'MobileMessage_SMS_Watcher';
        
        // Define the SOQL query that determines which record changes will send notifications.
        pushTopic.Query = 'SELECT Id, Contact__c, Direction__c, Short_Message__c, CreatedDate FROM MobileMessaging_SMS_Message__c';
        
        // Set the API version for this PushTopic.
        pushTopic.ApiVersion = 58.0;
        
        // Configure the PushTopic to send notifications for record creation, update, undelete, and delete operations.
        pushTopic.NotifyForOperationCreate = true;
        pushTopic.NotifyForOperationUpdate = true;
        pushTopic.NotifyForOperationUndelete = true;
        pushTopic.NotifyForOperationDelete = true;
        
        // Specify that notifications should be sent for changes to fields referenced in the SOQL query.
        pushTopic.NotifyForFields = 'Referenced';
        
        try {
            // Insert the new PushTopic record into Salesforce.
            insert pushTopic;
        } catch (Exception e) {
            // Log the exception and rethrow it to ensure that callers are aware of any issues during the creation process.
            System.debug('Exception occurred while creating PushTopic: ' + e.getMessage());
            throw e;
        }
    }
}