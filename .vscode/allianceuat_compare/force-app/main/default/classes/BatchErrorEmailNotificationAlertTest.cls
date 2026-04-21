@isTest
public without sharing class BatchErrorEmailNotificationAlertTest {
    
    @isTest
    public static void givenErrorSet_whenSendBatchErrorEmailNotification_thenSendEmail() {
        BatchErrorEmailNotificationAlert alert = new BatchErrorEmailNotificationAlert('jobId', 
                                                                                      BatchErrorEmailNotificationAlert.BatchCtrl.ShiftAssignmentBatch,
                                                                                      new Set<String>{'Test error', 'test'});
        alert.sendEmail();
    }
    
    @isTest
    public static void givenEmptyErrorSet_whenSendBatchErrorEmailNotification_thenDoNotSendEmail() {
        BatchErrorEmailNotificationAlert alert = new BatchErrorEmailNotificationAlert('jobId', 
                                                                                      BatchErrorEmailNotificationAlert.BatchCtrl.ShiftAssignmentBatch,
                                                                                      new Set<String>());
        alert.sendEmail();
    }
}