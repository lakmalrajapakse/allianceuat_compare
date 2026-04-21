public class HouseKeeperHelper {

        @TestVisible
    static Boolean bypassTestGuard = false;
    
    public static void runNextHouseKeepingJob(Integer sortOrder) {
        if (Test.isRunningTest()&& !bypassTestGuard) {
            System.debug('Skipping batch execution in test context');
            return;
        }

        List<HouseKeeper_Config__mdt> configs = [
            SELECT DeveloperName, Object_API_Name__c, Where_Clause__c,
                   Batch_Size__c, Delete_Related_Content_Documents__c, Sort_Order__c, Active__c
            FROM HouseKeeper_Config__mdt        
            WHERE Active__c = true
            AND Sort_Order__c > :sortOrder
            LIMIT 1
        ];

        if (configs.isEmpty()) {
            System.debug('No active HouseKeeper configurations found for sort order ' + sortOrder);
            return;
        }

        HouseKeeper_Config__mdt cfg = configs[0];
        Integer size = cfg.Batch_Size__c != null ? Integer.valueOf(cfg.Batch_Size__c) : 200;

        if (cfg.Delete_Related_Content_Documents__c) {
            System.debug('Deleting related documents for ' + cfg.DeveloperName);
            Database.executeBatch(new HousekeepDocumentBatch(cfg), size);
        } else {
            System.debug('Deleting objects for ' + cfg.DeveloperName);
            Database.executeBatch(new HousekeepObjectBatch(cfg), size);
        }
    }
}