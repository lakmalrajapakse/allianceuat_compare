public class ContentDocumentLinkTriggerHandler {
    public static void linkPhotoToContact(List<ContentDocumentLink> newContentDocumentLinks) {
        System.debug(LOGGINGLEVEL.ERROR, 'IN linkPhotoToContact: ');
        List<Id> certificateIds = new List<Id>();
        List<ContentDocumentLink> contactCDLs = new List<ContentDocumentLink>();
        Map<Id,Id> certContactMap = new Map<Id,Id>();
        for (ContentDocumentLink cdl : newContentDocumentLinks) {
            if (cdl.LinkedEntityId.getSObjectType() == b3o__Certificate__c.SObjectType) {
                certificateIds.add(cdl.LinkedEntityId);
                
            }
        }

        if (certificateIds.size() == 0) {
            return;
        }

        List <b3o__Certificate__c> certs = [SELECT Id, b3o__Contact__c 
            FROM b3o__Certificate__c 
            WHERE Id IN :certificateIds
            AND b3o__Certificate_Type__r.Name = 'Photo ID'];

        if (certs.size() == 0) {
            return;
        }

        for (b3o__Certificate__c cert : certs) {
            certContactMap.put(cert.Id, cert.b3o__Contact__c);
        }

        for (ContentDocumentLink cdl : newContentDocumentLinks) {
            if(certContactMap.containsKey(cdl.LinkedEntityId)){
                ContentDocumentLink contactCDL = new ContentDocumentLink(
                    ContentDocumentId = cdl.ContentDocumentId,
                    LinkedEntityId = certContactMap.get(cdl.LinkedEntityId),
                    ShareType = cdl.ShareType,
                    Visibility = cdl.Visibility
                );
                contactCDLs.add(contactCDL);
            }
        }
        
        if (contactCDLs.size() > 0) {
            insert contactCDLs;
        }
    }
}