/**
*   Class         :  MinimumEngagementService
*   Description   :  Invocable class for processing Minimum Engagement
*   Author        :  Tew Panuwich 
*   CreateDate    :  01/02/23
*   TestClass     :  MinimumEngagementTest

Change History
**********************************************************************************************************************************************
SCRUM        ModifiedBy        Date            Requested By                           Description                              Tag
**********************************************************************************************************************************************
C9D-107       Tew             01/02/23          Ben Albani             Minimum Engagement invocable method
**/
public class MinimumEngagementService {
    
    public static final String TYPE_MINIMUM_ENGAGEMENT = 'Minimum Engagement';
    
    public static final String RECORD_TYPE_INTERPRETATION = 'Interpretation';
    public static final String RECORD_TYPE_PAYMENT = 'Payment';
    
    public static final String INTERPRETATION_CATEGORY_LOADING = 'Loading';
    
    @InvocableMethod(label='Process Minimum Engagement')
    public static void process(List<Id> timesheetIds) {
        if(timesheetIds != null && !timesheetIds.isEmpty()) {
            doProcessMinimumEngagement(timesheetIds.get(0));
        }
    }
    
    public static void doProcessMinimumEngagement(Id timesheetId) {
        System.debug('BEGIN with MinimumEngagementService.doProcessMinimumEngagement: timesheetId=' + timesheetId);
        List<tc9_et__Timesheet__c> timesheets = [SELECT Id, tc9_et__Interpretation_Rule__c
                                                 FROM tc9_et__Timesheet__c
                                                 WHERE Id =: timesheetId];
        
        if(timesheets.isEmpty()) {
            System.debug('WARN with MinimumEngagementService.doProcessMinimumEngagement: Timesheet not found. timesheetId=' + timesheetId);
            return;
        }   
        tc9_et__Timesheet__c timesheet = timesheets.get(0);
        
        List<Custom_Rule__c> customRules = [SELECT Id, Name, Interpretation_Rule__c, Interpretation_Type__c, Maximum_Hours_to_Uplift__c, Minimum_Hours_to_Uplift__c,
                                            Timesheet_Activities_to_Include__c, TS_Entry_Gap_to_Exclude__c, TS_Entry_Hours_to_Uplift__c, Additional_Uplift_Hours__c 
                                            FROM Custom_Rule__c
                                            WHERE RecordType.DeveloperName = :RECORD_TYPE_INTERPRETATION 
                                            AND Interpretation_Type__c = :TYPE_MINIMUM_ENGAGEMENT
                                            AND Interpretation_Rule__c = :timesheet.tc9_et__Interpretation_Rule__c
                                            AND Interpretation_Rule__c != null];
        
        if(customRules.isEmpty()) {
            System.debug('WARN with MinimumEngagementService.doProcessMinimumEngagement: Custom rule not found.');
            return;
        }
        
        List<tc9_et__Timesheet_Entry__c> timesheetEntries = [SELECT Id, Name, tc9_et__Assignment__c, tc9_et__Timesheet_Activity__c, tc9_et__Timesheet_Activity__r.Name, tc9_et__Total_Hours__c,
                                                             tc9_et__Start_Date__c, tc9_et__Start_Time__c, tc9_et__End_Date__c, tc9_et__End_Time__c 
                                                             FROM tc9_et__Timesheet_Entry__c
                                                             WHERE tc9_et__Timesheet__c = :timesheet.Id
                                                             AND tc9_et__Start_Date__c != null AND tc9_et__Start_Time__c != null
                                                             AND tc9_et__End_Date__c != null AND tc9_et__End_Time__c != null
                                                             ORDER BY tc9_et__Start_Date__c, tc9_et__Start_Time__c];
        Set<Id> tseAssignmentIdSet = new Set<Id>();
        for(tc9_et__Timesheet_Entry__c tse : timesheetEntries) {
            tseAssignmentIdSet.add(tse.tc9_et__Assignment__c);
        }

        String ptQuery = ' SELECT ' + getFields('tc9_pr__Pay_Transaction__c') + ', tc9_pr__Pay_Code__r.Minimum_Engagement_Pay_Code__c, RecordType.DeveloperName, ' + 
            			 ' tc9_pr__Pay_Code__r.Min_Engagement_Add_Uplift_Pay_Code__c, tc9_pr__Pay_Code__r.Min_Engagement_Add_AR_Pay_Code__c ' +
                         ' FROM tc9_pr__Pay_Transaction__c ' +
                         ' WHERE tc9_et__Timesheet_Entry__c IN :timesheetEntries ';
        
        List<tc9_pr__Pay_Transaction__c> payTransations = Database.query(ptQuery);
        
        Map<Id, tc9_pr__Pay_Transaction__c> highestPayTrnTseMap = new Map<Id, tc9_pr__Pay_Transaction__c>();     
        Map<Id, List<tc9_pr__Pay_Transaction__c>> payTrnLoadingTseMap = new Map<Id, List<tc9_pr__Pay_Transaction__c>>();  
        List<tc9_pr__Pay_Transaction__c> clonePayTrns = new List<tc9_pr__Pay_Transaction__c>();
        
        for(tc9_pr__Pay_Transaction__c payTrn : payTransations) {
            
            if(INTERPRETATION_CATEGORY_LOADING.equalsIgnoreCase(payTrn.tc9_et__Interpretation_Category__c)) {
                if(payTrnLoadingTseMap.get(payTrn.tc9_et__Timesheet_Entry__c) != null) {
                    payTrnLoadingTseMap.get(payTrn.tc9_et__Timesheet_Entry__c).add(payTrn);
                } else {
                    payTrnLoadingTseMap.put(payTrn.tc9_et__Timesheet_Entry__c, new List<tc9_pr__Pay_Transaction__c>{payTrn});
                }
                
            } else if(RECORD_TYPE_PAYMENT.equalsIgnoreCase(payTrn.RecordType.DeveloperName)){
                
                if(highestPayTrnTseMap.get(payTrn.tc9_et__Timesheet_Entry__c) == null) {
                    highestPayTrnTseMap.put(payTrn.tc9_et__Timesheet_Entry__c, payTrn);
                    
                } else {
                    tc9_pr__Pay_Transaction__c highestPT = highestPayTrnTseMap.get(payTrn.tc9_et__Timesheet_Entry__c);
                    Decimal highestPayRate = highestPT.tc9_pr__Pay_Rate__c != null ? highestPT.tc9_pr__Pay_Rate__c : 0;
                    Decimal currentPayRate = payTrn.tc9_pr__Pay_Rate__c != null ? payTrn.tc9_pr__Pay_Rate__c : 0;
                    
                    if(currentPayRate > highestPayRate) {
                        highestPayTrnTseMap.put(payTrn.tc9_et__Timesheet_Entry__c, payTrn);
                    }
                }
            }
        }

        Set<Id> highestTrnMinPayCodeIdSet = new Set<Id>();
        Set<Id> highestTrnTimesheetActIdSet = new Set<Id>();
        for(tc9_pr__Pay_Transaction__c pt : highestPayTrnTseMap.values()) {
            highestTrnMinPayCodeIdSet.add(pt.tc9_pr__Pay_Code__r.Min_Engagement_Add_AR_Pay_Code__c);
            highestTrnTimesheetActIdSet.add(pt.tc9_et__Timesheet_Activity__c);
        }

        Map<String, List<tc9_pr__Assignment_Rate__c>> assignRateMap = new Map<String, List<tc9_pr__Assignment_Rate__c>>(); 
        for(tc9_pr__Assignment_Rate__c ar : [SELECT Id, tc9_pr__Assignment__c, tc9_et__Timesheet_Activity__c, tc9_pr__Pay_code__c,
                                             tc9_pr__Effective_Date__c, tc9_pr__Expiry_Date__c, tc9_et__Invoice_Rate__c, tc9_pr__Pay_Rate__c
                                             FROM tc9_pr__Assignment_Rate__c
                                             WHERE tc9_pr__Assignment__c IN :tseAssignmentIdSet
                                             AND tc9_pr__Pay_code__c IN :highestTrnMinPayCodeIdSet
                                             AND tc9_et__Timesheet_Activity__c IN :highestTrnTimesheetActIdSet
                                             ORDER BY tc9_pr__Effective_Date__c]) {

            String key = ar.tc9_pr__Assignment__c + '-' + ar.tc9_et__Timesheet_Activity__c + '-' + ar.tc9_pr__Pay_code__c;
            if(assignRateMap.get(key) == null) {
                assignRateMap.put(key, new List<tc9_pr__Assignment_Rate__c>());
            }
            assignRateMap.get(key).add(ar);
        }
        
        for(Integer index=0 ; index < timesheetEntries.size() ; index++) {
            Custom_Rule__c customRule = findFirstCustomRule(timesheetEntries[index], customRules);
            
            System.debug(timesheetEntries[index].Name + ', customRule=' + customRule?.Name);
            if(customRule != null) {
                List<String> activitiesRules = customRule.Timesheet_Activities_to_Include__c != null ? customRule.Timesheet_Activities_to_Include__c.split('\\s*;\\s*') : new List<String>();

                if(isIncludedTimesheetActivity(timesheetEntries[index], activitiesRules)) {
                    if(isTotalHourInSpan(timesheetEntries[index], customRule)) {
                                     
                        DateTime currentStartDateTime = DateTime.newInstance(timesheetEntries[index].tc9_et__Start_Date__c, timesheetEntries[index].tc9_et__Start_Time__c);
                        DateTime currentEndDateTime = DateTime.newInstance(timesheetEntries[index].tc9_et__End_Date__c, timesheetEntries[index].tc9_et__End_Time__c);
                        
                        /*
                            NOTES:
                            - Gap to Exclude is designed to ensure someone isn’t working very small Shifts
                            - e.g.
                                - TS_Entry_Gap_to_Exclude__c = 60 mins
                                - Someone works the same day and finishes at 3pm and then starts a new shift at 3.30pm (Time has only been 30 mins)
                                - A gap time must be more than Gap to exlclude to continue to calculate the uplift time
                            - Skip checking before gap if processing first TSE
                            - Skip checking after gap if process last TSE
                        */
                        if(!isFirstIndexOfList(index)) {
                            tc9_et__Timesheet_Entry__c prevTSE = timesheetEntries[index-1];
                            DateTime prevEndDateTime = DateTime.newInstance(prevTSE.tc9_et__End_Date__c, prevTSE.tc9_et__End_Time__c);
                            Integer beforeGap = getTimeDifferentInMinutes(prevEndDateTime, currentStartDateTime);
                            
                            if(customRule.TS_Entry_Gap_to_Exclude__c > beforeGap) {
                                System.debug('WARN with MinimumEngagementService.doProcessMinimumEngagement: Gap to exclude more than before gap. tseId=' + timesheetEntries[index].Id);
                                System.debug('TS_Entry_Gap_to_Exclude__c=' + customRule.TS_Entry_Gap_to_Exclude__c + ', BeforeGap=' + beforeGap);
                                continue;
                            }
                        }
                        
                        if(!isLastIndexOfList(index, timesheetEntries)) {
                            tc9_et__Timesheet_Entry__c nextTSE = timesheetEntries[index+1];
                            DateTime nextStartDateTime = DateTime.newInstance(nextTSE.tc9_et__Start_Date__c, nextTSE.tc9_et__Start_Time__c);
                            Integer afterGap = getTimeDifferentInMinutes(currentEndDateTime, nextStartDateTime);
                            
                            if(customRule.TS_Entry_Gap_to_Exclude__c > afterGap) {
                                System.debug('WARN with MinimumEngagementService.doProcessMinimumEngagement: Gap to exclude more than after gap. tseId=' + timesheetEntries[index].Id);
                                System.debug('TS_Entry_Gap_to_Exclude__c=' + customRule.TS_Entry_Gap_to_Exclude__c + ', AfterGap=' + afterGap);
                                continue;
                            }
                        }
                        
                        Decimal hourUplift = customRule.TS_Entry_Hours_to_Uplift__c != null ? customRule.TS_Entry_Hours_to_Uplift__c : 0;
                        Decimal totalHours = timesheetEntries[index].tc9_et__Total_Hours__c != null ? timesheetEntries[index].tc9_et__Total_Hours__c : 0;
                        
                        tc9_pr__Pay_Transaction__c highestPT = highestPayTrnTseMap.get(timesheetEntries[index].Id);
                        if(highestPT != null) {
                            Id minimumPayCode = highestPT.tc9_pr__Pay_Code__r?.Minimum_Engagement_Pay_Code__c != null ? highestPT.tc9_pr__Pay_Code__r.Minimum_Engagement_Pay_Code__c : highestPT.tc9_pr__Pay_Code__c;
                            
                            System.debug('Clone highest PT');

                            tc9_pr__Pay_Transaction__c clonedPT = clonePayTransaction(highestPT, (hourUplift - totalHours), minimumPayCode);
                            clonedPT.tc9_pr__Description__c = '- Minimum Engagement - ' + customRule.Name;
                            clonePayTrns.add(clonedPT);
                            
                            if(customRule.Additional_Uplift_Hours__c > 0) {
                                String key = highestPT.tc9_pr__Assignment__c + '-' + highestPT.tc9_et__Timesheet_Activity__c + '-' + highestPT.tc9_pr__Pay_Code__r?.Min_Engagement_Add_AR_Pay_Code__c;
                                tc9_pr__Assignment_Rate__c ar = filterUpliftAssignmentRate(assignRateMap.get(key), highestPT);
                                
                                Id addUpLiftPayCode = highestPT.tc9_pr__Pay_Code__r?.Min_Engagement_Add_Uplift_Pay_Code__c != null ? highestPT.tc9_pr__Pay_Code__r.Min_Engagement_Add_Uplift_Pay_Code__c : highestPT.tc9_pr__Pay_Code__c;
                                
                                tc9_pr__Pay_Transaction__c clonedAddUpLiftPT = clonePayTransaction(highestPT, customRule.Additional_Uplift_Hours__c, addUpLiftPayCode);
                                clonedAddUpLiftPT.tc9_pr__Description__c = '- Minimum Engagement Additional Uplift - ' + customRule.Name;
                                if(ar != null) {
                                    clonedAddUpLiftPT.tc9_et__Invoice_Rate__c = ar.tc9_et__Invoice_Rate__c;
                                    clonedAddUpLiftPT.tc9_pr__Pay_Rate__c = ar.tc9_pr__Pay_Rate__c;
                                }
                                
                                System.debug('Clone additional highest PT: assignmentRate=' + ar);
                                clonePayTrns.add(clonedAddUpLiftPT);
                            }
                        }
                        
                        List<tc9_pr__Pay_Transaction__c> loadingPTs = payTrnLoadingTseMap.get(timesheetEntries[index].Id);
                        if(loadingPTs != null) {
                            Set<Id> loadingPayCodeSet = new Set<Id>();
                            for(tc9_pr__Pay_Transaction__c pt : loadingPTs) {
                                if(!loadingPayCodeSet.contains(pt.tc9_pr__Pay_Code__c)) {
                                    Id minimumPayCode = pt.tc9_pr__Pay_Code__r?.Minimum_Engagement_Pay_Code__c != null ? pt.tc9_pr__Pay_Code__r.Minimum_Engagement_Pay_Code__c : pt.tc9_pr__Pay_Code__c;
                                    
                                    System.debug('Clone loading PT');
                                    tc9_pr__Pay_Transaction__c clonedPT = clonePayTransaction(pt, (hourUplift - totalHours), minimumPayCode);
                                    clonedPT.tc9_pr__Description__c = '- Minimum Engagement Loading - ' + customRule.Name;
                                    clonePayTrns.add(clonedPT);
                                    
                            
                                    if(customRule.Additional_Uplift_Hours__c > 0) {
                                        Id addUpLiftPayCode = highestPT.tc9_pr__Pay_Code__r?.Min_Engagement_Add_Uplift_Pay_Code__c != null ? highestPT.tc9_pr__Pay_Code__r.Min_Engagement_Add_Uplift_Pay_Code__c : highestPT.tc9_pr__Pay_Code__c;
                                        
                                        System.debug('Clone additional loading PT');
                                        tc9_pr__Pay_Transaction__c clonedAddUpLiftPT = clonePayTransaction(highestPT, customRule.Additional_Uplift_Hours__c, addUpLiftPayCode);
                                        clonedAddUpLiftPT.tc9_pr__Description__c = '- Min Engagement Additional Uplift Loading - ' + customRule.Name;
                                        clonePayTrns.add(clonedAddUpLiftPT);
                                    }
                                    
                                    loadingPayCodeSet.add(pt.tc9_pr__Pay_Code__c);
                                }
                            }
                        }
                        
                        timesheetEntries[index].Minimum_Engagement_Flag__c = true;
    
                    } else {
                        System.debug('WARN with MinimumEngagementService.doProcessMinimumEngagement: TSE Total Hours is not in span. tseId=' + timesheetEntries[index].Id);
                    }
                } else {
                    System.debug('WARN with MinimumEngagementService.doProcessMinimumEngagement: TSE is not included Timesheet Activity. tseId=' + timesheetEntries[index].Id + ', timesheetActivity=' + timesheetEntries[index].tc9_et__Timesheet_Activity__r.Name);
                    System.debug('activitiesRules=' + activitiesRules);
                }
            } else {
             	System.debug('WARN with MinimumEngagementService.doProcessMinimumEngagement: Custom Rule Not found. tseId=' + timesheetEntries[index].Id);
            }
        }
        
        
        if(!clonePayTrns.isEmpty()) {
            insert clonePayTrns;
        }
        
        if(!timesheetEntries.isEmpty()) {
            update timesheetEntries;
        }
        
        timesheet.Minimum_Engagement_Flag__c = true;
        update timesheet;
        
        System.debug('END with MinimumEngagementService.doProcessMinimumEngagement: timesheetId=' + timesheetId);
    }
    
    public static Integer getTimeDifferentInMinutes(DateTime stTime, DateTime endTime) {
        if(stTime == null || endTime == null) {
            return null;
        }
        /*
            NOTES:
            - Divined by 1000 to convert long to second
            - Divined by 60 to convert second to minute 
        */
        Long diffTime = endTime.getTime() - stTime.getTime();
        Long minutes = diffTime / (1000 * 60); 
        
        return minutes.intValue(); 
    }
    
    public static tc9_pr__Pay_Transaction__c clonePayTransaction(tc9_pr__Pay_Transaction__c originalPT, Decimal quantity, Id payCodeId) {
        tc9_pr__Pay_Transaction__c clonePT = originalPT.clone(false, true ,false ,true);
        clonePT.tc9_pr__Quantity__c = quantity;
        clonePT.tc9_pr__Pay_Code__c = payCodeId;
        
        return clonePT;
    }
    
    private static Boolean isIncludedTimesheetActivity(tc9_et__Timesheet_Entry__c tse, List<String> activitiesRules) {
        return tse.tc9_et__Timesheet_Activity__c == null || (tse.tc9_et__Timesheet_Activity__c != null && activitiesRules.contains(tse.tc9_et__Timesheet_Activity__r.Name));
    }
    
    private static Boolean isTotalHourInSpan(tc9_et__Timesheet_Entry__c tse, Custom_Rule__c customRule) {
        Decimal totalHours = tse.tc9_et__Total_Hours__c != null ? tse.tc9_et__Total_Hours__c : 0;
        
        return  totalHours >= customRule.Minimum_Hours_to_Uplift__c && totalHours <= customRule.Maximum_Hours_to_Uplift__c;
    }

    private static Boolean isFirstIndexOfList(Integer index) {
        return index == 0;
    }

    private static Boolean isLastIndexOfList(Integer index, List<SObject> objects) {
        return index == objects.size() - 1;
    }
    
    private static String getFields(String objectAPI){
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectAPI).getDescribe().fields.getMap();
        
        return String.join(new List<String>(fieldMap.keySet()), ', ');
    }

    public static Custom_Rule__c findFirstCustomRule(tc9_et__Timesheet_Entry__c tse, List<Custom_Rule__c> customRules) {
        if(!customRules.isEmpty()) {
            for(Custom_Rule__c cr : customRules) {
                List<String> activitiesRules = cr.Timesheet_Activities_to_Include__c != null ? cr.Timesheet_Activities_to_Include__c.split('\\s*;\\s*') : new List<String>();

                Double minUplift =  cr.Minimum_Hours_to_Uplift__c != null ?  cr.Minimum_Hours_to_Uplift__c : 0;
                Double maxUplift =  cr.Maximum_Hours_to_Uplift__c != null ?  cr.Maximum_Hours_to_Uplift__c : 0;
                if(isIncludedTimesheetActivity(tse, activitiesRules) && tse.tc9_et__Total_Hours__c >= minUplift && tse.tc9_et__Total_Hours__c <= maxUplift) {
                    return cr;
                }
            }
        }
        return null;
    }

    private static tc9_pr__Assignment_Rate__c filterUpliftAssignmentRate(List<tc9_pr__Assignment_Rate__c> assignRates, tc9_pr__Pay_Transaction__c highestPT) {
        if(assignRates != null) {
            for(tc9_pr__Assignment_Rate__c ar : assignRates) {
                if(ar.tc9_pr__Effective_Date__c <= highestPT.tc9_pr__Entry_Date__c && (ar.tc9_pr__Expiry_Date__c == null || ar.tc9_pr__Expiry_Date__c >= highestPT.tc9_pr__Entry_Date__c)) {
                    return ar;
                }
            }
        }

        return null;
    }
}