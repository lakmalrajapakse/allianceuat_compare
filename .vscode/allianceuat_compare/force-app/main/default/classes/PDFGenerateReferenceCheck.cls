public with sharing class PDFGenerateReferenceCheck {

    //@testVisible Public static boolean throwException = false;
    @testVisible Public static boolean throwExceptionGet = false;
    @testVisible Public static boolean throwExceptionGeneral = false;

    @AuraEnabled
    public static void createReferenceCheckSingle(Id recordId) {
        System.debug('createReferenceCheckSingle recordId: ' + recordId);
        createReferenceChecks(new List<Id> {recordId});

    }

    @AuraEnabled
    public static void createReferenceChecks(List<Id> recordIds) {

        List<b3o__Reference__c> records = [SELECT Id, b3o__Contact__r.FirstName, b3o__Contact__r.LastName, b3o__Contact__c
                                    FROM b3o__Reference__c WHERE Id = :recordIds];
        
        Map<Id, b3o__Reference__c> recordsWithError = new Map<Id, b3o__Reference__c>();
        List<b3o__Reference__c> successfulRecords = new List<b3o__Reference__c>();
                                        
        List<ContentVersion> ccContentVersions = new List<ContentVersion>();
        List<ContentDocumentLink> ccContentDLs = new List<ContentDocumentLink>();
        List<ContentDocumentLink> ccContactContentDLs = new List<ContentDocumentLink>();

        For (b3o__Reference__c record : records){
            try{
                Map<String, Object> ccResult = genReferenceCheckPDF(record);

                ccContentVersions.add((ContentVersion) ccResult.get('version'));
                ccContentDLs.add((ContentDocumentLink) ccResult.get('contentLink'));
                ccContactContentDLs.add((ContentDocumentLink) ccResult.get('contentLinkContact'));
                successfulRecords.add(record);
            } catch (Exception error) {
                recordsWithError.put(
                    record.Id,
                    new b3o__Reference__c (
                        Id = record.Id
                        //, Error__c = error.getMessage() + '\n' + error.getStackTraceString()
                    )
                );
            }
        }

        insertDocuments(ccContentVersions, ccContentDLs, ccContactContentDLs);

        List<b3o__Reference__c> errorRecordsToSave = recordsWithError.values();
        update errorRecordsToSave;

    }

    public static Map<String, Object> genReferenceCheckPDF(b3o__Reference__c record) {
        System.debug(LOGGINGLEVEL.ERROR, record);
        PageReference pdf =  Page.ReferenceCheck;
        pdf.getParameters().put('Id', record.Id);
        pdf.setRedirect(true);

        Blob b; 

        if (Test.isRunningTest()) { 
            b = blob.valueOf('Unit.Test');
        }else {
            b = pdf.getContent();
        }

        ContentVersion version = new ContentVersion();
        version.Title = 'Reference Check - ' + record.b3o__Contact__r.FirstName + ' ' + record.b3o__Contact__r.FirstName + ' - ' + Datetime.now().format('YYYY-MM-dd HH:mm:ss', UserInfo.getTimeZone().getID());
        version.PathOnClient = 'Reference Check' + Datetime.now() + '.pdf';
        version.VersionData = b; 

        ContentDocumentLink contentLink = new ContentDocumentLink();
        contentLink.LinkedEntityId = record.Id;
        contentLink.ShareType = 'V';
        contentLink.Visibility = 'AllUsers';

        ContentDocumentLink contentLinkContact = new ContentDocumentLink();
        contentLinkContact.LinkedEntityId = record.b3o__Contact__c;
        contentLinkContact.ShareType = 'V';
        contentLinkContact.Visibility = 'AllUsers';

        // List<Object> contentLinks = new List<ContentDocumentLink>();
        // contentLinks.add(contentLink);
        // contentLinks.add(contentLinkContact);

        return new Map<String, Object> {
            'version' => version,
            'contentLink' => contentLink,
            'contentLinkContact' => contentLinkContact
        };
    }

    private static Set<Integer> insertDocuments(List<ContentVersion> versions, List<ContentDocumentLink> links, List<ContentDocumentLink> contactLinks) {
        List<Database.SaveResult> versionsResult = Database.insert(versions, false);
        List<Id> versionIds = new List<Id>();
        List<ContentDocumentLink> validDocumentLinks = new List<ContentDocumentLink>();
        List<ContentDocumentLink> validContactDocumentLinks = new List<ContentDocumentLink>();
        
        Set<Integer> failedIndices = new Set<Integer>();
        for (Integer i = 0; i < versionsResult.size(); i++) {
           
            if (versionsResult[i].isSuccess()) {
                versionIds.add(versionsResult[i].getId());
                validDocumentLinks.add(links[i]);
                validContactDocumentLinks.add(contactLinks[i]);
            } else {
                failedIndices.add(i);
            }
        }
        
        List<ContentVersion> resultversions = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :versionIds];
        Map<Id, ContentVersion> resultversionsById = new Map<Id, ContentVersion>(resultversions);
        
        for (Integer i = 0; i < validDocumentLinks.size(); i++) {
            validDocumentLinks[i].ContentDocumentId = resultversionsById.get(versionIds[i]).ContentDocumentId;
        }

        for (Integer i = 0; i < validContactDocumentLinks.size(); i++) {
            validContactDocumentLinks[i].ContentDocumentId = resultversionsById.get(versionIds[i]).ContentDocumentId;
        }

        insert validDocumentLinks;
        insert validContactDocumentLinks;
        return failedIndices;
    }
}