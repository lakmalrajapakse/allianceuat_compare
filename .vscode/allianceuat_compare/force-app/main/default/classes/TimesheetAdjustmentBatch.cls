/*
TimesheetAdjustmentBatch b = new TimesheetAdjustmentBatch();
b.execute(null);

System.schedule('TimesheetAdjustmentBatch 01', '0 01 * * * ?', new TimesheetAdjustmentBatch());
System.schedule('TimesheetAdjustmentBatch 06', '0 06 * * * ?', new TimesheetAdjustmentBatch());
System.schedule('TimesheetAdjustmentBatch 11', '0 11 * * * ?', new TimesheetAdjustmentBatch());
System.schedule('TimesheetAdjustmentBatch 16', '0 16 * * * ?', new TimesheetAdjustmentBatch());
System.schedule('TimesheetAdjustmentBatch 21', '0 21 * * * ?', new TimesheetAdjustmentBatch());
System.schedule('TimesheetAdjustmentBatch 26', '0 26 * * * ?', new TimesheetAdjustmentBatch());
System.schedule('TimesheetAdjustmentBatch 31', '0 31 * * * ?', new TimesheetAdjustmentBatch());
System.schedule('TimesheetAdjustmentBatch 36', '0 36 * * * ?', new TimesheetAdjustmentBatch());
System.schedule('TimesheetAdjustmentBatch 41', '0 41 * * * ?', new TimesheetAdjustmentBatch());
System.schedule('TimesheetAdjustmentBatch 46', '0 46 * * * ?', new TimesheetAdjustmentBatch());
System.schedule('TimesheetAdjustmentBatch 51', '0 51 * * * ?', new TimesheetAdjustmentBatch());
System.schedule('TimesheetAdjustmentBatch 56', '0 56 * * * ?', new TimesheetAdjustmentBatch());
*/
/**
*   Class         :  ShiftTimesheetBatch
*   Description   :  Scheduled and Invokable class for the creation of Shift Timesheets
*   Author        :  Skie
*   CreateDate    :  01/07/2022

    Change History
    ******************************************************************************************************************************************
         SCRUM        ModifiedBy        Date            Requested By                           Description                              Tag
    ******************************************************************************************************************************************
        SC-34087    Tew             06/10/2022            Ben                 Update all Timesheet Items related to the Timesheet being adjusted to clear the date pay transaction generated to NULL
        C9D-93      Tew             15/11/2022            Ben                 Add Timesheet Adjustment Invocable method
        C9D-121     Tew             17/04/2023            Ben                 Update Pay transaction with lookups to the Reversed From Timesheet, Original TSE, Original TSI
        C9D-121     Tew             20/04/2023            Ben                 Count Timesheet Reversed count every time when updating the timesheet
        C9D-126     Tew             11/05/2023            Ben                 Update TimesheetAdjustmentBatchTest to update TSI & EXP mapping.
**/
public without sharing class TimesheetAdjustmentBatch implements Database.Batchable<sObject>, Schedulable, Database.Stateful
{
    public static Timesheet_Adjustment_Setting__c setting = Timesheet_Adjustment_Setting__c.getOrgDefaults();
    public static tc9_pr__Override_TC9P_Validation__c validationSetting = tc9_pr__Override_TC9P_Validation__c.getOrgDefaults();

    public static final String APPROVED_STATUS = 'Approved';
    public static final String SUBMITTED_STATUS = 'Submitted';
    public static final String NEW_STATUS = 'New';

    public Set<Id> shiftIds = new Set<Id>();
    public Set<String> errorMessages = new Set<String>();

    // FOR UNIT TEST
    @testvisible
    private Boolean isTestUpdatePtFail = false;

    public void execute(SchedulableContext SC) 
    {
        TimesheetAdjustmentBatch.process();
    }

    @InvocableMethod(label='Timesheet Adjustment Job' description='Timesheet Adjustment Job' category='Timsheet')
    public static void process()
    {
        List<AsyncApexJob> jobs = [SELECT Id, ApexClassId, Status 
                                   FROM AsyncApexJob 
                                   WHERE ApexClassId IN (select id from ApexClass where Name = 'TimesheetAdjustmentBatch') 
                                   AND Status NOT IN ('Aborted', 'Completed', 'Failed') 
                                   AND JobType = 'BatchApex'];
                                   
        if(jobs.isEmpty()) {
            Integer batchSize = setting.Timesheet_Adjustment_Batch_Size__c != null ? Integer.valueOf(setting.Timesheet_Adjustment_Batch_Size__c) : 200; 
            TimesheetAdjustmentBatch batch = new TimesheetAdjustmentBatch();
            System.debug(Database.executeBatch(batch, batchSize));

        } else {
            System.debug('WARN with TimesheetAdjustmentBatch: There is in-progress batch. jobId=' + jobs.get(0)?.Id);
        }   
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('start');  
        String ptField = String.join(new List<String>(Schema.SObjectType.tc9_pr__Pay_Transaction__c.fields.getMap().keySet()), ',');
        String ptQuery = ' SELECT {FIELDS} , tc9_et__Timesheet__r.Adjustment_Reason__c FROM tc9_et__Pay_Transactions__r ';
        ptQuery = ptQuery.replace('{FIELDS}', ptField);
        
        String tseQuery = ' SELECT Id, tc9_et__Submitted_Flag__c, tc9_et__Submitted_Date__c FROM tc9_et__Timesheet_Entries__r ';
 
        String tsQuery = ' SELECT Id, Reversed_Count__c, TS_Adjustment_Approval_Status__c, tc9_et__Approval_Status__c, ' +
                         ' tc9_et__Approved_Rejected_By__c, tc9_et__Approved_Rejected_on_Behalf_Reason__c, tc9_et__Approved_Rejected_on_Behalf_User__c, ' +
                         ' tc9_et__Submitted_Date__c, ' + 
                         ' (' + ptQuery + '), ' +
                         ' (' + tseQuery + ') ' +
                         ' FROM tc9_et__Timesheet__c ' +
                         ' WHERE ScheduledJobProcessed__c = TRUE ' +
                         ' AND tc9_et__Approval_Status__c = :APPROVED_STATUS ' +
                         ' ORDER BY Id ASC ';

        return Database.getQueryLocator(tsQuery);
    }

    public void execute(Database.BatchableContext bc, List<tc9_et__Timesheet__c> timesheets) {
        System.debug('execute');
        try {
            validationSetting.tc9_et__OV_Timesheet_Item__c = true;
            update validationSetting;

            List<tc9_pr__Pay_Transaction__c> transactionsToInsert = new List<tc9_pr__Pay_Transaction__c>();
            List<tc9_pr__Pay_Transaction__c> transactionsToUpdate = new List<tc9_pr__Pay_Transaction__c>();
            List<tc9_pr__Pay_Transaction__c> transactionsToDelete = new List<tc9_pr__Pay_Transaction__c>();
            List<tc9_et__Timesheet__c> timesheetsToUpdate = new List<tc9_et__Timesheet__c>();
            List<tc9_et__Timesheet_Entry__c> timesheetEntriesToUpdate = new List<tc9_et__Timesheet_Entry__c>();
            
            for (tc9_et__Timesheet__c timesheet : timesheets) {
                //Loop Transactions
                for (tc9_pr__Pay_Transaction__c pt : timesheet.tc9_et__Pay_Transactions__r) {

                    //Not Paid of Invoiced
                    if (pt.tc9_pr__Pay_Batch__c == null && pt.tc9_et__Invoice_Item__c == null) {
                        transactionsToDelete.add(pt); //Delete Transactions

                    } else {
                        if (pt.tc9_pr__Pay_Batch__c != null ||
                            (pt.tc9_et__Invoice_Item__c != null && 
                             pt.tc9_et__Has_Been_Credited__c == false && pt.tc9_et__Is_Credit_Record__c == false)) //Reversal Required
                        {
                            //Create Pay Transactions                    
                            tc9_pr__Pay_Transaction__c trnToInsert = buildInsertPayTransaction(pt);
                            transactionsToInsert.add(trnToInsert);
                        } 
                        {
                            //Update Original Transaction
                            tc9_pr__Pay_Transaction__c trnToUpdate = buildUpdatePayTransaction(pt);
                            transactionsToUpdate.add(trnToUpdate);
                        }                    
                    }             
                }

                //Update Timesheet
                tc9_et__Timesheet__c timesheetToUpdate = buildUpdateTimesheet(timesheet);
                timesheetsToUpdate.add(timesheetToUpdate);

                //Update TSE
                for (tc9_et__Timesheet_Entry__c tse : timesheet.tc9_et__Timesheet_Entries__r) {
                    tc9_et__Timesheet_Entry__c timesheetEntryToUpdate = buildUpdateTimesheetEntry(tse, timesheet);
                    timesheetEntriesToUpdate.add(timesheetEntryToUpdate);              
                }
            }
            
            delete transactionsToDelete;

            // Create a savepoint before insert new pay transactions.
            Savepoint sp = Database.setSavepoint(); 
            insert transactionsToInsert;

            List<Database.SaveResult> results = Database.update(transactionsToUpdate, false);
            List<tc9_pr__Debug_Log__c> logs = new List<tc9_pr__Debug_Log__c>();
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    String errorJSON = JSON.serializePretty(results[i].getErrors());
                    String errorMessage = 'payTransactionId=' + transactionsToUpdate[i].Id + '\nError Message=' + errorJSON;
                    errorMessages.add(errorMessage);

                    tc9_pr__Debug_Log__c log = buildDebugLog('Errors from TimesheetAdjustmentBatch when updating pay transactions', transactionsToUpdate[i].Id, 'tc9_pr__Pay_Transaction__c', errorJSON);
                    logs.add(log);
                }
            }

            if(!logs.isEmpty()) {
                // Rollback if original Pay Transactions were unable to be updated.
                Database.rollback(sp);

                tc9_pr__Debug_Header__c header = buildDebugHeader('Errors from TimesheetAdjustmentBatch when updating pay transactions', bc.getJobId());
                insert header;

                for(tc9_pr__Debug_Log__c log : logs) {
                    log.tc9_pr__Debug_Header__c = header.Id;
                }
                insert logs;

                // Stop process if there are errors.
                return;
            }  

            update timesheetsToUpdate;
            update timesheetEntriesToUpdate;
            
            List<tc9_et__Timesheet_Item__c> timesheetItems = [SELECT Id, tc9_et__Date_Pay_Transaction_Generated__c, tc9_et__Submitted_Date__c,
                                                              tc9_et__Approved_Rejected_Date__c, tc9_et__Approved_Rejected_on_Behalf_Reason__c, 
                                                              tc9_et__Approved_Rejected_on_Behalf_User__c, tc9_et__Approved_Rejected_By__c, 
                                                              tc9_et__Approval_Flag__c, tc9_et__Submitted_Flag__c, 
                                                              tc9_et__Timesheet__c, tc9_et__Timesheet__r.TS_Adjustment_Approval_Status__c,
                                                              tc9_et__Timesheet__r.tc9_et__Approval_Status__c,
                                                              tc9_et__Timesheet__r.tc9_et__Approved_Rejected_on_Behalf_Reason__c,
                                                              tc9_et__Timesheet__r.tc9_et__Approved_Rejected_on_Behalf_User__c,
                                                              tc9_et__Timesheet__r.tc9_et__Submitted_Date__c, tc9_et__Timesheet__r.tc9_et__Approved_Rejected_By__c 
                                                              FROM tc9_et__Timesheet_Item__c 
                                                              WHERE tc9_et__Timesheet__c IN :timesheets];

            List<tc9_et__Timesheet_Item__c> uTimesheetItems = new List<tc9_et__Timesheet_Item__c>();                                                
            if(!timesheetItems.isEmpty()) {                                            
                for(tc9_et__Timesheet_Item__c timesheetItem : timesheetItems) {
                    uTimesheetItems.add(buildUpdateTimesheetItem(timesheetItem));
                }

                update uTimesheetItems;
            }
            
            List<tc9_et__Expense__c> expenses = [SELECT Id, tc9_et__Timesheet__c, tc9_et__Timesheet__r.TS_Adjustment_Approval_Status__c, tc9_et__Submitted_Date__c,
                                                 tc9_et__Timesheet__r.tc9_et__Approval_Status__c, tc9_et__Timesheet__r.tc9_et__Approved_Rejected_By__c,
                                                 tc9_et__Timesheet__r.tc9_et__Approved_Rejected_on_Behalf_Reason__c,
                                                 tc9_et__Timesheet__r.tc9_et__Approved_Rejected_on_Behalf_User__c,
                                                 tc9_et__Timesheet__r.tc9_et__Submitted_Date__c, tc9_et__Submitted_Flag__c  
                                                 FROM tc9_et__Expense__c
                                                 WHERE tc9_et__Timesheet__c IN :timesheets];
           
            List<tc9_et__Expense__c> uExpenses = new List<tc9_et__Expense__c>();  
            if(!expenses.isEmpty()) {
                for(tc9_et__Expense__c exp : expenses) {
                    uExpenses.add(buildUpdateExpense(exp));
                }

                update uExpenses;
            }

            validationSetting.tc9_et__OV_Timesheet_Item__c = false;
            update validationSetting;

        } catch(Exception e) {
            System.debug('ERROR with TimesheetAdjustmentBatch.execute ERROR: message=' + e.getMessage() + ', stackTrace=' + e.getStackTraceString());
            errorMessages.add(e.getMessage());
        }
    }

    public void finish(Database.BatchableContext bc) {
        //validate async job error or execution error and send an email
        //if there is any error of execution or async job, then notification email will be sent to current user.
        BatchErrorEmailNotificationAlert alert = new BatchErrorEmailNotificationAlert(bc.getJobId(), 
                                                                                      BatchErrorEmailNotificationAlert.BatchCtrl.TimesheetAdjustmentBatch,
                                                                                      errorMessages);
        
        alert.sendEmail();
        
        System.debug('finish');
    }

    public tc9_pr__Pay_Transaction__c buildInsertPayTransaction(tc9_pr__Pay_Transaction__c pt) {
        tc9_pr__Pay_Transaction__c transactionToInsert = pt.clone(false, true ,false ,true);
        transactionToInsert.tc9_pr__Quantity__c = -1 * (pt.tc9_pr__Quantity__c);

        if (pt.tc9_et__Invoice_Item__c == NULL || (pt.tc9_et__Has_Been_Credited__c == false && pt.tc9_et__Is_Credit_Record__c == false)) {
            transactionToInsert.tc9_et__Invoice_Rate__c = pt.tc9_et__Invoice_Rate__c;

        }  else {
            transactionToInsert.tc9_et__Invoice_Rate__c = 0;
        }                    

        transactionToInsert.tc9_pr__Pay_Rate__c = pt.tc9_pr__Pay_Rate__c;                    
        transactionToInsert.tc9_pr__Pay_Batch__c = null;
        transactionToInsert.tc9_et__Invoice_Item__c = null;
        transactionToInsert.Is_Reversal__c = true;
        transactionToInsert.tc9_pr__Status__c = 'New';
        transactionToInsert.tc9_pr__Processed_Date__c = null;
        transactionToInsert.tc9_pr__Pay_Batch_Item__c = null;
        transactionToInsert.tc9_pr__Pay_Advice__c = null; 
        transactionToInsert.tc9_pr__Invoice_Payment_Status__c = 'Not Invoiced';
        transactionToInsert.tc9_et__Date_Invoice_Generated__c = null;
        transactionToInsert.tc9_et__X2cloudnine_Time2Pay_Generated__c = false;
        transactionToInsert.tc9_et__Manual_Entry__c = true;
        transactionToInsert.tc9_pr__Pay_Batch_Event__c = null;
        transactionToInsert.tc9_et__Timesheet__c = null;
        transactionToInsert.tc9_et__Timesheet_Entry__c = null;
        /*transactionToInsert.Original_Reverse_Transaction_ID__c = pt.Id;*/
        transactionToInsert.tc9_pr__Invoice_Creation_Status__c = 'No'; 
        transactionToInsert.Name = null;         
        transactionToInsert.Reversed_From_Timesheet__c = pt.tc9_et__Timesheet__c;
        transactionToInsert.OriginalTSEID__c = pt.tc9_et__Timesheet_Entry__c;
        transactionToInsert.OriginalTSIID__c = pt.tc9_et__Timesheet_Item__c;
        transactionToInsert.Original_Pay_Transaction__c = pt.Id;
        transactionToInsert.tc9_et__T2P_Product_Override__c = 'Yes';

        return transactionToInsert;
    }

    public tc9_pr__Pay_Transaction__c buildUpdatePayTransaction(tc9_pr__Pay_Transaction__c pt) {
        tc9_pr__Pay_Transaction__c transactionToUpdate = new tc9_pr__Pay_Transaction__c();
        transactionToUpdate.Id = pt.Id;                    
        transactionToUpdate.Is_Reversed__c = true;
        transactionToUpdate.Is_Reversal__c = false;
        transactionToUpdate.Reversed_From_Timesheet__c = pt.tc9_et__Timesheet__c;
        transactionToUpdate.Adjustment_Reason__c = pt.tc9_et__Timesheet__r.Adjustment_Reason__c;
        transactionToUpdate.tc9_et__Timesheet__c = null;
        transactionToUpdate.tc9_et__Timesheet_Entry__c = null;    
        transactionToUpdate.OriginalTSEID__c = pt.tc9_et__Timesheet_Entry__c;
        transactionToUpdate.OriginalTSIID__c = pt.tc9_et__Timesheet_Item__c;

        // FOR UNIT TEST ONLY
        if(this.isTestUpdatePtFail && Test.isRunningTest()) {
            transactionToUpdate.tc9_pr__Accrual_Type__c	 = 'test-update-fail';
        }
        
        return transactionToUpdate;
    }

    public static tc9_et__Timesheet__c buildUpdateTimesheet(tc9_et__Timesheet__c timesheet) {
        Boolean isSubmitted = SUBMITTED_STATUS.equalsIgnoreCase(timesheet.TS_Adjustment_Approval_Status__c);
        Boolean isApproved = APPROVED_STATUS.equalsIgnoreCase(timesheet.TS_Adjustment_Approval_Status__c);
        Boolean isNew = String.isBlank(timesheet.TS_Adjustment_Approval_Status__c) || NEW_STATUS.equalsIgnoreCase(timesheet.TS_Adjustment_Approval_Status__c);
        
        tc9_et__Timesheet__c timesheetToUpdate = new tc9_et__Timesheet__c();
        timesheetToUpdate.Id = timesheet.Id;            
        timesheetToUpdate.tc9_et__Approval_Status__c = timesheet.TS_Adjustment_Approval_Status__c == null ? 'New' : timesheet.TS_Adjustment_Approval_Status__c;
        timesheetToUpdate.tc9_et__Transaction_Creation_Stage__c = isApproved && timesheet.TS_Adjustment_Approval_Status__c != null ? '2' : '1';
        timesheetToUpdate.tc9_et__Approved_Rejected_By__c = isApproved ? timesheet.tc9_et__Approved_Rejected_By__c : null;
        timesheetToUpdate.tc9_et__Approved_Rejected_Date__c = isApproved ? System.now() : null;            
        timesheetToUpdate.tc9_et__Approved_Rejected_on_Behalf_Reason__c = isApproved ? timesheet.tc9_et__Approved_Rejected_on_Behalf_Reason__c : null;
        timesheetToUpdate.tc9_et__Approved_Rejected_on_Behalf_User__c = isApproved ? timesheet.tc9_et__Approved_Rejected_on_Behalf_User__c : null;
        timesheetToUpdate.tc9_et__Submitted_Date__c = isNew ? null : isSubmitted ? System.now() : timesheet.tc9_et__Submitted_Date__c;

        timesheetToUpdate.ScheduledJobProcessed__c = false;
        
        Decimal reversedCount = timesheet.Reversed_Count__c != null ? timesheet.Reversed_Count__c : 0;
        timesheetToUpdate.Reversed_Count__c = reversedCount + 1;

        return timesheetToUpdate;
    }

    public static tc9_et__Timesheet_Item__c buildUpdateTimesheetItem(tc9_et__Timesheet_Item__c item) { 
        Boolean isSubmitted = SUBMITTED_STATUS.equalsIgnoreCase(item.tc9_et__Timesheet__r.TS_Adjustment_Approval_Status__c);
        Boolean isApproved = APPROVED_STATUS.equalsIgnoreCase(item.tc9_et__Timesheet__r.TS_Adjustment_Approval_Status__c);
        Boolean isNew = String.isBlank(item.tc9_et__Timesheet__r.TS_Adjustment_Approval_Status__c) || 
                            NEW_STATUS.equalsIgnoreCase(item.tc9_et__Timesheet__r.TS_Adjustment_Approval_Status__c);

        tc9_et__Timesheet_Item__c uItem = new tc9_et__Timesheet_Item__c(Id=item.Id);
        uItem.tc9_et__Approval_Flag__c = isApproved;
        uItem.tc9_et__Approved_Rejected_By__c = isApproved ? item.tc9_et__Timesheet__r.tc9_et__Approved_Rejected_By__c : null;
        uItem.tc9_et__Approved_Rejected_Date__c = isApproved ? System.now() : null;            
        uItem.tc9_et__Approved_Rejected_on_Behalf_Reason__c = isApproved ? item.tc9_et__Timesheet__r.tc9_et__Approved_Rejected_on_Behalf_Reason__c : null;
        uItem.tc9_et__Approved_Rejected_on_Behalf_User__c = isApproved ? item.tc9_et__Timesheet__r.tc9_et__Approved_Rejected_on_Behalf_User__c : null;
        uItem.tc9_et__Submitted_Date__c = isNew ? null : isSubmitted ? System.now() : item.tc9_et__Submitted_Date__c;
        uItem.tc9_et__Submitted_Flag__c = isNew ? false : isSubmitted ? true : item.tc9_et__Submitted_Flag__c;
        uItem.tc9_et__Submitted_By__c = isSubmitted ? UserInfo.getUserId() : null;
        uItem.tc9_et__Date_Pay_Transaction_Generated__c = null;

        return uItem;
    }

    public static tc9_et__Expense__c buildUpdateExpense(tc9_et__Expense__c exp) {
        Boolean isSubmitted = SUBMITTED_STATUS.equalsIgnoreCase(exp.tc9_et__Timesheet__r.TS_Adjustment_Approval_Status__c);
        Boolean isApproved = APPROVED_STATUS.equalsIgnoreCase(exp.tc9_et__Timesheet__r.TS_Adjustment_Approval_Status__c);
        Boolean isNew = String.isBlank(exp.tc9_et__Timesheet__r.TS_Adjustment_Approval_Status__c) || NEW_STATUS.equalsIgnoreCase(exp.tc9_et__Timesheet__r.TS_Adjustment_Approval_Status__c);

        tc9_et__Expense__c uExp = new tc9_et__Expense__c(Id=exp.Id);
        uExp.tc9_et__Approval_Flag__c = isApproved;
        uExp.tc9_et__Approved_Rejected_By__c = isApproved ? exp.tc9_et__Timesheet__r.tc9_et__Approved_Rejected_By__c : null;
        uExp.tc9_et__Approved_Rejected_Date__c = isApproved ? System.now() : null;            
        uExp.tc9_et__Approved_Rejected_on_Behalf_Reason__c = isApproved ? exp.tc9_et__Timesheet__r.tc9_et__Approved_Rejected_on_Behalf_Reason__c : null;
        uExp.tc9_et__Approved_Rejected_on_Behalf_User__c = isApproved ? exp.tc9_et__Timesheet__r.tc9_et__Approved_Rejected_on_Behalf_User__c : null;
        uExp.tc9_et__Submitted_Date__c = isNew ? null : isSubmitted ? System.now() : exp.tc9_et__Submitted_Date__c;
        uExp.tc9_et__Submitted_Flag__c = isNew ? false : isSubmitted ? true : exp.tc9_et__Submitted_Flag__c;
        uExp.tc9_et__Date_Pay_Transaction_Generated__c = null;

        return uExp;
    }

    public static tc9_et__Timesheet_Entry__c buildUpdateTimesheetEntry(tc9_et__Timesheet_Entry__c tse, tc9_et__Timesheet__c timesheet) {
        Boolean isSubmitted = SUBMITTED_STATUS.equalsIgnoreCase(timesheet.TS_Adjustment_Approval_Status__c);
        Boolean isApproved = APPROVED_STATUS.equalsIgnoreCase(timesheet.TS_Adjustment_Approval_Status__c);
        Boolean isNew = String.isBlank(timesheet.TS_Adjustment_Approval_Status__c) || NEW_STATUS.equalsIgnoreCase(timesheet.TS_Adjustment_Approval_Status__c);
        
        tc9_et__Timesheet_Entry__c utimesheetEntry = new tc9_et__Timesheet_Entry__c(Id=tse.Id);
        utimesheetEntry.tc9_et__Approval_Flag__c = isApproved;
        utimesheetEntry.tc9_et__Approved_Rejected_By__c = isApproved ? timesheet.tc9_et__Approved_Rejected_By__c : null;
        utimesheetEntry.tc9_et__Approved_Rejected_Date__c = isApproved ? System.now() : null;
        utimesheetEntry.tc9_et__Approved_Rejected_on_Behalf_Reason__c = isApproved ? timesheet.tc9_et__Approved_Rejected_on_Behalf_Reason__c : null;
        utimesheetEntry.tc9_et__Approved_Rejected_on_Behalf_User__c = isApproved ? timesheet.tc9_et__Approved_Rejected_on_Behalf_User__c : null;
        utimesheetEntry.tc9_et__Submitted_Date__c = isNew ? null : isSubmitted ? System.now() : utimesheetEntry.tc9_et__Submitted_Date__c;
        utimesheetEntry.tc9_et__Submitted_Flag__c = isNew ? false : isSubmitted ? true : tse.tc9_et__Submitted_Flag__c; 
        utimesheetEntry.tc9_et__Date_Pay_Transaction_Generated__c = null;

        return utimesheetEntry;
    }

    public static tc9_pr__Debug_Header__c buildDebugHeader(String processName, String jobId) {
        tc9_pr__Debug_Header__c header = new tc9_pr__Debug_Header__c();
        header.tc9_pr__Area__c = 'TimesheetAdjustmentBatch';
        header.tc9_pr__Process_Name__c = processName;
        header.tc9_pr__Description__c = 'One or more errors from TimesheetAdjustmentBatch. See Debug Lines for details.';
        header.tc9_pr__Job_Id__c = jobId;

        return header;
    }

    private static tc9_pr__Debug_Log__c buildDebugLog(String processName, String recordId, String objectName, String error) {
        tc9_pr__Debug_Log__c log = new tc9_pr__Debug_Log__c();
        log.tc9_pr__Area__c = 'TimesheetAdjustmentBatch';
        log.tc9_pr__Record_Detail__c = '<a href="/' + recordId + '" target="_blank">' + recordId + '</a>';
        log.tc9_pr__Source__c = processName;
        log.tc9_pr__Record_Type__c = objectName;
        log.tc9_pr__Description__c = error?.left(10000);
        
        return log;
    }
}