public class HousekeepObjectBatch implements Database.Batchable<SObject>, Database.Stateful {

    private HouseKeeper_Config__mdt config;
    private String soqlQuery;

    public HousekeepObjectBatch(HouseKeeper_Config__mdt cfg) {
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
        system.debug('Deleting Object Records for config: ' + config.DeveloperName);
        delete scope;
    }

    public void finish(Database.BatchableContext bc) {
        if (!Test.isRunningTest()) {
            HouseKeeperHelper.runNextHouseKeepingJob(Integer.valueOf(config.Sort_Order__c));
        }
    }


}