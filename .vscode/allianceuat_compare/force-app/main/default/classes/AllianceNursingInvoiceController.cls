public without sharing class AllianceNursingInvoiceController {

    public List<AllianceNursingInvoiceData> invoiceDatas {get; set;}

    public Map<Id, Id> invoiceLogoMap {get; set;}
    public Map<Id, Boolean> hasInvoiceLogoMap {get; set;}
    public Map<Id, Boolean> hasInvoiceAttachmentMap {get; set;}

    public AllianceNursingInvoiceController(ApexPages.StandardSetController controller){
        invoiceDatas = new List<AllianceNursingInvoiceData>();
        invoiceLogoMap = new Map<Id, Id>();
        hasInvoiceLogoMap = new Map<Id, Boolean>();

        String token = ApexPages.currentPage()?.getParameters()?.get('token');
        if(token != null){
            token  = EncodingUtil.urlEncode(token, 'UTF-8');
        }
        
        List<Id> validatingInvoices = new List<Id>();

        String printId = ApexPages.currentPage()?.getParameters()?.get('printId');
        if(printId!= null){
            token ='1';
            validatingInvoices = printId.split('-');
        }
        
        if(token == null && printId == null){
            token = '1';
            List<tc9_et__Invoice__c> selectedIds = (List<tc9_et__Invoice__c>) Controller.getSelected();
            for(tc9_et__Invoice__c iteratingInvoice : selectedIds) {
                validatingInvoices.add(iteratingInvoice.Id);
            }
        }

        String invoiceId = ApexPages.currentPage()?.getParameters()?.get('invoiceId');
        if(String.isNotBlank(invoiceId) && validatingInvoices.isEmpty()) {
             validatingInvoices.add(invoiceId);
        }
        
        System.debug('[START] AllianceNursingInvoiceController REQ: token=' + token + ', printId=' + printId + ', invoiceId=' + invoiceId + ', validatingInvoices=' + validatingInvoices);

        List<tc9_et__Invoice__c> invoices = SkieInvoiceTemplateQuery.getInvoices(validatingInvoices, token);
        System.debug('[INFO] invoiceSize=' + invoices.size() + ', invoices=' + invoices);

        if(invoices == null || invoices.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid Invoice Id'));
            return;
        }

        // Set default map value for display validation on VF page.
        for(tc9_et__Invoice__c invoice : invoices) {
            hasInvoiceLogoMap.put(invoice.tc9_et__Invoice_Entity__c, false);    
        }

        populateInvoiceDetail(invoices);
        populateInvoiceLogo(invoices);
    }

    public void populateInvoiceDetail(List<tc9_et__Invoice__c> invoices) {
        Map<Id, tc9_et__Invoice__c> invMap = new Map<Id, tc9_et__Invoice__c>(invoices);
        List<tc9_et__Invoice_Item__c> invItems = SkieInvoiceTemplateQuery.getInvoiceItems(invoices);

        Map<Id, AllianceNursingInvoiceData> invDataMap = new Map<Id, AllianceNursingInvoiceData>();
        for(tc9_et__Invoice_Item__c item : invItems) {
            Id invoiceId = item.tc9_et__Invoice__c;
            Date startDate = item.tc9_et__Pay_Transaction__r.tc9_et__Timesheet_Entry__r.tc9_et__Timesheet__r.tc9_et__Start_Date__c;
            Time startTime = item.tc9_et__Pay_Transaction__r.tc9_et__Timesheet_Entry__r.tc9_et__Start_Time__c;
            Time endTime = item.tc9_et__Pay_Transaction__r.tc9_et__Timesheet_Entry__r.tc9_et__End_Time__c;
            String timesheetFormula = item.tc9_et__Pay_Transaction__r.tc9_et__Timesheet_Entry__r.tc9_et__Timesheet_Formula__c;
            String empName = item.tc9_et__Assignment__r.tc9_pr__Employee__r.Name;
            String assignmentName = item.tc9_et__Assignment__r.tc9_pr__Assignment_Name__c;

            String groupKey = invoiceId + '-' + startDate + '-' + startTime + '-' + endTime + '-' + timesheetFormula + '-' + empName + '-' + assignmentName;
            String subGroupKey = item.tc9_et__Pay_Code__r.Name + '-' + item.tc9_et__Invoice_Rate__c;
        
            // System.debug('groupkey= ' + groupKey);
            // System.debug('subGroupKey= ' + subGroupKey);

            if(invDataMap.get(item.tc9_et__Invoice__c) != null) {
                invDataMap.get(item.tc9_et__Invoice__c).addItem(item, groupKey, subGroupKey);

            } else {
                AllianceNursingInvoiceData invData = new AllianceNursingInvoiceData(invMap.get(invoiceId));
                invData.addItem(item, groupKey, subGroupKey);
                invDataMap.put(item.tc9_et__Invoice__c, invData);
            }
        }

        this.invoiceDatas = invDataMap.values();

        Map<Id, List<Id>> invoiceAttachmentMap = getInvoiceAttachments(invMap.keySet());
        for(AllianceNursingInvoiceData inv : this.invoiceDatas) {
            inv.attachmentIds = invoiceAttachmentMap.get(inv.sfInvoice.Id) ?? new List<Id>();
        }
   
    }

    /*
     Attachments from Invoiceable Fee, Timesheet, Expense Claim
    */
    public Map<Id, List<Id>> getInvoiceAttachments(Set<Id> invIdSet) {
        Map<Id, Id> linkEntIdMap = new Map<Id, Id>();
        System.debug('[INFO] getInvoiceAttachments invIdSet=' + invIdSet);

        for(tc9_et__Invoice_Item__c item : [SELECT Id, tc9_et__Assignment__c, tc9_et__Pay_Transaction__c, tc9_et__Pay_Transaction__r.tc9_et__Invoiceable_Fee__c,
                                            tc9_et__Pay_Transaction__r.tc9_et__Expense__c, tc9_et__Pay_Transaction__r.tc9_et__Expense_Claim__c,
                                            tc9_et__Timesheet_Entry__c, tc9_et__Timesheet_Entry__r.tc9_et__Timesheet__c, tc9_et__Invoice__c
                                            FROM tc9_et__Invoice_Item__c
                                            WHERE tc9_et__Invoice__c IN : invIdSet]){ 

            if(item.tc9_et__Timesheet_Entry__r.tc9_et__Timesheet__c != null) {
                linkEntIdMap.put(item.tc9_et__Timesheet_Entry__r.tc9_et__Timesheet__c, item.tc9_et__Invoice__c);
            }                                    

            if(item.tc9_et__Pay_Transaction__r.tc9_et__Invoiceable_Fee__c != null) {
                linkEntIdMap.put(item.tc9_et__Pay_Transaction__r.tc9_et__Invoiceable_Fee__c, item.tc9_et__Invoice__c);
            }                                    

            if(item.tc9_et__Pay_Transaction__r.tc9_et__Expense_Claim__c != null) {
                linkEntIdMap.put(item.tc9_et__Pay_Transaction__r.tc9_et__Expense_Claim__c, item.tc9_et__Invoice__c);
            }         
        }
        
         System.debug('[INFO] getInvoiceAttachments linkEntIdMap=' + linkEntIdMap);

        Map<Id, List<Id>> invoiceAttachmentMap = new Map<Id, List<Id>>();
        if(linkEntIdMap.isEmpty()) {
            return invoiceAttachmentMap;
        }

        for(ContentDocumentLink cdl : SkieInvoiceTemplateQuery.getImageContentDocumentLink(linkEntIdMap.keySet())){
            Id invoiceId = linkEntIdMap.get(cdl.LinkedEntityId);
            if(invoiceId != null) {
                if(invoiceAttachmentMap.get(invoiceId) != null) {
                    invoiceAttachmentMap.get(invoiceId).add(cdl.ContentDocument.LatestPublishedVersionId);
                } else {
                    invoiceAttachmentMap.put(invoiceId, new List<Id>{cdl.ContentDocument.LatestPublishedVersionId});
                }
            }
        }
        
        System.debug('[INFO] invoiceAttachmentMap' + invoiceAttachmentMap);

        return invoiceAttachmentMap;
    }

    public void populateInvoiceLogo(List<tc9_et__Invoice__c> invoices) {
        for(ContentDocumentLink logoFile : SkieInvoiceTemplateQuery.getLogoContentDocumentLink(hasInvoiceLogoMap.keySet())){
            invoiceLogoMap.put(logoFile.LinkedEntityId,logoFile.ContentDocument.LatestPublishedVersionId);
            hasInvoiceLogoMap.put(logoFile.LinkedEntityId, true);
        }
    }
}