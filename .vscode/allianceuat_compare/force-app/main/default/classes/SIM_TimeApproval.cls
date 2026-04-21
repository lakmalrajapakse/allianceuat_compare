/**
 * @description       : 
 * @author            : Simon Coles
 * @group             : 
 * @last modified on  : 20-11-2024
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   20-11-2024   Simon Coles   Initial Version
**/
public with sharing class SIM_TimeApproval {
    private static final Integer MAX_RECORDS_TO_LOAD = 200;
    private static final Integer MAX_RECORDS_PER_BATCH = 1000;

    /** Get Component Settings and Permissions **/
    @AuraEnabled
    public static String getSetup(String usrID){
        Id usrContactId = Test.isRunningTest() ? (Id)usrId : [SELECT ContactId FROM User WHERE Id = :usrID].ContactId;
        Boolean canEnterExpenses = 
        (Schema.sObjectType.sirenum__Expense__c.isUpdateable() && Schema.sObjectType.sirenum__Expense__c.isCreateable());
        Boolean canEnterActual = 
        (Schema.sObjectType.sirenum__Shift__c.fields.sirenum__Actual_Start_Time__c.isUpdateable() && Schema.sObjectType.sirenum__Shift__c.fields.sirenum__Actual_End_Time__c.isUpdateable());
        Boolean canEnterBillable = 
        (Schema.sObjectType.sirenum__Shift__c.fields.sirenum__Billable_Start_Time__c.isUpdateable() && Schema.sObjectType.sirenum__Shift__c.fields.sirenum__Billable_End_Time__c.isUpdateable());
        boolean canReject =
        (Schema.sObjectType.sirenum__Shift__c.fields.Rejected__c.isUpdateable() && Schema.sObjectType.sirenum__Shift__c.fields.Rejection_Reason__c.isUpdateable());
        
        // new
        boolean canEnterAbsolute =
        (Schema.sObjectType.sirenum__Shift__c.fields.sirenum__Absolute_Start_Time__c.isUpdateable() && Schema.sObjectType.sirenum__Shift__c.fields.sirenum__Absolute_End_Time__c.isUpdateable());
        boolean canViewWorker = Schema.sObjectType.sirenum__Shift__c.fields.sirenum__Contact__c.isAccessible();
        boolean canViewSite = Schema.sObjectType.sirenum__Shift__c.fields.sirenum__Site__c.isAccessible();
        boolean canViewJobRole = Schema.sObjectType.sirenum__Shift__c.fields.sirenum__Site__c.isAccessible();
        boolean canViewBreaks = 
        (Schema.sObjectType.sirenum__Shift__c.fields.sirenum__Break_Length__c.isAccessible() && Schema.sObjectType.sirenum__Shift__c.fields.sirenum__BreakStartTime__c.isAccessible());
        boolean canEditBreaks = 
        (Schema.sObjectType.sirenum__Shift__c.fields.sirenum__Break_Length__c.isUpdateable() && Schema.sObjectType.sirenum__Shift__c.fields.sirenum__BreakStartTime__c.isUpdateable());
        boolean canEnterBreak = canEditBreaks && canViewBreaks;
        return JSON.serialize(new SIM_Response.SuccessResponse(new Map<String, Object>{
            // start new
            'canSeeWorker' => canViewWorker,
            'canSeeSite' => canViewSite,
            'canSeeJobRole' => canViewJobRole,
            'canEnterBreaks' => canEditBreaks,
            // end new
            'userType' => UserInfo.getUserType(),
            'userName' => UserInfo.getName(),
            'userId' => UserInfo.getUserId(),
            'currency' => UserInfo.getDefaultCurrency(), 
            'canSeePay' => Schema.sObjectType.sirenum__Shift__c.fields.Basic_Pay__c.isAccessible(),
            'canSeeCharge' => Schema.sObjectType.sirenum__Shift__c.fields.sirenum__Charge__c.isAccessible(),
            'canEnterExpenses' => canEnterExpenses,
            'canEnterAbsolute' => canEnterAbsolute,
            'canEnterActual' => canEnterActual,
            'canEnterBillable' => canEnterBillable,
            'canApprovePay' => Schema.sObjectType.sirenum__Shift__c.fields.sirenum__Allow_pay__c.isUpdateable(),
            'canApproveCharge' => Schema.sObjectType.sirenum__Shift__c.fields.sirenum__Allow_charge__c.isUpdateable(),
            'canSubmit' => Schema.sObjectType.sirenum__Shift__c.fields.Submitted__c.isUpdateable(),
            'canSeeSubmit' => Schema.sObjectType.sirenum__Shift__c.fields.Submitted__c.isAccessible(),
            'canRejectShift' => canReject,
            'canSeeApprovePay' => Schema.sObjectType.sirenum__Shift__c.fields.sirenum__Allow_pay__c.isAccessible(),
            'canSeeApproveCharge' => Schema.sObjectType.sirenum__Shift__c.fields.sirenum__Allow_pay__c.isUpdateable(),
            'userContactId' => usrContactId
        }));
    }

    /**
     * This function loads the full shift records
     * based on a set of record IDs retreived after
     * successfull application of record filter
     */
    @AuraEnabled
    public static String getData(String soqlFilter, String weekStart, String weekEnd, List<String> filterContacts, List<String> filterAccounts, List<String> filterSites, String resumeFromId, List<String> filterBranches, List<String> filterJobRoles) {
        try{
            try{
                System.debug('week start str:: ' + weekStart);
                System.debug('week end str:: ' + weekEnd);
                return JSON.serialize(new SIM_Response.SuccessResponse(loadData(soqlFilter, weekStart, weekEnd, filterContacts, filterAccounts, filterSites, (String.isNotBlank(resumeFromId) ? resumeFromId : null), filterBranches, filterJobRoles)));
            }catch(ApprovalException ae){
                return JSON.serialize(new SIM_Response.ErrorResponse(ae.getMessage()));
            }            
        }catch(Exception e){
            
            return JSON.serialize(new SIM_Response.ErrorResponse(String.format(
                Label.CRM_GeneralApexFailure,
                new Object[]{
                    e.getMessage(),
                    e.getLineNumber(),
                    e.getStackTraceString()
                }
            )));
        }
    }
    
    
    /**
     * Updates a list of shifts and re-loads data
     */
    @AuraEnabled
    public static String updateShifts(String jsonData) {
        List<sirenum__Shift__c> recordsToUpdate = (List<sirenum__Shift__c>) JSON.deserialize(jsonData, List<sirenum__Shift__c>.class);
        List<SaveResultItem> results = new List<SaveResultItem>();
        System.debug(LOGGINGLEVEL.ERROR, 'recordsToUpdate:' + recordsToUpdate);

        Boolean hasErrors = false;
        List<Database.SaveResult> srList = Database.update(recordsToUpdate, false);    
        System.debug(LOGGINGLEVEL.ERROR, 'srList:' + srList);            

        for (Integer i = 0; i < recordsToUpdate.size(); i++) {
            Database.SaveResult sr = srList[i];
            if (sr.isSuccess()) {
                results.add(new SaveResultItem(sr.getId(), true, null));
            }else if (!sr.isSuccess()) {
                hasErrors = true;
                sirenum__Shift__c origRecord = recordsToUpdate[i];
                List<ErrorMessage> errorMessages = new List<ErrorMessage>();
                // Operation failed, map all errors  
                Integer index = 1;              
                for(Database.Error err : sr.getErrors()) {
                    errorMessages.add(new ErrorMessage(
                        index,
                        ''+err.getStatusCode(),
                        ''+err.getMessage(),
                        ''+err.getFields()
                    ));
                    index++;
                }

                results.add(new SaveResultItem(origRecord.Id, false, errorMessages));
            } 
        }

        if(hasErrors)
            {return JSON.serialize(new SIM_Response.ErrorResponse(results));}
        else
            {return JSON.serialize(new SIM_Response.SuccessResponse(results));}
    }

    
    /**
     * This loads filtered shift records 
     * TODO: Implement pages
     * 
     * return - list of Shift or Integer 
     */
    private static Map<String, Object> loadData(String soqlFilter, String weekStart, String weekEnd, List<String> filterContacts, List<String> filterAccounts, List<String> filterSites, String resumeFromId, List<String> filterBranches, List<String> filterJobRoles){
        // sirenum__Week__c week = getPeriod(periodId);
        // Date filterStartDate = week.sirenum__Start_Date__c;
        // Date filterEndDate = week.sirenum__Week_Ending__c;
        // Id cycleId = week.sirenum__PayrollCycle__c;
        Set<Id> shiftIds = new Set<Id>();
        // Map<Id, Attachment> shiftSignatureLinks = new Map<Id, Attachment>();

        // date strings are in mm/dd/yyyy format
        List<String> sDate = weekStart.split('/');
        List<String> eDate = weekEnd.split('/');
        Date startDate = Date.newInstance(Integer.valueOf(sDate[2]), Integer.valueOf(sDate[0]), Integer.valueOf(sDate[1]));
        Date endDate = Date.newInstance(Integer.valueOf(eDate[2]), Integer.valueOf(eDate[0]), Integer.valueOf(eDate[1]));
        System.debug('week start:: ' + weekStart);
        System.debug('week end:: ' + weekEnd);
        System.debug('startDate:: ' + startDate);
        System.debug('endDate:: ' + endDate);

        String strSOQL = 'SELECT ';
        strSOQL += 'Id, Name, sirenum__Contact__c, PO_Number__c, sirenum__Shift_Status__c, sirenum__AdHoc__c, sirenum__Shift_Date__c, sirenum__Allow_charge__c, sirenum__Allow_pay__c, Query__c,';
        // SHif length added here
        strSOQL += 'sirenum__Actual_Start_Time__c, sirenum__Actual_End_Time__c, sirenum__Billable_Start_Time__c,Minimum_Pay_Rate__c,Minimum_Pay_Rate__r.Name, sirenum__Billable_End_Time__c, sirenum__Scheduled_Shift_Length_Decimal__c, ';
        strSOQL += 'sirenum__Absolute_Start_Time__c, sirenum__Absolute_End_Time__c, RecordTypeId, sirenum__Billable_Shift_Length_Decimal__c, tc9_ext_sirint__Second_Break_Length__c, tc9_ext_sirint__Second_Break_Start_Time__c, sirenum__BreakStartTime__c, sirenum__Break_Length__c, sirenum__Absolute_Shift_Length__c,';
        strSOQL += 'sirenum__Scheduled_Start_Time__c, sirenum__Scheduled_End_Time__c, sirenum__Timesheet_summaries__c, sirenum__Placement__c, sirenum__Placement__r.Name, SK_Feedback__c, ';
        strSOQL += 'sirenum__Contact__r.Name, sirenum__Site__c, sirenum__Site__r.Name, sirenum__Contract__c, sirenum__Cancelled__c, sirenum__CancellationReason__c,';
        strSOQL += '(SELECT Id, sirenum__Shift__c, sirenum__Start_Time__c, sirenum__End_Time__c, sirenum__Duration__c FROM sirenum__Shift_Breaks__r), ';
        // strSOQL += ('(SELECT Id FROM Attachments ORDER BY CreatedDate DESC), ');
        // NEW for expenses
        // strSOQL += '(SELECT Id, Shift__c, sirenum__Expense_Type__c, sirenum__Expense_Type__r.Name, sirenum__Expense_Type__r.sirenum__Value__c, sirenum__Units__c FROM ShiftExpenses__r), ';
        // strSOQL += '(SELECT Id, sirenum__Timesheet__c ,Shift__c, Shift_Date__c, sirenum__Expense_Type__c, sirenum__Expense_Type__r.Name, sirenum__Expense_Type__r.sirenum__Value__c, sirenum__Units__c, sirenum__Amount__c, sirenum__Approved__c, sirenum__Approved_For_Payment__c, sirenum__Is_Locked__c FROM ShiftExpenses__r), ';
        strSOQL += 'sirenum__Site__r.sirenum__Operating_Company__c, sirenum__Site__r.sirenum__Operating_Company__r.Name,';
        // get signature from content document link
        // strSOQL += '(SELECT Id, Title FROM ContentDocumentLink__r), ';
        strSOQL += 'sirenum__Rota__c, sirenum__Rota__r.Name, sirenum__Contract__r.Name, sirenum__Contract__r.sirenum__Account_Manager__c, sirenum__Contract__r.sirenum__Account_Manager__r.Name, Rejected__c, Rejection_Reason__c,';
        strSOQL += 'sirenum__Team__c, sirenum__Team__r.Name, sirenum__Team__r.sirenum__Account__c,';
        // NEW
        strSOQL += 'sirenum__Contact__r.FirstName, sirenum__Contact__r.LastName, ';
        strSOQL += 'Timesheet_Approver_Name__c, Timesheet_Approver_Position__c ';
        // strSOQL += '(SELECT Id, Name, sirenum__Contact__c, sirenum__Rank__c, sirenum__Score__c, sirenum__Site__c, Shift__c FROM Ratings__r)';
        //  strSOQL += ', (SELECT Id, CreatedDate FROM Attachments WHERE Name LIKE \'ESign-%\' ORDER BY CreatedDate DESC LIMIT 1) ';
        strSOQL += ', (SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.Title, ContentDocument.FileExtension,  ContentDocument.LatestPublishedVersionId FROM ContentDocumentLinks WHERE ContentDocumentId IN (SELECT Id FROM ContentDocument)) ';
        strSOQL += ', (SELECT Id, Name, ContentType FROM Attachments)';
        strSOQL += 'FROM sirenum__Shift__c ';
        
        // NOTE OG
        // strSOQL += 'WHERE (sirenum__Shift_Date__c >=: filterStartDate AND sirenum__Shift_Date__c <=: filterEndDate) ';
        // strSOQL += 'AND sirenum__Team__r.sirenum__Account__r.sirenum__PayrollCycle__c =: cycleId ';
        // NOTE causing some shifts not to show when it overnite shifts
        // strSOQL += 'WHERE (sirenum__Shift_Date__c >=: startDate AND sirenum__Shift_Date__c <=: endDate)';
        strSOQL += 'WHERE (sirenum__Scheduled_Local_Start_Date__c >= :startDate AND sirenum__Scheduled_Local_End_Date__c <= :endDate)';
        
        strSOQL += 'AND sirenum__Cancelled__c = false ';
        // set published to false to get around validtion rule for testing
        // NOTE uncomment Test.isRunningTest() Ternary and comment out the line for Is_Test_Shift__c = true
        // strSOQL += Test.isRunningTest() ? 'AND sirenum__Published__c = false ' : 'AND sirenum__Published__c = true ';
        strSOQL += 'And (sirenum__Published__c = true OR Is_Test_Shift__c = true)';
        strSOQL += 'AND sirenum__Contact__c != null ';

        if(soqlFilter != null && soqlFilter != 'null' && soqlFilter.length() > 0) {
            strSOQL += 'AND (' + soqlFilter + ') ';
        }
        
        if(filterContacts != null && !filterContacts.isEmpty()){
            strSOQL += 'AND  sirenum__Contact__c IN:filterContacts ';
        }
        
        if(filterAccounts != null && !filterAccounts.isEmpty()){
    		strSOQL += 'AND sirenum__Site__r.sirenum__Operating_Company__c IN :filterAccounts ';
            
		}
        
        if(filterSites != null && !filterSites.isEmpty()){
            strSOQL += 'AND sirenum__Site__c IN:filterSites ';
        }

        if(filterJobRoles != null && !filterJobRoles.isEmpty()){
            strSOQL += 'AND sirenum__Team__c IN:filterJobRoles ';
        }        

        if(filterBranches != null && !filterBranches.isEmpty()){

            strSOQL += 'AND sirenum__Site__r.sirenum__Operating_Company__r.Branch__c IN:filterBranches ';
            system.debug('Branch filter applied: ' + filterBranches);
        }        

        //Staged loading filter
        if(!String.isBlank(resumeFromId)){
            strSOQL += 'AND Id > \'' + String.escapeSingleQuotes(resumeFromId) + '\' ';
        }
            
        strSOQL += 'ORDER BY Id ASC ';//sirenum__Contact__r.Name ASC, sirenum__Absolute_Start_Time__c ASC,
        strSOQL += 'LIMIT ' +  MAX_RECORDS_PER_BATCH + ' ';
        

        List<sirenum__Shift__c> shifts = Database.query(strSOQL);
        return new Map<String, Object>{
            // 'records' => Database.query(strSOQL)
            'records' => shifts,
            'siteTimezones' => getSiteTimezones(shifts)
        };
    }

    private static Map<Id, String> getSiteTimezones(List<sirenum__Shift__c> shifts) {
        Set<Id> siteIds = new Set<Id>();
        Map<Id, String> siteTimezones = new Map<Id, String>();
        List<sirenum__Site__c> sites = new List<sirenum__Site__c>();

        for (sirenum__Shift__c shift : shifts) {
            if (!siteIds.contains(shift.sirenum__Site__c)) {
                siteIds.add(shift.sirenum__Site__c);
            }
        }
        
        sites = [SELECT Id, sirenum__Timezone__c FROM sirenum__Site__c WHERE Id IN :siteIds];

        for (sirenum__Site__c site : sites) {
            if (!siteTimezones.containsKey(site.Id)) {
                siteTimezones.put(site.Id, site.sirenum__Timezone__c);
            }
        }

        return siteTimezones;
    }

    private static sirenum__Week__c getPeriod(String periodId){
        List<sirenum__Week__c> weeks = [SELECT Id, sirenum__Week_Ending__c, sirenum__Start_Date__c, sirenum__PayrollCycle__c FROM sirenum__Week__c WHERE Id =:periodId];
        if(!weeks.isEmpty())
            return weeks[0];

        return null;
    }
    
    public class SaveResultItem{
        public String recId;
        public Boolean success;
        public List<ErrorMessage> errors;

        public SaveResultItem(String recId, Boolean success, List<ErrorMessage> errors){
            this.recId = recId;
            this.success = success;
            this.errors = errors;
        }
    }

    public class ErrorMessage{
        public Integer errorItem;
        public String statusCode;
        public String message;
        public String fields;

        public ErrorMessage(Integer errorItem, String statusCode, String message, String fields){
            this.errorItem = errorItem;
            this.statusCode = statusCode;
            this.message = message;
            this.fields = fields;
        }
    }

    @AuraEnabled
    public static string getShiftSignature(ContentDocumentLink documentLink) {
        try{
            ContentDocument signatureDocument = [
                SELECT Id, Title, FileType, Description
                FROM ContentDocument
                WHERE Id = :documentLink.Id
            ];
 
            return JSON.serialize(new Map<string, object> {
                'signature' => signatureDocument
            });
        } catch(Exception e) {
            String generalError = String.format(
                Label.CRM_GeneralApexFailure,
                new Object[]{
                    e.getMessage(),
                    e.getLineNumber(),
                    e.getStackTraceString()
                }
            );
            return JSON.serialize(new SIM_Response.ErrorResponse(generalError));
        }
    }

    public class ApprovalException extends exception{}
}