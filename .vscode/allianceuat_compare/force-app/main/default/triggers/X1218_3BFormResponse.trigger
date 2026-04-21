trigger X1218_3BFormResponse on b3f__FormResponse__c (after update) {
    
    if (Trigger.isAfter && Trigger.isUpdate) {
        SIM_RouteEOISourcingRoleJobHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
    
}