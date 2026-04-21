public class CrossAssignmentDeleteBatch  implements Database.Batchable<sObject>, Schedulable {

    public void execute(SchedulableContext sc) {
        deleteCrossAssignment(null);
    }

    @InvocableMethod(label = 'Cross assignment deletion')
    public static void deleteCrossAssignment(List<List<Id>> timesheetIds) {
        List<Id> tsIds = new List<Id>();
        if(timesheetIds != null && !timesheetIds.isEmpty() && timesheetIds[0] != null) {
            for (List<Id> request : timesheetIds) {
                tsIds.addAll(request);
            }
        }

        List<AsyncApexJob> jobs = [SELECT Id, ApexClassId, Status 
                                   FROM AsyncApexJob 
                                   WHERE ApexClassId IN (select id from ApexClass where Name = 'CrossAssignmentDeleteBatch')
                                   AND Status NOT IN ('Aborted', 'Completed', 'Failed')
                                   AND JobType = 'BatchApex'];


        if(jobs.isEmpty()) {
            CrossAssignmentDeleteBatch batch = new CrossAssignmentDeleteBatch();
            batch.timesheetIds = tsIds;
            
            Database.executeBatch(batch, 10);

        } else {
            System.debug('WARN with CrossAssignmentDeleteBatch: There is in-progress batch. jobId=' + jobs.get(0)?.Id);
        }
    }

    private List<Id> timesheetIds;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('[START] CrossAssignmentDeleteBatch.start');
        updateValidationSetting(true);
        String query = ' SELECT Id, ' +

                       ' (SELECT Id, tc9_et__Timesheet__c FROM tc9_et__Timesheet_Entries__r ' +
                       ' WHERE Cross_Assignment_Timesheet_Entry__c = TRUE), ' +

                       ' (SELECT Id, tc9_et__Timesheet__c FROM tc9_et__Pay_Transactions__r ' +
                       ' WHERE tc9_et__Timesheet_Entry__r.Cross_Assignment_Timesheet_Entry__c = TRUE ' +
                       ' AND tc9_et__Invoice_Item__c = NULL ' +
                       ' AND tc9_pr__Pay_Batch__c = NULL) ' +

                       ' FROM tc9_et__Timesheet__c ' +
                       ' WHERE tc9_et__Transaction_Creation_Stage__c = \'3\' ' +
                       ' AND Cross_Assignment_Status__c = \'Pending Delete\'';

        if (timesheetIds != null && !timesheetIds.isEmpty()) {
            query += ' AND Id IN :timesheetIds';
        }

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<tc9_et__Timesheet__c> timesheets) {
        List<tc9_et__Timesheet_Entry__c> delEntries = new List<tc9_et__Timesheet_Entry__c>();
        List<tc9_pr__Pay_Transaction__c> delPayTrns = new List<tc9_pr__Pay_Transaction__c>();

        for(tc9_et__Timesheet__c ts : timesheets)  {
            if(ts.tc9_et__Timesheet_Entries__r != null && !ts.tc9_et__Timesheet_Entries__r.isEmpty()) {
                delEntries.addAll(ts.tc9_et__Timesheet_Entries__r);
            }
            if(ts.tc9_et__Pay_Transactions__r != null && !ts.tc9_et__Pay_Transactions__r.isEmpty()) {
                delPayTrns.addAll(ts.tc9_et__Pay_Transactions__r);
            }
        }

        Set<Id> failedDelLineTimesheetIdset = new Set<Id>();
        List<tc9_pr__Debug_Log__c> logs = new List<tc9_pr__Debug_Log__c>();

        if(!delPayTrns.isEmpty()) {
            Database.DeleteResult[] delResults = Database.delete(delPayTrns, false);
            for (Integer i = 0; i < delResults.size(); i++) {
                if (!delResults[i].isSuccess()) {
                    logs.add(buildDebugLog(delPayTrns[i].Id, 'Pay Transactions', JSON.serialize(delResults[i].getErrors())));
                    failedDelLineTimesheetIdset.add(delPayTrns[i].tc9_et__Timesheet__c);
                } 
            }
        }

        if(!delEntries.isEmpty()) {
            Database.DeleteResult[] delResults = Database.delete(delEntries, false);
            for (Integer i = 0; i < delResults.size(); i++) {
                if (!delResults[i].isSuccess()) {
                    logs.add(buildDebugLog(delEntries[i].Id, 'Timesheet Entries', JSON.serialize(delResults[i].getErrors())));
                    failedDelLineTimesheetIdset.add(delEntries[i].tc9_et__Timesheet__c);
                } 
            }
        }

        if(!logs.isEmpty()) {
            tc9_pr__Debug_Header__c header = buildDebugHeader();
            insert header;

            for(tc9_pr__Debug_Log__c log : logs) {
                log.tc9_pr__Debug_Header__c = header.Id;
            }
            insert logs;
        }

        for(tc9_et__Timesheet__c ts : timesheets)  {
            ts.Cross_Assignment_Status__c = 'Complete';

            if(failedDelLineTimesheetIdset.contains(ts.Id)) {
                ts.Cross_Assignment_Status__c = 'Delete Failed';
                ts.Cross_Assignment_Details__c = 'Cross-Assignment Delete Failed, Check Debug Logs for Error - ' + System.now(); 
            }
        }

        update timesheets;
    }

    public void finish(Database.BatchableContext bc) {
        updateValidationSetting(false);
    }

    public static tc9_pr__Debug_Header__c buildDebugHeader() {
        tc9_pr__Debug_Header__c header = new tc9_pr__Debug_Header__c();
        header.tc9_pr__Area__c = 'CrossAssignmentDeleteBatch';
        header.tc9_pr__Description__c = 'One or more errors from CrossAssignmentDeleteBatch. See Debug Lines for details.';
        header.tc9_pr__Process_Name__c = 'Delete dummy Cross-Assignment Timesheet Entries and Pay Transactions after Timesheet interpretation';
        
        return header;
    }
    
    public static tc9_pr__Debug_Log__c buildDebugLog( String recordId, String objectName, String error) {
        tc9_pr__Debug_Log__c log = new tc9_pr__Debug_Log__c();
        log.tc9_pr__Area__c = 'CrossAssignmentDeleteBatch';
        log.tc9_pr__Record_Detail__c = '<a href="/' + recordId + '" target="_blank">' + recordId + '</a>';
        log.tc9_pr__Source__c = 'Delete dummy Cross-Assignment ' + objectName + ' after Timesheet interpretation';
        log.tc9_pr__Record_Type__c = recordId;
        log.tc9_pr__Description__c = error?.left(10000);
        
        return log;
    }

    private static void updateValidationSetting(Boolean ovTSE) {
        tc9_pr__Override_TC9P_Validation__c setting = tc9_pr__Override_TC9P_Validation__c.getOrgDefaults();
        setting.tc9_et__OV_Timesheet_Entry__c = ovTSE;
        setting.tc9_et__OV_Timesheet__c = ovTSE;
        update setting;
    }
}