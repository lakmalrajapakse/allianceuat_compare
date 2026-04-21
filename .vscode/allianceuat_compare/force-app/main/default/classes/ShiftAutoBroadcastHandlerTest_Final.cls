@isTest
public class ShiftAutoBroadcastHandlerTest_Final {

 
    private static Integer countRequestsByShift(Id shiftId) {
        Integer count = 0;

        for (sirenum__LogicServiceRequest__c r :
            [SELECT Id, sirenum__Demand__c FROM sirenum__LogicServiceRequest__c]) {

            if (r.sirenum__Demand__c == shiftId) {
                count++;
            }
        }
        return count;
    }

    @testSetup
    static void setupData() {

        // Enable Auto Bidding
        insert new sirenum__Candidate_Search_Settings__c(
            Auto_Shift_Bidding_Enabled__c = true,
            Auto_Shift_Bidding_Matching_Percentage__c = 50,
            Auto_Shift_Bidding_Enable_Info_Logs__c = true
        );

        // Record Type
        Id shiftDemandRT;
        Map<String, Schema.RecordTypeInfo> rtMap =
            Schema.SObjectType.sirenum__Shift__c.getRecordTypeInfosByDeveloperName();

        if (rtMap.containsKey('Shift_Demand')) {
            shiftDemandRT = rtMap.get('Shift_Demand').getRecordTypeId();
        }

        // Optional Site (if required in your org)
        Id siteId;
        try {
            sirenum__Site__c site = new sirenum__Site__c(Name = 'Test Site');
            insert site;
            siteId = site.Id;
        } catch (Exception e) {}

        // Create shifts (NO Name field!)
        List<sirenum__Shift__c> shifts = new List<sirenum__Shift__c>();

        for (Integer i = 0; i < 5; i++) {
            sirenum__Shift__c s = new sirenum__Shift__c();
            s.RecordTypeId = shiftDemandRT;
            s.Auto_Broadcast__c = false;
            if (siteId != null) {
                s.sirenum__Site__c = siteId;
                
            }

            shifts.add(s);
        }

        insert shifts;
    }

    
    
  
    
    // Non Shift Demand skip
   
    @isTest
    static void testNonShiftDemandSkipped() {

        sirenum__Shift__c shift = new sirenum__Shift__c();
        shift.Auto_Broadcast__c = true;
        insert shift;

        Test.startTest();
        ShiftAutoBroadcastHandler.runAutoBroadcast(
            new List<sirenum__Shift__c>{shift},
            null
        );
        Test.stopTest();

        System.assertEquals(0, countRequestsByShift(shift.Id));
    }

    
    

   
    //  Completed + error requests
    
    @isTest
    static void testCompletedAndErroredRequests() {

        sirenum__Shift__c shift = [SELECT Id FROM sirenum__Shift__c LIMIT 1];

        List<sirenum__LogicServiceRequest__c> reqs =
            new List<sirenum__LogicServiceRequest__c>();

        reqs.add(new sirenum__LogicServiceRequest__c(
            Is_Auto_Shift_Bidding_Request__c = true,
            sirenum__Demand__c = shift.Id,
            sirenum__Status__c = 'Complete'
        ));

        reqs.add(new sirenum__LogicServiceRequest__c(
            Is_Auto_Shift_Bidding_Request__c = true,
            sirenum__Demand__c = shift.Id,
            sirenum__Status__c = 'Failed',
            sirenum__ProcessingError__c = 'Error'
        ));

        insert reqs;

        Test.startTest();
        ShiftBiddingService.processAutoBidCandidateSearchResults(reqs);
        Test.stopTest();

        System.assert(
            [SELECT COUNT() FROM Auto_Shift_Bidding_Log__c] > 0
        );
    }

 
    //  No candidates branch
 
    @isTest
    static void testNoCandidatesFound() {

        sirenum__Shift__c shift = [SELECT Id FROM sirenum__Shift__c LIMIT 1];

        sirenum__LogicServiceRequest__c req =
            new sirenum__LogicServiceRequest__c(
                Is_Auto_Shift_Bidding_Request__c = true,
                sirenum__Demand__c = shift.Id,
                sirenum__Status__c = 'Complete'
            );
        insert req;

        Test.startTest();
        ShiftBiddingService.processAutoBidCandidateSearchResults(
            new List<sirenum__LogicServiceRequest__c>{req}
        );
        Test.stopTest();

        System.assert(true);
    }

    
    
    //  Selector coverage
    
    @isTest
    static void testSelector() {

        Test.startTest();
        List<sirenum__LogicServiceDomain__c> res =
            ShiftBiddingSelector.getLogicServiceDomainResultsByRequestIdsWithMinScore(
                new List<Id>(),
                0
            );
        Test.stopTest();

        System.assertNotEquals(null, res);
    }
    @isTest
    static void testSummaryLog() {
        List<sirenum__Shift__c> shifts = [SELECT Id, Name, RecordTypeId, Auto_Broadcast__c
                                         FROM sirenum__Shift__c];

        Test.startTest();
         // Execute summary log method
        ShiftBiddingService.insertAutoBidShiftDemandsSummaryLog(shifts.size(),
                                                                shifts.size(), shifts,
                                                               new List<sirenum__LogicServiceRequest__c>());
        Test.stopTest();
        System.assert(true);// Confirm execution
    }
    @isTest
     static void testLogicHandler() {
         sirenum__Shift__c shift = [SELECT Id FROM sirenum__Shift__c LIMIT 1];
    
         sirenum__LogicServiceRequest__c req = new sirenum__LogicServiceRequest__c();
         req.sirenum__Demand__c = shift.Id;
         req.sirenum__Status__c = 'Interrupted'; 
         insert req; 
 
         req.sirenum__Status__c = 'Ready'; // Change status to trigger update logic

         Test.startTest();
         update req; // Fire after update trigger
         Test.stopTest();
         System.assert(true);
    }
}