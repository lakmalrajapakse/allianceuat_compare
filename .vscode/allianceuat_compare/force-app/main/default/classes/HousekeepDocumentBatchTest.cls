@isTest
public class HousekeepDocumentBatchTest {

    private static HouseKeeper_Config__mdt createMockConfig() {
        // Mock metadata configuration (not inserted)
        HouseKeeper_Config__mdt cfg = (HouseKeeper_Config__mdt) Type.forName('HouseKeeper_Config__mdt').newInstance();
        cfg.DeveloperName = 'TestDocumentBatch';
        cfg.Object_API_Name__c = 'Account';
        cfg.Batch_Size__c = 200;
        cfg.Delete_Related_Content_Documents__c = true;
        cfg.Sort_Order__c = 1;
        cfg.Where_Clause__c = null;
        return cfg;
    }

    @testSetup
    static void setupData() {
        // Create test Accounts
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 3; i++) {
            Account acc = SIM_TestDataFactory.genTestAccount('DocBatchAccount' + i, 'Client', false);
            acc.Payroll_Tax_Exempt__c = 'No';
            acc.Approval_Type__c = 'Not Charged';
            accounts.add(acc);
        }
        insert accounts;

        // Create ContentDocuments and link them to Accounts
        List<ContentVersion> versions = new List<ContentVersion>();
        for (Account acc : accounts) {
            ContentVersion ver = new ContentVersion(
                Title = 'TestDoc_' + acc.Id,
                PathOnClient = 'Test.pdf',
                VersionData = Blob.valueOf('Test content for ' + acc.Id)
            );
            versions.add(ver);
        }
        insert versions;

        // Link the ContentDocuments to Accounts
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for (ContentVersion v : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Title LIKE 'TestDoc_%']) {
            Account linkedAcc = [SELECT Id FROM Account WHERE Name LIKE 'DocBatchAccount%' LIMIT 1 OFFSET 0];
            links.add(new ContentDocumentLink(
                LinkedEntityId = linkedAcc.Id,
                ContentDocumentId = v.ContentDocumentId,
                ShareType = 'V'
            ));
        }
        insert links;
    }

    @isTest
    static void testDocumentBatch() {
        HouseKeeper_Config__mdt cfg = createMockConfig();

        // Count documents before running the batch
        Integer initialDocs = [SELECT COUNT() FROM ContentDocument];
        System.assert(initialDocs > 0, 'Setup should have created ContentDocuments.');

        // Run batch with batch size > record count (to ensure only one chunk)
        Test.startTest();
        Database.executeBatch(new HousekeepDocumentBatch(cfg), initialDocs + 1);
        Test.stopTest();

        // Assert that the ContentDocuments were deleted
        Integer remainingDocs = [SELECT COUNT() FROM ContentDocument];
        System.assertEquals(0, remainingDocs, 'All linked ContentDocuments should have been deleted.');
    }
}