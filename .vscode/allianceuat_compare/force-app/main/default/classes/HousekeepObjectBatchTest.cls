@isTest
public class HousekeepObjectBatchTest {

    private static HouseKeeper_Config__mdt createMockConfig() {
        HouseKeeper_Config__mdt cfg = (HouseKeeper_Config__mdt) Type.forName('HouseKeeper_Config__mdt').newInstance();
        cfg.DeveloperName = 'TestObjectBatch';
        cfg.Object_API_Name__c = 'Account';
        cfg.Batch_Size__c = 2;
        cfg.Delete_Related_Content_Documents__c = false;
        cfg.Sort_Order__c = 1;
        cfg.Where_Clause__c = null;
        return cfg;
    }

    @testSetup
    static void setupData() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 3; i++) {
            Account acc = SIM_TestDataFactory.genTestAccount('ObjectBatchAccount'+i, 'Client', false);
            acc.Payroll_Tax_Exempt__c = 'No';
            acc.Approval_Type__c = 'Not Charged';
            accounts.add(acc);
        }
        insert accounts;
    }

    @isTest
    static void testObjectBatch() {
        HouseKeeper_Config__mdt cfg = createMockConfig();

        // Count how many records exist
        Integer recordCount = [SELECT COUNT() FROM Account WHERE Name LIKE 'ObjectBatchAccount%'];

        Test.startTest();
        // Ensure batch size is larger than record count (so only one chunk runs)
        Database.executeBatch(new HousekeepObjectBatch(cfg), recordCount + 1);
        Test.stopTest();

        Integer remaining = [SELECT COUNT() FROM Account WHERE Name LIKE 'ObjectBatchAccount%'];
        System.assertEquals(0, remaining, 'All object batch accounts should be deleted');
    }
}