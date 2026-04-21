@isTest
private class PDFGenerateIDBadge_test {

    public static Account acc = new Account();
    public static Contact cont = new Contact();
    public static TR1__Fixed_Assets__c idBadge = new TR1__Fixed_Assets__c();
    public static Branch__c branch = new Branch__c();

    @isTest
    static void generateIDBadgeTest() {
        createData();
        System.Test.startTest();
        PDFGenerateIDBadge.createIDBadgeSingle(idBadge.Id);
               
        System.Test.stopTest();
    }

    public static void createData(){
        acc = SIM_TestDataFactory.genTestAccount('accountName', 'Candidate Pool', true);
        cont = SIM_TestDataFactory.genTestContact('Brown', acc.Id, 'Candidate', false);
        // cont = SIM_TestDataFactory.genTestContact('Brown', acc.Id, 'Candidate Contact', false);
        cont.FirstName = 'Charlie';
        cont.Email = '1218-SFDC-Support@1218global.com';
        insert cont; 

        branch = new Branch__c(
            Branch_Name__c = 'Test Branch',
            Branch_Code__c = 'A',
            City__c = 'Sydney'
        );
        insert branch;

        idBadge = new TR1__Fixed_Assets__c(
            Assigned__c = cont.Id,
            Preferred_Name__c = 'Charlie',
            AHPRA_Number__c = 'NUM00001', 
            Branch__c = branch.Id, 
            Branch_Email__c = 'testemail@test.com',
            Branch_Phone_Number__c = '0401010101',
            Brand__c = 'Nursing',
            RecordTypeId = Schema.SObjectType.TR1__Fixed_Assets__c.getRecordTypeInfosByDeveloperName().get('ID_Badge').getRecordTypeId(),
            Position__c = 'Nursing Assistant');
        insert idBadge;

    }
}