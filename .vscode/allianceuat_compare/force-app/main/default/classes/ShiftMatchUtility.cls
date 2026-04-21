public with sharing class ShiftMatchUtility {
    public static final String SHIFTMATCH_ERROR_CATEGORY = 'ShiftMatch';
    public static final String SHIFTMATCH_ERROR_SEVERITY = 'Fatal';

    public static void logError(Id accountId, String errorMessage) {
        insert new sirenum__LogEntry__c(
            sirenum__Category__c = 'ShiftMatch',
            sirenum__Details__c = errorMessage,
            sirenum__Severity__c = SHIFTMATCH_ERROR_SEVERITY,
            Account__c = accountId
        );
    }


    public static Time convertShiftTimeToTime(String shiftTime) {        
        String[] timeSplit = shiftTime.split(':');
        Integer hour = Integer.valueOf(timeSplit[0]);
        Integer minute = Integer.valueOf(timeSplit[1]);
        return Time.newInstance(hour, minute, 0, 0);
    }

    public static Date convertShiftDateToDate(String shiftTime) {        
        String[] dateSplit = shiftTime.split('T')[0].split('-');

        Integer year = Integer.valueOf(dateSplit[0]);
        Integer month = Integer.valueOf(dateSplit[1]);
        Integer day = Integer.valueOf(dateSplit[2]);
        return Date.newInstance(year, month, day);
    }


    public static DateTime convertShiftDateToDateTime(String shiftTime) {        
        String[] dateSplit = shiftTime.split('T')[0].split('-');

        Integer year = Integer.valueOf(dateSplit[0]);
        Integer month = Integer.valueOf(dateSplit[1]);
        Integer day = Integer.valueOf(dateSplit[2]);        

        String[] timeSplit = shiftTime.split('T')[1].split('\\+');        
        Time tm = convertShiftTimeToTime(timeSplit[0]);

        String[] offsetSplit = timeSplit[1].split(':');

        return DateTime.newInstanceGmt(year, month, day, tm.hour(), tm.minute(), 0)
            .addHours(-Integer.valueOf(offsetSplit[0]))
            .addMinutes(-Integer.valueOf(offsetSplit[1]));
    }
}