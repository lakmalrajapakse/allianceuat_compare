public with sharing class PDFGenerateCV {
    //@testVisible Public static boolean throwException = false;
    @testVisible Public static boolean throwExceptionGet = false;
    @testVisible Public static boolean throwExceptionGeneral = false;

    @AuraEnabled
    public static void createCVSingle(Id recordId) {
        System.debug('createCVSingle recordId: ' + recordId);
        createCVs(new List<Id> {recordId});

    }

    @AuraEnabled
    public static void createCVs(List<Id> recordIds) {

        List<Contact> records = [SELECT Id, Name
                                    FROM Contact WHERE Id = :recordIds];
        
        Map<Id, Contact> recordsWithError = new Map<Id, Contact>();
        List<Contact> successfulRecords = new List<Contact>();
                                        
        List<ContentVersion> ccContentVersions = new List<ContentVersion>();
        List<ContentDocumentLink> ccContentDLs = new List<ContentDocumentLink>();

        For (Contact record : records){
            try{
                Map<String, Object> ccResult = generateCV(record);

                ccContentVersions.add((ContentVersion) ccResult.get('version'));
                ccContentDLs.add((ContentDocumentLink) ccResult.get('contentLink'));
                successfulRecords.add(record);
            } catch (Exception error) {
                recordsWithError.put(
                    record.Id,
                    new Contact (
                        Id = record.Id
                        //, Error__c = error.getMessage() + '\n' + error.getStackTraceString()
                    )
                );
            }
        }

        insertDocuments(ccContentVersions, ccContentDLs);

        List<Contact> errorRecordsToSave = recordsWithError.values();
        update errorRecordsToSave;

    }

    public static Map<String, Object> generateCV(Contact record) {
        System.debug(LOGGINGLEVEL.ERROR, record);
        PageReference pdf =  Page.PDF_CVTemplate;
        pdf.getParameters().put('Id', record.Id);
        pdf.setRedirect(true);

        Blob b; 

        if (Test.isRunningTest()) { 
            b = blob.valueOf('Unit.Test');
        }else {
            b = pdf.getContent();
        }

        ContentVersion version = new ContentVersion();
        version.Title = '' + record.Name + ' - CV' + ' - ' + Datetime.now().format('YYYY-MM-dd HH:mm:ss', UserInfo.getTimeZone().getID());
        version.PathOnClient = '' + record.Name + ' - CV' + Datetime.now() + '.pdf';
        version.VersionData = b;

        ContentDocumentLink contentLink = new ContentDocumentLink();
        contentLink.LinkedEntityId = record.Id;
        contentLink.ShareType = 'V';
        contentLink.Visibility = 'AllUsers';

        return new Map<String, Object> {
            'version' => version,
            'contentLink' => contentLink
        };
    }

    private static Set<Integer> insertDocuments(List<ContentVersion> versions, List<ContentDocumentLink> links) {
        List<Database.SaveResult> versionsResult = Database.insert(versions, false);
        List<Id> versionIds = new List<Id>();
        List<ContentDocumentLink> validDocumentLinks = new List<ContentDocumentLink>();
        
        Set<Integer> failedIndices = new Set<Integer>();
        for (Integer i = 0; i < versionsResult.size(); i++) {
           
            if (versionsResult[i].isSuccess()) {
                versionIds.add(versionsResult[i].getId());
                validDocumentLinks.add(links[i]);
            } else {
                failedIndices.add(i);
            }
        }
        
        List<ContentVersion> resultversions = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :versionIds];
        Map<Id, ContentVersion> resultversionsById = new Map<Id, ContentVersion>(resultversions);
        
        for (Integer i = 0; i < validDocumentLinks.size(); i++) {
            validDocumentLinks[i].ContentDocumentId = resultversionsById.get(versionIds[i]).ContentDocumentId;
        
        }

        insert validDocumentLinks;
        return failedIndices;
    }
}