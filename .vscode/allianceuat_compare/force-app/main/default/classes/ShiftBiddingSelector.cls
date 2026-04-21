public inherited sharing class ShiftBiddingSelector {
    public static List<sirenum__LogicServiceDomain__c> getLogicServiceDomainResultsByRequestIdsWithMinScore(
        List<Id> requestIds,
        Double minimumPercentageScore
    ) {
        // SYSTEM_MODE is to ensure that Auto Shift Bidding can run regardless of User permissions, as this is a system process
        return [
            SELECT
                Id,
                sirenum__Request__c,
                sirenum__Record__c,
                sirenum__Score__c,
                sirenum__Percentage__c,
                sirenum__Request__r.sirenum__Demand__c
            FROM sirenum__LogicServiceDomain__c
            WHERE
                sirenum__Request__c IN :requestIds
                AND sirenum__Percentage__c >= :minimumPercentageScore
                AND RecordType.DeveloperName = 'Result'
            WITH SYSTEM_MODE
            ORDER BY sirenum__Record__c ASC, sirenum__Percentage__c DESC
        ];
    }
}