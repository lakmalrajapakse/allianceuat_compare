/**
* Created by: Rishikesh Kumar Suman
* Date: 24-Sep-2025
* Description: This Apex class is used to send push notifications to candidates whenever a new job offer is created.
*/
public class JobOfferNotificationService {

    public static void handleShiftInvitations(List<sirenum__Shift_Invitation__c> invitations) {

        // Load custom setting
        Job_Offer_Notification__c settings = Job_Offer_Notification__c.getOrgDefaults();
        Integer batchSize = Integer.valueOf(settings.Batch_Size__c);
        String message = settings.Message__c;
        String title = settings.Title__c;
        String requiredStatus = settings.Status__c;

        List<Id> validInvitationIds = new List<Id>();

        // Filter records based on status and related fields
        for (sirenum__Shift_Invitation__c inv : invitations) {
            if (inv.sirenum__Status__c == requiredStatus &&
                inv.sirenum__Shift__c != null &&
                inv.sirenum__Contact__c != null) {

                validInvitationIds.add(inv.Id);
            }
        }

        if (validInvitationIds.isEmpty()) return;

        // Check execution context
        if (System.isBatch() || System.isFuture() || System.isQueueable() || System.isScheduled()) {
            // Already async -> send notifications synchronously
            sendNotificationsSync(validInvitationIds, message, title);
        } else {
            // Synchronous context -> run batch for notifications
            sendNotificationsBatch(validInvitationIds, message, title, batchSize);
        }
    }

    // Synchronous notification creation
    Public static void sendNotificationsSync(List<Id> invitationIds, String message, String title) {
        List<sirenum__PushNotificationEvent__e> notifications = new List<sirenum__PushNotificationEvent__e>();

        List<sirenum__Shift_Invitation__c> invitations = [
            SELECT Id, sirenum__Contact__c
            FROM sirenum__Shift_Invitation__c
            WHERE Id IN :invitationIds
        ];

        for (sirenum__Shift_Invitation__c inv : invitations) {
            sirenum__PushNotificationEvent__e notif = new sirenum__PushNotificationEvent__e();
            notif.sirenum__Message__c = message;
            notif.sirenum__Title__c = title;
            notif.sirenum__WhatId__c = String.valueOf(inv.Id);
            notif.sirenum__WhoId__c = String.valueOf(inv.sirenum__Contact__c);
            notifications.add(notif);
        }

        if ( !Test.isRunningTest() && !notifications.isEmpty()) {
            insert notifications;
        }
    }

    // Batch notification creation for synchronous triggers
    private static void sendNotificationsBatch(List<Id> invitationIds, String message, String title, Integer batchSize) {
        JobOfferNotificationBatch batch = new JobOfferNotificationBatch(invitationIds, message, title);
        Database.executeBatch(batch, batchSize);
    }
}