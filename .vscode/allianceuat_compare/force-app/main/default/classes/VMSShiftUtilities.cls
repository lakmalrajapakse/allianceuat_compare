public with sharing class VMSShiftUtilities {

    /* 
    ** Utilities for use in VMS Shift Processing
    */

    public static Time convertShiftTimeToTime(String shiftTime) {
        // Time can be in the format 09:00 or 09:00 AM
        String[] timeSeparator = shiftTime.split(' ');
        // System.debug(LOGGINGLEVEL.ERROR, 'VMSShiftUtilities convertShiftTimeToTime timeSeparator: ' +  timeSeparator);
        String[] timeSplit = timeSeparator[0].split(':');
        // System.debug(LOGGINGLEVEL.ERROR, 'VMSShiftUtilities convertShiftTimeToTime timeSplit: ' +  timeSplit);
        Integer hour = timeSeparator.size() == 2 && timeSeparator[1] == 'PM' ? Integer.valueOf(timeSplit[0]) + 12 : Integer.valueOf(timeSplit[0]);
        Integer minute = Integer.valueOf(timeSplit[1]);
        return Time.newInstance(hour, minute, 0, 0);
    }


    public static String getData(String str, String strSearch, Integer startPosition, Integer endPositon){
        System.debug(LOGGINGLEVEL.ERROR, 'VMSShiftUtilities getPosition strSearch / startPosition / endPositon: ' +  strSearch  + ' / ' + startPosition  + ' / ' + endPositon);
        Integer position = str.indexOf(strSearch);
        return str.substring(position+startPosition, position+endPositon); 
    }

    // NO LONGER CALLED
    // public static List<sirenum__Site__c> findSite(String siteData, string firstSeparator, string secondSeparator){
    // // public static String findSite(String siteData, string firstSeparator, string secondSeparator){
    //     String siteId;
    //     List<sirenum__Site__c> facilitySites = new List<sirenum__Site__c>();
    //     // Split Facility Name into separate parts
    //     System.debug(LOGGINGLEVEL.ERROR, 'siteData: ' + siteData);
    //     List<String> facilityAddressParts = siteData.split(firstSeparator);
    //     // System.debug(LOGGINGLEVEL.ERROR, 'facilityAddressParts: ' + facilityAddressParts);
    //     for (Integer i = 0; i < facilityAddressParts.size(); i++){
    //         System.debug(LOGGINGLEVEL.ERROR, 'facilityAddressParts[' + i + ']: ' + facilityAddressParts[i]);
    //     }

    //     String siteName;
    //     // TODO - this is specific to Emprevo / St Vincent's Private Hospital
    //     if (facilityAddressParts[1].indexOf(')') != -1){
    //         siteName = facilityAddressParts[1].substring(0, facilityAddressParts[1].indexOf(')') +1);
    //         System.debug(LOGGINGLEVEL.ERROR, 'siteName: ' + siteName);
    //     }
        


    //     // TODO - Address Split Parameter - define in Metadata 
    //     List<String> fullAddress = facilityAddressParts[facilityAddressParts.size() - 1].split(secondSeparator);
    //     System.debug(LOGGINGLEVEL.ERROR, 'fullAddress: ' + fullAddress);
    //     // Array in reverse is Postcode, State, City, Street Parts
    //     for (Integer i = 0; i < fullAddress.size(); i++){
    //         System.debug(LOGGINGLEVEL.ERROR, 'fullAddress[' + i + ']: ' + fullAddress[i]);
    //     }

    //     // String streetAddress = ;

    //     // List<List<SObject>> facilitySites = [FIND :facilityAddressParts[0] IN NAME FIELDS RETURNING sirenum__Site__c(Id, Name, WFM_Contract__c)];

    //     // TODO include Name / Street in search when above fixed and correct City
    //     // List<SObject> facilitySites = [SELECT Id, Name, WFM_Contract__c 
    //     //                             FROM sirenum__Site__c 
    //     //                             WHERE sirenum__Postal_Code__c = :fullAddress[fullAddress.size() -1]
    //     //                             AND sirenum__County__c = :fullAddress[fullAddress.size() -2]
    //     //                             AND sirenum__City__c = :fullAddress[fullAddress.size() -3]];
    //     // System.debug(LOGGINGLEVEL.ERROR, 'facilitySites: ' + facilitySites);
    //     List<SObject> facilityAccounts = [SELECT Id, Name 
    //                                 FROM Account 
    //                                 WHERE BillingPostalCode = :fullAddress[fullAddress.size() -1]
    //                                 AND BillingState = :fullAddress[fullAddress.size() -2]
    //                                 AND BillingCity = :fullAddress[fullAddress.size() -3]];
    //     System.debug(LOGGINGLEVEL.ERROR, 'facilityAccounts: ' + facilityAccounts);

    //     // If (facilitySites.size() == 1){
    //     If (facilityAccounts.size() == 1){
    //         System.debug(LOGGINGLEVEL.ERROR, 'One Account Returned.');
    //         System.debug(LOGGINGLEVEL.ERROR, 'facilitySites BEFORE: ' + facilitySites);
    //         // List<SObject> facilitySites
    //         facilitySites = [SELECT Id, Name, WFM_Contract__c,  sirenum__Operating_Company__c, VMS_Default_Site__c
    //                                 FROM sirenum__Site__c 
    //                                 WHERE sirenum__Operating_Company__c = :facilityAccounts[0].Id
    //                                 AND Name = :siteName
    //                         ];
    //         // siteId = facilitySites[0][0].Id;
    //         System.debug(LOGGINGLEVEL.ERROR, 'facilitySites AFTER: ' + facilitySites);

    //         // siteId = facilitySites[0].Id; 
    //         // System.debug(LOGGINGLEVEL.ERROR, 'siteId: ' + siteId);

    //         // contractId = (string)facilitySites[0][0].get('WFM_Contract__c');
    //         // System.debug(LOGGINGLEVEL.ERROR, 'contractId: ' + contractId);
    //     // } else If (facilitySites.size() == 0){
    //     // } else If (facilityAccounts.size() == 0){
    //     //     System.debug(LOGGINGLEVEL.ERROR, 'No Sites Returned.');
    //         // create a Shift Error Log / Notification 
    //         // 
    //     } else {
    //         System.debug(LOGGINGLEVEL.ERROR, 'Multiple Sites Returned.');
    //         // create a Shift Error Log / Notification 
    //         facilitySites = [SELECT Id, Name, WFM_Contract__c,  sirenum__Operating_Company__c, VMS_Default_Site__c 
    //                                 FROM sirenum__Site__c 
    //                                 WHERE sirenum__Operating_Company__c = :facilityAccounts[0].Id
    //                                 AND VMS_Default_Site__c = true];
    //         // siteId = facilitySites[0][0].Id;
    //         System.debug(LOGGINGLEVEL.ERROR, 'facilitySites Default: ' + facilitySites);
    //     }
    //     // return siteId;
    //     return facilitySites;
    // }

    // public static String findContract(String site){
    //     String contractId;

    //     System.debug(LOGGINGLEVEL.ERROR, 'contractId: ' + contractId);
    //     return contractId;
    // }

    // public static String findJobRole(String jobRole, String contractId){
    public static String findJobRole(String jobRole, String accountId, String contractId, String strVMS){
        // need to map to JobType / Source System to get Job Role
        String jobRoleId;
        // List<SObject> jobRoles = [SELECT Id, sirenum__Account__c FROM sirenum__Team__c WHERE Name = :jobRole AND sirenum__Account__c = :contractId];
        List<Shift_Job_Role_Mapping__c> jobRoles = [SELECT Id, VMS_Name__c, VMS_Job_Role__c, Account__c, Job_Type__c, Job_Role__c 
                                                FROM Shift_Job_Role_Mapping__c 
                                                WHERE VMS_Name__c = :strVMS 
                                                AND VMS_Job_Role__c = :jobRole 
                                                AND Account__c = :accountId
                                                AND WFM_Contract__c = :contractId];
        System.debug(LOGGINGLEVEL.ERROR, 'jobRoles: ' + jobRoles);
        If (jobRoles.size() == 1){
            jobRoleId = jobRoles[0].Job_Role__c;
            System.debug(LOGGINGLEVEL.ERROR, 'jobRoleId: ' + jobRoleId);
        } else {
            System.debug(LOGGINGLEVEL.ERROR, 'Unable to determine Job Role.');
            // create a Shift Error Log / Notification 
        }
        return jobRoleId;
    }

    /**
     * Map VMS Facility to Salesforce Facility/Contract/Site
     */
    public static VMS_Facility_Mapping__c mapFacility(String facilityName, String strVMS){

        List<VMS_Facility_Mapping__c> vmsFacilities;
        vmsFacilities = [SELECT Id, VMS_Facility__c, Facility__c, WFM_Contract__c, Site__c
                        FROM VMS_Facility_Mapping__c 
                        WHERE VMS_Facility__c = :facilityName];

        if(vmsFacilities.size() == 1){
            return vmsFacilities[0];
        } else {
            // INSERT VMS Facility Mapping with Blank Values
            System.debug(LOGGINGLEVEL.ERROR, 'Facility not mapped.');
        }

        return null;
    }

     /**
     * Get Default Site for Facility
     */
    public static sirenum__Site__c getDefaultSite(String facilityName, string firstSeparator, string secondSeparator){
        sirenum__Site__c defaultSite;

        List<String> facilityAddressParts = facilityName.split(firstSeparator);
        for (Integer i = 0; i < facilityAddressParts.size(); i++){
            System.debug(LOGGINGLEVEL.ERROR, 'facilityAddressParts[' + i + ']: ' + facilityAddressParts[i]);
        }

        List<String> fullAddress = facilityAddressParts[facilityAddressParts.size() - 1].split(secondSeparator);
        System.debug(LOGGINGLEVEL.ERROR, 'fullAddress: ' + fullAddress);
        // Array in reverse is Postcode, State, City, Street Parts
        for (Integer i = 0; i < fullAddress.size(); i++){
            System.debug(LOGGINGLEVEL.ERROR, 'fullAddress[' + i + ']: ' + fullAddress[i]);
        }
        String strCityOneWord = 'undefined';
        if (fullAddress.size() >= 3){
            strCityOneWord= fullAddress[fullAddress.size() -3];
        }
        String strCityTwoWords = 'undefined';
        if (fullAddress.size() >= 4){
            strCityTwoWords = fullAddress[fullAddress.size() -4] + ' '  + fullAddress[fullAddress.size() -3];
        }
        String strCityThreeWords = 'undefined';
        if (fullAddress.size() >= 5){
            strCityThreeWords = fullAddress[fullAddress.size() -5] + ' ' + fullAddress[fullAddress.size() -4] + ' ' + fullAddress[fullAddress.size() -3];
        }
        

        List<Account> facilityAccounts = [SELECT Id, Name 
                                            FROM Account 
                                            WHERE BillingPostalCode = :fullAddress[fullAddress.size() -1]
                                            AND BillingState = :fullAddress[fullAddress.size() -2]
                                            AND (BillingCity = :strCityOneWord
                                            OR BillingCity = :strCityTwoWords
                                            OR BillingCity = :strCityThreeWords)];
        System.debug(LOGGINGLEVEL.ERROR, 'facilityAccounts: ' + facilityAccounts);

        If (facilityAccounts.size() == 1){
            List<sirenum__Site__c> facilitySites = [SELECT Id, Name, WFM_Contract__c,  sirenum__Operating_Company__c, VMS_Default_Site__c 
                                FROM sirenum__Site__c 
                                WHERE sirenum__Operating_Company__c = :facilityAccounts[0].Id
                                AND VMS_Default_Site__c = true];
            System.debug(LOGGINGLEVEL.ERROR, 'facilitySites Default: ' + facilitySites);    
            defaultSite = facilitySites[0];
        }

        return defaultSite;

    }


}