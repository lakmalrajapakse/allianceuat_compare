trigger ShiftInvitationTrigger on sirenum__Shift_Invitation__c (after insert) {
    // Call the service class method
    JobOfferNotificationService.handleShiftInvitations(Trigger.new);
}