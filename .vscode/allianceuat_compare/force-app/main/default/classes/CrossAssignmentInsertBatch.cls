public class CrossAssignmentInsertBatch implements Database.Batchable<sObject>, Schedulable {
    
    public void execute(SchedulableContext sc) {
        insertCrossAssignment(null);
    }

    @InvocableMethod(label = 'Cross assignment insertion')
    public static void insertCrossAssignment(List<List<id>> timesheetIds) {
        List<Id> tsIds = new List<Id>();
        if(timesheetIds != null && !timesheetIds.isEmpty() && timesheetIds[0] != null) {
            for (List<Id> request : timesheetIds) {
                tsIds.addAll(request);
            }
        }

        List<AsyncApexJob> jobs = [SELECT Id, ApexClassId, Status 
                                   FROM AsyncApexJob 
                                   WHERE ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = 'CrossAssignmentInsertBatch')
                                   AND Status NOT IN ('Aborted', 'Completed', 'Failed')
                                   AND JobType = 'BatchApex'];
        if (jobs.isEmpty()) {
            CrossAssignmentInsertBatch batch = new CrossAssignmentInsertBatch();
            batch.timesheetIds = tsIds;

            Database.executeBatch(batch, 1);
        } else {
            System.debug('WARN with CrossAssignmentInsertBatch: There is an in-progress batch. jobId=' + jobs.get(0)?.Id);
        }
    }

    private List<Id> timesheetIds;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        updateValidationSetting(true);
        String query = ' SELECT Id, tc9_et__End_Date__c, ' + 
                       ' tc9_et__Assignment__r.Cross_Assignment_Group_By_ID__c, tc9_et__Assignment__r.Cross_Assignment_Timesheet_Status__c, Start_Date__c, tc9_et__Payee__c, ' + 
                       '  (SELECT Id, tc9_et__Timesheet__c FROM tc9_et__Timesheet_Entries__r ' + 
                       '   WHERE Cross_Assignment_Timesheet_Entry__c = TRUE) ' + 
                       ' FROM tc9_et__Timesheet__c ' +
                       ' WHERE Cross_Assignment_Status__c = \'Pending Insert\' ';

        if (timesheetIds != null && !timesheetIds.isEmpty()) {
            query += ' AND Id IN :timesheetIds';
        }

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<tc9_et__Timesheet__c> timesheets) {
        System.debug('[EXECUTE] CrossAssignmentInsertBatch.execute timesheets=' + timesheets);
        List<tc9_et__Timesheet_Entry__c> delEntries = new List<tc9_et__Timesheet_Entry__c>();
        List<tc9_pr__Pay_Transaction__c> delPayTrns = new List<tc9_pr__Pay_Transaction__c>();

        Set<String> crossAssignmentGrpSet = new Set<String>();
        for (tc9_et__Timesheet__c ts : timesheets) {
            crossAssignmentGrpSet.add(ts.tc9_et__Assignment__r.Cross_Assignment_Group_By_ID__c);
        }
        
        Map<String, List<tc9_et__Timesheet_Entry__c>> nonCrossAssignmentTseMap = new Map<String,List<tc9_et__Timesheet_Entry__c>>();
        String queryTSEStr = ' SELECT ' + getFields('tc9_et__Timesheet_Entry__c') +
                             ' , tc9_et__Timesheet__r.Name ' + 
                             ' FROM tc9_et__Timesheet_Entry__c WHERE Cross_Assignment_Timesheet_Entry__c = FALSE ' + 
                             ' AND tc9_et__Total_Hours__c > 0 ' +
                             ' AND Cross_Assignment_Group_By_ID__c IN :crossAssignmentGrpSet ';

        List<tc9_et__Timesheet_Entry__c> tses = Database.query(queryTSEStr);
        for(tc9_et__Timesheet_Entry__c tse : tses) {
            if(!nonCrossAssignmentTseMap.containsKey(tse.Cross_Assignment_Group_By_ID__c)) {
                nonCrossAssignmentTseMap.put(tse.Cross_Assignment_Group_By_ID__c, new List<tc9_et__Timesheet_Entry__c>{tse});
                
            } else {
                nonCrossAssignmentTseMap.get(tse.Cross_Assignment_Group_By_ID__c).add(tse);
            }
        }

        System.debug('[INFO] CrossAssignmentInsertBatch.execute nonCrossAssignmentTseMap=' + nonCrossAssignmentTseMap);

        for (tc9_et__Timesheet__c ts : timesheets) {
            if (ts.tc9_et__Timesheet_Entries__r != null && !ts.tc9_et__Timesheet_Entries__r.isEmpty()) {
                delEntries.addAll(ts.tc9_et__Timesheet_Entries__r);
            }
        }

        System.debug('[INFO] CrossAssignmentInsertBatch.execute delEntries size=' + delEntries.size() + ' delEntries=' + delEntries);

        List<tc9_et__Timesheet_Entry__c> newEntries = new List<tc9_et__Timesheet_Entry__c>();

        for (tc9_et__Timesheet__c ts : timesheets) {
            List<tc9_et__Timesheet_Entry__c> nonCrossAssignmentTSEs = nonCrossAssignmentTseMap.get(ts.tc9_et__Assignment__r.Cross_Assignment_Group_By_ID__c);
            Set<String> varTimesheets = new Set<String>();
        
            System.debug('CrossAssignmentInsertBatch.execute nonCrossAssignmentTSEs=' + nonCrossAssignmentTSEs);
        
            if (nonCrossAssignmentTSEs != null && !nonCrossAssignmentTSEs.isEmpty()) {
                
                String status = ts.tc9_et__Assignment__r.Cross_Assignment_Timesheet_Status__c == 'Approved' ? 'Approved' : null;
                System.debug('ts status=' + status);
        
                for(tc9_et__Timesheet_Entry__c tse : nonCrossAssignmentTSEs) {
                    if(status == 'Approved' && tse.tc9_et__Approval_Status__c == status && validateTSE(ts, tse)) {
                        tc9_et__Timesheet_Entry__c newEntry = cloneTSE(tse, ts);
                        newEntries.add(newEntry);
    
                        varTimesheets.add(tse.tc9_et__Timesheet__r.Name);

                    } else if(status != 'Approved' && validateTSE(ts, tse)){
                        tc9_et__Timesheet_Entry__c newEntry = cloneTSE(tse, ts);
                        newEntries.add(newEntry);
    
                        varTimesheets.add(tse.tc9_et__Timesheet__r.Name);
                    }
                }
            }        

            ts.tc9_et__Transaction_Creation_Stage__c = '2';
            ts.Cross_Assignment_Status__c = 'Pending Delete';
            String assignmentDetail = 'Timesheets Included in Cross-Assignment Interpretation:' + String.join(new List<String>(varTimesheets), ',') + ' - ' + System.now();
            ts.Cross_Assignment_Details__c = !varTimesheets.isEmpty() && varTimesheets != null ? assignmentDetail.left(255) : 'No Cross-Assignment Timesheets Found';
        }

        System.debug('[INFO] CrossAssignmentInsertBatch.execute newEntries=' + newEntries);
        System.debug('[INFO] CrossAssignmentInsertBatch.execute newEntries.size()=' + newEntries.size());

        Set<Id> failedInsLineTimesheetIdset = new Set<Id>();
        List<tc9_pr__Debug_Log__c> logs = new List<tc9_pr__Debug_Log__c>();

        if(!newEntries.isEmpty()) {
            Database.SaveResult[] insertResults = Database.insert(newEntries, false);
            for (Integer i = 0; i < insertResults.size(); i++) {
                if (!insertResults[i].isSuccess()) {
                    logs.add(buildDebugLog(newEntries[i].Id, 'Timesheet Entries', JSON.serialize(insertResults[i].getErrors())));
                    failedInsLineTimesheetIdset.add(newEntries[i].tc9_et__Timesheet__c);
                } 
            }
        }

        if(!delEntries.isEmpty()) {
            Database.DeleteResult[] delResults = Database.delete(delEntries, false);
            for (Integer i = 0; i < delResults.size(); i++) {
                if (!delResults[i].isSuccess()) {
                    logs.add(buildDebugLog(delEntries[i].Id, 'Timesheet Entries', JSON.serialize(delResults[i].getErrors())));
                } 
            }
        }

        System.debug('failedInsLineTimesheetIdset=' + failedInsLineTimesheetIdset);

        if(!failedInsLineTimesheetIdset.isEmpty()) {
            for(tc9_et__Timesheet__c ts : timesheets)  {
                if(failedInsLineTimesheetIdset.contains(ts.Id)) {
                    ts.Cross_Assignment_Status__c = 'Insert Failed';
                    ts.Cross_Assignment_Details__c = 'Cross-Assignment Insert Failed, Check Debug Logs for Error - ' + System.now();
                }
            }

            //delete all inserted TSEs if there is any failed insertion
            //change query
            List<tc9_et__Timesheet_Entry__c> delTSEforErrorTS = new List<tc9_et__Timesheet_Entry__c>();
            List<tc9_et__Timesheet__c> errorTSs = [SELECT Id,tc9_et__End_Date__c,
                                                    tc9_et__Assignment__r.Cross_Assignment_Group_By_ID__c, tc9_et__Assignment__r.Cross_Assignment_Timesheet_Status__c, Start_Date__c, tc9_et__Payee__c, 
                                                        (SELECT Id, tc9_et__Timesheet__c 
                                                        FROM tc9_et__Timesheet_Entries__r 
                                                        WHERE Cross_Assignment_Timesheet_Entry__c = TRUE) 
                                                    FROM tc9_et__Timesheet__c
                                                    WHERE Id IN :failedInsLineTimesheetIdset];
            
            for (tc9_et__Timesheet__c ts : errorTSs) {
                if (ts.tc9_et__Timesheet_Entries__r != null && !ts.tc9_et__Timesheet_Entries__r.isEmpty()) {
                    delTSEforErrorTS.addAll(ts.tc9_et__Timesheet_Entries__r);
                }
            }

            delete delTSEforErrorTS;
        }


        if(!logs.isEmpty()) {
            tc9_pr__Debug_Header__c header = buildDebugHeader();
            insert header;

            for(tc9_pr__Debug_Log__c log : logs) {
                log.tc9_pr__Debug_Header__c = header.Id;
            }
            insert logs;
        }

        update timesheets;
    }

    public void finish(Database.BatchableContext bc) {
        updateValidationSetting(false);
    }
    
    public static tc9_pr__Debug_Header__c buildDebugHeader() {
        tc9_pr__Debug_Header__c header = new tc9_pr__Debug_Header__c();
        header.tc9_pr__Area__c = 'CrossAssignmentInsertBatch';
        header.tc9_pr__Description__c = 'One or more errors from CrossAssignmentInsertBatch. See Debug Lines for details.';
        header.tc9_pr__Process_Name__c = 'Insert dummy Cross-Assignment Timesheet Entries and Pay Transactions before Timesheet interpretation';
        return header;
    }

    public static tc9_pr__Debug_Log__c buildDebugLog(String recordId, String objectName, String error) {
        tc9_pr__Debug_Log__c log = new tc9_pr__Debug_Log__c();
        log.tc9_pr__Area__c = 'CrossAssignmentInsertBatch';
        log.tc9_pr__Record_Detail__c = '<a href="/' + recordId + '" target="_blank">' + recordId + '</a>';
        log.tc9_pr__Source__c = 'Insert dummy Cross-Assignment ' + objectName + ' and Pay Transactions before Timesheet interpretation';
        log.tc9_pr__Record_Type__c = recordId;
        log.tc9_pr__Description__c = error?.left(10000);
        return log;
    }

    private static String getFields(String objectAPI){
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectAPI).getDescribe().fields.getMap();
    
        return String.join(new List<String>(fieldMap.keySet()), ', ');
    }

    private static void updateValidationSetting(Boolean ovTSE) {
        tc9_pr__Override_TC9P_Validation__c setting = tc9_pr__Override_TC9P_Validation__c.getOrgDefaults();
        setting.tc9_et__OV_Timesheet_Entry__c = ovTSE;
        setting.tc9_et__OV_Timesheet__c = ovTSE;
        update setting;
    }

    private static tc9_et__Timesheet_Entry__c cloneTSE(tc9_et__Timesheet_Entry__c tse, tc9_et__Timesheet__c ts) {
        tc9_et__Timesheet_Entry__c newEntry = tse.clone(false, true, false, false);
        newEntry.tc9_et__Assignment__c = ts.tc9_et__Assignment__c;
        newEntry.tc9_et__Approval_Flag__c = true;
        newEntry.tc9_et__Submitted_Flag__c = true;
        newEntry.tc9_et__Timesheet__c = ts.Id;
        newEntry.Cross_Assignment_Timesheet_Entry__c = true;
        newEntry.tc9_et__Date_Pay_Transaction_Generated__c = null;
        newEntry.tc9_et__Project_Code__c = null;
        newEntry.tc9_et__Timesheet_Activity__c = null;

        return newEntry;
    }

    //boolean validateTSE method
    private static Boolean validateTSE(tc9_et__Timesheet__c ts, tc9_et__Timesheet_Entry__c tse) {
        if(tse.tc9_et__Assignment__c != ts.tc9_et__Assignment__c && 
            tse.tc9_et__Start_Date__c <= ts.tc9_et__End_Date__c && 
            tse.tc9_et__Start_Date__c >= ts.Start_Date__c) {
            return true;

        } else {
            return false;
        }
    }
}