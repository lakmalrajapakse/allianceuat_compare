global class SIM_AhpraCandidateCheckBatch implements Database.Batchable<SObject>, Database.stateful, Database.AllowsCallouts {

    // Member variable to store the list across batches
    // private 

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, aa_AHPRA_Number__c, aa_AHPRA_Number_2__c,
                   aa_AHPRA_Number_3__c, Allow_Auto_Fetch_of_Ahpra_Details__c, 
                   Add_to_Ahpra_nightly_Batch_Job__c, Ahpra_Last_Checked__c
            FROM Contact
            WHERE Allow_Auto_Fetch_of_Ahpra_Details__c = true 
              AND Add_to_Ahpra_nightly_Batch_Job__c = true
              AND Ahpra_Last_Checked__c != TODAY
              AND (aa_AHPRA_Number__c != null OR aa_AHPRA_Number_2__c != null OR aa_AHPRA_Number_3__c != null)
        ]);
    }

    global void execute(Database.BatchableContext BC, List<Contact> scope) {
        List<String> ahpraCodeList = new List<String>();
        List<List<String>> ahpraNumberList = new List<List<String>>();
        List<Contact> processedRecords = new List<Contact>();

        for(Contact c : scope) {
            if(c.aa_AHPRA_Number__c != null) ahpraCodeList.add(c.aa_AHPRA_Number__c);
            if(c.aa_AHPRA_Number_2__c != null) ahpraCodeList.add(c.aa_AHPRA_Number_2__c);
            if(c.aa_AHPRA_Number_3__c != null) ahpraCodeList.add(c.aa_AHPRA_Number_3__c);
        }

        if(!ahpraCodeList.isEmpty()) {
            ahpraNumberList.add(ahpraCodeList);
            List<SIM_AhpraIntegrationHandler.ahpraResponse> res = SIM_AhpraIntegrationHandler.sendRequest(ahpraNumberList);

            // Add successfully processed contacts
            processedRecords.addAll(scope);
        }

        // System.debug('Processed Records: ' + processedRecords.size());
        for(Contact c : processedRecords) {
            // System.debug('Updating Contact Id: ' + c.Id + ' Previous Ahpra_Last_Checked__c: ' + c.Ahpra_Last_Checked__c);
            c.Ahpra_Last_Checked__c = Date.today();
        }
        
        Database.SaveResult[] results = Database.update(processedRecords, false);
        for (Integer i = 0; i < results.size(); i++) {
            if(!results[i].isSuccess()) {
                System.debug('❌ Failed to update Contact Id: ' + processedRecords[i].Id + ' Error: ' + results[i].getErrors()[0].getMessage());
            } else {
                System.debug('✅ Updated Contact Id: ' + processedRecords[i].Id + ' New Ahpra_Last_Checked__c: ' + processedRecords[i].Ahpra_Last_Checked__c);
            }
        }        
    }

    global void finish(Database.BatchableContext BC) {
    }

    global void execute(SchedulableContext SC) {
        Database.executeBatch(new SIM_AhpraCandidateCheckBatch(), 10);
    }
}