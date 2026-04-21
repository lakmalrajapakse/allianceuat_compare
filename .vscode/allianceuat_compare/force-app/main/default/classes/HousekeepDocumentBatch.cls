public class HousekeepDocumentBatch implements Database.Batchable<SObject>, Database.Stateful {

    private HouseKeeper_Config__mdt config;
    private String soqlQuery;

    public HousekeepDocumentBatch(HouseKeeper_Config__mdt cfg) {
        system.debug('Deleting documents for config: ' + cfg.DeveloperName);
        this.config = cfg;
        soqlQuery = 'SELECT Id FROM ' + cfg.Object_API_Name__c;
        if (String.isNotBlank(cfg.Where_Clause__c)) {
            soqlQuery += ' WHERE ' + cfg.Where_Clause__c;
        }
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(soqlQuery);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        Set<Id> recordIds = new Set<Id>();
        for (SObject s : scope) {
            recordIds.add(s.Id);
        }

        if (!recordIds.isEmpty()) {
            List<ContentDocumentLink> links = [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :recordIds
            ];

            if (!links.isEmpty()) {
                Set<Id> docIds = new Set<Id>();
                for (ContentDocumentLink l : links) {
                    docIds.add(l.ContentDocumentId);
                }

                if (!docIds.isEmpty()) {
                    List<ContentDocument> docs = [
                        SELECT Id FROM ContentDocument WHERE Id IN :docIds
                    ];
                    delete docs;
                    system.debug('Deleted documents for ' + this.config.DeveloperName);
                }
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        Integer size = config.Batch_Size__c != null ? Integer.valueOf(config.Batch_Size__c) : 200;
        if (!Test.isRunningTest()) {
            Database.executeBatch(new HousekeepObjectBatch(config), size);
        }
    }

}