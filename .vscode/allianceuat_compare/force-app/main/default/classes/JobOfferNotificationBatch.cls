/**
* Created by: Rishikesh Kumar Suman
* Date: 24-Sep-2025
* Description: This Apex class is used to send push notifications to candidates whenever a new job offer is created.
*/
public class JobOfferNotificationBatch implements Database.Batchable<sObject>, Database.Stateful {

    private List<Id> invitationIds;
    private String message;
    private String title;

    public JobOfferNotificationBatch(List<Id> ids, String message, String title) {

        this.invitationIds = ids;
        this.message = message;
        this.title = title;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {

        Database.QueryLocator ql = Database.getQueryLocator([
            SELECT Id, sirenum__Contact__c
            FROM sirenum__Shift_Invitation__c
            WHERE Id IN :invitationIds
        ]);
        return ql;
    }

    public void execute(Database.BatchableContext BC, List<sirenum__Shift_Invitation__c> scope) {
        List<SObject> notifications = new List<SObject>();

        for (sirenum__Shift_Invitation__c inv : scope) {
            // Only send if Contact exists
            if (inv.sirenum__Contact__c != null) {

                // Create Platform Event dynamically
                SObject notif = (SObject) Type.forName('sirenum__PushNotificationEvent__e').newInstance();
                notif.put('sirenum__Message__c', message);
                notif.put('sirenum__Title__c', title);
                notif.put('sirenum__WhatId__c', inv.Id);
                notif.put('sirenum__WhoId__c', inv.sirenum__Contact__c);

                notifications.add(notif);
            } else {
                System.debug('### Skipping invitation, Contact is null: ' + JSON.serialize(inv));
            }
        }

        if (!notifications.isEmpty()) {
            Database.insert(notifications);
        }
    }

    public void finish(Database.BatchableContext BC) {
        System.debug('### Push notifications batch finished.');
    }
}