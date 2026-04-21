trigger X1218_SubStatusTrigger on TR1__Sub_Status__c (after insert, after update) {

    // This is deprecated.
    // if (Trigger.isAfter) {
    //     if(Trigger.isInsert || Trigger.isAfter) {
    //         X1218_CreateBHConnectUser.processSubStatus(Trigger.new);
    //     }
    // }

}