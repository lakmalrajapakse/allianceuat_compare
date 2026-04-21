@isTest
private class MobileMessagingCreatePushTopicTest {

    @isTest
    static void testMobileMessagingCreatePushTopic() {
        Test.startTest();
        MobileMessagingCreatePushTopic.createMobileMessageSMSPushTopic();
        Test.stopTest();
        
        // Verify that the PushTopic has been created with the correct properties
        PushTopic createdPushTopic = [SELECT Name, Query, ApiVersion, NotifyForOperationCreate, NotifyForOperationUpdate, 
                                              NotifyForOperationUndelete, NotifyForOperationDelete, NotifyForFields 
                                       FROM PushTopic 
                                       WHERE Name = 'MobileMessage_SMS_Watcher' 
                                       LIMIT 1];
        
        System.assertEquals('MobileMessage_SMS_Watcher', createdPushTopic.Name, 'PushTopic Name should match');
        //System.assertEquals('SELECT Id, Contact__c, Contact__r.Name, Direction__c, Short_Message__c, CreatedDate FROM MobileMessaging_SMS_Message__c', createdPushTopic.Query, 'PushTopic Query should match');
        System.assertEquals(58.0, createdPushTopic.ApiVersion, 'PushTopic ApiVersion should match');
        System.assertEquals(true, createdPushTopic.NotifyForOperationCreate, 'PushTopic NotifyForOperationCreate should be true');
        System.assertEquals(true, createdPushTopic.NotifyForOperationUpdate, 'PushTopic NotifyForOperationUpdate should be true');
        System.assertEquals(true, createdPushTopic.NotifyForOperationUndelete, 'PushTopic NotifyForOperationUndelete should be true');
        System.assertEquals(true, createdPushTopic.NotifyForOperationDelete, 'PushTopic NotifyForOperationDelete should be true');
        System.assertEquals('Referenced', createdPushTopic.NotifyForFields, 'PushTopic NotifyForFields should match');
    
 }
}