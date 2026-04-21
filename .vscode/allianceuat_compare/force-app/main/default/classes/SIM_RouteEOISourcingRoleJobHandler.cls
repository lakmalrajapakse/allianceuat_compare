public without sharing class SIM_RouteEOISourcingRoleJobHandler {

    public static void handleAfterUpdate(
        List<b3f__FormResponse__c> formResponses,
        Map<Id, b3f__FormResponse__c> oldMap
    ) {

        Set<Id> formResponsesSuccess = new Set<Id>();
        
        // Create a set of FormResponse Ids
        Set<Id> formResponsesIds = new Set<Id>();
        for (b3f__FormResponse__c formResponse : formResponses) {
            formResponsesIds.add(formResponse.Id);
        }

        // Get a list of Associated Forms
        Map<Id, Boolean> formResponseFormMap = new Map<Id, Boolean>();
        for (b3f__FormResponse__c f : [
            SELECT Id, b3f__Form__r.Route_EOI_Sourcing_Role_to_Job__c
            FROM b3f__FormResponse__c
            WHERE Id IN :formResponsesIds
        ]) {
            formResponseFormMap.put(
                f.Id,
                f.b3f__Form__r.Route_EOI_Sourcing_Role_to_Job__c
            );
        }

        // Load mapping
        Map<String, String> eoiRouteMappingMap = new Map<String, String>();
        for (EOI_Route_Mapping__mdt m : [
            SELECT EOI_Domain_Source__c, EOI_Source_Job_Name__c FROM EOI_Route_Mapping__mdt
        ]) {
            eoiRouteMappingMap.put(m.EOI_Domain_Source__c, m.EOI_Source_Job_Name__c);
        }

        // Allow testing
        if (Test.isRunningTest()) {
            eoiRouteMappingMap.put('source', 'null - TestJob');
        }

        if (eoiRouteMappingMap.isEmpty()) return;

        // Get Jobs
        List<TR1__Job__c> jobList = [
            SELECT Id, Name 
            FROM TR1__Job__c 
            WHERE Name IN :eoiRouteMappingMap.values()
        ];

        if (jobList.isEmpty()) return;

        Map<String, Id> jobMap = new Map<String, Id>();
        for (TR1__Job__c job : jobList) {
            jobMap.put(job.Name, job.Id);
        }

        // Build Contact → FormResponse map
        Map<Id, b3f__FormResponse__c> contactFormResponseMap = new Map<Id, b3f__FormResponse__c>();

        for (b3f__FormResponse__c formResponse : formResponses) {
            b3f__FormResponse__c oldRecord = oldMap.get(formResponse.Id);

            if (
                oldRecord.b3f__Type__c == 'DRAFT' &&
                formResponse.b3f__Type__c == 'COMPLETE' &&
                formResponseFormMap.get(formResponse.Id) == true &&
                formResponse.b3f__New_Record_ID__c != null
            ) {
                contactFormResponseMap.put(
                    formResponse.b3f__New_Record_ID__c,
                    formResponse
                );
            }
        }

        if (contactFormResponseMap.isEmpty()) return;

        // Get contacts
        List<Contact> contactList = [
            SELECT Id, Source_domain__c
            FROM Contact
            WHERE Id IN :contactFormResponseMap.keySet()
        ];

        List<TR1__Application_V2__c> applications = new List<TR1__Application_V2__c>();

        for (Contact c : contactList) {
            if (eoiRouteMappingMap.containsKey(c.Source_domain__c)) {
                String jobName = eoiRouteMappingMap.get(c.Source_domain__c);
                if (jobMap.containsKey(jobName)) {
                    applications.add(new TR1__Application_V2__c(
                        TR1__Applicant__c = c.Id,
                        TR1__Job__c = jobMap.get(jobName),
                        TR1__Stage__c = 'Application'
                    ));
                    formResponsesSuccess.add(c.Id);
                }
            }
        }

        if (!applications.isEmpty()) {
            Database.insert(applications, false);

            List<EOI_Sub_Status__e> subEvents = new List<EOI_Sub_Status__e>();
            for (TR1__Application_V2__c app : applications) {
                if (app.Id != null) {
                    subEvents.add(new EOI_Sub_Status__e(
                        Application_Id__c = app.Id
                    ));
                }
            }
            EventBus.publish(subEvents);
        }

        // ❗ Must be a separate DML because we are in AFTER update
        List<b3f__FormResponse__c> frToUpdate = new List<b3f__FormResponse__c>();

        for (b3f__FormResponse__c f : formResponses) {
            if (
                f.b3f__Type__c == 'COMPLETE' &&
                formResponseFormMap.get(f.Id) == true &&
                f.b3f__New_Record_ID__c != null &&
                formResponsesSuccess.contains(f.b3f__New_Record_ID__c)
            ) {
                frToUpdate.add(new b3f__FormResponse__c(
                    Id = f.Id,
                    b3f__ErrorMessage__c = f.b3f__ErrorMessage__c + ' \n\n EOI Application Created'
                ));
            }
        }

        if (!frToUpdate.isEmpty()) {
            update frToUpdate;
        }
    }
}