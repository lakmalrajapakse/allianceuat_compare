public class InvoicePreviewController {

    private static Set<Id> filterInvoicesWithPdf(Set<Id> invoiceIds) {
        if (invoiceIds == null || invoiceIds.isEmpty()) return new Set<Id>();

        Map<Id, Set<Id>> invToDocIds = new Map<Id, Set<Id>>();
        Set<Id> allDocIds = new Set<Id>();
        for (ContentDocumentLink cdl : [
            SELECT LinkedEntityId, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :invoiceIds
        ]) {
            if (!invToDocIds.containsKey(cdl.LinkedEntityId)) {
                invToDocIds.put(cdl.LinkedEntityId, new Set<Id>());
            }
            invToDocIds.get(cdl.LinkedEntityId).add(cdl.ContentDocumentId);
            allDocIds.add(cdl.ContentDocumentId);
        }
        if (allDocIds.isEmpty()) return new Set<Id>();

        Set<Id> pdfDocIds = new Set<Id>();
        for (ContentVersion cv : [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE ContentDocumentId IN :allDocIds
              AND IsLatest = true
              AND FileType = 'PDF'
        ]) {
            pdfDocIds.add(cv.ContentDocumentId);
        }
        if (pdfDocIds.isEmpty()) return new Set<Id>();

        Set<Id> result = new Set<Id>();
        for (Id invId : invToDocIds.keySet()) {
            for (Id docId : invToDocIds.get(invId)) {
                if (pdfDocIds.contains(docId)) {
                    result.add(invId);
                    break;
                }
            }
        }
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<tc9_et__Invoice__c> getInvoices(Id branchId, Date startDate, Date endDate) {
        if (branchId == null || startDate == null || endDate == null) return new List<tc9_et__Invoice__c>();

        Set<Id> assignmentIds = new Set<Id>();
        for (tc9_pr__Assignment__c a : [
            SELECT Id FROM tc9_pr__Assignment__c WHERE Branch__c = :branchId LIMIT 50000
        ]) assignmentIds.add(a.Id);
        if (assignmentIds.isEmpty()) return new List<tc9_et__Invoice__c>();

        Set<Id> invoiceItemIds = new Set<Id>();
        for (tc9_pr__Pay_Transaction__c pt : [
            SELECT tc9_et__Invoice_Item__c
            FROM tc9_pr__Pay_Transaction__c
            WHERE tc9_pr__Assignment__c IN :assignmentIds
              AND tc9_et__Invoice_Item__c != null
            LIMIT 50000
        ]) invoiceItemIds.add(pt.tc9_et__Invoice_Item__c);
        if (invoiceItemIds.isEmpty()) return new List<tc9_et__Invoice__c>();

        Set<Id> invoiceIds = new Set<Id>();
        for (tc9_et__Invoice_Item__c ii : [
            SELECT tc9_et__Invoice__c
            FROM tc9_et__Invoice_Item__c
            WHERE Id IN :invoiceItemIds AND tc9_et__Invoice__c != null
            LIMIT 50000
        ]) invoiceIds.add(ii.tc9_et__Invoice__c);
        if (invoiceIds.isEmpty()) return new List<tc9_et__Invoice__c>();

        Set<Id> invoicesWithPdf = filterInvoicesWithPdf(invoiceIds);
        if (invoicesWithPdf.isEmpty()) return new List<tc9_et__Invoice__c>();

        return [
            SELECT Id, Name, tc9_et__Invoice_Date__c,
                   tc9_et__Invoice_To_Account__r.Name,
                   tc9_et__Invoice_Total_Inc_Tax__c,
                   tc9_et__Balance_Due__c
            FROM tc9_et__Invoice__c
            WHERE Id IN :invoicesWithPdf
              AND tc9_et__Invoice_Date__c >= :startDate
              AND tc9_et__Invoice_Date__c <= :endDate
            ORDER BY tc9_et__Invoice_Date__c ASC, Name ASC
            LIMIT 2000
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Integer countInvoices(Id branchId, Date startDate, Date endDate) {
        if (branchId == null || startDate == null || endDate == null) return 0;

        Set<Id> assignmentIds = new Set<Id>();
        for (tc9_pr__Assignment__c a : [
            SELECT Id FROM tc9_pr__Assignment__c WHERE Branch__c = :branchId LIMIT 50000
        ]) assignmentIds.add(a.Id);
        if (assignmentIds.isEmpty()) return 0;

        Set<Id> invoiceItemIds = new Set<Id>();
        for (tc9_pr__Pay_Transaction__c pt : [
            SELECT tc9_et__Invoice_Item__c
            FROM tc9_pr__Pay_Transaction__c
            WHERE tc9_pr__Assignment__c IN :assignmentIds
              AND tc9_et__Invoice_Item__c != null
            LIMIT 50000
        ]) invoiceItemIds.add(pt.tc9_et__Invoice_Item__c);
        if (invoiceItemIds.isEmpty()) return 0;

        Set<Id> invoiceIds = new Set<Id>();
        for (tc9_et__Invoice_Item__c ii : [
            SELECT tc9_et__Invoice__c
            FROM tc9_et__Invoice_Item__c
            WHERE Id IN :invoiceItemIds AND tc9_et__Invoice__c != null
            LIMIT 50000
        ]) invoiceIds.add(ii.tc9_et__Invoice__c);
        if (invoiceIds.isEmpty()) return 0;

        Set<Id> invoicesWithPdf = filterInvoicesWithPdf(invoiceIds);
        if (invoicesWithPdf.isEmpty()) return 0;

        return (Integer) Database.countQuery(
            'SELECT COUNT() FROM tc9_et__Invoice__c ' +
            'WHERE Id IN :invoicesWithPdf ' +
            'AND tc9_et__Invoice_Date__c >= :startDate ' +
            'AND tc9_et__Invoice_Date__c <= :endDate'
        );
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getSelectedInvoicePdfs(List<Id> invoiceIds) {
        if (invoiceIds == null || invoiceIds.isEmpty()) return new List<Map<String,String>>();

        Map<Id, Id> invToDoc = new Map<Id, Id>();
        Set<Id> docIds = new Set<Id>();

        for (ContentDocumentLink cdl : [
            SELECT LinkedEntityId, ContentDocumentId, SystemModstamp
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :invoiceIds
            ORDER BY SystemModstamp DESC
        ]) {
            if (!invToDoc.containsKey(cdl.LinkedEntityId)) {
                invToDoc.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
                docIds.add(cdl.ContentDocumentId);
            }
        }
        if (docIds.isEmpty()) return new List<Map<String,String>>();

        Map<Id, ContentVersion> docToCv = new Map<Id, ContentVersion>();
        for (ContentVersion cv : [
            SELECT ContentDocumentId, Title, VersionData, FileType, IsLatest
            FROM ContentVersion
            WHERE ContentDocumentId IN :docIds
              AND IsLatest = true
              AND FileType = 'PDF'
        ]) {
            docToCv.put(cv.ContentDocumentId, cv);
        }

        List<tc9_et__Invoice__c> invs = [
            SELECT Id, Name, tc9_et__Invoice_Date__c
            FROM tc9_et__Invoice__c
            WHERE Id IN :invoiceIds
            ORDER BY tc9_et__Invoice_Date__c ASC, Name ASC
        ];

        List<Map<String,String>> files = new List<Map<String,String>>();
        for (tc9_et__Invoice__c inv : invs) {
            Id docId = invToDoc.get(inv.Id);
            if (docId == null) continue;
            ContentVersion cv = docToCv.get(docId);
            if (cv == null) continue;
            files.add(new Map<String,String>{
                'name'   => (cv.Title != null ? cv.Title : inv.Name) + '.pdf',
                'base64' => EncodingUtil.base64Encode(cv.VersionData)
            });
        }
        return files;
    }
}