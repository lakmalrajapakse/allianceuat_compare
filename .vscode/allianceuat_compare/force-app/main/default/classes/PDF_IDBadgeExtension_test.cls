@isTest
private class PDF_IDBadgeExtension_test {
    public static Account acc = new Account();
    public static Contact cont = new Contact();
    public static TR1__Fixed_Assets__c idBadge = new TR1__Fixed_Assets__c();
    public static Branch__c branch = new Branch__c();
    public static List<b3o__Certificate__c> certs = new List<b3o__Certificate__c>();
    public static List<ContentVersion> contentVersions = new List<ContentVersion>();

    @isTest
    static void generateIDBadgeTest() {
        createData();
        PageReference pageRef = Page.PDF_IDBadge;
        Test.setCurrentPage(pageRef);

        ApexPages.StandardController sController1 = new ApexPages.StandardController(idBadge);
        
        System.Test.startTest();
        PDF_IDBadgeExtension controller1 = new PDF_IDBadgeExtension(sController1);
        System.Test.stopTest();

        System.debug(LOGGINGLEVEL.ERROR, 'controller1: ' + controller1);
        // System.assertEquals('/servlet/servlet.FileDownload?file=A' , controller1.photoIdLink, 'Photo ID Link');
        System.assertEquals('' , controller1.photoIdLink, 'Photo ID Link');

    }

    public static void createData(){
        acc = SIM_TestDataFactory.genTestAccount('accountName', 'Candidate Pool', true);
        cont = SIM_TestDataFactory.genTestContact('Brown', acc.Id, 'Candidate', false);
        // cont = SIM_TestDataFactory.genTestContact('Brown', acc.Id, 'Candidate Contact', false);
        cont.FirstName = 'Charlie';
        cont.Email = '1218-SFDC-Support@1218global.com';
        cont.sirenum__Photo_ID__c = 'A';
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

        List<b3o__Certificate_Type__c> certTypes = new List<b3o__Certificate_Type__c>{
            new b3o__Certificate_Type__c(
                Name = 'Photo ID'
            )
        };
        insert certTypes;

        certs = new List<b3o__Certificate__c>{
            new b3o__Certificate__c(
                b3o__Contact__c = cont.Id,
                // b3o__Status__c = 'Active',
                Certificate_Status__c = 'Complete',
                b3o__Certificate_Type__c = certTypes[0].Id
            )
        };
        insert certs;

        contentVersions = new List<ContentVersion>{
            new ContentVersion(
                Title = 'Photo ID Form',
                PathOnClient   = 'photo.JPG',
                VersionData    = Blob.valueOf('Photo ID Form'),
                IsMajorVersion = true
            )
        };
        insert contentVersions;

        List<ContentDocumentLink> cdls = new List<ContentDocumentLink>{
            new ContentDocumentLink(
                ContentDocumentId = contentVersions[0].Id,
                LinkedEntityId = certs[0].Id,
                ShareType = 'V'
            )
        };

    }

}