@isTest
private class ContentDocumentLinkTriggerHandlerTest {
    public static Account acc = new Account();
    public static Contact cont = new Contact();
    public static List<b3o__Certificate__c> certs = new List<b3o__Certificate__c>();
    public static List<ContentVersion> contentVersions = new List<ContentVersion>();

    @TestSetup
    public static void testData(){
        acc = SIM_TestDataFactory.genTestAccount('accountName', 'Candidate Pool', true);
        cont = SIM_TestDataFactory.genTestContact('Brown', acc.Id, 'Candidate', false);
        cont.FirstName = 'Charlie';
        cont.Email = '1218-SFDC-Support@1218global.com';
        insert cont; 

        List<b3o__Certificate_Type__c> certTypes = new List<b3o__Certificate_Type__c>{
            new b3o__Certificate_Type__c(
                Name = 'Photo ID'
            ),
             new b3o__Certificate_Type__c(
                Name = 'Not Photo Id'
            )
        };
        insert certTypes;

        certs = new List<b3o__Certificate__c>{
            new b3o__Certificate__c(
                b3o__Contact__c = cont.Id,
                // b3o__Status__c = 'Active',
                b3o__Certificate_Type__c = certTypes[0].Id
            ),
            new b3o__Certificate__c(
                b3o__Contact__c = cont.Id,
                // b3o__Status__c = 'Active',
                b3o__Certificate_Type__c = certTypes[1].Id)
        };
        insert certs;

       contentVersions = new List<ContentVersion>{
            new ContentVersion(
                Title = 'Photo ID Form',
                PathOnClient   = 'photo.jpg',
                VersionData    = Blob.valueOf('Photo ID Form'),
                IsMajorVersion = true
            ),
            new ContentVersion(
                Title = 'Not Photo ID Form',
                PathOnClient   = 'notPhoto.jpg',
                VersionData    = Blob.valueOf('Not Photo ID Form'),
                IsMajorVersion = true
            )
        };
        insert contentVersions;

        List<ContentDocumentLink> cdls = new List<ContentDocumentLink>{
            new ContentDocumentLink(
                ContentDocumentId = contentVersions[0].Id,
                LinkedEntityId = certs[0].Id,
                ShareType = 'V'
            ),
            new ContentDocumentLink(
                ContentDocumentId = contentVersions[1].Id,
                LinkedEntityId = certs[1].Id,
                ShareType = 'V'
            )
        };
    }
    
    @istest 
    static void triggerTest_Success() {

        List<Contact> contacts = [SELECT Id FROM Contact];

        List<b3o__Certificate__c> certs = [SELECT Id, b3o__Contact__c, b3o__Certificate_Type__c, Certificate_Type_Name__c
            FROM b3o__Certificate__c 
            ORDER BY Certificate_Type_Name__c DESC];

        List<ContentDocument> contentDocs = [SELECT Id, Title 
            FROM ContentDocument 
            // WHERE Title = 'Photo ID Form' 
            // OR Title = 'Not Photo ID Form'
            ORDER BY Title DESC];

        System.debug(LOGGINGLEVEL.ERROR, 'contentDocs: ' + contentDocs);

        List<ContentDocumentLink> cdls = new List<ContentDocumentLink>{
            new ContentDocumentLink(
                ContentDocumentId = contentDocs[0].Id,
                LinkedEntityId = certs[0].Id,
                ShareType = 'V'
            ),
            new ContentDocumentLink(
                ContentDocumentId = contentDocs[1].Id,
                LinkedEntityId = certs[1].Id,
                ShareType = 'V'
            )
        };

        System.debug(LOGGINGLEVEL.ERROR, 'cdls: ' + cdls);

        Test.startTest();
        insert cdls;
        Test.stopTest();

        System.debug(LOGGINGLEVEL.ERROR, 'AFTER stopTest cont.Id: ' + contacts[0].Id);

        List<ContentDocumentLink> contactCDLs = [SELECT Id, ContentDocumentId, LinkedEntityId, ShareType, Visibility
            FROM ContentDocumentLink
            // WHERE LinkedEntityId = :cont.Id
            WHERE LinkedEntityId = :contacts[0].Id
            ORDER BY LinkedEntityId DESC];

     System.debug(LOGGINGLEVEL.ERROR, 'contactCDLs.size(): ' + contactCDLs.size());

        System.assertEquals(1, contactCDLs.size(), 'Contact CDL count is not 1');

    }
}