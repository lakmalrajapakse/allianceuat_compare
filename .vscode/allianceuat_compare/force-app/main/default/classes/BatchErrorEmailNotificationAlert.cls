/**
*   Class         :  EmailNotificationAlert
*   Description   :  Email Template Class for Email Notification Alert
*   Author        :  Skie
*   CreateDate    :  25/08/2022

    Change History
    ******************************************************************************************************************************************
         SCRUM        ModifiedBy        Date            Requested By                           Description                              Tag
    ******************************************************************************************************************************************
        SC-33994        James         06/10/2022             Ben                      Add Notification for Assignment created error
**/
public class BatchErrorEmailNotificationAlert {

    public BatchCtrl ctrl;
    public String jobId;
    public Set<String> errors;
    public String additionalErrorBody;
    public Map<String, List<String>> errorMap;
    public String emailAddress;
    
    public static String TEXT_CONTENT_TYPE = 'text/plain';

    public static Map<String, String> ERROR_EMAIL_SUBJECT_TEMPLATE = new Map<String, String>();
    static {
        ERROR_EMAIL_SUBJECT_TEMPLATE.put('ShiftAssignmentBatch', 'Failure occurred with ShiftAssignmentBatch execution.');
        ERROR_EMAIL_SUBJECT_TEMPLATE.put('ShiftTimesheetBatch', 'Failure occurred with ShiftTimesheetBatch execution.');
        ERROR_EMAIL_SUBJECT_TEMPLATE.put('ShiftTimesheetEntryBatch', 'Failure occurred with ShiftTimesheetEntryBatch execution.');
        ERROR_EMAIL_SUBJECT_TEMPLATE.put('TimesheetAdjustmentBatch', 'Failure occurred with TimesheetAdjustmentBatch execution.');
    }

    public static String ERROR_EMAIL_CONTENT_TEMPLATE;
    static {
        ERROR_EMAIL_CONTENT_TEMPLATE = 'Hi, \n ' +
            'There were failures during execution of the Apex batch job {jobId} while executing the {controllerName} \n ' +
            'Please review the error message for further details. \n\n ' +
            '{errorBody} ' +
            '{additionalErrorBody} ' +
            '{errorMap} ' +
            'Regards \n ' +
            '2cloudnine Sirenum Integration \n\n ' +
            'System Administrator Information \n '+
            'Organisation Name: {organizationName} \n ' +
            'Organisation ID: {organizationId} \n ' +
            'User:  {userName} \n ';
    }

    public static final String SHIFT_ASSIGNMENT_BATCH_ERR001 = 'SHIFT_ASSIGNMENT_BATCH_ERR001';
    public static final String SHIFT_ASSIGNMENT_BATCH_ERR002 = 'SHIFT_ASSIGNMENT_BATCH_ERR002';
    public static final String SHIFT_ASSIGNMENT_BATCH_ERR003 = 'SHIFT_ASSIGNMENT_BATCH_ERR003';
    public static final String SHIFT_ASSIGNMENT_BATCH_ERR004 = 'SHIFT_ASSIGNMENT_BATCH_ERR004';

    public static Map<String, String> ERROR_VALIDATION_TEMPLATE = new Map<String, String>();
    static {
        ERROR_VALIDATION_TEMPLATE.put(SHIFT_ASSIGNMENT_BATCH_ERR001, 'Assignment cannot be created because Team__c is null.');
        ERROR_VALIDATION_TEMPLATE.put(SHIFT_ASSIGNMENT_BATCH_ERR002, 'Assignment cannot be created because Contact__c is null.');
        ERROR_VALIDATION_TEMPLATE.put(SHIFT_ASSIGNMENT_BATCH_ERR003, 'Assignment cannot be created because Sent_to_Payroll__c is false.');
        ERROR_VALIDATION_TEMPLATE.put(SHIFT_ASSIGNMENT_BATCH_ERR004, 'Assignment cannot be created because cannot find matched Payee.');
    }

    public BatchErrorEmailNotificationAlert(String jobId, BatchCtrl ctrl, Set<String> errors) {
        this(jobId, ctrl, errors, null);
    }

    public BatchErrorEmailNotificationAlert(String jobId, BatchCtrl ctrl, Set<String> errors, Map<String, List<String>> errorMap) {
        this.jobId = jobId;
        this.ctrl = ctrl;
        this.errors = errors;
        AsyncApexJob job = getAsyncApexJobError();
        this.additionalErrorBody = job != null ? job.ExtendedStatus : null;
        this.emailAddress = job != null ? job.CreatedBy.Email : UserInfo.getUserEmail();
        this.errorMap = errorMap;
    }
    
    public void sendEmail() {
        System.debug('BEGIN with BatchErrorEmailNotificationAlert.sendEmail REQ: JobId=' + this.jobId);
        try {
            if(!isBatchError()) {
                System.debug('Do not send any error email because of no Error Content, REQ: JobId=' + this.jobId);
                return;
            }
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();     

            // Sets the paramaters of the email
            email.setSubject(ERROR_EMAIL_SUBJECT_TEMPLATE.get(this.ctrl.name()));
            email.setToAddresses(new String[] { this.emailAddress });
            email.setPlainTextBody(getContentBody());
            email.setFileAttachments(new Messaging.EmailFileAttachment[] { getAttachment() });
            
            // Sends the email
            Messaging.SendEmailResult[] result = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email }); 
            System.debug('END with BatchErrorEmailNotificationAlert.sendEmail RES: result=' + result);
        } catch(Exception e) {
            System.debug('ERROR with BatchErrorEmailNotificationAlert.sendEmail ERROR: message=' + e.getMessage() + ', stackTrace=' + e.getStackTraceString());
        }
    }
    
    public Boolean isBatchError() {
        if((this.errors != null && !this.errors.isEmpty()) || this.additionalErrorBody != null || (this.errorMap != null && !this.errorMap.isEmpty()))  {
            return true;
        }
        
        return false;
    }
    
    public AsyncApexJob getAsyncApexJobError() {
        List<AsyncApexJob> jobs = [SELECT Id, ApexClassId, JobItemsProcessed, TotalJobItems, NumberOfErrors, ExtendedStatus, CreatedBy.Email 
                                   FROM AsyncApexJob 
                                   WHERE Id = :this.jobId
                                   AND (ExtendedStatus != NULL OR NumberOfErrors != 0)
                                   LIMIT 1];
        if(!jobs.isEmpty()) {
            return jobs[0];
        }
        return null;
    }
    
    public String getErrorEmailContent(String errorParam1, String errorParam2, String errorParam3) {
        return BatchErrorEmailNotificationAlert.ERROR_EMAIL_CONTENT_TEMPLATE
            .replace('{jobId}', this.jobId)
            .replace('{controllerName}', this.ctrl.name())
            .replace('{errorBody}', errorParam1)
            .replace('{additionalErrorBody}', errorParam2)
            .replace('{errorMap}', errorParam3)
            .replace('{organizationName}', UserInfo.getOrganizationName())
            .replace('{organizationId}', UserInfo.getOrganizationId())
            .replace('{userName}', UserInfo.getUserName());
    }
    
    public String getContentBody() {    
        return getErrorEmailContent(getErrorParam1(), getErrorParam2(), getErrorParam3());
    }
    
    public String getErrorParam1() {
        String errorMessage = '';
        if(errors != null && !errors.isEmpty()) {
            for(String error :errors) {
                errorMessage += error + '\n';
            }
        }
        return (errorMessage + '\n');
    }
    
    public String getErrorParam2() {
        return this.additionalErrorBody != null ? additionalErrorBody + '\n\n' : '\n';
    }

    public String getErrorParam3() {
        if(this.errorMap == null || this.errorMap.isEmpty()) {
            return '';
        } else {
            String errorMessage = '';
            for(String errorKey : this.errorMap.keySet()) {
                errorMessage += ERROR_VALIDATION_TEMPLATE.get(errorKey) + '\n';
                for(String shiftId : this.errorMap.get(errorKey)) {
                    errorMessage += shiftId + ', ';
                }
                errorMessage += '\n';
            }

            return (errorMessage + '\n');
        }
    }
    
    public Messaging.EmailFileAttachment getAttachment() {
        String body = getErrorParam1() + getErrorParam2() + getErrorParam3();
        
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setFileName(this.ctrl.name());
        efa.setContentType(TEXT_CONTENT_TYPE);
        efa.setBody(Blob.valueOf(body));
            
        return efa;  
    }
    
    public enum BatchCtrl {
        	ShiftAssignmentBatch, 
            ShiftTimesheetBatch, 
            ShiftTimesheetEntryBatch,
            TimesheetAdjustmentBatch
    }
}