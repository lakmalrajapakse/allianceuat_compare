public with sharing class LogicServiceRequestTriggerHandler {
    public static void onAfterUpdateAll(
        Map<Id, sirenum__LogicServiceRequest__c> oldMap,
        Map<Id, sirenum__LogicServiceRequest__c> newMap
    ) {
        performAutoShiftBidding(oldMap, newMap.values());
    }

    private static void performAutoShiftBidding(
        Map<Id, sirenum__LogicServiceRequest__c> oldMap,
        List<sirenum__LogicServiceRequest__c> newList
    ) {
        List<sirenum__LogicServiceRequest__c> requestsToProcess = new List<sirenum__LogicServiceRequest__c>();

        for (sirenum__LogicServiceRequest__c newReq : newList) {
            sirenum__LogicServiceRequest__c oldReq = oldMap.get(newReq.Id);

            Boolean hasStatusChangedToComplete =
                oldReq.sirenum__Status__c != 'Complete' &&
                newReq.sirenum__Status__c == 'Complete';

            if (hasStatusChangedToComplete) {
                requestsToProcess.add(newReq);
            }
        }

        if (!requestsToProcess.isEmpty()) {
            ShiftBiddingService.processAutoBidCandidateSearchResults(requestsToProcess);
        }
    }
}