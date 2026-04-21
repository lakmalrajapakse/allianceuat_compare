public with sharing class TimesheetItemsAllowanceController {

    public Id   recordId          { get; set; }
    public Boolean isProcessed    { get; private set; }
    public Boolean hasEdits       { get; set; }

    public tc9_et__Timesheet__c          timesheet   { get; private set; }
    public List<TimesheetItemWrapper>    itemWrappers { get; private set; }

    public String successMessage { get; set; }
    public String errorMessage   { get; set; }

    public TimesheetItemsAllowanceController(ApexPages.StandardController sc) {
        recordId = sc.getId();
        hasEdits = false;
        load();
    }

    private void load() {
        if (recordId == null) {
            errorMessage = 'No Timesheet record Id supplied.';
            return;
        }

        try {
            timesheet = [
                SELECT Id, Name,
                       tc9_et__Transaction_Creation_Stage__c,
                       tc9_et__Total_Hours__c
                FROM   tc9_et__Timesheet__c
                WHERE  Id = :recordId
                LIMIT  1
            ];

            String stage = timesheet.tc9_et__Transaction_Creation_Stage__c;
            isProcessed = (stage != '1');

            List<tc9_et__Timesheet_Item__c> items = [
                SELECT Id,
                       Name,
                       tc9_util__Start_Time__c,
                       tc9_util__End_Time__c,
                       tc9_et__Quantity__c,
                       tc9_et__Payee_Allowance_Record__c,
                       tc9_et__Payee_Allowance_Record__r.Name,
                       tc9_et__Date_Incurred__c,
                       tc9_et__Approval_Status_No_Colour__c,
                       RecordType.Name
                FROM   tc9_et__Timesheet_Item__c
                WHERE  tc9_et__Timesheet__c = :recordId
                  AND  RecordType.Name      = 'Allowance'
                ORDER BY tc9_et__Date_Incurred__c ASC
            ];

            itemWrappers = new List<TimesheetItemWrapper>();
            for (tc9_et__Timesheet_Item__c item : items) {
                itemWrappers.add(new TimesheetItemWrapper(item));
            }

        } catch (Exception e) {
            errorMessage = 'Error loading timesheet: ' + e.getMessage();
        }
    }

    public PageReference markEdited() {
        hasEdits = true;
        return null;
    }

    public PageReference saveItems() {
        tc9_et__Timesheet__c latest = [
            SELECT tc9_et__Transaction_Creation_Stage__c
            FROM   tc9_et__Timesheet__c
            WHERE  Id = :recordId
            LIMIT  1
        ];
        if (latest.tc9_et__Transaction_Creation_Stage__c != '1') {
            errorMessage = 'Editing is not allowed in the current state. To make changes, click Revert To New above.';
            successMessage = null;
            load();
            return null;
        }

        List<tc9_et__Timesheet_Item__c> toUpdate = new List<tc9_et__Timesheet_Item__c>();
        for (TimesheetItemWrapper w : itemWrappers) {

            if (String.isNotBlank(w.startTimeStr)) {
                w.item.tc9_util__Start_Time__c = parseTime(w.startTimeStr);
            }
            if (String.isNotBlank(w.endTimeStr)) {
                w.item.tc9_util__End_Time__c = parseTime(w.endTimeStr);
            }
            toUpdate.add(w.item);
        }

        try {
            update toUpdate;
            successMessage = 'Timesheet items updated successfully.';
            errorMessage   = null;
            hasEdits       = false;
            load();
        } catch (DmlException e) {
            errorMessage   = 'Save failed: ' + e.getDmlMessage(0);
            successMessage = null;
        }
        return null;
    }

    private static Time parseTime(String s) {
        if (String.isBlank(s)) return null;
        s = s.trim().toLowerCase();
        Boolean isPm = s.contains('pm');
        Boolean isAm = s.contains('am');
        s = s.replace('am','').replace('pm','').trim();
        List<String> parts = s.split(':');
        if (parts.size() < 2) return null;
        Integer h = Integer.valueOf(parts[0].trim());
        Integer m = Integer.valueOf(parts[1].trim());
        if (isPm && h != 12) h += 12;
        if (isAm && h == 12) h = 0;
        return Time.newInstance(h, m, 0, 0);
    }

    public PageReference refreshIfStageChanged() {
        if (recordId == null) return null;
        tc9_et__Timesheet__c current = [
            SELECT tc9_et__Transaction_Creation_Stage__c
            FROM   tc9_et__Timesheet__c
            WHERE  Id = :recordId
            LIMIT  1
        ];
        Boolean newIsProcessed = (current.tc9_et__Transaction_Creation_Stage__c != '1');
        if (newIsProcessed != isProcessed) {
            load();
        }
        return null;
    }

    public PageReference cancel() {
        hasEdits = false;
        load();
        return null;
    }


    public class TimesheetItemWrapper {
        public tc9_et__Timesheet_Item__c item       { get; set; }
        public Boolean                   isEdited   { get; set; }
        public String                    startTimeStr { get; set; }
        public String                    endTimeStr   { get; set; }

        public TimesheetItemWrapper(tc9_et__Timesheet_Item__c item) {
            this.item     = item;
            this.isEdited = false;

            this.startTimeStr = item.tc9_util__Start_Time__c != null ? formatTime(item.tc9_util__Start_Time__c) : '';
            this.endTimeStr   = item.tc9_util__End_Time__c   != null ? formatTime(item.tc9_util__End_Time__c)   : '';
        }

        private String formatTime(Time t) {
            Integer h = t.hour();
            Integer m = t.minute();
            String ampm = h >= 12 ? 'pm' : 'am';
            Integer h12 = Math.mod(h, 12);
            if (h12 == 0) h12 = 12;
            return h12 + ':' + (m < 10 ? '0' : '') + m + ' ' + ampm;
        }
    }
}