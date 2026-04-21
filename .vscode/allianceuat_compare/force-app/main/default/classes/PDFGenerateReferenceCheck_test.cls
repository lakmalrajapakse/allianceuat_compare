@isTest
private class PDFGenerateReferenceCheck_test {
    public static Account acc = new Account();
    public static Contact cont = new Contact();
    public static b3o__Reference__c ref = new b3o__Reference__c();

    @isTest
    static void generateReferenceTest() {
        createData();
        Test.startTest();
        PDFGenerateReferenceCheck.createReferenceCheckSingle(ref.Id);
               
        Test.stopTest();
    }

    public static void createData(){
        acc = SIM_TestDataFactory.genTestAccount('accountName', 'Candidate Pool', true);
        cont = SIM_TestDataFactory.genTestContact('lastName', acc.Id, 'Candidate', false);
        cont.FirstName = 'First';
        cont.Email = '1218-SFDC-Support@1218global.com';
        insert cont; 
        ref = new b3o__Reference__c(
            b3o__Contact__c = cont.id

        );
        insert ref;

    }
}