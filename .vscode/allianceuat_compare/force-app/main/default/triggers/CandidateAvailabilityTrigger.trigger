trigger CandidateAvailabilityTrigger on TR1__Candidate_Availability__c(before delete, after insert, after update) {
    switch on Trigger.operationType {
        when BEFORE_DELETE {
            CandidateAvailabilityTriggerHandler.onBeforeDeleteAll(Trigger.oldMap);
        }
        when AFTER_INSERT {
            CandidateAvailabilityTriggerHandler.onAfterInsertAll(Trigger.newMap);
        }
        when AFTER_UPDATE {
            CandidateAvailabilityTriggerHandler.onAfterUpdateAll(Trigger.oldMap, Trigger.newMap);
        }
    }
}