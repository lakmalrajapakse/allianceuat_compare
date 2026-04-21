/**
* Created by Adelaide Greenaway on 31/10/2022.

*   Class         :  Custom_SummaryPayAdviceCtrl

*   Description   :  Custom Class for Summary pay Advice PDF generation page
*   Author        :  Adelaide Greenaway
*   Created Date    :  31/10/2022

IMPORTANT NOTE : This custom class and its accompanying VF Page (Custom_SummaryPayrollPayAdvice_Page) and Test Class (Test_CustomSummaryPayAdviceCtrl) is a temporary solution and will be
removed and replaced with the product versions once they are released as GA.
Change History
********************************************************************************************************************************************************************
SCRUM           ModifiedBy          Date        Requested By        Description                                                Tag
********************************************************************************************************************************************************************
SC-34289        Adelaide            31/10/22    Sam Nobes           CUSTOM Summarised Pay Advice
*/

public with sharing class Custom_SummaryPayAdviceCtrl {
    
    //class variables
    public String Locale{get;set;}
    public String payAdviceId;
    public Map<String, Integer> mapOfPayCodeToSortOrder;
    public Map<String, PayCodeWrapper> mapOfPayCodeToPayCodeWrapper;
    public Map<String, LeaveBalancesWrapper> mapOfLeaveRuleNameToLeaveBalancesWrapper;
    private List<Id> listOfSuperAnnuationFundIds;
    private Boolean isAssignmentPayAdvice;
    private Boolean isProjCodePayAdvice;
    private Set<String> paycodeSetTaxableGross = new Set<String>();
    private Set<String> payCodeSetPreTax = new Set<String>();
    
    
    //page variables
    public tc9_pr__Pay_Advice__c payAdvice{get;set;}
    public tc9_pr__Payee_Withholding__c payeeWithholding{get;set;}
    public List<PayCodeWrapper> listOfPayCodeWrappersGroup1{get;set;}
    public List<PayCodeWrapper> listOfPayCodeWrappersGroup2{get;set;}
    
    public List<PayAdviceLinesWrapper> listOfEmpPayAdvLinesWrappers{get;set;}
    public List<LeaveBalancesWrapper> listOfLeaveBalancesWrappers{get;set;}
    public List<PaymentFileLinesWrapper> listOfPaymentFileLinesWrapper{get;set;}
    public List<PayTransactionsWrapper> listOfPayTransactionsWrapper{get;set;}
    
    public String logoId{get;set;}
    public Boolean foundLogo{get;set;}
    public String documentTitle{get;set;}
    public Boolean isDraft {get;set;}
    public String employeeName {get;set;}
    public Decimal gst {get;set;}
    public Decimal multiplier = 1;
    public Decimal leaveMultiplier = 1;
    
    //color code variables
    public String colorHeaderLabel {get;set;}
    public String colorHeaderValue {get;set;}
    public String colorSectionHeadingBg {get;set;}
    public String colorSectionHeadingText {get;set;}
    public String colorSectionDetailBg {get;set;}
    public String colorSectionDetailText {get;set;}
    public String displayAddressBorder {get;set;}
    public String footerPosition {get;set;}
    public String footerText {get;set;}
    public String colorFooterText {get;set;}
    //constants
    public String labelNetPayDistribution {get;set;}
    public String labelSuperannuationDistribution {get;set;}
    public String labelLeaveBalance {get;set;}
    public String labelSummary{get;set;}
    public String labelPersonalMessage{get;set;}
    public String labelGeneralMessage{get;set;}
    public String personalMessage{get;set;}
    public String generalMessage{get;set;}
    public Map<String, tc9_pr__Payee_Aggregate__c> payeeAggMap{get;set;}
    
    public Map<String, tc9_pr__Pay_Transaction__c> transactionMap{get;set;}
    
    public String PAYCODE_NON_TAXABLE_PAYMENTS;
    public String PAYCODE_TAXABLE_PAYMENTS;
    public String PAYCODE_PRE_TAX_DEDUCTIONS;
    public String PAYCODE_POST_TAX_DEDUCTIONS;
    public String PAYCODE_PAYG;
    public String PAYCODE_EMPLOYER_SUPERANNUATION;
    public String PAYCODE_EXPENSE_REIMBURSEMENTS;
    public String PAYCODE_LEAVE_BALANCES;
    public String PAYCODE_GST;
    public final static String PAYCODE_RECORD_TYPE_DEVELOPER_NAME_DEDUCTION = 'Deduction';
    public final static String PAYCODE_RECORD_TYPE_DEVELOPER_NAME_EXPENSE = 'Expense';
    public final static String CLASSIFICATION_WITHHOLDING_PAYG = 'Withholding - PAYG';
    public final static String CLASSIFICATION_WITHHOLDING_HELP = 'Withholding - HELP';
    public final static String CLASSIFICATION_WITHHOLDING_SFSS = 'Withholding - SFSS';
    public final static String CLASSIFICATION_WITHHOLDING_STSL = 'Withholding - STSL';
    public final static String CLASSIFICATION_WITHHOLDING_GST = 'Withholding - GST';
    public final static String CLASSIFICATION_WITHHOLDING_ETP_PAYG = 'Withholding - ETP PAYG';
    public final static String CLASSIFICATION_WITHHOLDING_SUPERANNUATION = 'Withholding - Superannuation';
    public final static String RECORD_TYPE_WITHHOLDING_SUPERANNUATION = 'Withholding_Superannuation';
    public final static String RECORD_TYPE_Deduction = 'Deduction';
    public final static String DEDUCTION_PRE_TAX = 'Pre-tax Deduction';
    public final static String DEDUCTION_POST_TAX = 'Post-tax Deduction';
    private final static String maskCode = '****';
    
    private final static List<String> IMAGE_FILE_TYPES = new List<String>{'BMP', 'GIF', 'JPEG', 'JPG', 'PNG', 'TIF', 'TIFF', 'VSD', 'SVG'};
        
        public Id GST_RECORDTYPE = Schema.SObjectType.tc9_pr__Pay_Advice__c.getRecordTypeInfosByDeveloperName().get('Contractor_Invoice').getRecordTypeId(); //Schema.getGlobalDescribe().get(objName).getDescribe().getRecordTypeInfosByDeveloperName().get('Contractor_Invoice').getRecordTypeId();
    
    //Summary Table
    public Decimal summaryNonTaxableGross{get;set;}
    public Decimal summaryNonTaxableGross_YTD{get;set;}
    public Decimal summaryGross{get;set;}
    public Decimal summaryGross_YTD{get;set;}
    public Decimal summaryPreTaxDeduction{get;set;}
    public Decimal summaryPreTaxDeduction_YTD{get;set;}
    public Decimal summaryTaxableGross{get;set;}
    public Decimal summaryTaxableGross_YTD{get;set;}
    public Decimal summaryPostTaxDeduction{get;set;}
    public Decimal summaryPostTaxDeduction_YTD{get;set;}
    public Decimal summaryPAYG{get;set;}
    public Decimal summaryPAYG_YTD{get;set;}
    public Decimal summaryExpenses{get;set;}
    public Decimal summaryExpenses_YTD{get;set;}
    public Decimal summaryNet{get;set;}
    public Decimal summaryNet_YTD{get;set;}
    public Decimal summarySuper{get;set;}
    public Decimal summarySuper_YTD{get;set;}
    
    //constructor
    public Custom_SummaryPayAdviceCtrl(ApexPages.StandardSetController controller){
        String UserId = UserInfo.getUserId();
        Locale = [SELECT LocaleSidKey FROM User WHERE Id =: UserId].LocaleSidKey;
        foundLogo = false;
        isDraft = false;
        employeeName = null;
        listOfPayCodeWrappersGroup1 = new List<PayCodeWrapper>();
        listOfPayCodeWrappersGroup2 = new List<PayCodeWrapper>();
        listOfLeaveBalancesWrappers = new List<LeaveBalancesWrapper>();
        payAdviceId = ApexPages.currentPage().getParameters().get('id'); //get the id of pay advice record from url
        
        
        if(payAdviceId != null){
            //query required fields from pay advice record
            payAdvice = [SELECT Id, Name, tc9_pr__Gross_Earnings__c, tc9_pr__Net_Earnings__c, tc9_pr__Employee__c, tc9_pr__Pay_Batch__c, tc9_pr__Payee__c, tc9_pr__Pay_Batch_Item__c, tc9_pr__Payment_Entity__c, tc9_pr__Payment_Entity__r.Name, tc9_pr__Payment_Entity__r.tc9_pr__ABN__c,
                         tc9_pr__Payment_Entity__r.tc9_eau__STP_Contact_Phone__c, tc9_pr__Payment_Entity__r.tc9_eau__STP_Contact_Email__c , tc9_pr__Pay_Batch__r.tc9_pr__Calendar_Period__r.tc9_pr__Start_Date__c,
                         tc9_pr__Pay_Batch__r.tc9_pr__Calendar_Period__r.tc9_pr__End_Date__c, tc9_pr__Pay_Batch__r.tc9_pr__Payment_Date__c, tc9_pr__Employee__r.FirstName, tc9_pr__Employee__r.LastName, tc9_pr__Employee__r.MailingStreet, tc9_pr__Pay_Batch__r.tc9_pr__Status__c, tc9_pr__Pay_Advice_Template__c,
                         tc9_pr__Employee__r.MailingCity, tc9_pr__Employee__r.MailingState, tc9_pr__Employee__r.MailingPostalCode, tc9_pr__Employee__r.MailingCountry, tc9_pr__Pay_Advice_Message__c, tc9_pr__Pay_Batch__r.tc9_pr__Schedule__c, tc9_pr__Payee__r.tc9_pr__Payroll_Id__c,
                         tc9_pr__Pay_Batch__r.tc9_pr__Schedule__r.tc9_pr__Pay_Advice_Detail_Level__c, tc9_pr__Employee__r.Name, tc9_pr__Employee__r.Salutation, tc9_pr__GST__c, RecordTypeId, RecordType.DeveloperName,
                         tc9_pr__Period_Start_Date__c, tc9_pr__Period_End_Date__c, tc9_pr__Payment_Entity__r.General_Pay_Advice_Message__c, Primary_Branch__c 
                         FROM tc9_pr__Pay_Advice__c WHERE Id = :payAdviceId];
            if(payAdvice.tc9_pr__GST__c != null) {
                gst = payAdvice.tc9_pr__GST__c.setScale(2);
            }
            if(payAdvice != null && payAdvice.RecordTypeId == GST_RECORDTYPE){
                for(tc9_pr__Payee_Withholding__c pwh : [SELECT Id,Name, tc9_pr__Payee__c, tc9_pr__Status__c, tc9_pr__Effective_Date__c, tc9_pr__ABN__c, tc9_pr__Business_Name__c, tc9_pr__Business_Street__c, tc9_pr__Business_CIty__c, tc9_pr__Business_State_Province__c, tc9_pr__Business_Zip_Postal_Code__c, tc9_pr__Business_Country__c
                                                        FROM tc9_pr__Payee_Withholding__c WHERE tc9_pr__Payee__c =: payAdvice.tc9_pr__Payee__c AND tc9_pr__Status__c !=: 'On Hold' AND RecordType.DeveloperName =: 'AU_GST' AND tc9_pr__Effective_Date__c <=: payAdvice.tc9_pr__Pay_Batch__r.tc9_pr__Calendar_Period__r.tc9_pr__End_Date__c]){
                                                            payeeWithholding = pwh;
                                                        }
            }
            //T07
            if(payAdvice.tc9_pr__Pay_Batch__r.tc9_pr__Status__c != 'Payment File Released'){
                isDraft = true;
            }
            employeeName = payAdvice.tc9_pr__Employee__r.Name;
            
            isAssignmentPayAdvice = false;
            isProjCodePayAdvice = true;
            if('Assignment'.equals(payAdvice.tc9_pr__Pay_Batch__r.tc9_pr__Schedule__r.tc9_pr__Pay_Advice_Detail_Level__c)){
                isAssignmentPayAdvice = true;
            }else if('Project Code'.equals(payAdvice.tc9_pr__Pay_Batch__r.tc9_pr__Schedule__r.tc9_pr__Pay_Advice_Detail_Level__c)){
                isProjCodePayAdvice = true;
            }
            
            tc9_pr__Pay_Advice_Template__c template = getRelatedPayAdviceTemplate();
            if(template != null){
                setCustomLablesAndColorForPayAdvice(template, payAdviceId, payAdvice );
                documentTitle = template.tc9_pr__Document_Title__c;
            }
            //get logo from related payment entity
            loadPrimaryBranchLogo();
            // loadLogo();
            
            //create a map to maintain the sort order for different pay codes
            mapOfPayCodeToSortOrder = new Map<String, Integer>();
            loadSortOrder();
            System.debug('mapOfPayCodeToSortOrder >>> ' + mapOfPayCodeToSortOrder);
            
            //compute totals based on different grroupings
            mapOfPayCodeToPayCodeWrapper = new Map<String, PayCodeWrapper>();
            mapOfLeaveRuleNameToLeaveBalancesWrapper = new Map<String, LeaveBalancesWrapper>();
            loadPayAdviceSection();
            System.debug('mapOfPayCodeToPayCodeWrapper >>> ' + mapOfPayCodeToPayCodeWrapper);
            if(template.tc9_pr__Hide_Blank_Detail_Sections__c != 'Yes') {
                populateDefaultValues();
            }
            //CI-228947
            if(template.tc9_pr__Hide_Blank_Detail_Sections__c == 'Yes'){
                removeBlankSections();
            }
            System.debug('after populating missing paycodes, mapOfPayCodeToPayCodeWrapper >>> ' + mapOfPayCodeToPayCodeWrapper);
            
            //compute net pay distribution from related payment file lines
            listOfPaymentFileLinesWrapper = new List<PaymentFileLinesWrapper>();
            computeNetPayDistribution();
            System.debug('listOfPaymentFileLinesWrapper >>> ' + listOfPaymentFileLinesWrapper);
            summaryNet = payAdvice.tc9_pr__Net_Earnings__c;
            computeNetYtdSummary(payAdvice.tc9_pr__Pay_Batch_Item__c);
            //compute superannuation distribution from related paytransactions
            listOfPayTransactionsWrapper = new List<PayTransactionsWrapper>();
            computeSuperannuationDistribution();
            System.debug('listOfPayTransactionsWrapper >>> ' + listOfPayTransactionsWrapper);
            
            //convert map to list, sort based on custom sort order and use the list in page
            if(!mapOfPayCodeToPayCodeWrapper.isEmpty()){
                //T07 - Starts
                if(payAdvice.RecordTypeId == GST_RECORDTYPE){
                    if(mapOfPayCodeToPayCodeWrapper.containsKey('Employer Superannuation') && mapOfPayCodeToPayCodeWrapper.get('Employer Superannuation').listOfPayAdviceLinesWrapper != null){
                        listOfEmpPayAdvLinesWrappers = mapOfPayCodeToPayCodeWrapper.get('Employer Superannuation').listOfPayAdviceLinesWrapper;
                        if(listOfEmpPayAdvLinesWrappers.size() > 0){
                            for(PayAdviceLinesWrapper ipayAdvLineWrap : listOfEmpPayAdvLinesWrappers){
                                if(ipayAdvLineWrap.CP_totalUnits == 0.00 && ipayAdvLineWrap.CP_totalValue == 0.00 && ipayAdvLineWrap.rate == 0.00 &&
                                   ipayAdvLineWrap.PP_totalValue == 0.00 && ipayAdvLineWrap.PP_totalUnits == 0.00 && ipayAdvLineWrap.PayCode == null &&
                                   ipayAdvLineWrap.assignmentKey == null){
                                       List<PayCodeWrapper> listOfPayCodeWrappersSample = new List<PayCodeWrapper>();
                                       listOfPayCodeWrappersSample = mapOfPayCodeToPayCodeWrapper.values();
                                       mapOfPayCodeToPayCodeWrapper.remove('Employer Superannuation');
                                       listOfPayCodeWrappersGroup2 = mapOfPayCodeToPayCodeWrapper.values();
                                       
                                   }
                                else {
                                    listOfPayCodeWrappersGroup2 = mapOfPayCodeToPayCodeWrapper.values();
                                }
                            }
                        }
                        else {
                            listOfPayCodeWrappersGroup2 = mapOfPayCodeToPayCodeWrapper.values();
                        }
                    }
                    else {
                        listOfPayCodeWrappersGroup2 = mapOfPayCodeToPayCodeWrapper.values();
                    }
                }
                else {
                    if (mapOfPayCodeToPayCodeWrapper.containsKey(PAYCODE_NON_TAXABLE_PAYMENTS)) {
                        listOfPayCodeWrappersGroup1.add(mapOfPayCodeToPayCodeWrapper.get(PAYCODE_NON_TAXABLE_PAYMENTS));
                    }
                    if (mapOfPayCodeToPayCodeWrapper.containsKey(PAYCODE_TAXABLE_PAYMENTS)) {
                        listOfPayCodeWrappersGroup1.add(mapOfPayCodeToPayCodeWrapper.get(PAYCODE_TAXABLE_PAYMENTS));
                    }
                    if (mapOfPayCodeToPayCodeWrapper.containsKey(PAYCODE_PRE_TAX_DEDUCTIONS)) {
                        listOfPayCodeWrappersGroup2.add(mapOfPayCodeToPayCodeWrapper.get(PAYCODE_PRE_TAX_DEDUCTIONS));
                    }
                    if (mapOfPayCodeToPayCodeWrapper.containsKey(PAYCODE_PAYG)) {
                        listOfPayCodeWrappersGroup2.add(mapOfPayCodeToPayCodeWrapper.get(PAYCODE_PAYG));
                    }
                    if (mapOfPayCodeToPayCodeWrapper.containsKey(PAYCODE_POST_TAX_DEDUCTIONS)) {
                        listOfPayCodeWrappersGroup2.add(mapOfPayCodeToPayCodeWrapper.get(PAYCODE_POST_TAX_DEDUCTIONS));
                    }
                    
                    
                    //C9D-160
                    // if (mapOfPayCodeToPayCodeWrapper.containsKey(PAYCODE_EMPLOYER_SUPERANNUATION)) {
                    //      listOfPayCodeWrappersGroup2.add(mapOfPayCodeToPayCodeWrapper.get(PAYCODE_EMPLOYER_SUPERANNUATION));
                    // }
                    //C9D-174
                    // if (mapOfPayCodeToPayCodeWrapper.containsKey(PAYCODE_EXPENSE_REIMBURSEMENTS)) {
                    //     listOfPayCodeWrappersGroup2.add(mapOfPayCodeToPayCodeWrapper.get(PAYCODE_EXPENSE_REIMBURSEMENTS));
                    // }
                    if (mapOfPayCodeToPayCodeWrapper.containsKey(PAYCODE_GST)) {
                        listOfPayCodeWrappersGroup2.add(mapOfPayCodeToPayCodeWrapper.get(PAYCODE_GST));
                    }
                    
                    
                }
                //T07 - Ends
                listOfPayCodeWrappersGroup1.sort();
                listOfPayCodeWrappersGroup2.sort();
                System.debug('listOfPayCodeWrappersGroup1--->'+listOfPayCodeWrappersGroup1);
                System.debug('listOfPayCodeWrappersGroup2--->'+listOfPayCodeWrappersGroup2);
                for(PayCodeWrapper pcwrapper : listOfPayCodeWrappersGroup1) {
                    if(pcwrapper.mapOfRateToPayAdviceLinesWrapper != null && !pcwrapper.mapOfRateToPayAdviceLinesWrapper.isEmpty()){
                        pcwrapper.listOfPayAdviceLinesWrapper = pcwrapper.mapOfRateToPayAdviceLinesWrapper.values();
                        
                        //[C9D-153]
                        if(pcwrapper.payCode == 'Non-Taxable Payments') {
                            pcwrapper.payCodeTotalLabel = 'Total Non-Taxable Gross Amount:';
                            pcwrapper.payCodeYTDTotalLabel = 'YTD Non-Taxable Gross:';
                            pcwrapper.payCodeTotalValue = summaryNonTaxableGross != null ? summaryNonTaxableGross : 0.00;
                            pcwrapper.payCodeYTDTotalValue = summaryNonTaxableGross_YTD != null ? summaryNonTaxableGross_YTD : 0.00;
                            
                        } else if(pcwrapper.payCode == 'Taxable Payments') {
                            pcwrapper.payCodeTotalLabel = 'Taxable Gross Amount:';
                            pcwrapper.payCodeYTDTotalLabel = 'YTD Taxable Gross:';
                            pcwrapper.payCodeTotalValue = summaryTaxableGross != null ? summaryTaxableGross : 0.00;
                            pcwrapper.payCodeYTDTotalValue = summaryTaxableGross_YTD != null ? summaryTaxableGross_YTD : 0.00;
                        }
                        
                        System.debug('listOfPayAdviceLinesWrapper >>> ' + pcwrapper.listOfPayAdviceLinesWrapper);
                        setAssignmentGroupings(pcwrapper);
                        System.debug('mapOfAssignmentPayAdviceLinesWrapper >>> ' + pcwrapper.mapOfAssignmentPayAdviceLinesWrapper);
                    }
                }
                System.debug('listOfPayCodeWrappersGroup1 >>> ' +listOfPayCodeWrappersGroup1);
                
                for(PayCodeWrapper pcwrapper : listOfPayCodeWrappersGroup2){
                    if(pcwrapper.mapOfRateToPayAdviceLinesWrapper != null && !pcwrapper.mapOfRateToPayAdviceLinesWrapper.isEmpty()){
                        pcwrapper.listOfPayAdviceLinesWrapper = pcwrapper.mapOfRateToPayAdviceLinesWrapper.values();
                        
                        if(pcwrapper.payCode == 'Pre-Tax Deductions') {
                            pcwrapper.payCodeTotalLabel = 'Total Pre-Tax Deduction Amount:';
                            pcwrapper.payCodeYTDTotalLabel = 'YTD Pre-Tax Deduction:';
                            pcwrapper.payCodeTotalValue = summaryPreTaxDeduction != null ? summaryPreTaxDeduction : 0.00;
                            pcwrapper.payCodeYTDTotalValue = summaryPreTaxDeduction_YTD != null ? summaryPreTaxDeduction_YTD : 0.00;
                        } 
                        
                        System.debug('pcwrapper >>> ' + pcwrapper);
                        System.debug('listOfPayAdviceLinesWrapper >>> ' + pcwrapper.listOfPayAdviceLinesWrapper);
                        setAssignmentGroupings(pcwrapper);
                        System.debug('mapOfAssignmentPayAdviceLinesWrapper >>> ' + pcwrapper.mapOfAssignmentPayAdviceLinesWrapper);
                    }
                }
                System.debug('listOfPayCodeWrappersGroup2 >>> ' +listOfPayCodeWrappersGroup2);
                //System.debug('listOfPayCodeWrappers >>> ' + listOfPayCodeWrappers[3]);
            }
            
            setPayAdviceLinesDisplay(listOfPayCodeWrappersGroup1);
            
            //convert map to list and use the list in page
            if(!mapOfLeaveRuleNameToLeaveBalancesWrapper.isEmpty()){
                listOfLeaveBalancesWrappers = mapOfLeaveRuleNameToLeaveBalancesWrapper.values();
                listOfLeaveBalancesWrappers.sort();
                System.debug('listOfLeaveBalancesWrappers >>> ' + listOfLeaveBalancesWrappers);
            }
        }
    }
    
    public List<tc9_pr__Pay_Transaction__c> getLeaveTransactions() {
        List<tc9_pr__Pay_Transaction__c> leaveTns = [SELECT tc9_pr__Pay_Code__r.Name, tc9_pr__Quantity__c, tc9_pr__Payee_Leave_Event__r.tc9_pr__Start_Date__c, tc9_pr__Payee_Leave_Event__r.tc9_pr__End_Date__c
                                                     FROM tc9_pr__Pay_Transaction__c
                                                     WHERE tc9_pr__Pay_Advice__c = :payAdviceId
                                                     AND RecordType.DeveloperName = 'Payment'
                                                     AND tc9_pr__Payee_Leave_Event__c != NULL];
        return leaveTns;
    }
    
    public List<tc9_pr__Payee_Leave_Event__c> getTOILCreditEvents() {
        // ALN-512 - Surface TOIL leave credits on the pay advice.
        // PLE records of type 'Leave_Credit' are created by the TOIL conversion flow
        // but are not linked to a Pay Transaction, so they never appear via getLeaveTransactions().
        // We query them here by Payee + pay period date range.
        Date periodStart = payAdvice.tc9_pr__Period_Start_Date__c;
        Date periodEnd   = payAdvice.tc9_pr__Period_End_Date__c;
        
        // Fallback to Pay Batch calendar period if period dates not stamped on Pay Advice
        if (periodStart == null) {
            periodStart = payAdvice.tc9_pr__Pay_Batch__r.tc9_pr__Calendar_Period__r.tc9_pr__Start_Date__c;
        }
        if (periodEnd == null) {
            periodEnd = payAdvice.tc9_pr__Pay_Batch__r.tc9_pr__Calendar_Period__r.tc9_pr__End_Date__c;
        }
        
        return [
            SELECT  tc9_pr__Payee_Leave_Rule__r.tc9_pr__Leave_Rule__r.Name,
            tc9_pr__Hours__c,
            tc9_pr__Start_Date__c,
            tc9_pr__End_Date__c
            FROM    tc9_pr__Payee_Leave_Event__c
            WHERE   tc9_pr__Payee__c = :payAdvice.tc9_pr__Payee__c
            AND     RecordType.DeveloperName = 'Leave_Credit'
            AND     tc9_pr__Start_Date__c >= :periodStart
            AND     tc9_pr__Start_Date__c <= :periodEnd
            ORDER BY tc9_pr__Start_Date__c ASC
        ];
    }    
    
    //17/04/2025 NS-23
    private void loadPrimaryBranchLogo() {
        if(String.isBlank(payAdvice.Primary_Branch__c)) {
            foundLogo = false;
            return;
        }
        
        Set<Id> cdmIds = new Set<Id>();
        for(ContentDocumentLink contentDocLink : [SELECT Id, ContentDocumentId, ContentDocument.ContentSize,LinkedEntityId 
                                                  FROM ContentDocumentLink
                                                  WHERE LinkedEntityId = :payAdvice.Primary_Branch__c]) {
                                                      cdmIds.add(contentDocLink.ContentDocumentId);
                                                  }
        
        List<ContentVersion> contentVersions = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN: cdmIds AND FileType IN :IMAGE_FILE_TYPES ORDER BY CreatedDate DESC];
        
        if(!contentVersions.isEmpty()) {
            ContentVersion cv = contentVersions[0];
            logoId = cv.Id;
            foundLogo = true;
        } else {
            foundLogo = false;
        }
    }
    
    //T02 method to get logo from related payment entity
    // private void loadLogo(){
    //     tc9_pr__Pay_Advice_Template__c payAdviceTemplate = new tc9_pr__Pay_Advice_Template__c();
    //     for(tc9_pr__Pay_Advice_Template__c template : [SELECT Id FROM tc9_pr__Pay_Advice_Template__c WHERE  tc9_pr__Payment_Entity__c =: payAdvice.tc9_pr__Payment_Entity__c AND tc9_pr__Schedule__c =: payAdvice.tc9_pr__Pay_Batch__r.tc9_pr__Schedule__c ORDER BY CreatedDate DESC LIMIT 1]){
    //         payAdviceTemplate = template;
    //     }
    //     List<Id> linkedEntities = new List<Id>{payAdviceTemplate.Id,payAdvice.tc9_pr__Payment_Entity__c,payAdvice.tc9_pr__Pay_Advice_Template__c};
    //     Map<Id,String> documentToEntityTypeMap = new Map<Id,String>();
    //     List<ContentDocumentLink> contentDocLinks = [SELECT Id, ContentDocumentId, ContentDocument.ContentSize,LinkedEntityId FROM ContentDocumentLink
    //     WHERE LinkedEntityId IN: linkedEntities AND ContentDocument.Title LIKE '%logo%'];
    //     for(ContentDocumentLink contentDocLink : contentDocLinks){
    //         if(contentDocLink.LinkedEntityId.equals(payAdvice.tc9_pr__Payment_Entity__c)){
    //             documentToEntityTypeMap.put(contentDocLink.ContentDocumentId,'PaymentEntity');
    //         }
    //         else if(contentDocLink.LinkedEntityId.equals(payAdviceTemplate.Id)){
    //             documentToEntityTypeMap.put(contentDocLink.ContentDocumentId,'PayAdviceTemplate');
    //         }
    //         else if(contentDocLink.LinkedEntityId.equals(payAdvice.tc9_pr__Pay_Advice_Template__c)){
    //             documentToEntityTypeMap.put(contentDocLink.ContentDocumentId,'Primary PayAdviceTemplate');
    //         }
    //     }
    //     System.debug('documentToEntityTypeMap : ' + documentToEntityTypeMap);
    //     Id primaryTemplateLogoId;
    //     Id templateLogoId;
    //     Id peLogoId;
    //     List<ContentVersion> contentVersions = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN: documentToEntityTypeMap.keySet() ORDER BY CreatedDate DESC];
    //     for(ContentVersion contentVersion : contentVersions){
    //         if('Primary PayAdviceTemplate'.equals(documentToEntityTypeMap.get(contentVersion.ContentDocumentId))){
    //             primaryTemplateLogoId = contentVersion.Id;
    //             foundLogo = true;
    //         }
    //         if('PayAdviceTemplate'.equals(documentToEntityTypeMap.get(contentVersion.ContentDocumentId))){
    //             templateLogoId = contentVersion.Id;
    //             foundLogo = true;
    //         }
    //         if('PaymentEntity'.equals(documentToEntityTypeMap.get(contentVersion.ContentDocumentId))){
    //             peLogoId = contentVersion.Id;
    //             foundLogo = true;
    //         }
    //     }
    //     if(primaryTemplateLogoId != null) {
    //         logoId = primaryTemplateLogoId;
    //     } else if(templateLogoId != null) {
    //         logoId = templateLogoId;
    //     } else if(peLogoId != null) {
    //         logoId = peLogoId;
    //     } else {
    //         foundLogo = false;
    //     }
    // }
    
    //method to compute totals for different type of pay codes
    private void loadPayAdviceSection(){
        List<tc9_pr__Pay_Advice_Line__c> listOfPayAdviceLines = [SELECT Id, Name, tc9_pr__Classification__c, tc9_pr__Payee_Leave_Rule__c, tc9_pr__Payee_Leave_Rule__r.tc9_pr__Leave_Rule__r.tc9_pr__Display_on_Pay_Advice__c, tc9_pr__Payee_Leave_Rule__r.tc9_pr__Leave_Rule__r.Name, tc9_pr__Payee_Leave_Rule__r.tc9_pr__Leave_Rule__r.tc9_pr__Display_Leave_Balance_As__c,tc9_pr__Pay_Code__r.tc9_pr__Pay_Advice_Sort_Order__c,
                                                                 tc9_pr__Pay_Code__r.tc9_pr__PAYG_Tax_Exempt__c, tc9_pr__Pay_Code__r.RecordType.DeveloperName, tc9_pr__Current_Units__c, tc9_pr__Current_Value__c, tc9_pr__Pay_Code__r.tc9_pr__Pay_Advice_Description__c, tc9_pr__Pay_Advice__r.tc9_pr__GST__c, tc9_pr__Pay_Advice__r.RecordTypeId,tc9_pr__Leave_Balance_Days__c, tc9_pr__Leave_Balance_Hours__c, tc9_pr__Project_Code__r.tc9_pr__Pay_Advice_Description__c,
                                                                 tc9_pr__Prior_Units__c, tc9_pr__Prior_Value__c, tc9_pr__Rate__c, tc9_pr__YTD_Units__c, tc9_pr__YTD_Value__c, tc9_pr__Pay_Code__r.Name, tc9_pr__Display_Payee_Leave_Rule__c, tc9_pr__Assignment__c, tc9_pr__Assignment__r.tc9_pr__Assignment_Name__c, tc9_pr__Assignment__r.tc9_pr__Client__r.Name, tc9_pr__Pay_Code__r.tc9_pr__Deduction_Type__c, tc9_pr__Pay_Rate_Multiplier__c, tc9_pr__Leave_Rate_Multiplier__c,
                                                                 tc9_pr__Payee__c
                                                                 FROM tc9_pr__Pay_Advice_Line__c
                                                                 WHERE tc9_pr__Pay_Advice__c = :payAdviceId AND tc9_pr__Display_Pay_Code__c != 'No' ORDER BY tc9_pr__Pay_Code__r.tc9_pr__Pay_Advice_Sort_Order__c];
        
        //[C9D-153] start
        Set<Id> payeeIds = new Set<Id>();
        Set<Id> payCodes = new Set<Id>();
        
        for (tc9_pr__Pay_Advice_Line__c line : listOfPayAdviceLines) {
            payeeIds.add(line.tc9_pr__Payee__c);
            payCodes.add(line.tc9_pr__Pay_Code__c);
        }
        
        List<tc9_pr__Payee_Aggregate__c> payeeAggs = [SELECT Id,tc9_pr__YTD_Value__c, tc9_pr__YTD_Units__c, tc9_pr__Pay_Code__c, tc9_pr__Pay_Code__r.Name, tc9_pr__Pay_Code__r.tc9_pr__PAYG_Tax_Exempt__c, RecordType.DeveloperName 
                                                      FROM tc9_pr__Payee_Aggregate__c 
                                                      WHERE tc9_pr__Payee__c IN :payeeIds 
                                                      AND tc9_pr__Pay_Code__c IN :payCodes
                                                      ORDER BY CreatedDate DESC];
        
        payeeAggMap = new Map<String, tc9_pr__Payee_Aggregate__c>();
        
        for(tc9_pr__Payee_Aggregate__c pa : payeeAggs) {
            if(payeeAggMap.get(pa.tc9_pr__Pay_Code__c) == null) {
                payeeAggMap.put(pa.tc9_pr__Pay_Code__c, pa);
            } 
        }
        //[C9D-153] end
        
        //[NS-23] start
        List<tc9_pr__Pay_Transaction__c> trns = [SELECT Id, tc9_pr__Entry_Date__c, tc9_pr__Quantity__c, tc9_pr__Pay_Code__c, tc9_pr__Pay_Code__r.Name,tc9_pr__Assignment_Rate__c, tc9_pr__Pay_Total__c, tc9_pr__Pay_Rate__c,
                                                 tc9_pr__Pay_Advice__r.tc9_pr__Gross_Earnings__c, tc9_et__Timesheet_Entry__r.tc9_et__Start_Time__c, tc9_et__Timesheet_Entry__r.tc9_et__End_Time__c,
                                                 Shift__c, Shift__r.sirenum__Site__c, Shift__r.sirenum__Site__r.Name, Shift__r.tc9_ext_sirint__Award_Level__c, tc9_pr__Pay_Code__r.tc9_pr__Pay_Advice_Description__c,
                                                 Shift__r.tc9_ext_sirint__Award_Level__r.Name, Shift__r.sirenum__Location__c, Shift__r.sirenum__Location__r.Name, Shift__r.Minimum_Pay_rate__r.Award_Classification_Level_Name__c,
                                                 tc9_et__Timesheet_Entry__c, tc9_et__Timesheet_Item__c, OriginalTSEID__c, OriginalTSIID__c, tc9_et__Timesheet_Activity__c, tc9_pr__Project_Code__r.Name, tc9_pr__Project_Code__c,
                                                 RecordType.DeveloperName, tc9_pr__Project_Code__r.Display_on_Pay_Advice__c, Casual_Loading_Amount__c, Multiplied_Pay_Rate__c, tc9_et__Timesheet_Entry__r.tc9_et__Timesheet_Activity__r.Name,
                                                 tc9_et__Timesheet_Entry__r.tc9_et__Project_Code__r.Name
                                                 FROM tc9_pr__Pay_Transaction__c
                                                 WHERE tc9_pr__Payee__c IN :payeeIds 
                                                 AND tc9_pr__Pay_Code__c IN :payCodes
                                                 AND tc9_pr__Pay_Advice__c = :payAdviceId
                                                 ORDER BY CreatedDate DESC];
        
        transactionMap = new Map<String, tc9_pr__Pay_Transaction__c>();
        for(tc9_pr__Pay_Transaction__c trn : trns) {
            if(transactionMap.get(trn.tc9_pr__Pay_Code__c) == null) {
                transactionMap.put(trn.tc9_pr__Pay_Code__c, trn);
            }
        }
        
        for(tc9_pr__Pay_Advice_Line__c iPayAdviceLine : listOfPayAdviceLines){
            //non taxable payments
            if(iPayAdviceLine.tc9_pr__Pay_Code__r.tc9_pr__PAYG_Tax_Exempt__c == true && (iPayAdviceLine.tc9_pr__Pay_Code__r.RecordType.DeveloperName != PAYCODE_RECORD_TYPE_DEVELOPER_NAME_DEDUCTION && iPayAdviceLine.tc9_pr__Pay_Code__r.RecordType.DeveloperName != PAYCODE_RECORD_TYPE_DEVELOPER_NAME_EXPENSE)){
                consolidatePayCode(PAYCODE_NON_TAXABLE_PAYMENTS, iPayAdviceLine);
            }
            //C9D-174
            if(iPayAdviceLine.tc9_pr__Pay_Code__r.RecordType.DeveloperName == PAYCODE_RECORD_TYPE_DEVELOPER_NAME_EXPENSE) {
                consolidatePayCode(PAYCODE_NON_TAXABLE_PAYMENTS, iPayAdviceLine);
            }
            
            //taxable payments
            if(iPayAdviceLine.tc9_pr__Pay_Code__c!=null && iPayAdviceLine.tc9_pr__Pay_Code__r.tc9_pr__PAYG_Tax_Exempt__c == false && (iPayAdviceLine.tc9_pr__Pay_Code__r.RecordType.DeveloperName != PAYCODE_RECORD_TYPE_DEVELOPER_NAME_DEDUCTION && iPayAdviceLine.tc9_pr__Pay_Code__r.RecordType.DeveloperName != PAYCODE_RECORD_TYPE_DEVELOPER_NAME_EXPENSE)){
                System.debug('computing values for ' + PAYCODE_TAXABLE_PAYMENTS);
                //consolidatePayCode(iPayAdviceLine.tc9_pr__Pay_Code__r.Name, iPayAdviceLine);
                consolidatePayCode(PAYCODE_TAXABLE_PAYMENTS, iPayAdviceLine);
            }
            
            //Pre-Tax Deductions
            if(iPayAdviceLine.tc9_pr__Pay_Code__r.tc9_pr__Deduction_Type__c == DEDUCTION_PRE_TAX && iPayAdviceLine.tc9_pr__Pay_Code__r.RecordType.DeveloperName == PAYCODE_RECORD_TYPE_DEVELOPER_NAME_DEDUCTION){
                System.debug('computing values for ' + PAYCODE_PRE_TAX_DEDUCTIONS);
                consolidatePayCode(PAYCODE_PRE_TAX_DEDUCTIONS, iPayAdviceLine);
            }
            
            //PAYG - T09
            if((iPayAdviceLine.tc9_pr__Pay_Advice__r.RecordTypeId != GST_RECORDTYPE) && (iPayAdviceLine.tc9_pr__Classification__c == CLASSIFICATION_WITHHOLDING_PAYG || iPayAdviceLine.tc9_pr__Classification__c == CLASSIFICATION_WITHHOLDING_SFSS || iPayAdviceLine.tc9_pr__Classification__c == CLASSIFICATION_WITHHOLDING_ETP_PAYG || iPayAdviceLine.tc9_pr__Classification__c == CLASSIFICATION_WITHHOLDING_STSL || iPayAdviceLine.tc9_pr__Classification__c == CLASSIFICATION_WITHHOLDING_HELP)){
                System.debug('computing values for ' + PAYCODE_PAYG);
                consolidatePayCode(PAYCODE_PAYG, iPayAdviceLine);
            }
            
            //Post-Tax Deductions
            if(iPayAdviceLine.tc9_pr__Pay_Code__r.tc9_pr__Deduction_Type__c == DEDUCTION_POST_TAX && iPayAdviceLine.tc9_pr__Pay_Code__r.RecordType.DeveloperName == PAYCODE_RECORD_TYPE_DEVELOPER_NAME_DEDUCTION){
                System.debug('computing values for ' + PAYCODE_POST_TAX_DEDUCTIONS);
                consolidatePayCode(PAYCODE_POST_TAX_DEDUCTIONS, iPayAdviceLine);
            }
            
            //Employer Superannuation
            if(iPayAdviceLine.tc9_pr__Classification__c == CLASSIFICATION_WITHHOLDING_SUPERANNUATION){
                System.debug('computing values for ' + PAYCODE_EMPLOYER_SUPERANNUATION);
                consolidatePayCode(PAYCODE_EMPLOYER_SUPERANNUATION, iPayAdviceLine);
            }
            
            //C9D-174 comment out
            //Expenses Reimbursements
            // if(iPayAdviceLine.tc9_pr__Pay_Code__r.RecordType.DeveloperName == PAYCODE_RECORD_TYPE_DEVELOPER_NAME_EXPENSE){
            //     System.debug('computing values for ' + PAYCODE_EXPENSE_REIMBURSEMENTS);
            //     consolidatePayCode(PAYCODE_EXPENSE_REIMBURSEMENTS, iPayAdviceLine);
            // }
            
            //Leave Balance
            if(iPayAdviceLine.tc9_pr__Payee_Leave_Rule__c != null && iPayAdviceLine.tc9_pr__Display_Payee_Leave_Rule__c == 'Yes'){
                System.debug('computing values for ' + PAYCODE_LEAVE_BALANCES + ' ' + iPayAdviceLine);
                computeLeaveBalances(PAYCODE_LEAVE_BALANCES, iPayAdviceLine);
            }
            //GST - T07
            if(iPayAdviceLine.tc9_pr__Classification__c == CLASSIFICATION_WITHHOLDING_GST && iPayAdviceLine.tc9_pr__Pay_Advice__r.RecordTypeId == GST_RECORDTYPE){       //T08
                System.debug('computing values for ' + CLASSIFICATION_WITHHOLDING_GST);
                consolidatePayCode(PAYCODE_GST, iPayAdviceLine);
            }
        }
        //SC-34991 - Now that the lines have been calculated, handle any final summary calcs for summaryTaxableGross
        system.debug('summaryTaxableGross Before: ' + summaryTaxableGross);
        system.debug('summaryPreTaxDeduction: ' + summaryPreTaxDeduction);
        
        if(summaryPreTaxDeduction != null){
            if(summaryTaxableGross != null){
                summaryTaxableGross -= summaryPreTaxDeduction;
            } else {
                summaryTaxableGross = 0 - summaryPreTaxDeduction;
            }
        }
        
        if(summaryPreTaxDeduction_YTD != null){
            if(summaryTaxableGross_YTD != null){
                summaryTaxableGross_YTD -= summaryPreTaxDeduction_YTD;
            } else {
                summaryTaxableGross_YTD = 0-summaryPreTaxDeduction_YTD;
            }
        }
        system.debug('summaryTaxableGross After: ' + summaryTaxableGross);
    }
    
    //compute Net Pay Distribution
    private void computeNetPayDistribution(){
        Set<String> paymentFileLineCombos = new Set<String>();
        String combo;
        for(tc9_pr__Payment_File_Line__c iPaymentFileLine : [SELECT tc9_pr__Bank_Account_Name__c, tc9_pr__Bank_Account_Number__c, tc9_pr__Bank_Branch_Code__c, tc9_pr__Pay_Advice__c,
                                                             tc9_pr__Payment_Amount__c, tc9_pr__Payment_File__c FROM tc9_pr__Payment_File_Line__c WHERE tc9_pr__Pay_Advice__c = :payAdviceId]){
                                                                 if(iPaymentFileLine.tc9_pr__Bank_Account_Name__c != null && iPaymentFileLine.tc9_pr__Bank_Account_Number__c != null && iPaymentFileLine.tc9_pr__Bank_Branch_Code__c != null && iPaymentFileLine.tc9_pr__Payment_Amount__c != null) {
                                                                     combo = iPaymentFileLine.tc9_pr__Bank_Account_Name__c + iPaymentFileLine.tc9_pr__Bank_Account_Number__c + iPaymentFileLine.tc9_pr__Bank_Branch_Code__c + iPaymentFileLine.tc9_pr__Payment_Amount__c;
                                                                 }
                                                                 System.debug('combo ' + combo); //T11
                                                                 if(paymentFileLineCombos != null && paymentFileLineCombos.contains(combo)){
                                                                     continue;
                                                                 }
                                                                 PaymentFileLinesWrapper paymentFileLinesWrapper = new PaymentFileLinesWrapper();
                                                                 paymentFileLinesWrapper.bankAccountName = iPaymentFileLine.tc9_pr__Bank_Account_Name__c;
                                                                 if(iPaymentFileLine.tc9_pr__Bank_Account_Number__c != null && iPaymentFileLine.tc9_pr__Bank_Account_Number__c.length() > 4){
                                                                     paymentFileLinesWrapper.bankAccountNumber = maskCode + iPaymentFileLine.tc9_pr__Bank_Account_Number__c.substring(4);
                                                                 }else{
                                                                     paymentFileLinesWrapper.bankAccountNumber = maskCode;
                                                                 }
                                                                 paymentFileLinesWrapper.bankBranchCode = iPaymentFileLine.tc9_pr__Bank_Branch_Code__c;
                                                                 paymentFileLinesWrapper.paymentAmount = iPaymentFileLine.tc9_pr__Payment_Amount__c;
                                                                 listOfPaymentFileLinesWrapper.add(paymentFileLinesWrapper);
                                                                 paymentFileLineCombos.add(combo);
                                                             }
    }
    
    //Net YTD Summary
    private void computeNetYtdSummary(Id payAdvicePBI){
        if(summaryNet_YTD == null){ summaryNet_YTD = 0; }
        for(tc9_pr__Payee_Aggregate__c payeeAgg : [SELECT Id, tc9_pr__Pay_Code__c, tc9_pr__Pay_Code__r.tc9_pr__PAYG_Tax_Exempt__c, RecordType.DeveloperName, tc9_pr__YTD_Value__c FROM tc9_pr__Payee_Aggregate__c WHERE tc9_pr__Pay_Batch_Item__c =: payAdvicePBI AND RecordType.DeveloperName != 'Leave_Accrual' AND RecordType.DeveloperName != 'FBT' AND RecordType.DeveloperName != 'Withholding_Superannuation']){
            if(payeeAgg.RecordType.DeveloperName == 'Deduction' || payeeAgg.RecordType.DeveloperName == 'Withholding_PAYG' || payeeAgg.RecordType.DeveloperName == 'Withholding_ETP_PAYG' || payeeAgg.RecordType.DeveloperName == 'Withholding_STSL'){
                Decimal tempYTD = payeeAgg.tc9_pr__YTD_Value__c * -1;
                summaryNet_YTD += tempYTD.setScale(2);
            } else {
                summaryNet_YTD += payeeAgg.tc9_pr__YTD_Value__c.setScale(2);
            }
            System.debug('payeeAgg = ' + payeeAgg);
            //[C9D-153]
            if((payeeAgg.RecordType.DeveloperName == 'Allowance' 
                || payeeAgg.RecordType.DeveloperName == 'ETP' 
                //C9D-174[added record type expense check]
                || payeeAgg.RecordType.DeveloperName == 'Expense' 
                || payeeAgg.RecordType.DeveloperName == 'Lump_Sum'  
                || payeeAgg.RecordType.DeveloperName == 'Payment') 
               && (payeeAgg.tc9_pr__Pay_Code__c != null && payeeAgg.tc9_pr__Pay_Code__r.tc9_pr__PAYG_Tax_Exempt__c == true)){
                   if(summaryNonTaxableGross_YTD == null){
                       summaryNonTaxableGross_YTD = payeeAgg.tc9_pr__YTD_Value__c.setScale(2);
                   } else {
                       summaryNonTaxableGross_YTD += payeeAgg.tc9_pr__YTD_Value__c.setScale(2);
                   }
               }
        }
    }
    
    //compute Superannuation Distribution
    private void computeSuperannuationDistribution(){
        listOfSuperAnnuationFundIds = new List<Id>();
        List<AggregateResult> listOfSuperAnnuationAggregateResults = [SELECT tc9_pr__Pay_Batch_Event__r.tc9_pr__Payee_Withholding__r.tc9_pr__Superannuation_Fund__c fundId,
                                                                      tc9_pr__Pay_Batch_Event__r.tc9_pr__Payee_Withholding__r.tc9_pr__Super_Membership_Number__c memberNumber, SUM(tc9_pr__Superannuation_Guarantee__c) aggr
                                                                      FROM tc9_pr__Pay_Transaction__c
                                                                      WHERE tc9_pr__Pay_Advice__c = :payAdviceId AND RecordType.DeveloperName = :RECORD_TYPE_WITHHOLDING_SUPERANNUATION AND tc9_pr__Superannuation_Guarantee__c != NULL
                                                                      AND tc9_pr__Pay_Batch_Event__r.tc9_pr__Payee_Withholding__r.tc9_pr__Superannuation_Fund__c != NULL
                                                                      GROUP BY tc9_pr__Pay_Batch_Event__r.tc9_pr__Payee_Withholding__r.tc9_pr__Superannuation_Fund__c, tc9_pr__Pay_Batch_Event__r.tc9_pr__Payee_Withholding__r.tc9_pr__Super_Membership_Number__c];
        
        List<AggregateResult> listOfSuperAdditionalAggregateResults = [SELECT tc9_pr__Pay_Batch_Event__r.tc9_pr__Payee_Withholding__r.tc9_pr__Superannuation_Fund__c fundId,
                                                                       tc9_pr__Pay_Batch_Event__r.tc9_pr__Payee_Withholding__r.tc9_pr__Super_Membership_Number__c memberNumber, SUM(tc9_pr__Superannuation_Employer_Additional__c) aggr
                                                                       FROM tc9_pr__Pay_Transaction__c
                                                                       WHERE tc9_pr__Pay_Advice__c = :payAdviceId AND RecordType.DeveloperName = :RECORD_TYPE_WITHHOLDING_SUPERANNUATION AND tc9_pr__Superannuation_Guarantee__c != NULL
                                                                       AND tc9_pr__Superannuation_Employer_Additional__c != NULL
                                                                       AND tc9_pr__Pay_Batch_Event__r.tc9_pr__Payee_Withholding__r.tc9_pr__Superannuation_Fund__c != NULL
                                                                       GROUP BY tc9_pr__Pay_Batch_Event__r.tc9_pr__Payee_Withholding__r.tc9_pr__Superannuation_Fund__c, tc9_pr__Pay_Batch_Event__r.tc9_pr__Payee_Withholding__r.tc9_pr__Super_Membership_Number__c];
        
        List<AggregateResult> listOfPreTaxDeductionAggregateResults = [SELECT tc9_pr__Pay_Batch_Event__r.tc9_pr__Payee_Deduction_Record__r.tc9_pr__Pay_To_Withholding_Record__r.tc9_pr__Superannuation_Fund__c fundId,
                                                                       tc9_pr__Pay_Batch_Event__r.tc9_pr__Payee_Deduction_Record__r.tc9_pr__Pay_To_Withholding_Record__r.tc9_pr__Super_Membership_Number__c memberNumber, SUM(tc9_pr__Pre_Tax_Superannuation__c ) aggr
                                                                       FROM tc9_pr__Pay_Transaction__c
                                                                       WHERE tc9_pr__Pay_Advice__c = :payAdviceId AND RecordType.DeveloperName = :RECORD_TYPE_Deduction AND tc9_pr__Pre_Tax_Superannuation__c != NULL
                                                                       AND tc9_pr__Pay_Batch_Event__r.tc9_pr__Payee_Deduction_Record__r.tc9_pr__Pay_To_Withholding_Record__r.tc9_pr__Superannuation_Fund__c != NULL
                                                                       GROUP BY tc9_pr__Pay_Batch_Event__r.tc9_pr__Payee_Deduction_Record__r.tc9_pr__Pay_To_Withholding_Record__r.tc9_pr__Superannuation_Fund__c, tc9_pr__Pay_Batch_Event__r.tc9_pr__Payee_Deduction_Record__r.tc9_pr__Pay_To_Withholding_Record__r.tc9_pr__Super_Membership_Number__c];
        
        List<AggregateResult> listOfPostTaxDeductionAggregateResults = [SELECT tc9_pr__Pay_Batch_Event__r.tc9_pr__Payee_Deduction_Record__r.tc9_pr__Pay_To_Withholding_Record__r.tc9_pr__Superannuation_Fund__c fundId,
                                                                        tc9_pr__Pay_Batch_Event__r.tc9_pr__Payee_Deduction_Record__r.tc9_pr__Pay_To_Withholding_Record__r.tc9_pr__Super_Membership_Number__c memberNumber, SUM(tc9_pr__Post_Tax_Superannuation__c) aggr
                                                                        FROM tc9_pr__Pay_Transaction__c
                                                                        WHERE tc9_pr__Pay_Advice__c = :payAdviceId AND RecordType.DeveloperName = :RECORD_TYPE_Deduction AND tc9_pr__Post_Tax_Superannuation__c != NULL
                                                                        AND tc9_pr__Pay_Batch_Event__r.tc9_pr__Payee_Deduction_Record__r.tc9_pr__Pay_To_Withholding_Record__r.tc9_pr__Superannuation_Fund__c != NULL
                                                                        GROUP BY tc9_pr__Pay_Batch_Event__r.tc9_pr__Payee_Deduction_Record__r.tc9_pr__Pay_To_Withholding_Record__r.tc9_pr__Superannuation_Fund__c, tc9_pr__Pay_Batch_Event__r.tc9_pr__Payee_Deduction_Record__r.tc9_pr__Pay_To_Withholding_Record__r.tc9_pr__Super_Membership_Number__c];
        System.debug('listOfSuperAdditionalAggregateResults --'+listOfSuperAdditionalAggregateResults);
        if(!listOfSuperAdditionalAggregateResults.isEmpty()){
            consolidatePayTransaction(listOfSuperAdditionalAggregateResults);
        }
        if(!listOfSuperAnnuationAggregateResults.isEmpty()){
            consolidatePayTransaction(listOfSuperAnnuationAggregateResults);
        }
        if(!listOfPreTaxDeductionAggregateResults.isEmpty()){
            consolidatePayTransaction(listOfPreTaxDeductionAggregateResults);
        }
        if(!listOfPostTaxDeductionAggregateResults.isEmpty()){
            consolidatePayTransaction(listOfPostTaxDeductionAggregateResults);
        }
        
        //populate super annuation fund name based on id, name cannot be used in group by clause
        if(!listOfSuperAnnuationFundIds.isEmpty()){
            Map<Id, tc9_pr__Superannuation_Fund__c> mapOfSuperAnnuationFunds = new Map<Id, tc9_pr__Superannuation_Fund__c>([SELECT Id, Name, tc9_pr__Fund_Name__c FROM tc9_pr__Superannuation_Fund__c WHERE Id IN :listOfSuperAnnuationFundIds]);
            if(!listOfPayTransactionsWrapper.isEmpty()){
                //C9D-160
                // List<tc9_pr__Payee_Aggregate__c> relatedPayeeAggs = [SELECT Id, tc9_pr__YTD_Value__c, tc9_pr__Superannuation_Fund__c
                //                                                      FROM tc9_pr__Payee_Aggregate__c 
                //                                                      WHERE tc9_pr__Superannuation_Fund__c 
                //                                                      IN :mapOfSuperAnnuationFunds.keySet()
                //                                                      ORDER BY CreatedDate DESC];
                // Map<String, tc9_pr__Payee_Aggregate__c> payeeAggsMap = new Map<String, tc9_pr__Payee_Aggregate__c>();
                // for(tc9_pr__Payee_Aggregate__c pa : relatedPayeeAggs) {
                //     if(payeeAggsMap.get(pa.tc9_pr__Superannuation_Fund__c) == null) {
                //         payeeAggsMap.put(pa.tc9_pr__Superannuation_Fund__c, pa);
                //     }
                // }
                
                List<tc9_pr__Pay_Advice_Line__c> payAdvice = [SELECT Id, tc9_pr__Superannuation_Fund__c, tc9_pr__YTD_Value__c 
                                                              FROM tc9_pr__Pay_Advice_Line__c 
                                                              WHERE tc9_pr__Superannuation_Fund__c 
                                                              IN :mapOfSuperAnnuationFunds.keySet() 
                                                              AND tc9_pr__Pay_Advice__c = :payAdviceId];
                Map<String, Decimal> ytdMap = new Map<String, Decimal>();
                for(tc9_pr__Pay_Advice_Line__c pa : payAdvice) {
                    if(ytdMap.containsKey(pa.tc9_pr__Superannuation_Fund__c)) {
                        ytdMap.put(pa.tc9_pr__Superannuation_Fund__c, ytdMap.get(pa.tc9_pr__Superannuation_Fund__c) + pa.tc9_pr__YTD_Value__c);
                    } else {
                        ytdMap.put(pa.tc9_pr__Superannuation_Fund__c, pa.tc9_pr__YTD_Value__c);
                    }
                }
                
                for(PayTransactionsWrapper ptWrapper : listOfPayTransactionsWrapper){
                    //C9D-160
                    ptWrapper.ytdAmount = ytdMap.containsKey(ptWrapper.fundId) ? ytdMap.get(ptWrapper.fundId) : null;
                    ptWrapper.fundName = mapOfSuperAnnuationFunds.containsKey(ptWrapper.fundId) ? mapOfSuperAnnuationFunds.get(ptWrapper.fundId).tc9_pr__Fund_Name__c : '';
                }
            }
        }
        
    }
    
    private void consolidatePayTransaction(List<AggregateResult> listOfAggregateResults){
        for(AggregateResult ar : listOfAggregateResults){
            PayTransactionsWrapper ptWrapper = new PayTransactionsWrapper();
            ptWrapper.fundId = String.valueOf(ar.get('fundId'));
            listOfSuperAnnuationFundIds.add(ptWrapper.fundId);
            ptWrapper.memberNumber = ar.get('memberNumber') != NULL ? String.valueOf(ar.get('memberNumber')) : '';
            ptWrapper.amount = Decimal.valueOf(String.valueOf(ar.get('aggr')));
            if(ptWrapper.amount == null){
                ptWrapper.amount = 0.00;
            }else{
                ptWrapper.amount = ptWrapper.amount.setScale(2);
            }
            listOfPayTransactionsWrapper.add(ptWrapper);
        }
    }
    
    //method to compute leave balances
    private void computeLeaveBalances(String payCodeName, tc9_pr__Pay_Advice_Line__c iPayAdviceLine){
        System.debug('computing values for ' + PAYCODE_LEAVE_BALANCES);
        if(iPayAdviceLine.tc9_pr__Payee_Leave_Rule__r.tc9_pr__Leave_Rule__r.Name != null && !mapOfLeaveRuleNameToLeaveBalancesWrapper.containsKey(iPayAdviceLine.tc9_pr__Payee_Leave_Rule__r.tc9_pr__Leave_Rule__r.Name)){
            LeaveBalancesWrapper lbw = new LeaveBalancesWrapper();
            lbw.leaveRuleName = iPayAdviceLine.tc9_pr__Payee_Leave_Rule__r.tc9_pr__Leave_Rule__r.Name;
            if(iPayAdviceLine.tc9_pr__Payee_Leave_Rule__r.tc9_pr__Leave_Rule__r.tc9_pr__Display_Leave_Balance_As__c != null){
                if(iPayAdviceLine.tc9_pr__Payee_Leave_Rule__r.tc9_pr__Leave_Rule__r.tc9_pr__Display_Leave_Balance_As__c.contains('Hours'))
                    lbw.balanceHours = iPayAdviceLine.tc9_pr__Leave_Balance_Hours__c != null ? iPayAdviceLine.tc9_pr__Leave_Balance_Hours__c  : 0;
                if(iPayAdviceLine.tc9_pr__Payee_Leave_Rule__r.tc9_pr__Leave_Rule__r.tc9_pr__Display_Leave_Balance_As__c.contains('Days'))
                    lbw.balanceDays = iPayAdviceLine.tc9_pr__Leave_Balance_Days__c != null ? iPayAdviceLine.tc9_pr__Leave_Balance_Days__c  : 0;
            }
            mapOfLeaveRuleNameToLeaveBalancesWrapper.put(iPayAdviceLine.tc9_pr__Payee_Leave_Rule__r.tc9_pr__Leave_Rule__r.Name, lbw);
        }
    }
    
    //generic method to create map of pay code to wrapper class
    private void consolidatePayCode(String payCodeName, tc9_pr__Pay_Advice_Line__c iPayAdviceLine){
        PayCodeWrapper pcWrapper;
        if(mapOfPayCodeToPayCodeWrapper.containsKey(payCodeName)){
            System.debug('wrapper exists for pay code ' + payCodeName);
            pcWrapper = mapOfPayCodeToPayCodeWrapper.get(payCodeName);
            computePayAdviceLines(pcWrapper, iPayAdviceLine);
        }
        else{
            System.debug('creating new wrapper for pay code ' + payCodeName);
            pcWrapper = new PayCodeWrapper();
            pcWrapper.payCode = payCodeName;
            
            
            
            pcWrapper.sortOrder = mapOfPayCodeToSortOrder.get(payCodeName);
            pcWrapper.mapOfRateToPayAdviceLinesWrapper = new Map<String, PayAdviceLinesWrapper>();
            mapOfPayCodeToPayCodeWrapper.put(payCodeName, pcWrapper);
            System.debug('paycodeWrapper' + mapOfPayCodeToPayCodeWrapper);
            computePayAdviceLines(pcWrapper, iPayAdviceLine);
        }
    }
    
    //generic method to compute total from pay advice lines based on rate
    private void computePayAdviceLines(PayCodeWrapper pcWrapper, tc9_pr__Pay_Advice_Line__c iPayAdviceLine){
        System.debug('before updating map >>> ' + pcWrapper.mapOfRateToPayAdviceLinesWrapper);
        String rate = '';
        
        if(iPayAdviceLine.tc9_pr__Leave_Rate_Multiplier__c != null) {
            leaveMultiplier = iPayAdviceLine.tc9_pr__Leave_Rate_Multiplier__c;
        }
        rate = iPayAdviceLine.tc9_pr__Rate__c != null ? String.valueOf(iPayAdviceLine.tc9_pr__Rate__c * leaveMultiplier) : iPayAdviceLine.tc9_pr__Classification__c;
        String uniqueKey = rate;
        if(iPayAdviceLine.tc9_pr__Pay_Code__c != null){
            uniqueKey += iPayAdviceLine.tc9_pr__Pay_Code__c; //T11
        }
        if(iPayAdviceLine.tc9_pr__Assignment__c != null){
            uniqueKey += iPayAdviceLine.tc9_pr__Assignment__c;
            if(isProjCodePayAdvice) {
                uniqueKey += iPayAdviceLine.tc9_pr__Project_Code__c;
            }
        }
        System.debug('Unique Key for Wrapper ' + uniqueKey);
        if(iPayAdviceLine.tc9_pr__Pay_Rate_Multiplier__c != null) {
            multiplier = iPayAdviceLine.tc9_pr__Pay_Rate_Multiplier__c;
        }
        
        if(pcWrapper.mapOfRateToPayAdviceLinesWrapper.containsKey(uniqueKey) && pcWrapper.mapOfRateToPayAdviceLinesWrapper.get(uniqueKey) != null){
            System.debug('wrapper exists for PayCode Id' + iPayAdviceLine.tc9_pr__Pay_Code__r.Id);
            System.debug('wrapper exists for PayCode ' + iPayAdviceLine.tc9_pr__Pay_Code__r.Name);
            PayAdviceLinesWrapper palWrapper = pcWrapper.mapOfRateToPayAdviceLinesWrapper.get(uniqueKey);
            tc9_pr__Pay_Transaction__c trn = transactionMap.get(iPayAdviceLine.tc9_pr__Pay_Code__c);
            
            if(trn != null && trn.tc9_et__Timesheet_Entry__r != null){
                
                palWrapper.timesheetActivityName = trn.tc9_et__Timesheet_Entry__r?.tc9_et__Timesheet_Activity__r?.Name;
                palWrapper.projectCodeName = trn.tc9_et__Timesheet_Entry__r?.tc9_et__Project_Code__r?.Name;
            }
            palWrapper.rate = iPayAdviceLine.tc9_pr__Rate__c != null ? (iPayAdviceLine.tc9_pr__Rate__c * multiplier * leaveMultiplier).setScale(5) : 0.00;
            palWrapper.CP_totalValue += iPayAdviceLine.tc9_pr__Current_Value__c != null ? iPayAdviceLine.tc9_pr__Current_Value__c.setScale(2) : 0.00;
            palWrapper.PP_totalValue += iPayAdviceLine.tc9_pr__Prior_Value__c != null ? iPayAdviceLine.tc9_pr__Prior_Value__c.setScale(2) : 0.00;
            palWrapper.YTD_totalValue += iPayAdviceLine.tc9_pr__YTD_Value__c != null ? iPayAdviceLine.tc9_pr__YTD_Value__c.setScale(2) : 0.00;
            
            palWrapper.currentPlusPriorValue += (iPayAdviceLine.tc9_pr__Current_Value__c != null ? iPayAdviceLine.tc9_pr__Current_Value__c.setScale(2) : 0.00) + (iPayAdviceLine.tc9_pr__Prior_Value__c != null ? iPayAdviceLine.tc9_pr__Prior_Value__c.setScale(2) : 0.00);
            palWrapper.TP_TotalUnits = payeeAggMap.get(iPayAdviceLine.tc9_pr__Pay_Code__c)?.tc9_pr__YTD_Units__c != null ? payeeAggMap.get(iPayAdviceLine.tc9_pr__Pay_Code__c).tc9_pr__YTD_Units__c.setScale(2) : 0.00;
            palWrapper.shiftDate = transactionMap.get(iPayAdviceLine.tc9_pr__Pay_Code__c)?.tc9_pr__Entry_Date__c != null ? transactionMap.get(iPayAdviceLine.tc9_pr__Pay_Code__c).tc9_pr__Entry_Date__c : null;
            palWrapper.casualLoadingAmount = transactionMap.get(iPayAdviceLine.tc9_pr__Pay_Code__c)?.Casual_Loading_Amount__c != null ? transactionMap.get(iPayAdviceLine.tc9_pr__Pay_Code__c).Casual_Loading_Amount__c : null;
            palWrapper.rateExclCasualLoading = transactionMap.get(iPayAdviceLine.tc9_pr__Pay_Code__c)?.Multiplied_Pay_Rate__c != null ? transactionMap.get(iPayAdviceLine.tc9_pr__Pay_Code__c).Multiplied_Pay_Rate__c : null;
            
            if(iPayAdviceLine.tc9_pr__Classification__c == CLASSIFICATION_WITHHOLDING_PAYG || iPayAdviceLine.tc9_pr__Classification__c == CLASSIFICATION_WITHHOLDING_HELP || iPayAdviceLine.tc9_pr__Classification__c == CLASSIFICATION_WITHHOLDING_SFSS || iPayAdviceLine.tc9_pr__Classification__c == CLASSIFICATION_WITHHOLDING_ETP_PAYG || iPayAdviceLine.tc9_pr__Classification__c == CLASSIFICATION_WITHHOLDING_STSL || iPayAdviceLine.tc9_pr__Classification__c == CLASSIFICATION_WITHHOLDING_GST || iPayAdviceLine.tc9_pr__Classification__c == CLASSIFICATION_WITHHOLDING_SUPERANNUATION){
                palWrapper.PayCode = iPayAdviceLine.tc9_pr__Classification__c.replace('Withholding - ', '');
                palWrapper.CP_totalUnits = 0;
                palWrapper.PP_totalUnits = 0;
                
            }
            else{
                palWrapper.PayCode = iPayAdviceLine.tc9_pr__Pay_Code__r.tc9_pr__Pay_Advice_Description__c;
                palWrapper.CP_totalUnits += iPayAdviceLine.tc9_pr__Current_Units__c != null ? iPayAdviceLine.tc9_pr__Current_Units__c.setScale(5): 0.00;
                palWrapper.PP_totalUnits += iPayAdviceLine.tc9_pr__Prior_Units__c != null ? iPayAdviceLine.tc9_pr__Prior_Units__c.setScale(5) : 0.00;
            }
            
            if(iPayAdviceLine.tc9_pr__Assignment__c != null){
                if(isAssignmentPayAdvice || (isProjCodePayAdvice && iPayAdviceLine.tc9_pr__Project_Code__r.tc9_pr__Pay_Advice_Description__c == null)){
                    palWrapper.assignmentKey = iPayAdviceLine.tc9_pr__Assignment__r.tc9_pr__Assignment_Name__c + ' - ' + iPayAdviceLine.tc9_pr__Assignment__r.tc9_pr__Client__r.Name;
                }else if(isProjCodePayAdvice && iPayAdviceLine.tc9_pr__Project_Code__r.tc9_pr__Pay_Advice_Description__c != null){
                    palWrapper.assignmentKey = iPayAdviceLine.tc9_pr__Assignment__r.tc9_pr__Assignment_Name__c + ' - ' + iPayAdviceLine.tc9_pr__Assignment__r.tc9_pr__Client__r.Name + ' (' + iPayAdviceLine.tc9_pr__Project_Code__r.tc9_pr__Pay_Advice_Description__c +')';
                }
            }
        } else{
            System.debug('creating new wrapper for rate ' + iPayAdviceLine.tc9_pr__Rate__c);
            PayAdviceLinesWrapper palWrapper = new PayAdviceLinesWrapper();
            
            tc9_pr__Pay_Transaction__c trn = transactionMap.get(iPayAdviceLine.tc9_pr__Pay_Code__c);
            if(trn != null && trn.tc9_et__Timesheet_Entry__r != null){
                
                palWrapper.timesheetActivityName = trn.tc9_et__Timesheet_Entry__r?.tc9_et__Timesheet_Activity__r?.Name;
                palWrapper.projectCodeName = trn.tc9_et__Timesheet_Entry__r?.tc9_et__Project_Code__r?.Name;
            }
            
            palWrapper.rate = iPayAdviceLine.tc9_pr__Rate__c != null ? (iPayAdviceLine.tc9_pr__Rate__c  * multiplier * leaveMultiplier).setScale(5) : 0.00;
            palWrapper.CP_totalValue = iPayAdviceLine.tc9_pr__Current_Value__c != null ? iPayAdviceLine.tc9_pr__Current_Value__c.setScale(2) : 0.00;
            palWrapper.PP_totalValue = iPayAdviceLine.tc9_pr__Prior_Value__c != null ? iPayAdviceLine.tc9_pr__Prior_Value__c.setScale(2) : 0.00;
            palWrapper.YTD_totalValue = iPayAdviceLine.tc9_pr__YTD_Value__c != null ? iPayAdviceLine.tc9_pr__YTD_Value__c.setScale(2) : 0.00;
            
            palWrapper.currentPlusPriorValue = (iPayAdviceLine.tc9_pr__Current_Value__c != null ? iPayAdviceLine.tc9_pr__Current_Value__c.setScale(2) : 0.00) + (iPayAdviceLine.tc9_pr__Prior_Value__c != null ? iPayAdviceLine.tc9_pr__Prior_Value__c.setScale(2) : 0.00);
            palWrapper.TP_TotalUnits = payeeAggMap.get(iPayAdviceLine.tc9_pr__Pay_Code__c)?.tc9_pr__YTD_Units__c != null ? payeeAggMap.get(iPayAdviceLine.tc9_pr__Pay_Code__c).tc9_pr__YTD_Units__c.setScale(2) : 0.00;
            palWrapper.shiftDate = transactionMap.get(iPayAdviceLine.tc9_pr__Pay_Code__c)?.tc9_pr__Entry_Date__c != null ? transactionMap.get(iPayAdviceLine.tc9_pr__Pay_Code__c).tc9_pr__Entry_Date__c : null;
            palWrapper.casualLoadingAmount = transactionMap.get(iPayAdviceLine.tc9_pr__Pay_Code__c)?.Casual_Loading_Amount__c != null ? transactionMap.get(iPayAdviceLine.tc9_pr__Pay_Code__c).Casual_Loading_Amount__c : null;
            palWrapper.rateExclCasualLoading = transactionMap.get(iPayAdviceLine.tc9_pr__Pay_Code__c)?.Multiplied_Pay_Rate__c != null ? transactionMap.get(iPayAdviceLine.tc9_pr__Pay_Code__c).Multiplied_Pay_Rate__c : null;
            
            if(iPayAdviceLine.tc9_pr__Classification__c == CLASSIFICATION_WITHHOLDING_PAYG || iPayAdviceLine.tc9_pr__Classification__c == CLASSIFICATION_WITHHOLDING_HELP || iPayAdviceLine.tc9_pr__Classification__c == CLASSIFICATION_WITHHOLDING_SFSS || iPayAdviceLine.tc9_pr__Classification__c == CLASSIFICATION_WITHHOLDING_ETP_PAYG || iPayAdviceLine.tc9_pr__Classification__c == CLASSIFICATION_WITHHOLDING_STSL || iPayAdviceLine.tc9_pr__Classification__c == CLASSIFICATION_WITHHOLDING_GST || iPayAdviceLine.tc9_pr__Classification__c == CLASSIFICATION_WITHHOLDING_SUPERANNUATION){
                palWrapper.PayCode = iPayAdviceLine.tc9_pr__Classification__c.replace('Withholding - ', '');
                palWrapper.CP_totalUnits = 0;
                palWrapper.PP_totalUnits = 0;
                
            }
            else{
                palWrapper.PayCode = iPayAdviceLine.tc9_pr__Pay_Code__r.tc9_pr__Pay_Advice_Description__c;
                palWrapper.CP_totalUnits = iPayAdviceLine.tc9_pr__Current_Units__c != null ? iPayAdviceLine.tc9_pr__Current_Units__c.setScale(5) : 0.00;
                palWrapper.PP_totalUnits = iPayAdviceLine.tc9_pr__Prior_Units__c != null ? iPayAdviceLine.tc9_pr__Prior_Units__c.setScale(5) : 0.00;
            }
            
            if(iPayAdviceLine.tc9_pr__Assignment__c != null){
                if(isAssignmentPayAdvice || (isProjCodePayAdvice && iPayAdviceLine.tc9_pr__Project_Code__r.tc9_pr__Pay_Advice_Description__c == null)) {
                    palWrapper.assignmentKey = iPayAdviceLine.tc9_pr__Assignment__r.tc9_pr__Assignment_Name__c + ' - ' + iPayAdviceLine.tc9_pr__Assignment__r.tc9_pr__Client__r.Name;
                } else if(isProjCodePayAdvice && iPayAdviceLine.tc9_pr__Project_Code__r.tc9_pr__Pay_Advice_Description__c != null) {
                    palWrapper.assignmentKey = iPayAdviceLine.tc9_pr__Assignment__r.tc9_pr__Assignment_Name__c + ' - ' + iPayAdviceLine.tc9_pr__Assignment__r.tc9_pr__Client__r.Name + ' (' + iPayAdviceLine.tc9_pr__Project_Code__r.tc9_pr__Pay_Advice_Description__c + ')';
                }
            }
            //handle our Summary values now if they apply
            if(palWrapper.currentPlusPriorValue != null && palWrapper.YTD_totalValue != null
               && iPayAdviceLine.tc9_pr__Classification__c != null
               && (iPayAdviceLine.tc9_pr__Classification__c == 'Allowance'
                   || iPayAdviceLine.tc9_pr__Classification__c == 'ETP'
                   || iPayAdviceLine.tc9_pr__Classification__c == 'Lump Sum'
                   || iPayAdviceLine.tc9_pr__Classification__c == 'Payment')){
                       
                       
                       if(summaryGross == null){
                           summaryGross = palWrapper.currentPlusPriorValue;
                       } else {
                           summaryGross += palWrapper.currentPlusPriorValue;
                       }
                       if(summaryGross_YTD == null){
                           summaryGross_YTD = palWrapper.YTD_totalValue;
                       } else {
                           summaryGross_YTD += palWrapper.YTD_totalValue;
                       }
                       
                       //[C9D-153]
                       if(iPayAdviceLine.tc9_pr__Pay_Code__c != null && iPayAdviceLine.tc9_pr__Pay_Code__r.tc9_pr__PAYG_Tax_Exempt__c == true) {
                           if(summaryNonTaxableGross == null){
                               summaryNonTaxableGross = palWrapper.currentPlusPriorValue;
                               
                           } else {
                               summaryNonTaxableGross += palWrapper.currentPlusPriorValue;
                           }
                       }
                   }
            
            if(palWrapper.currentPlusPriorValue != null && palWrapper.YTD_totalValue != null
               && iPayAdviceLine.tc9_pr__Classification__c != null && iPayAdviceLine.tc9_pr__Classification__c == 'Deduction'
               && iPayAdviceLine.tc9_pr__Pay_Code__c != null && iPayAdviceLine.tc9_pr__Pay_Code__r.tc9_pr__Deduction_Type__c == 'Pre-tax Deduction'){
                   if(summaryPreTaxDeduction == null){
                       summaryPreTaxDeduction = palWrapper.currentPlusPriorValue;
                   } else {
                       summaryPreTaxDeduction += palWrapper.currentPlusPriorValue;
                   }
                   if(summaryPreTaxDeduction_YTD == null){
                       summaryPreTaxDeduction_YTD = palWrapper.YTD_totalValue;
                   } else {
                       summaryPreTaxDeduction_YTD += palWrapper.YTD_totalValue;
                   }
               }
            
            if(palWrapper.currentPlusPriorValue != null && palWrapper.YTD_totalValue != null
               && iPayAdviceLine.tc9_pr__Classification__c != null
               && (iPayAdviceLine.tc9_pr__Classification__c == 'Allowance'
                   || iPayAdviceLine.tc9_pr__Classification__c == 'ETP'
                   || iPayAdviceLine.tc9_pr__Classification__c == 'Lump Sum'
                   || iPayAdviceLine.tc9_pr__Classification__c == 'Payment')
               && iPayAdviceLine.tc9_pr__Pay_Code__c != null
               && !iPayAdviceLine.tc9_pr__Pay_Code__r.tc9_pr__PAYG_Tax_Exempt__c){
                   if(summaryTaxableGross == null){
                       summaryTaxableGross = palWrapper.currentPlusPriorValue;
                   } else {
                       summaryTaxableGross += palWrapper.currentPlusPriorValue;
                   }
                   
                   if(!paycodeSetTaxableGross.contains(iPayAdviceLine.tc9_pr__Pay_Code__c)){
                       
                       if(summaryTaxableGross_YTD == null){
                           summaryTaxableGross_YTD = palWrapper.YTD_totalValue;
                       } else {
                           summaryTaxableGross_YTD+= (palWrapper.YTD_totalValue != null ? palWrapper.YTD_totalValue : 0.00);
                       }
                       paycodeSetTaxableGross.add(iPayAdviceLine.tc9_pr__Pay_Code__c);
                   }
               }
            
            
            if(palWrapper.currentPlusPriorValue != null && palWrapper.YTD_totalValue != null
               && iPayAdviceLine.tc9_pr__Classification__c != null && iPayAdviceLine.tc9_pr__Classification__c == 'Deduction'
               && iPayAdviceLine.tc9_pr__Pay_Code__c != null && iPayAdviceLine.tc9_pr__Pay_Code__r.tc9_pr__Deduction_Type__c == 'Post-tax Deduction'){
                   if(summaryPostTaxDeduction == null){
                       summaryPostTaxDeduction = palWrapper.currentPlusPriorValue;
                   } else {
                       summaryPostTaxDeduction += palWrapper.currentPlusPriorValue;
                   }
                   if(summaryPostTaxDeduction_YTD == null){
                       summaryPostTaxDeduction_YTD = palWrapper.YTD_totalValue;
                   } else {
                       summaryPostTaxDeduction_YTD += palWrapper.YTD_totalValue;
                   }
               }
            
            if(palWrapper.currentPlusPriorValue != null && palWrapper.YTD_totalValue != null
               && iPayAdviceLine.tc9_pr__Classification__c != null
               && (iPayAdviceLine.tc9_pr__Classification__c == 'Withholding - PAYG'
                   || iPayAdviceLine.tc9_pr__Classification__c == 'Withholding - STSL'
                   || iPayAdviceLine.tc9_pr__Classification__c == 'Withholding - EFP - PAYG')){
                       if(summaryPAYG == null){
                           summaryPAYG = palWrapper.currentPlusPriorValue;
                       } else {
                           summaryPAYG += palWrapper.currentPlusPriorValue;
                       }
                       if(summaryPAYG_YTD == null){
                           summaryPAYG_YTD = palWrapper.YTD_totalValue;
                       } else {
                           summaryPAYG_YTD += palWrapper.YTD_totalValue;
                       }
                   }
            
            if(palWrapper.currentPlusPriorValue != null && palWrapper.YTD_totalValue != null
               && iPayAdviceLine.tc9_pr__Classification__c != null && iPayAdviceLine.tc9_pr__Classification__c == 'Expense'){
                   if(summaryExpenses == null){
                       summaryExpenses = palWrapper.currentPlusPriorValue;
                   } else {
                       summaryExpenses += palWrapper.currentPlusPriorValue;
                   }
                   if(summaryExpenses_YTD == null){
                       summaryExpenses_YTD = palWrapper.YTD_totalValue;
                   } else {
                       summaryExpenses_YTD += palWrapper.YTD_totalValue;
                   }
               }
            
            if(palWrapper.currentPlusPriorValue != null && palWrapper.YTD_totalValue != null
               && iPayAdviceLine.tc9_pr__Classification__c != null && iPayAdviceLine.tc9_pr__Classification__c == 'Withholding - Superannuation'){
                   if(summarySuper == null){
                       summarySuper = palWrapper.currentPlusPriorValue;
                   } else {
                       summarySuper += palWrapper.currentPlusPriorValue;
                   }
                   if(summarySuper_YTD == null){
                       summarySuper_YTD = palWrapper.YTD_totalValue;
                   } else {
                       summarySuper_YTD += palWrapper.YTD_totalValue;
                   }
               }
            
            //before we add to the pcWrapper lets check if we have values to show for current and/or prior, if not then don't add!
            //            if((palWrapper.CP_totalUnits != null && palWrapper.CP_totalUnits > 0 && palWrapper.CP_totalValue != null && palWrapper.CP_totalValue > 0 )
            //                || (palWrapper.PP_totalUnits != null && palWrapper.PP_totalUnits > 0  && palWrapper.PP_totalValue != null && palWrapper.PP_totalValue > 0 )){
            //                pcWrapper.mapOfRateToPayAdviceLinesWrapper.put(uniqueKey, palWrapper);
            //            }
            
            //SC-35538 - handle currentPlusPriorValue rendering on the page itself - so long as we don't have null its up for consideration
            //            if(palWrapper.currentPlusPriorValue != null && palWrapper.currentPlusPriorValue != 0 ){
            //<!--                            <div style="{!IF(OR(payAdviceLineWrapper.CP_totalUnits!=0.00,payAdviceLineWrapper.CP_totalValue!=0.00,payAdviceLineWrapper.PP_totalUnits!=0.00,payAdviceLineWrapper.PP_totalValue!=0.00, payAdviceLineWrapper.currentPlusPriorValue!=0.00), 'display:block;', 'display:none;')}">-->
            if(palWrapper.currentPlusPriorValue != null &&
               (palWrapper.CP_totalUnits!=0.00 || palWrapper.CP_totalValue!=0.00 || palWrapper.PP_totalUnits!=0.00 || palWrapper.PP_totalValue!=0.00 || palWrapper.currentPlusPriorValue!=0.00)){
                   pcWrapper.mapOfRateToPayAdviceLinesWrapper.put(uniqueKey, palWrapper);
               }
            
            //C9D-160
            // if(pcWrapper.payCode == 'PAYG Withholding') {
            //     palWrapper.currentPlusPriorValue = summaryPAYG_YTD;
            // }
            // if(pcWrapper.payCode == 'PAYG Withholding') {
            //     palWrapper.currentPlusPriorValue = palWrapper.YTD_totalValue;
            // }
            // if(pcWrapper.payCode == 'Post-Tax Deductions') {
            //     palWrapper.currentPlusPriorValue = palWrapper.TP_TotalUnits * palWrapper.CP_totalValue;
            // }
        }
        
        System.debug('after updating map >>> ' + pcWrapper.mapOfRateToPayAdviceLinesWrapper);
    }
    
    
    private void setAssignmentGroupings(PayCodeWrapper pcwrapper){
        List<PayAdviceLinesWrapper> listOfPayAdviceLinesWrapper = pcwrapper.listOfPayAdviceLinesWrapper;
        Map<String, List<PayAdviceLinesWrapper>> mapOfAssignmentToPalWrapper = new Map<String, List<PayAdviceLinesWrapper>>();
        if(isAssignmentPayAdvice || isProjCodePayAdvice){
            for(PayAdviceLinesWrapper palWrapper : listOfPayAdviceLinesWrapper){
                String uniqueKey = palWrapper.assignmentKey;
                if(uniqueKey == null) {
                    uniqueKey = 'Default'; // Using a default key here because, a map with null key will not be rendered properly
                }
                if(mapOfAssignmentToPalWrapper.containsKey(uniqueKey)){
                    mapOfAssignmentToPalWrapper.get(uniqueKey).add(palWrapper);
                }else{
                    mapOfAssignmentToPalWrapper.put(uniqueKey, new List<PayAdviceLinesWrapper>{palWrapper});
                }
            }
        }else{
            mapOfAssignmentToPalWrapper.put('Default',listOfPayAdviceLinesWrapper);
        }
        
        pcwrapper.mapOfAssignmentPayAdviceLinesWrapper = mapOfAssignmentToPalWrapper;
    }
    //if payadvicelines are not found for a paycode, populate the values as zero
    private void populateDefaultValues(){
        for(String payCode : mapOfPayCodeToSortOrder.keySet()){
            if(!mapOfPayCodeToPayCodeWrapper.containsKey(payCode)){
                PayCodeWrapper pcWrapper = new PayCodeWrapper();
                pcWrapper.payCode = payCode;
                pcWrapper.sortOrder = mapOfPayCodeToSortOrder.get(payCode);
                pcWrapper.mapOfRateToPayAdviceLinesWrapper = new Map<String, PayAdviceLinesWrapper>();
                PayAdviceLinesWrapper palWrapper = new PayAdviceLinesWrapper();
                palWrapper.CP_totalUnits =0.00;
                palWrapper.CP_totalValue = 0.00;
                palWrapper.rate = 0.00;
                palWrapper.PP_totalUnits = 0.00;
                palWrapper.PP_totalValue = 0.00;
                palWrapper.YTD_totalValue = 0.00;
                palWrapper.currentPlusPriorValue = 0.00;
                pcWrapper.mapOfRateToPayAdviceLinesWrapper.put('', palWrapper);
                pcWrapper.listOfPayAdviceLinesWrapper = pcWrapper.mapOfRateToPayAdviceLinesWrapper.values();
                mapOfPayCodeToPayCodeWrapper.put(payCode, pcWrapper);
            }
        }
    }
    //CI-228947
    private void removeBlankSections(){
        for(String payCode : mapOfPayCodeToSortOrder.keySet()){
            if(mapOfPayCodeToPayCodeWrapper.containsKey(payCode)){
                if(mapOfPayCodeToPayCodeWrapper.get(payCode).mapOfRateToPayAdviceLinesWrapper.isEmpty()){
                    //remove the pay code!
                    mapOfPayCodeToPayCodeWrapper.remove(payCode);
                }
            }
        }
    }
    
    //method to hard code the custom sort order for pay codes
    private void loadSortOrder(){
        mapOfPayCodeToSortOrder.put(PAYCODE_TAXABLE_PAYMENTS, 1);
        mapOfPayCodeToSortOrder.put(PAYCODE_NON_TAXABLE_PAYMENTS, 2);
        mapOfPayCodeToSortOrder.put(PAYCODE_PRE_TAX_DEDUCTIONS, 3);
        //T07
        if(payAdvice.RecordTypeId == GST_RECORDTYPE){
            mapOfPayCodeToSortOrder.put(PAYCODE_GST, 4);
            mapOfPayCodeToSortOrder.put(PAYCODE_POST_TAX_DEDUCTIONS, 5);
            mapOfPayCodeToSortOrder.put(PAYCODE_EMPLOYER_SUPERANNUATION, 6);
            mapOfPayCodeToSortOrder.put(PAYCODE_EXPENSE_REIMBURSEMENTS, 7);
        }
        else{
            mapOfPayCodeToSortOrder.put(PAYCODE_PAYG, 4);           //T09
            mapOfPayCodeToSortOrder.put(PAYCODE_POST_TAX_DEDUCTIONS, 5);
            mapOfPayCodeToSortOrder.put(PAYCODE_EMPLOYER_SUPERANNUATION, 6);
            mapOfPayCodeToSortOrder.put(PAYCODE_EXPENSE_REIMBURSEMENTS, 7);
        }//T07
    }
    
    private tc9_pr__Pay_Advice_Template__c getRelatedPayAdviceTemplate(){
        tc9_pr__Pay_Advice_Template__c[] templateList = [SELECT Id, tc9_pr__Label_Non_Taxable_Payments__c, tc9_pr__Label_Taxable_Payments__c, tc9_pr__Label_Pre_Tax_Deductions__c, tc9_pr__Label_PAYG_Withholding__c, tc9_pr__Label_Post_Tax_Deductions__c,
                                                         tc9_pr__Label_Employer_Superannuation__c, tc9_pr__Label_Expenses_Reimbursements__c, tc9_pr__Label_Goods_and_Services_Tax__c, tc9_pr__Label_Net_Pay_Distribution__c, tc9_pr__Label_Superannuation_Distribution__c, tc9_pr__Display_Address_Border__c,
                                                         tc9_pr__Label_Leave_Balances__c, tc9_pr__Colour_Header_Label_Text__c, tc9_pr__Colour_Header_Value_Text__c, tc9_pr__Colour_Section_Heading_Background__c, tc9_pr__Colour_Section_Heading_Text__c, tc9_pr__Colour_Section_Detail_Background__c,
                                                         tc9_pr__Colour_Section_Detail_Text__c, tc9_pr__Hide_Blank_Detail_Sections__c, tc9_pr__Document_Title__c, tc9_pr__Colour_Footer_Text__c, tc9_pr__Position_Footer__c, tc9_pr__Text_Footer__c FROM tc9_pr__Pay_Advice_Template__c WHERE Id=: payAdvice.tc9_pr__Pay_Advice_Template__c];
        
        if(templateList != null && templateList.size() > 0) {
            return templateList[0];
        }
        return null;
    }
    
    private void setCustomLablesAndColorForPayAdvice(tc9_pr__Pay_Advice_Template__c template, Id payAdviceId, tc9_pr__Pay_Advice__c payAdvice){
        PAYCODE_NON_TAXABLE_PAYMENTS    = template.tc9_pr__Label_Non_Taxable_Payments__c;
        PAYCODE_TAXABLE_PAYMENTS        = template.tc9_pr__Label_Taxable_Payments__c;
        PAYCODE_PRE_TAX_DEDUCTIONS      = template.tc9_pr__Label_Pre_Tax_Deductions__c;
        PAYCODE_POST_TAX_DEDUCTIONS     = template.tc9_pr__Label_Post_Tax_Deductions__c;
        PAYCODE_PAYG                    = template.tc9_pr__Label_PAYG_Withholding__c;
        PAYCODE_GST                     = template.tc9_pr__Label_Goods_and_Services_Tax__c;
        PAYCODE_EMPLOYER_SUPERANNUATION = template.tc9_pr__Label_Employer_Superannuation__c;
        PAYCODE_EXPENSE_REIMBURSEMENTS  = template.tc9_pr__Label_Expenses_Reimbursements__c;
        PAYCODE_LEAVE_BALANCES          = template.tc9_pr__Label_Leave_Balances__c;
        labelNetPayDistribution         = template.tc9_pr__Label_Net_Pay_Distribution__c;
        labelSuperannuationDistribution = template.tc9_pr__Label_Superannuation_Distribution__c;
        labelLeaveBalance               = template.tc9_pr__Label_Leave_Balances__c;
        labelSummary                    = 'Year to Date Summary';
        labelPersonalMessage = 'Personal Message';
        labelGeneralMessage = 'General Message';
        personalMessage = payAdvice.tc9_pr__Pay_Advice_Message__c;
        generalMessage = payAdvice.tc9_pr__Payment_Entity__r.General_Pay_Advice_Message__c;
        
        colorHeaderLabel        = template.tc9_pr__Colour_Header_Label_Text__c;
        colorHeaderValue        = template.tc9_pr__Colour_Header_Value_Text__c;
        colorSectionHeadingBg   = template.tc9_pr__Colour_Section_Heading_Background__c;
        colorSectionHeadingText = template.tc9_pr__Colour_Section_Heading_Text__c;
        colorSectionDetailBg    = template.tc9_pr__Colour_Section_Detail_Background__c;
        colorSectionDetailText  = template.tc9_pr__Colour_Section_Detail_Text__c;
        displayAddressBorder    = template.tc9_pr__Display_Address_Border__c;
        
        footerPosition          = template.tc9_pr__Position_Footer__c;
        if(template.tc9_pr__Text_Footer__c != null && template.tc9_pr__Text_Footer__c.contains('{!')) {
            Set <SObject> mergedObjs = new Set<SObject>();
            if(payAdvice.tc9_pr__Employee__c != null){
                Contact con = new Contact(Id=payAdvice.tc9_pr__Employee__c); // contact object
                mergedObjs.add(con);
            } if(payAdvice.tc9_pr__Payee__c!=null){
                tc9_pr__Payee__c payee = new tc9_pr__Payee__c(Id=payAdvice.tc9_pr__Payee__c ); //Payee object
                mergedObjs.add(payee);
            } if(payAdvice.tc9_pr__Pay_Batch_Item__c!=null){
                tc9_pr__Pay_Batch_Item__c payBatchItem = new tc9_pr__Pay_Batch_Item__c(Id=payAdvice.tc9_pr__Pay_Batch_Item__c ); //PBI object
                mergedObjs.add(payBatchItem);
            } if(payAdvice.tc9_pr__Pay_Batch__c!=null){
                tc9_pr__Pay_Batch__c paybatch = new tc9_pr__Pay_Batch__c(Id=payAdvice.tc9_pr__Pay_Batch__c ); //PB object
                mergedObjs.add(paybatch);
            }  if(payAdvice.tc9_pr__Payment_Entity__c!=null){
                Account paymentEntity = new Account(Id=payAdvice.tc9_pr__Payment_Entity__c ); //Account Object
                mergedObjs.add(paymentEntity);
            }
            mergedObjs.add(payAdvice);
            
            CUSTOM_Ctrl_EmailTemplate tmplt = new CUSTOM_Ctrl_EmailTemplate();
            footerText = tmplt.parsePayAdvFooter(template.tc9_pr__Text_Footer__c, mergedObjs);
        } else {
            footerText              = template.tc9_pr__Text_Footer__c;
        }
        colorFooterText         = template.tc9_pr__Colour_Footer_Text__c;
        System.debug('displayAddressBorder ' + displayAddressBorder) ;
    }
    
    private void setPayAdviceLinesDisplay(List<PayCodeWrapper> listOfPayCodeWrappersGroup) {
        Set<String> displayedPaycodeSet = new Set<String>();
        
        for (Integer i = listOfPayCodeWrappersGroup.size() - 1; i >= 0; i--) {
            Map<String, List<PayAdviceLinesWrapper>> assignmentMap = listOfPayCodeWrappersGroup[i].mapOfAssignmentPayAdviceLinesWrapper;
            
            if (assignmentMap == null || assignmentMap.isEmpty()) continue;
            
            List<String> keyList = new List<String>(assignmentMap.keySet());
            
            if(keyList.isEmpty()) continue;
            
            for (Integer j = keyList.size()-1 ; j >= 0 ; j--) {
                String key = keyList[j];
                List<PayAdviceLinesWrapper> adviceLines = assignmentMap.get(key);
                System.debug('>>> ' + key);
                
                if (adviceLines == null || adviceLines.isEmpty()) continue;
                
                for (Integer k = adviceLines.size() - 1; k >= 0; k--) {
                    PayAdviceLinesWrapper line = adviceLines[k];
                    System.debug('>>>>>> ' + line.PayCode);
                    
                    if (displayedPaycodeSet.add(line.PayCode)) {
                        line.displayYTDTotalValue = true;
                        line.displayTPTotalUnit = true;
                    }
                }
            }
        }
        
    }
    
    public ShiftBackingSheet getShiftBackingSheetData() {
        tc9_pr__Pay_Advice__c payAdvice = [SELECT Id, tc9_pr__Gross_Earnings__c
                                           FROM tc9_pr__Pay_Advice__c
                                           WHERE Id =:payAdviceId
                                           LIMIT 1];
        
        List<tc9_pr__Pay_Transaction__c> payTrns = [SELECT Id, tc9_pr__Entry_Date__c, tc9_pr__Quantity__c, tc9_pr__Pay_Code__c, tc9_pr__Pay_Code__r.Name,tc9_pr__Assignment_Rate__c, tc9_pr__Pay_Code__r.tc9_pr__Pay_Advice_Sort_Order__c, 
                                                    tc9_pr__Pay_Total__c, tc9_pr__Pay_Rate__c, tc9_pr__Pay_Advice__r.tc9_pr__Gross_Earnings__c, tc9_et__Timesheet_Entry__r.tc9_et__Start_Time__c, tc9_et__Timesheet_Entry__r.tc9_et__End_Time__c,
                                                    Shift__c, Shift__r.sirenum__Site__c, Shift__r.sirenum__Site__r.Name, Shift__r.tc9_ext_sirint__Award_Level__c, tc9_pr__Pay_Code__r.tc9_pr__Pay_Advice_Description__c,
                                                    Shift__r.tc9_ext_sirint__Award_Level__r.Name, Shift__r.sirenum__Location__c, Shift__r.sirenum__Location__r.Name, Shift__r.Minimum_Pay_rate__r.Award_Classification_Level_Name__c,
                                                    Shift__r.Allowance_Start_Time__c, Shift__r.Allowance_End_Time__c, tc9_et__Timesheet_Entry__c, tc9_et__Timesheet_Item__c, OriginalTSEID__c, OriginalTSIID__c, tc9_et__Timesheet_Activity__c, tc9_pr__Project_Code__r.Name, tc9_pr__Project_Code__c,
                                                    tc9_et__Timesheet_Item__r.tc9_util__Start_Time__c, tc9_et__Timesheet_Item__r.tc9_util__End_Time__c,
                                                    RecordType.DeveloperName, tc9_pr__Project_Code__r.Display_on_Pay_Advice__c, Casual_Loading_Amount__c, Multiplied_Pay_Rate__c, tc9_et__Timesheet_Entry__r.tc9_et__Timesheet_Activity__r.Name,
                                                    tc9_et__Timesheet_Entry__r.tc9_et__Project_Code__r.Name
                                                    FROM tc9_pr__Pay_Transaction__c
                                                    WHERE tc9_pr__Pay_Advice__c = :payAdviceId
                                                    AND (tc9_et__Timesheet_Entry__c != null OR tc9_et__Timesheet_Item__c != null OR Shift__c != null)
                                                    ORDER BY tc9_pr__Entry_Date__c];
        Set<Id> tseIdSet = new Set<Id>();
        Set<Id> tsiIdSet = new Set<Id>();
        Set<Id> siteIdSet = new Set<Id>();
        Set<Id> locationIdSet = new Set<Id>();
        Set<Id> timesheetActivityIdSet = new Set<Id>();
        
        for(tc9_pr__Pay_Transaction__c trn : payTrns) {
            if(trn.tc9_et__Timesheet_Entry__c != null) {
                tseIdSet.add(trn.tc9_et__Timesheet_Entry__c);
            }
            
            if(trn.OriginalTSEID__c != null) {
                tseIdSet.add(trn.OriginalTSEID__c);
            }
            
            if(trn.tc9_et__Timesheet_Item__c != null) {
                tsiIdSet.add(trn.tc9_et__Timesheet_Item__c);
            }
            
            if(trn.OriginalTSIID__c != null) {
                tsiIdSet.add(trn.OriginalTSIID__c);
            }
            
            if(trn.Shift__r.sirenum__Location__c != null) {
                locationIdSet.add(trn.Shift__r.sirenum__Location__c);
            }
            
            if(trn.tc9_et__Timesheet_Activity__c != null) {
                timesheetActivityIdSet.add(trn.tc9_et__Timesheet_Activity__c);
            }
        }
        
        Map<Id, tc9_et__Timesheet_Entry__c> tseMap = new Map<Id, tc9_et__Timesheet_Entry__c>([SELECT Id, tc9_et__Start_Time__c, tc9_et__End_Time__c, tc9_ext_sirint__Site__c, tc9_ext_sirint__Site__r.Name, 
                                                                                              tc9_ext_sirint__Location__c, tc9_ext_sirint__Shift__r.sirenum__Location__c , tc9_ext_sirint__Shift__r.sirenum__Location__r.Name
                                                                                              FROM tc9_et__Timesheet_Entry__c
                                                                                              WHERE Id IN :tseIdSet]);
        
        Map<Id, tc9_et__Timesheet_Item__c> tsiMap = new Map<Id, tc9_et__Timesheet_Item__c>([SELECT Id, tc9_ext_sirint__Site__c, tc9_ext_sirint__Site__r.Name, tc9_ext_sirint__Location__c,
                                                                                            tc9_ext_sirint__Shift__r.sirenum__Location__c , tc9_ext_sirint__Shift__r.sirenum__Location__r.Name
                                                                                            FROM tc9_et__Timesheet_Item__c
                                                                                            WHERE Id IN :tsiIdSet]);
        
        Map<String, tc9_pr__Project_Code__c> timesheetActivityMap = new Map<String, tc9_pr__Project_Code__c>([SELECT Id, Name, Display_on_Pay_Advice__c
                                                                                                              FROM tc9_pr__Project_Code__c
                                                                                                              WHERE Id IN :timesheetActivityIdSet]);
        
        for(tc9_et__Timesheet_Entry__c tse : tseMap.values()) {
            if(tse.tc9_ext_sirint__Site__c != null) {
                siteIdSet.add(tse.tc9_ext_sirint__Site__c);
            }
            if(tse.tc9_ext_sirint__Location__c != null) {
                locationIdSet.add(tse.tc9_ext_sirint__Location__c);
            }
        }
        
        for(tc9_et__Timesheet_Item__c tsi : tsiMap.values()) {
            if(tsi.tc9_ext_sirint__Site__c != null) {
                siteIdSet.add(tsi.tc9_ext_sirint__Site__c);
            }
            if(tsi.tc9_ext_sirint__Location__c != null) {
                locationIdSet.add(tsi.tc9_ext_sirint__Location__c);
            }
        }
        
        Map<Id, sirenum__Site__c> siteMap = new Map<Id, sirenum__Site__c >([SELECT Id, Name
                                                                            FROM sirenum__Site__c 
                                                                            WHERE Id IN :siteIdSet]);
        
        Map<Id, sirenum__Location__c> locationMap = new Map<Id, sirenum__Location__c >([SELECT Id, Name
                                                                                        FROM sirenum__Location__c 
                                                                                        WHERE Id IN :locationIdSet]);
        
        Decimal totalAllowanceQty = 0;
        Decimal totalHours = 0;
        Map<String, Map<String, ShiftGroupDetail>> shiftGroupMap = new Map<String, Map<String, ShiftGroupDetail>>();
        for(tc9_pr__Pay_Transaction__c trn : payTrns) {
            tc9_et__Timesheet_Entry__c tse = tseMap.get(trn.tc9_et__Timesheet_Entry__c);
            tc9_et__Timesheet_Entry__c originalTse = tseMap.get(trn.OriginalTSEID__c);
            tc9_et__Timesheet_Item__c tsi = tsiMap.get(trn.tc9_et__Timesheet_Item__c);
            tc9_et__Timesheet_Item__c originalTsi = tsiMap.get(trn.OriginalTSIID__c);
            tc9_pr__Project_Code__c timesheetActivity = timesheetActivityMap.get(trn?.tc9_et__Timesheet_Activity__c);
            
            Id siteId = getSiteId(tse, tsi, originalTse, originalTsi);
            Id locationId = getLocationId(tse, tsi, originalTse, originalTsi);
            sirenum__Site__c  site = siteId != null ? siteMap.get(siteId) : null;
            sirenum__Location__c  location = locationId != null ? locationMap.get(locationId) : null;
            
            System.debug('site ' + site); 
            System.debug('location ' + location); 
            
            ShiftGroupDetail shift = new ShiftGroupDetail(trn, site, location, tse, originalTse, timesheetActivity);
            
            String groupKey = trn.tc9_pr__Entry_Date__c + '_' + trn.Shift__c + '_' + trn.Shift__r.sirenum__Site__c + '_' + trn.Shift__r.Minimum_Pay_rate__r.Award_Classification_Level_Name__c;
            String subGroupKey = trn.tc9_pr__Pay_Code__c + '_' + trn.tc9_pr__Assignment_Rate__c + '-' + trn?.tc9_et__Timesheet_Activity__c + '-' + trn?.tc9_pr__Project_Code__c;
            
            Map<String, ShiftGroupDetail> subGroupMap = shiftGroupMap.get(groupKey);
            if(subGroupMap != null) {
                
                if(subGroupMap.get(subGroupKey) != null) {
                    subGroupMap.get(subGroupKey).quantity += shift.quantity;
                    subGroupMap.get(subGroupKey).amount += shift.amount;
                } else {
                    subGroupMap.put(subGroupKey, shift);
                }
                
            } else {
                shiftGroupMap.put(groupKey, new Map<String, ShiftGroupDetail>{ subGroupKey => shift});
            }
            
            if(trn.RecordType.DeveloperName == 'Allowance') {
                totalAllowanceQty += (trn.tc9_pr__Quantity__c != null ? trn.tc9_pr__Quantity__c : 0);
            } else {
                totalHours += (trn.tc9_pr__Quantity__c != null ? trn.tc9_pr__Quantity__c : 0);
            }
        }
        
        List<ShiftGroup> shiftGroups = new List<ShiftGroup>();
        for(String groupKey : shiftGroupMap.keySet()) {
            Map<String, ShiftGroupDetail> subGroupMap = shiftGroupMap.get(groupKey);
            List<ShiftGroupDetail> sortSubgroups = new List<ShiftGroupDetail>();
            
            for(String subGroupKey : subGroupMap.keySet()) {
                if(subGroupMap.get(subGroupKey).amount != null && subGroupMap.get(subGroupKey).amount != 0) {
                    sortSubgroups.add(subGroupMap.get(subGroupKey));
                }
            }
            sortSubgroups.sort();
            shiftGroups.add(new ShiftGroup(sortSubgroups));
        }
        
        ShiftBackingSheet backingSheet = new ShiftBackingSheet();
        backingSheet.shiftGroups = shiftGroups;
        backingSheet.totalGrossAmount = payAdvice.tc9_pr__Gross_Earnings__c != null ? payAdvice.tc9_pr__Gross_Earnings__c : 0;
        backingSheet.totalAllowanceQty = totalAllowanceQty;
        backingSheet.totalHours = totalHours;
        
        return backingSheet;
    }
    
    public static Id getSiteId(tc9_et__Timesheet_Entry__c tse, tc9_et__Timesheet_Item__c tsi, tc9_et__Timesheet_Entry__c originalTse, tc9_et__Timesheet_Item__c originalTsi) {
        if(tse != null && tse.tc9_ext_sirint__Site__c != null) {
            return tse.tc9_ext_sirint__Site__c;
            
        } else if(tsi != null && tsi.tc9_ext_sirint__Site__c != null) {
            return tsi.tc9_ext_sirint__Site__c;
            
        } else if(originalTse != null && originalTse.tc9_ext_sirint__Site__c != null) {
            return originalTse.tc9_ext_sirint__Site__c;
            
        }
        
        return originalTsi?.tc9_ext_sirint__Site__c;
    }
    
    public static Id getLocationId(tc9_et__Timesheet_Entry__c tse, tc9_et__Timesheet_Item__c tsi, tc9_et__Timesheet_Entry__c originalTse, tc9_et__Timesheet_Item__c originalTsi) {
        if(tse != null && tse.tc9_ext_sirint__Location__c != null) {
            return tse.tc9_ext_sirint__Location__c;
            
        } else if(tsi != null && tsi.tc9_ext_sirint__Location__c != null) {
            return tsi.tc9_ext_sirint__Location__c;
            
        } else if(originalTse != null && originalTse.tc9_ext_sirint__Location__c != null) {
            return originalTse.tc9_ext_sirint__Location__c;
            
        }
        
        return originalTsi?.tc9_ext_sirint__Location__c;
    }
    
    public class ShiftBackingSheet {
        public List<ShiftGroup> shiftGroups {get; set;}
        public Decimal totalGrossAmount {get; set;}
        public Decimal totalAllowanceQty {get; set;}
        public Decimal totalHours {get; set;}
        
        public ShiftBackingSheet() {
            this.shiftGroups = new List<ShiftGroup>();
            this.totalGrossAmount = 0;
            this.totalAllowanceQty = 0;
            this.totalHours = 0;
        }
    }
    
    public class ShiftGroup {
        public ShiftGroupDetail firstGroupDetail {get; set;}
        public List<ShiftGroupDetail> followingGroupDetails {get; set;}
        
        public ShiftGroup(List<ShiftGroupDetail> groupDetails) {
            if(groupDetails != null && !groupDetails.isEmpty()) {
                this.firstGroupDetail = groupDetails[0];
                this.followingGroupDetails = new List<ShiftGroupDetail>();
                
                if(groupDetails.size() > 1) {
                    groupDetails.remove(0);   
                    this.followingGroupDetails = groupDetails;
                }
            }
        }
    }
    
    public class ShiftGroupDetail implements Comparable {
        public Date shiftDate {get; set;}
        public String siteName {get; set;}
        public String department {get; set;}
        public String jobType {get; set;}
        public Datetime startDateTime {get; set;}
        public Datetime endDateTime {get; set;}
        public String shiftType {get; set;}
        public Decimal quantity {get; set;}
        public Decimal rate {get; set;}
        public Decimal amount {get; set;}
        public Decimal casualLoadingAmount {get; set;}
        public Decimal rateExclCasualLoading {get; set;}
        public Decimal sortOrder {get; set;}
        
        public ShiftGroupDetail(tc9_pr__Pay_Transaction__c trn, sirenum__Site__c site, sirenum__Location__c location, tc9_et__Timesheet_Entry__c tse, tc9_et__Timesheet_Entry__c originalTse, tc9_pr__Project_Code__c timesheetActivity) {
            String timesheetActivityName = String.isNotBlank(timesheetActivity?.Name) && 'Yes'.equalsIgnoreCase(timesheetActivity.Display_on_Pay_Advice__c) ? ' - ' + timesheetActivity.Name : '';
            String projectCodeName = String.isNotBlank(trn?.tc9_pr__Project_Code__r?.Name) && 'Yes'.equalsIgnoreCase(trn?.tc9_pr__Project_Code__r?.Display_on_Pay_Advice__c) ? ' - ' + trn.tc9_pr__Project_Code__r.Name : '';
            
            this.shiftDate = trn.tc9_pr__Entry_Date__c;
            // this.siteName = site?.Name;
            this.siteName = trn.Shift__r.sirenum__Site__r.Name;
            this.department = location?.Name;
            this.jobType = trn.Shift__r.Minimum_Pay_rate__r.Award_Classification_Level_Name__c;
            this.shiftType = trn.tc9_pr__Pay_Code__r.tc9_pr__Pay_Advice_Description__c + timesheetActivityName + projectCodeName;
            this.quantity = trn.tc9_pr__Quantity__c != null ? trn.tc9_pr__Quantity__c : 0;
            this.amount = trn.tc9_pr__Pay_Total__c != null ? trn.tc9_pr__Pay_Total__c : 0;
            this.rate = trn.tc9_pr__Pay_Rate__c != null ? trn.tc9_pr__Pay_Rate__c : 0;
            this.casualLoadingAmount = trn.Casual_Loading_Amount__c != null ? trn.Casual_Loading_Amount__c : 0;
            this.rateExclCasualLoading = trn.Multiplied_Pay_Rate__c != null ? trn.Multiplied_Pay_Rate__c : 0;
            this.sortOrder = trn.tc9_pr__Pay_Code__r.tc9_pr__Pay_Advice_Sort_Order__c ?? 0;
            
            /*
Time startTime = tse != null && tse.tc9_et__Start_Time__c != null ? tse.tc9_et__Start_Time__c : originalTse?.tc9_et__Start_Time__c;
Time endTime = tse != null && tse.tc9_et__End_Time__c != null  ? tse.tc9_et__End_Time__c : originalTse?.tc9_et__End_Time__c;
*/
            
            Time startTime;
            Time endTime;
            if(trn.RecordType.DeveloperName == 'Allowance') {
                startTime = trn.tc9_et__Timesheet_Item__r.tc9_util__Start_Time__c;
                endTime = trn.tc9_et__Timesheet_Item__r.tc9_util__End_Time__c;
                
            } else if(trn.RecordType.DeveloperName == 'Payment') {
                startTime = trn.tc9_et__Timesheet_Entry__r.tc9_et__Start_Time__c;
                endTime = trn.tc9_et__Timesheet_Entry__r.tc9_et__End_Time__c;
                
            } else {
                startTime = trn.Shift__r.Allowance_Start_Time__c;
                endTime = trn.Shift__r.Allowance_End_Time__c;
            }
            
            if(shiftDate != null && startTime != null) {
                this.startDateTime = Datetime.newInstanceGmt(this.shiftDate, startTime);
            }
            if(shiftDate != null && endTime != null) {
                this.endDateTime = Datetime.newInstanceGmt(this.shiftDate, endTime);
            }
        }
        
        
        public ShiftGroupDetail(tc9_pr__Pay_Transaction__c trn, sirenum__Site__c site, sirenum__Location__c location, tc9_et__Timesheet_Entry__c tse, tc9_et__Timesheet_Entry__c originalTse, tc9_pr__Project_Code__c timesheetActivity, String shiftType) {
            this(trn, site, location, tse, originalTse, timesheetActivity);
            this.shiftType = shiftType;
        }
        
        public Integer compareTo(Object obj){
            ShiftGroupDetail groupDetail = (ShiftGroupDetail) obj;
            
            if(this.sortOrder < groupDetail.sortOrder) {
                return -1;
            } else if(this.sortOrder > groupDetail.sortOrder) {
                return 1;
            } else {
                return 0;
            }
        }
    }
    
    //wrapper class to maintain list of paycode
    public with sharing class PayCodeWrapper implements Comparable{
        
        public String payCode{get;set;}
        public String payCodeTotalLabel{get;set;}
        public Double payCodeTotalValue{get;set;}
        public String payCodeYTDTotalLabel{get;set;}
        public Double payCodeYTDTotalValue{get;set;}
        public Integer sortOrder{get;set;}
        public Map<String, PayAdviceLinesWrapper> mapOfRateToPayAdviceLinesWrapper{get;set;}
        public List<PayAdviceLinesWrapper> listOfPayAdviceLinesWrapper{get;set;}
        public Map<String,List<PayAdviceLinesWrapper>> mapOfAssignmentPayAdviceLinesWrapper{get;set;}
        
        public Set<String> getGroupKeys() {
            if(mapOfAssignmentPayAdviceLinesWrapper != null && !mapOfAssignmentPayAdviceLinesWrapper.isEmpty()) {
                return mapOfAssignmentPayAdviceLinesWrapper.keySet();
            }
            return new Set<String>();
        }
        
        //custom sorting based on sort order
        public Integer compareTo(Object obj) {
            PayCodeWrapper payAdviceLine = (PayCodeWrapper)(obj);
            if (this.sortOrder > payAdviceLine.sortOrder) {
                return 1;
            }
            if (this.sortOrder == payAdviceLine.sortOrder) {
                return 0;
            }
            return -1;
        }
    }
    
    //wrapper class to maintain payadvicelines consolidated data
    public with sharing class PayAdviceLinesWrapper{
        
        public Date shiftDate{get; set;}
        public Decimal casualLoadingAmount {get; set;}
        public Decimal rateExclCasualLoading {get; set;}
        public Decimal rate{get;set;}
        public String PayCode {get;set;}
        public Decimal CP_totalUnits{get;set;}
        public Decimal CP_totalValue{get;set;}
        
        public Decimal PP_totalUnits{get;set;}
        public Decimal PP_totalValue{get;set;}
        
        public Boolean displayTPTotalUnit {get; set;}
        public Boolean displayYTDTotalValue {get; set;}
        
        public Decimal YTD_totalValue{get;set;}
        public Decimal TP_TotalUnits{get;set;}
        
        public Decimal currentPlusPriorValue{get;set;}
        public String assignmentKey;
        
        public Boolean hideCPonPaySlip{get;set;}
        public Boolean hidePPonPaySlip{get;set;}
        
        public String timesheetActivityName {get; set;}
        public String projectCodeName {get; set;}
    }
    
    //wrapper class to maintain leave balances consolidated data
    public with sharing class LeaveBalancesWrapper implements Comparable{
        
        public String leaveRuleName{get;set;}
        public Decimal balanceHours{get;set;}
        public Decimal balanceDays{get;set;}
        
        //custom sorting based on leaverulename
        public Integer compareTo(Object obj) {
            LeaveBalancesWrapper leaveBalance = (LeaveBalancesWrapper)(obj);
            if (this.leaveRuleName > leaveBalance.leaveRuleName) {
                return 1;
            }
            if (this.leaveRuleName == leaveBalance.leaveRuleName) {
                return 0;
            }
            return -1;
        }
    }
    
    //wrapper class to maintain payment file lines
    public with sharing class PaymentFileLinesWrapper{
        
        public String bankAccountName{get;set;}
        public String bankAccountNumber{get;set;}
        public String bankBranchCode{get;set;}
        public Decimal paymentAmount{get;set;}
        
    }
    
    //wrapper class to maintain consolidated pay transaction data
    public with sharing class PayTransactionsWrapper{
        public String fundId{get;set;}
        public String fundName{get;set;}
        public String memberNumber{get;set;}
        public Decimal amount{get;set;}
        public Decimal ytdAmount{get;set;}
        
    }
    
    //email template class
    public with sharing class CUSTOM_Ctrl_EmailTemplate {
        
        public String parsePayAdvFooter(String footerText, Set<SObject> sObjs) {
            String parsedSubject;
            Map<String, Id>mergedObjTypeIds;
            try{
                mergedObjTypeIds = getMergedObjMap(sObjs);
                if (footerText!= null) {
                    parsedSubject = parseEmailTemplate(footerText, mergedObjTypeIds);
                }
            }catch(Exception e){
                throw e;
            }
            return parsedSubject;
        }
        private Map<String, Id> getMergedObjMap(Set<SObject> sObjs){
            Map<String, Id> mergedFields = new Map<String, Id>(); // stores the object type and corresponding id
            for (SObject sObj : sObjs){
                mergedFields.put(sObj.getSObjectType().getDescribe().getName(),sObj.id);
            }
            return mergedFields;
        }
        
        //Parse Email Template content parse all the merged fields in a email content
        private String parseEmailTemplate(String tempContent, Map<String, Id> mergedObjIdMap){
            Map<String,String> mergObjFields = new Map<String,String>(); // store the objec name and all the fields for the object;
            Map<String, String> refFields = new Map<String, String>();
            String disp='';
            
            if (tempContent != null){
                String trunkStr = tempContent;
                disp = tempContent;
                String key='', value='', tmpVal, mergField, tempValChild = '';
                Integer posBeg= trunkStr.indexOf('{!') ;
                Integer posEnd = trunkStr.indexOf('}');
                //get all the merged fields in map <sObjectName, mergedfieldsName>, the mergedfieldsName is 'field1, field2'
                while (trunkStr.contains('{!') && trunkStr.contains('}') &&  posBeg < posEnd - 3){ //make sure the trunkStr contains {!} fields
                    mergField = trunkStr.substring(posBeg+2,  posEnd); // the mergered field, format is sObjce.fieldName;
                    key= mergField.substring(0,mergField.indexOf('.')); // the sObject name
                    
                    tmpVal = String.escapeSingleQuotes(mergField.substring(mergField.indexOf('.')+1, mergField.length())); // the filedName
                    
                    Schema.DescribeSObjectResult[] result = Schema.describeSObjects(new List<String>{key});
                    if(String.valueOf(result[0].fields.getMap().get(tmpVal).getDescribe().getType()) == 'reference') {
                        tempValChild = String.escapeSingleQuotes(mergField.substring(mergField.indexOf('.')+1, mergField.length()-1)) + 'r.Name';
                        refFields.put(mergField, key+'.'+tempValChild);
                    }
                    if(mergObjFields.containsKey(key) ){// if the sObject in the map, and filed is not included in value, then add the fields in the value
                        Set<String> setOfFields = new Set<String>();
                        if(mergObjFields.get(key)!=null) {
                            setOfFields.addAll(mergObjFields.get(key).split(','));
                        }
                        if (!setOfFields.contains(tmpVal)){
                            value = tmpVal + ',' + mergObjFields.get(key);
                        }
                        else {
                            if(setOfFields.contains('.'+tmpVal)) {
                                value = tmpVal + ',' + mergObjFields.get(key);
                            } else {
                                value = mergObjFields.get(key);
                            }
                        }
                        if(tempValChild != '') {
                            if (!setOfFields.contains(tempValChild)){
                                value = tempValChild + ',' + value;
                            }
                            tempValChild = '';
                        }
                    }else{
                        value = tmpVal;
                        if(tempValChild != '') {
                            value = tmpVal + ',' + tempValChild;
                            tempValChild = '';
                        }
                    }
                    mergObjFields.put(key, value); // store in map
                    if(posEnd+1 < trunkStr.length()) { // trunk this merged field off the emailtemp
                        trunkStr = trunkStr.substring(posEnd + 1, trunkStr.length());
                    } else {
                        trunkStr = '';
                    }
                    posBeg= trunkStr.indexOf('{!') ; //next merged field start pos
                    posEnd = trunkStr.indexOf('}'); //next merged field end pos;
                }
            }
            
            Map <String, Object> fieldVals = new Map<String, Object>(); // stores all the merged field name and corresponding values
            SObject sObj;
            //get merged field values
            for(String objName : mergObjFields.keySet()){ //for each object in the map
                if (mergedObjIdMap.containsKey(objName)){
                    String strFields= mergObjFields.get(objName); // get all the merged fields for this sObject
                    String query = 'select '+ strFields + ' from ' + String.escapeSingleQuotes(objName); // construct query
                    sObj = Database.query(query + ' WHERE Id= \''+String.escapeSingleQuotes(mergedObjIdMap.get(objName))+'\''); // get current user information
                    
                    String [] fields = strFields.split(',');
                    for( String field: fields){ // put the values in the map with
                        if(!field.contains('__r')) {
                            Object obj = sObj.get(field);
                            fieldVals.put(objName+'.'+field, obj);
                        }
                        else {
                            String rel = field.replace('.', ',');
                            String[] relFields = rel.split(',');
                            Object obj = sObj.getSObject(relFields[0]).get(relFields[1]);
                            fieldVals.put(objName+'.'+field, obj);
                        }
                    }
                }
            }
            
            //replace the mergered fields in the template with its values
            for (String mergField : fieldVals.keySet()){
                Object obj = fieldVals.get(mergField);
                if (obj != null && !mergField.contains('__r')){
                    if(refFields.containsKey(mergField) && fieldVals.containsKey(refFields.get(mergField))) {
                        disp=disp.replace('{!'+mergField+'}', (String)(fieldVals.get(refFields.get(mergField))));
                    }
                    else {
                        disp=disp.replace('{!'+mergField+'}', (String)obj);
                    }
                }else if(!mergField.contains('__r')){
                    disp=disp.replace('{!'+mergField+'}','');
                }
            }
            disp = disp.replace('\r\n','<br />');
            return disp;
        }
    }
}