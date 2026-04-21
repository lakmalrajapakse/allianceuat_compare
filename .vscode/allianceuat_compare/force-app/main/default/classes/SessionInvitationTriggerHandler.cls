public without sharing class SessionInvitationTriggerHandler {
    static final String DEFAULT_TIMEZONE = 'Australia/Sydney';
    public static void handleChange() {
        List<b3o__Session_Invitation__c> invitations = (List<b3o__Session_Invitation__c>) Trigger.new;
        Map<id, b3o__Session_Invitation__c> oldMap = (Map<id, b3o__Session_Invitation__c>) Trigger.oldMap;
                 
        List<b3o__Session_Invitation__c> toProcess = new List<b3o__Session_Invitation__c>();
        Set<id> contactIds = new Set<id>();
        Set<id> sessionIds = new Set<id>();
        for (b3o__Session_Invitation__c i : invitations) {
            if (i.b3o__Booking_Start_Time__c != null && i.b3o__Booking_End_Time__c != null &&
               (oldMap == null || oldMap.get(i.id) == null 
               || oldMap.get(i.id).b3o__Booking_Start_Time__c != i.b3o__Booking_Start_Time__c || i.Booking_Time_Local__c == null || i.Booking_End_Time_Local__c == null
               || i.Booking_Start_Time_Session__c == null || i.Booking_End_Time_Session__c == null)) {
               toProcess.add(i);                                    
               contactIds.add(i.b3o__Contact__c);
               sessionIds.add(i.b3o__Session__c);
            }
        }

        if (toProcess.isEmpty()) {
            return;
        }

        Map<id, Contact> contacts = new Map<id, Contact>([select id, Candidate_Timezone__c from Contact where id = :contactIds]);
        Map<id, b3o__Session__c> sessions = new Map<id, b3o__Session__c>([select id, Timezone__c from b3o__Session__c where id = :sessionIds]);
                
        for (b3o__Session_Invitation__c i : toProcess) {
            String timezone = (contacts.get(i.b3o__Contact__c).Candidate_Timezone__c == null) ? 
                              sessions.get(i.b3o__Session__c).Timezone__c : contacts.get(i.b3o__Contact__c).Candidate_Timezone__c;
            timezone = (timezone == null) ? DEFAULT_TIMEZONE : timezone;
            String sessionTimezone = (sessions.get(i.b3o__Session__c).Timezone__c == null) ? DEFAULT_TIMEZONE : sessions.get(i.b3o__Session__c).Timezone__c;

            i.Booking_Time_Local__c = i.b3o__Booking_Start_Time__c.format('dd/MM/yyyy h:mm a', timezone);
            i.Booking_End_Time_Local__c = i.b3o__Booking_End_Time__c.format('dd/MM/yyyy h:mm a', timezone);
            i.Booking_Start_Time_Session__c = i.b3o__Booking_Start_Time__c.format('dd/MM/yyyy h:mm a', sessionTimezone);
            i.Booking_End_Time_Session__c = i.b3o__Booking_End_Time__c.format('dd/MM/yyyy h:mm a', sessionTimezone);
            i.Booked_Timestamp__c = System.now();
        }
    }        
}