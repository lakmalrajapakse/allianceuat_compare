public with sharing class FeeForServiceController {
    public static final List<String> FILE_TYPES = new List<String> { 'JPG', 'JPEG', 'PNG', 'GIF', 'VISIO', 'TIFF', 'TIF', 'heic' };
    public List<FeeForServiceData> invoiceDatas {get; set;}
    
    public Map<Id, Id> invoiceLogoMap {get; set;}
    public Map<Id, Boolean> hasInvoiceLogoMap {get; set;}
    
    public FeeForServiceController(ApexPages.StandardSetController controller) {
        invoiceDatas = new List<FeeForServiceData>();
        invoiceLogoMap = new Map<Id, Id>();
        hasInvoiceLogoMap = new Map<Id, Boolean>();

        String token = ApexPages.currentPage()?.getParameters()?.get('token');
        if(token != null) {
            token  = EncodingUtil.urlEncode(token, 'UTF-8');
        }
        
        List<Id> validatingInvoices = new List<Id>();

        String printId = ApexPages.currentPage()?.getParameters()?.get('printId');
        if(printId!= null) {
            token ='1';
            validatingInvoices = printId.split('-');
        }
        
        if(token == null && printId == null) {
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
        
        System.debug('[START] FeeForServiceController REQ: token=' + token + ', printId=' + printId + ', invoiceId=' + invoiceId + ', validatingInvoices=' + validatingInvoices);

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
        populateBackingsheet(invoices);
        populateInvoiceLogo(invoices);
    }
    public void populateInvoiceDetail(List<tc9_et__Invoice__c> invoices) {
        Map<Id, tc9_et__Invoice__c> invMap = new Map<Id, tc9_et__Invoice__c>(invoices);
        List<tc9_et__Invoice_Item__c> invoiceItems = SkieInvoiceTemplateQuery.getInvoiceItems(invoices, 'tc9_et__Timesheet_Entry__r.tc9_et__Start_Date__c ASC NULLS LAST');

        Map<Id, FeeForServiceData> invDataMap = new Map<Id, FeeForServiceData>();
        System.Debug('[INFO] invoiceItems.size()=' + invoiceItems.size() + ', invoiceItems=' + JSON.serializePretty(invoiceItems));
        for(tc9_et__Invoice_Item__c invItem : invoiceItems) {
            Id invoiceId = invItem.tc9_et__Invoice__c;

            if(invDataMap.get(invoiceId) != null) {
                invDataMap.get(invoiceId).addItem(invItem);

            } else {
                FeeForServiceData invData = new FeeForServiceData(invMap.get(invoiceId));
                invData.addItem(invItem);
                invDataMap.put(invoiceId, invData);
            }
        }

        for(FeeForServiceData data : invDataMap.values()) {
            data.calculateGrandTotals();
        }
        
        this.invoiceDatas = invDataMap.values();
        System.Debug('[INFO] invoiceData='  + JSON.serializePretty(this.invoiceDatas));
    }

    public void populateBackingsheet(List<tc9_et__Invoice__c> invoices) {
        List<tc9_et__Invoice_Item__c> items = SkieInvoiceTemplateQuery.getInvoiceItems(invoices, 'tc9_et__Timesheet_Entry__r.tc9_et__Start_Date__c ASC NULLS LAST, tc9_et__Pay_Transaction__r.Shift__r.tc9_ext_sirint__TSE_Start_Time__c');
        
        Map<Id, Set<Id>> invTimesheetIdsMap = new Map<Id, Set<Id>>();
        Set<Id> timesheetIdSet = new Set<Id>();
        Set<Id> entryIdSet = new Set<Id>();
        Set<Id> allShiftIds = new Set<Id>();

        for(tc9_et__Invoice_Item__c item : items) {
            Id timesheetId = item.tc9_et__Timesheet_Entry__r.tc9_et__Timesheet__c;
            if(timesheetId != null) {
                timesheetIdSet.add(timesheetId);
                entryIdSet.add(item.tc9_et__Timesheet_Entry__c);
            
                if(invTimesheetIdsMap.get(item.tc9_et__Invoice__c) == null) {
                    invTimesheetIdsMap.put(item.tc9_et__Invoice__c, new Set<Id>());
                }
                invTimesheetIdsMap.get(item.tc9_et__Invoice__c).add(timesheetId);
                String shiftId = item.tc9_et__Timesheet_Entry__r.tc9_ext_sirint__Shift__c;
                if(shiftId != null) {
                    allShiftIds.add(shiftId);
                }
            }
        }
        
        Map<Id, tc9_et__Timesheet__c> timesheetsMap = new Map<Id, tc9_et__Timesheet__c>(SkieInvoiceTemplateQuery.getTimesheets(timesheetIdSet));

        Map<Id, List<tc9_et__Timesheet_Entry__c>> entriesMap = new Map<Id, List<tc9_et__Timesheet_Entry__c>>();
        for(tc9_et__Timesheet_Entry__c tse : SkieInvoiceTemplateQuery.getTimesheetEntries(entryIdSet)) {
            if(entriesMap.get(tse.tc9_et__Timesheet__c) == null) {
                entriesMap.put(tse.tc9_et__Timesheet__c, new List<tc9_et__Timesheet_Entry__c>());
            }
            entriesMap.get(tse.tc9_et__Timesheet__c).add(tse);

            if(tse.tc9_ext_sirint__Shift__c != null) {
                allShiftIds.add(tse.tc9_ext_sirint__Shift__c);
            }
        }
        
        Map<Id,String> shiftToSignatureUrl = FeeForServiceController.getShiftSignatureUrls(allShiftIds);

        for(FeeForServiceData invData : invoiceDatas) {
            Set<Id> timesheetIds = invTimesheetIdsMap.get(invData.sfInvoice?.Id);
            system.debug('timesheetIds > ' + timesheetIds);
            
			List<FeeForServiceData.Timesheet> bTimesheets = new List<FeeForServiceData.Timesheet>();            
            if(timesheetIds != null && !timesheetIds.isEmpty()) {
                for(Id tsId : timesheetIds) {
                    tc9_et__Timesheet__c timesheet = timesheetsMap.get(tsId); 
                    if(timesheet != null) {
                        bTimesheets.add(new FeeForServiceData.Timesheet(timesheet, entriesMap.get(tsId), shiftToSignatureUrl));
                    }
                }
            }
            
            invData.backingSheet = new FeeForServiceData.BackingSheet(bTimesheets);
        }
    }

    public void populateInvoiceLogo(List<tc9_et__Invoice__c> invoices) {
        for(ContentDocumentLink logoFile : SkieInvoiceTemplateQuery.getLogoContentDocumentLink(hasInvoiceLogoMap.keySet())){
            invoiceLogoMap.put(logoFile.LinkedEntityId,logoFile.ContentDocument.LatestPublishedVersionId);
            hasInvoiceLogoMap.put(logoFile.LinkedEntityId, true);
        }
    }

    public static Map<Id,String> getShiftSignatureUrls(Set<Id> shiftIds) {

        Map<Id,String> result = new Map<Id,String>();
    
        if(shiftIds == null || shiftIds.isEmpty()) {
            return result;
        }
    
        for(ContentDocumentLink cdl : [SELECT LinkedEntityId, ContentDocument.LatestPublishedVersionId, ContentDocument.CreatedDate
                                       FROM ContentDocumentLink
                                       WHERE LinkedEntityId IN :shiftIds
                                       AND ContentDocument.Title LIKE '%Esign%'
                                       AND ContentDocument.FileExtension IN :FILE_TYPES
                                       ORDER BY LinkedEntityId, ContentDocument.CreatedDate DESC]) {
                            
            String shiftId = cdl.LinkedEntityId;
            if(!result.containsKey(shiftId)) {
                result.put(shiftId, '/sfc/servlet.shepherd/version/download/' + cdl.ContentDocument.LatestPublishedVersionId);
            }
        }
        return result;
    }
}