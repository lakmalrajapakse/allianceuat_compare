public with sharing class SendCustomNotification {
    
    public static void notifyUsers (Set<String> userIds, String targetId, String titleNot, String bodyNot, String notificationName){
        // Get Id for custom notification type
        CustomNotificationType notificationType = 
            [SELECT Id, DeveloperName 
         FROM CustomNotificationType 
         WHERE DeveloperName= :notificationName];
     
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
             
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTitle(titleNot);
        notification.setBody(bodyNot);
        notification.setTargetId(targetId);
              
        try {
            notification.send(userIds);
        }
        catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
        }
    }
}