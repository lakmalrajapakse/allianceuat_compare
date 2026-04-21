// @author: Fazal
// @description: https://1218globaluk.eu.teamwork.com/app/tasks/36134591
trigger LogicServiceTrigger on sirenum__LogicServiceRequest__c (after update) {
		switch on Trigger.operationType {
        when AFTER_UPDATE {
            LogicServiceRequestTriggerHandler.onAfterUpdateAll(Trigger.oldMap, Trigger.newMap);
        }
    }
}