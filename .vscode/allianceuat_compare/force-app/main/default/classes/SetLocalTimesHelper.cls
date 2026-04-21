/**
 * PS-908 Store important Datetimes as local dates and times
 * PS-945: Changed to only check for insertion with, or change of, break times
 */

public without sharing class SetLocalTimesHelper {

    /**
     * Sets local date and time field variants of important Datetime fields.
     *
     * @param shifts The shifts to calculate local times for
     */
    public static void SetLocalTimes(List<sirenum__Shift__c> shifts){
        Set<Id> siteIds = new Set<Id>();

        for (sirenum__Shift__c shift : shifts){
            siteIds.add(shift.sirenum__Site__c);
        }

        Map<Id, sirenum__Site__c> sitesById = new Map<Id, sirenum__Site__c>([
                SELECT Id, sirenum__Timezone__c
                FROM sirenum__Site__c
                WHERE Id IN :siteIds
        ]);

        for (sirenum__Shift__c shift : shifts){
            sirenum__Site__c site = sitesById.get(shift.sirenum__Site__c);

            //PS-945: Removed fields now handled OOTB (e.g. scheduled and actual times), added TC9 Second Break
            SetLocalTime(shift, site, shift.sirenum__BreakStartTime__c, 'tc9_ext_sirint__TSE_First_Break_Date__c','tc9_ext_sirint__TSE_First_Break_Time__c');
            SetLocalTime(shift, site, shift.tc9_ext_sirint__Second_Break_Start_Time__c, 'tc9_ext_sirint__TSE_Second_Break_Date__c','tc9_ext_sirint__TSE_Second_Break_Time__c');
        }
    }

    /**
     * Calculates local time of dateTimeValue and stores the results in dateField and timefield. Outputs may be null.
     *
     * @param shift The shift to update. Required.
     * @param site The site of the shift to update; used to grab timezone to calculate local times. Required.
     * @param dateTimeValue The Datetime value of the source field to be converted to local time. May be null.
     * @param dateField The Date-only field to place the converted local date. Required.
     * @param timeField The Time-only field to place the converted local time. Required.
     */
    public static void SetLocalTime(sirenum__Shift__c shift, sirenum__Site__c site, Datetime dateTimeValue, String dateField, String timeField){
        if (dateTimeValue != null && site != null && site.sirenum__Timezone__c != null){
            List<String> timeStringSplit = dateTimeValue.format('HH:mm', site.sirenum__Timezone__c).split(':');
            shift.put(dateField, Date.valueOf(dateTimeValue.format('yyyy-MM-dd', site.sirenum__Timezone__c)));
            shift.put(timeField, Time.newInstance(Integer.valueOf(timeStringSplit[0]), Integer.valueOf(timeStringSplit[1]),0,0));
        } else {
            shift.put(dateField, null);
            shift.put(timeField, null);
        }
    }
}