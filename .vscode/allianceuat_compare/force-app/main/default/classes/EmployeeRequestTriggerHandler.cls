public without sharing class EmployeeRequestTriggerHandler {
    static final Integer START_AM_HOURS = 6;
    static final Integer END_AM_HOURS = 14;
    static final Integer START_PM_HOURS = 14;
    static final Integer END_PM_HOURS = 22;
    static final Integer START_ND_HOURS = 22;
    static final Integer END_ND_HOURS = 6;

    public static void handleChange() {
        List<sirenum__Employee_Request__c> requests = (List<sirenum__Employee_Request__c>) Trigger.new;
        Map<id, sirenum__Employee_Request__c> oldMap = (Map<id, sirenum__Employee_Request__c>) Trigger.oldMap;
                                 
        for (sirenum__Employee_Request__c r : requests) {
            if (r.sirenum__Type__c != null && (r.sirenum__Type__c.startsWith('AM -') || r.sirenum__Type__c.startsWith('PM -') || r.sirenum__Type__c.startsWith('ND -'))
                && (oldMap == null || oldMap.get(r.id) == null || oldMap.get(r.id).sirenum__Type__c != r.sirenum__Type__c)) {
                r.sirenum__Local_End_Date__c = null;
                r.sirenum__Local_Start_Time__c = Time.newInstance(
                    r.sirenum__Type__c.startsWith('AM -') ? START_AM_HOURS : r.sirenum__Type__c.startsWith('PM -') ? START_PM_HOURS : START_ND_HOURS, 0, 0, 0);
                r.sirenum__Local_End_Time__c = Time.newInstance(
                    r.sirenum__Type__c.startsWith('AM -') ? END_AM_HOURS : r.sirenum__Type__c.startsWith('PM -') ? END_PM_HOURS : END_ND_HOURS, 0, 0, 0);               
            }
        }

    }        
}