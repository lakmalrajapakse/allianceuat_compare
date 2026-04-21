/**
 * PS-908 Store important Datetimes as local dates and times
 * PS-945: Changed to only check for insertion with, or change of, break times
 */

trigger SetLocalTimes on sirenum__Shift__c (before insert, before update) {
    List<sirenum__Shift__c> shiftsToCalculateLocalTimes = new List<sirenum__Shift__c>();

    //Examine each shift and set any relevant local times
    for (sirenum__Shift__c shift : Trigger.new) {

        //Inserted shifts...
        if (Trigger.isInsert){
            if (shift.sirenum__Site__c == null) { //...With no site, skip to next shift
                continue;
            } else if ( //...With at least one important date populated, collate for locals calculation
                    shift.sirenum__BreakStartTime__c != null ||
                    shift.tc9_ext_sirint__Second_Break_Start_Time__c != null)
            {
                shiftsToCalculateLocalTimes.add(shift);
            }
        } else if (Trigger.isUpdate) {//Updated shifts...
            //...With a changed Site, collate for locals calculation
            if (shift.sirenum__Site__c != Trigger.oldMap.get(shift.Id).sirenum__Site__c) {
                shiftsToCalculateLocalTimes.add(shift);
            //...With at least one important datetime has changed (possibly to or from null), collate for locals calculation
            } else if (
                    shift.sirenum__BreakStartTime__c != Trigger.oldMap.get(shift.Id).sirenum__BreakStartTime__c ||
                            shift.tc9_ext_sirint__Second_Break_Start_Time__c != Trigger.oldMap.get(shift.Id).tc9_ext_sirint__Second_Break_Start_Time__c
                    ) {
                shiftsToCalculateLocalTimes.add(shift);
            }
        }
    }

    if (!shiftsToCalculateLocalTimes.isEmpty()) {
        SetLocalTimesHelper.SetLocalTimes(shiftsToCalculateLocalTimes);
    }
}