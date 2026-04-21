public inherited sharing class ShiftService {
    /**
     * Creates a number of shifts based on the provided requests.
     */
    public static void createShifts(List<CreateShiftRequest> requests) {
        List<sirenum__Shift__c> shifts = new List<sirenum__Shift__c>();

        for (CreateShiftRequest request : requests) {
            shifts.add(generateShiftRecord(request));
        }

        // TODO: Insert shifts, if any fail, report it back. (Change allornothing to false)
        Database.insert(shifts, true, AccessLevel.SYSTEM_MODE);
    }

    public static Database.SaveResult[] createShiftsFromEmail(List<CreateShiftRequest> requests) {
        List<sirenum__Shift__c> shifts = new List<sirenum__Shift__c>();

        for (CreateShiftRequest request : requests) {
            // System.debug('request.recordTypeId: ' + request.recordTypeId);
            shifts.add(generateShiftRecord(request));
            // System.debug('shifts[0].RecordTypeId: ' + shifts[0].RecordTypeId);
        }

        // Database.insert(shifts, true, AccessLevel.SYSTEM_MODE);
        Database.SaveResult[] srList = Database.insert(shifts, false, AccessLevel.SYSTEM_MODE);
        System.debug('srList: ' + srList);
        return srList;
    }

    /**
     * Cancels a number of shifts based on the provided requests.
     */
    public static void cancelShifts(List<CreateShiftRequest> requests) {
        String [] requestIds = new List<String>();

        for (CreateShiftRequest request : requests) {
            requestIds.add(request.extShiftId);
        }

        List<sirenum__Shift__c> shifts = [SELECT Id, sirenum__FMS_Shift_ID__c, sirenum__Cancelled__c, sirenum__Contact__c
                                        FROM sirenum__Shift__c
                                        WHERE sirenum__FMS_Shift_ID__c IN :requestIds];
        
        // Cancellation Reason "Cancelled by Facility NC" triggers a flow 1218 Cancel Notification
        // Cancellation Reason changed to "VMS Cancellation"
        for(sirenum__Shift__c shift : shifts) {
            // System.debug(LOGGINGLEVEL.ERROR, 'shift.sirenum__Contact__c: |' + shift.sirenum__Contact__c + '|');
            shift.sirenum__Cancelled__c = true;
            // shift.sirenum__CancellationReason__c = shift.sirenum__Contact__c == null ? 'Cancelled by Facility DNC' : 'Cancelled by Facility NC';
            shift.sirenum__CancellationReason__c = 'VMS Cancellation';
        } 

        // TODO: Update shifts, if any fail, report it back. (Change allornothing to false)
        Database.update(shifts, true, AccessLevel.SYSTEM_MODE);
    }

    public static Database.SaveResult[] cancelShiftsFromEmail(List<CreateShiftRequest> requests) {
        String [] requestIds = new List<String>();

        for (CreateShiftRequest request : requests) {
            requestIds.add(request.extShiftId);
        }

        List<sirenum__Shift__c> shifts = [SELECT Id, sirenum__FMS_Shift_ID__c, sirenum__Cancelled__c, sirenum__Contact__c
                                        FROM sirenum__Shift__c
                                        WHERE sirenum__FMS_Shift_ID__c IN :requestIds];
        
        // Cancellation Reason "Cancelled by Facility NC" triggers a flow 1218 Cancel Notification
        // Cancellation Reason changed to "VMS Cancellation"
        for(sirenum__Shift__c shift : shifts) {
            // System.debug(LOGGINGLEVEL.ERROR, 'shift.sirenum__Contact__c: |' + shift.sirenum__Contact__c + '|');
            shift.sirenum__Cancelled__c = true;
            // shift.sirenum__CancellationReason__c = shift.sirenum__Contact__c == null ? 'Cancelled by Facility DNC' : 'Cancelled by Facility NC';
            shift.sirenum__CancellationReason__c = 'VMS Cancellation';
        } 

        Database.SaveResult[] srList = Database.update(shifts, false, AccessLevel.SYSTEM_MODE);
        System.debug('srList: ' + srList);
        return srList;
    }

    /**
     * Create Shift Error records.
     */
    public static Database.SaveResult[] createShiftErrors(List<CreateShiftRequest> requests) {
        List<VMS_Shift_Error__c> shiftErrors = new List<VMS_Shift_Error__c>();

        for (CreateShiftRequest request : requests) {
            shiftErrors.add(generateShiftErrorRecord(request));
        }

        // TODO: Insert shifts, if any fail, report it back. (Change allornothing to false)
        // Database.insert(shifts, true, AccessLevel.SYSTEM_MODE);
        Database.SaveResult[] srList = Database.insert(shiftErrors, false, AccessLevel.SYSTEM_MODE);
        System.debug('srList: ' + srList);
        return srList;
    }

    /**
     * Generates and returns a BH Shift record, internally for this service, mapping it from a provided request, so they can be inserted in bulk later.
     */
    private static sirenum__Shift__c generateShiftRecord(
        CreateShiftRequest request
    ) {
        sirenum__Shift__c shift = new sirenum__Shift__c(
            // change these to local time
            // sirenum__Scheduled_Start_Time__c = addTimeToDate(
            //     request.day,
            //     request.startTime
            // ),
            // sirenum__Scheduled_End_Time__c = addTimeToDate(
            //     request.day,
            //     request.endTime
            // ),
            Booking_Date__c = request.day.date(),
            sirenum__Scheduled_Local_Start_Date__c = request.day.date(),
            sirenum__Scheduled_Local_Start_Time__c = request.startTime,
            sirenum__Scheduled_Local_End_Time__c = request.endTime,
            sirenum__Break_Length__c = request.breakLengthInMinutes,
            sirenum__Comments__c = request.comments,
            sirenum__FMS_Shift_ID__c = request.extShiftId, 
            VMS_Shift_URL__c = request.shiftURL,
            sirenum__Site__c = request.site,
            sirenum__Contract__c = request.contract,
            sirenum__Team__c = request.jobRole,
            sirenum__Broadcasts__c = request.numShifts != null ? request.numShifts : 1,
            VMS_Source__c = request.source,
            RecordTypeId = request.recordTypeId

        );

        return shift;
    }

    /**
     * Generates and returns a BH Shift record, internally for this service, mapping it from a provided request, so they can be inserted in bulk later.
     */
    private static VMS_Shift_Error__c generateShiftErrorRecord(
        CreateShiftRequest request
    ) {
        VMS_Shift_Error__c shiftError = new VMS_Shift_Error__c(
            // Name = '', // set to autonumber? 
            VMS_Source__c = request.source,
            External_Shift_ID__c = request.extShiftId, 
            VMS_Shift_URL__c = request.shiftURL,
            VMS_Shift_Info__c = request.shiftErrorInfo,
            Error_Type__c = request.errorType,
            Error_Message__c = request.errorMessage,
            Shift__c = request.sfShiftId
            // sirenum__Scheduled_Local_Start_Date__c = request.day.date(),
            // sirenum__Scheduled_Local_Start_Time__c = request.startTime,
            // sirenum__Scheduled_Local_End_Time__c = request.endTime,
            // sirenum__Comments__c = request.comments,
            // sirenum__Site__c = request.site,
            // sirenum__Contract__c = request.contract,
            // sirenum__Team__c = request.jobRole

        );

        return shiftError;
    }

    /**
     * Given a DateTime, will add the provided Time to it.
     */
    private static DateTime addTimeToDate(DateTime dt, Time t) {
        return dt.addHours(t.hour()).addMinutes(t.minute());
    }

    public class CreateShiftRequest {
        /**
         * Insert or Update (cancel/other?)
         */
        public String action { get; set; }
        /**
         * Midnight of the day the shift starts, in the timezone it takes place.
         */
        public DateTime day { get; set; }
        /**
         * Start time of the shift, irrespective of date.
         */
        public Time startTime { get; set; }
        /**
         * End time of the shift, irrespective of date.
         */
        public Time endTime { get; set; }
        /**
         * Length of break time, in minutes.
         */
        public Integer breakLengthInMinutes { get; set; }
        /**
         * Comments that relate to and could be useful for this shift.
         */
        public String comments { get; set; }
        /**
         * External Shift ID from VMS.
         */
        public String extShiftId { get; set; }
        /**
         * External Shift URL from VMS.
         */
        public String shiftURL { get; set; }
        /**
         * Job Role
         */
        public String jobRole { get; set; }
        /**
         * Site
         */
        public String site { get; set; }
        /**
         * contract
         */
        public String contract { get; set; }
        /**
         * Number of Shifts
         */
        public Integer numShifts { get; set; }
        /**
         * VMS Source
         */
        public String source { get; set; }
        /**
         * Salesforce Shift ID to add to error record.
         */
        public String sfShiftId { get; set; }
        /**
         * Shift Errors 
         */
        public String errorType { get; set; }
        public String errorMessage { get; set; }
        public String shiftErrorInfo { get; set; }
        /**
         * Record Type 
         */
        public Id recordTypeId { get; set; }
    }

    public class ServiceException extends Exception {
    }
}