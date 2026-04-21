trigger ShiftMatch_ShiftTrigger on sirenum__Shift__c (after update) {
    if (Trigger.isUpdate && Trigger.isAfter) {
        ShiftMatchManager sm = new ShiftMatchManager();
        sm.handlePublishedShiftsTrigger();
        /// Start Auto Broadcast Process
        //Added by Fazal: https://1218globaluk.eu.teamwork.com/app/tasks/36134591
        ShiftAutoBroadcastHandler.runAutoBroadcast(Trigger.New, Trigger.oldMap);
    }
}