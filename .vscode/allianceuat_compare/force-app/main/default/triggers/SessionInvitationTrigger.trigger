trigger SessionInvitationTrigger on b3o__Session_Invitation__c (before insert, before update) {
    SessionInvitationTriggerHandler.handleChange();
}