public with sharing class VMSParserStaffCentral implements VMSShiftParser {
    // TO DO 
    // HANDLE UPDATES/CANCELLATIONS 
    // MOVE COMMON CODE TO UTILITY CLASS
    public void createShift(ShiftService.CreateShiftRequest shiftRequest){

    }

    public void cancelShift(ShiftService.CreateShiftRequest shiftRequest){

    }

    public Database.SaveResult[] createShiftFromEmail(ShiftService.CreateShiftRequest shiftRequest){
        Database.SaveResult[] srList = new List<Database.SaveResult>();
        return srList;
    }

    public Database.SaveResult[] cancelShiftFromEmail(ShiftService.CreateShiftRequest shiftRequest){
        Database.SaveResult[] srList = new List<Database.SaveResult>();
        return srList;
    }

    public Database.SaveResult[] createShiftError(ShiftService.CreateShiftRequest shiftRequest){
        Database.SaveResult[] srList = new List<Database.SaveResult>();
        return srList;
    }

    public ShiftService.CreateShiftRequest parseEmail(Messaging.InboundEmail email){
    // public Map<String,Object> parseEmail(Messaging.InboundEmail email){

        ShiftService.CreateShiftRequest request = new ShiftService.CreateShiftRequest();
        
        // variables to set values
        // String shiftId;
        // String shiftURL;
        String facilityName;
        // String award;
        // String altAward;
        // String role;
        // String altRole;

        String primaryRole;
        String secondaryRole;
        // Date dtShiftDate;
        // Time startTime;
        // Time endTime;
        // Integer shiftMealBreak;
        // String shiftComments;
        // String siteId;
        // String contractId;
        // String jobRoleId;
        request.source = 'StaffCentral';

        String emailSubject = email.subject;
        System.debug(LOGGINGLEVEL.ERROR, 'emailSubject / length: ' + emailSubject + ' / ' + emailSubject.length());

        if(email.subject.indexOf('Cancelled Shift') > -1) {
            request.action = 'Cancel';
        }
        if(email.subject.indexOf('Edit Shift') > -1) {
            request.action = 'Create';
        }
        
        // Integer intShiftId = getPosition(emailSubject, 'ShiftId - ');
        // String shiftId = email.subject.substring(intShiftId+10, intShiftId+16);
        // String shiftId = getData(emailSubject, 'ShiftId - ', 10, 16);

        String emailBody = email.plainTextBody;
        // need to work out end position - use lines? 
        List<String> emailBodyLines = emailBody.split('\n');

        If (request.action == 'Create'){
            createRequest(emailBodyLines, request);
        }
        If (request.action == 'Cancel'){
            cancelRequest(emailBodyLines, request);
        }

        // Integer counter = 0;
        // for (String emailBodyLine : emailBodyLines){
        //     counter++;
        //     System.debug(LOGGINGLEVEL.ERROR, 'Line Nbr / emailBodyLine / length: ' + counter + ' / ' + emailBodyLine + ' / ' + emailBodyLine.length());
        //     if(counter == 3){
        //         // Shift Id and URL
        //         // shiftId = getData(emailBodyLine, 'Shift Id: ', 11, 17);
        //         // shiftURL =  getData(emailBodyLine, '<', 1, emailBodyLine.indexOf('>')-16);
        //         // System.debug(LOGGINGLEVEL.ERROR, 'shiftId: ' + shiftId);
        //         // System.debug(LOGGINGLEVEL.ERROR, 'shiftURL: ' + shiftURL);
        //         request.extShiftId = VMSShiftUtilities.getData(emailBodyLine, 'Shift Id: ', 11, 17);
        //         request.shiftURL =  VMSShiftUtilities.getData(emailBodyLine, '<', 1, emailBodyLine.indexOf('>')-16);
        //         System.debug(LOGGINGLEVEL.ERROR, 'request.extShiftId: ' + request.extShiftId);
        //         System.debug(LOGGINGLEVEL.ERROR, 'request.shiftURL: ' + request.shiftURL);
        //         continue;
        //     }
        //     if(counter == 4){
        //         // Facility Name
        //         // facilityName =  VMSShiftUtilities.getData(emailBodyLine, 'Facility Name: ', 15, emailBodyLine.length());
        //         facilityName =  emailBodyLine.substringAfter(': ');
        //         System.debug(LOGGINGLEVEL.ERROR, 'facilityName: ' + facilityName);
        //         continue;
        //     }
        //     if(counter == 9){
        //         // Role 
        //         // primaryRole = VMSShiftUtilities.getData(emailBodyLine, 'Role Description: ', 18, emailBodyLine.length());
        //         primaryRole =  emailBodyLine.substringAfter(': ');
        //         System.debug(LOGGINGLEVEL.ERROR, 'primaryRole: ' + primaryRole);
        //         continue;
        //     }
        //     if(counter == 10){
        //         // Alt Role 
        //         // secondaryRole = VMSShiftUtilities.getData(emailBodyLine, 'Alt Role Description: ', 22, emailBodyLine.length());
        //         secondaryRole =  emailBodyLine.substringAfter(': ');
        //         System.debug(LOGGINGLEVEL.ERROR, 'secondaryRole: ' + secondaryRole);
        //         continue;
        //     }
        //     if(counter == 11){
        //         // Shift Date 
        //         // String shiftDate = VMSShiftUtilities.getData(emailBodyLine, 'Shift Date: ', 12, emailBodyLine.length());
        //         // dtShiftDate = date.parse(shiftDate);
        //         // System.debug(LOGGINGLEVEL.ERROR, 'dtShiftDate: ' + dtShiftDate);
        //         // request.day = date.parse(shiftDate);
        //         request.day = date.parse(emailBodyLine.substringAfter(': '));
        //         System.debug(LOGGINGLEVEL.ERROR, 'request.day: ' + request.day);
        //         continue;
        //     }
        //     if(counter == 12){
        //         // Start Time
        //         // String shiftStartTime = VMSShiftUtilities.getData(emailBodyLine, 'Start Time: ', 12, emailBodyLine.length());
        //         // startTime = convertShiftTimeToTime(shiftStartTime);
        //         // System.debug(LOGGINGLEVEL.ERROR, 'startTime: ' + startTime);
        //         // request.startTime = VMSShiftUtilities.convertShiftTimeToTime(shiftStartTime);
        //         request.startTime = VMSShiftUtilities.convertShiftTimeToTime(emailBodyLine.substringAfter(': '));
        //         System.debug(LOGGINGLEVEL.ERROR, 'request.startTime: ' + request.startTime);
        //         continue;
        //     }
        //     if(counter == 13){
        //         // End Time 
        //         // String shiftEndTime = VMSShiftUtilities.getData(emailBodyLine, 'End Time: ', 10, emailBodyLine.length());
        //         // endTime = convertShiftTimeToTime(shiftEndTime);
        //         // System.debug(LOGGINGLEVEL.ERROR, 'endTime: ' + endTime);
        //         // request.endTime = VMSShiftUtilities.convertShiftTimeToTime(shiftEndTime);
        //         request.endTime = VMSShiftUtilities.convertShiftTimeToTime(emailBodyLine.substringAfter(': '));
        //         System.debug(LOGGINGLEVEL.ERROR, 'request.endTime: ' + request.endTime);
        //         continue;
        //     }
        //     if(counter == 14){
        //         // Meal break 
        //         // shiftMealBreak = Integer.valueOf(getData(emailBodyLine, 'Meal break: ', 12, emailBodyLine.length()));
        //         // System.debug(LOGGINGLEVEL.ERROR, 'shiftMealBreak: ' + shiftMealBreak);
        //         // request.breakLengthInMinutes = Integer.valueOf(VMSShiftUtilities.getData(emailBodyLine, 'Meal break: ', 12, emailBodyLine.length()));
        //         request.breakLengthInMinutes = Integer.valueOf(emailBodyLine.substringAfter(': '));
        //         System.debug(LOGGINGLEVEL.ERROR, 'request.breakLengthInMinutes: ' + request.breakLengthInMinutes);
        //         continue;
        //     }
        //     if(counter == 17){
        //         // Allocated Employee 
        //         System.debug(LOGGINGLEVEL.ERROR, 'Allocated Employee: ' );
        //         continue;
        //     }
        //     if(counter == 18){
        //         // Notes and comments 
        //         // shiftComments = getData(emailBodyLine, 'Notes and comments: ', 20, emailBodyLine.length());
        //         // System.debug(LOGGINGLEVEL.ERROR, 'shiftComments: ' + shiftComments);
        //         // request.comments = VMSShiftUtilities.getData(emailBodyLine, 'Notes and comments: ', 20, emailBodyLine.length());
        //         request.comments = emailBodyLine.substringAfter(': ');
        //         System.debug(LOGGINGLEVEL.ERROR, 'request.comments: ' + request.comments);
        //         continue;
        //     }
        // }

        // request.site = VMSShiftUtilities.findSite(facilityName, '/', ' ');

        // // Split Facility Name into separate parts
        // List<String> facilityAddressParts = facilityName.split('/');
        // System.debug(LOGGINGLEVEL.ERROR, 'facilityAddressParts: ' + facilityAddressParts);

        // List<List<SObject>> facilitySites = [FIND :facilityAddressParts[0] IN NAME FIELDS RETURNING sirenum__Site__c(Id, Name, WFM_Contract__c)];
        // System.debug(LOGGINGLEVEL.ERROR, 'facilitySites: ' + facilitySites);

        // If (facilitySites.size() == 1){
        //     siteId = facilitySites[0][0].Id;
        //     System.debug(LOGGINGLEVEL.ERROR, 'siteId: ' + siteId);
        //     contractId = (string)facilitySites[0][0].get('WFM_Contract__c');
        //     System.debug(LOGGINGLEVEL.ERROR, 'contractId: ' + contractId);
        // } else {
        //     System.debug(LOGGINGLEVEL.ERROR, 'Unable to determine Site.');
        // }

        // request.contract = VMSShiftUtilities.findContract(request.site);

        // request.jobRole = VMSShiftUtilities.findJobRole(primaryRole, request.contract);

        // get Job Role Id - by Contract/Job Type (Junction Object)
        // List<SObject> jobRoles = [SELECT Id, sirenum__Account__c FROM sirenum__Team__c WHERE Name = :primaryRole AND sirenum__Account__c = :contractId];
        // System.debug(LOGGINGLEVEL.ERROR, 'jobRoles: ' + jobRoles);
        // If (jobRoles.size() == 1){
        //     jobRoleId = jobRoles[0].Id;
        //     System.debug(LOGGINGLEVEL.ERROR, 'jobRoleId: ' + jobRoleId);
        // } else {
        //     System.debug(LOGGINGLEVEL.ERROR, 'Unable to determine Job Role.');
        // }




        // shiftURL =  getData(emailBody, '<', 1, str.indexOf('>')-17);

        // facilityName =  getData(emailBody, 'Facility Name: ', 15, 99);
        // primaryRole = getData(emailBody, 'Role Description: ', 18, 99);
        // secondaryRole = getData(emailBody, 'Alt Role Description: ', 22, 99);

        // Integer intShiftDate = getPosition(emailBody, 'Shift Date: ');
        // String shiftDate = emailBody.substring(intShiftDate+12, intShiftDate+22);
        // String shiftDate = getData(emailBody, 'Shift Date: ', 12, 22);
        // dtShiftDate = date.parse(shiftDate);
        // System.debug(LOGGINGLEVEL.ERROR, 'dtShiftDate: ' + dtShiftDate);

        // Integer intShiftStart = getPosition(emailBody, 'Start Time: ');
        // String shiftStartTime = emailBody.substring(intShiftStart+12, intShiftStart+17);
        // String shiftStartTime = getData(emailBody, 'Start Time: ', 12, 17);
        // startTime = convertShiftTimeToTime(shiftStartTime);
        // System.debug(LOGGINGLEVEL.ERROR, 'startTime: ' + startTime);

        // Integer intShiftEnd = getPosition(emailBody, 'End Time: ', 10, 15);
        // String shiftEndTime = emailBody.substring(intShiftEnd+10, intShiftEnd+15);
        // String shiftEndTime = getData(emailBody, 'End Time: ', 10, 15);
        // endTime = convertShiftTimeToTime(shiftEndTime);
        // System.debug(LOGGINGLEVEL.ERROR, 'endTime: ' + endTime);

        // Integer intMealBreak = getPosition(emailBody, 'Meal break: ', 12, 14);
        // String shiftMealBreak = emailBody.substring(intShiftEnd+12, intShiftEnd+14);
        // shiftMealBreak = Integer.valueOf(getData(emailBody, 'Meal break: ', 12, 14));
        
        // shiftComments = getData(emailBody, 'Notes and comments: ', 20, 99);

        // could put this map in a Class 
        // Map<String,Object> emailMap = new Map<String,Object>();
        // emailMap.put('Shift Id', shiftId);
        // emailMap.put('Shift Facility', facilityName);
        // emailMap.put('Shift URL', shiftURL);
        // emailMap.put('Shift Primary Role', primaryRole);
        // emailMap.put('Shift Secondary Role', secondaryRole);
        // emailMap.put('Shift Date', shiftDate);
        // emailMap.put('Shift Start Time', shiftStartTime);
        // emailMap.put('Shift End Time', shiftEndTime);
        // emailMap.put('Shift Meal Break', shiftMealBreak);
        // emailMap.put('Shift Comments', shiftComments);

        // This needs to cater for creating Shifts and updating Shifts (for cancellation)
        // MOVED - to VMSShiftParserBase
        // List<ShiftService.CreateShiftRequest> shiftRequests = new List<ShiftService.CreateShiftRequest>();

        // request variables set directly above
        // ShiftService.CreateShiftRequest request = new ShiftService.CreateShiftRequest();
        // request.day = dtShiftDate;
        // request.startTime = startTime;
        // request.endTime = endTime;
        // request.breakLengthInMinutes = shiftMealBreak;
        // request.comments = shiftComments;
        // request.extShiftId = shiftId;
        // request.shiftURL = shiftURL;
        // request.contract = contractId;
        // request.site = siteId;
        // request.jobRole = jobRoleId;

        // MOVED - to VMSShiftParserBase
        // shiftRequests.add(request);
        // ShiftService.createShifts(shiftRequests);
        
        // email.subject
        // email.plainTextBody
        // Integer firstCharRef = email.plainTextBody.indexOf('Reference: ');
        
        
        // return 'StaffCentral VMS Shift';
        // return emailMap;
        return request;
    }

    private ShiftService.CreateShiftRequest createRequest(List<String> emailBodyLines, ShiftService.CreateShiftRequest request){
        Integer counter = 0;

        String facilityName;
        String primaryRole;
        String secondaryRole;

        for (String emailBodyLine : emailBodyLines){
            counter++;
            System.debug(LOGGINGLEVEL.ERROR, 'Line Nbr / emailBodyLine / length: ' + counter + ' / ' + emailBodyLine + ' / ' + emailBodyLine.length());
            if(counter == 3){
                // Shift Id and URL
                // shiftId = getData(emailBodyLine, 'Shift Id: ', 11, 17);
                // shiftURL =  getData(emailBodyLine, '<', 1, emailBodyLine.indexOf('>')-16);
                // System.debug(LOGGINGLEVEL.ERROR, 'shiftId: ' + shiftId);
                // System.debug(LOGGINGLEVEL.ERROR, 'shiftURL: ' + shiftURL);
                request.extShiftId = VMSShiftUtilities.getData(emailBodyLine, 'Shift Id: ', 11, 17);
                request.shiftURL =  VMSShiftUtilities.getData(emailBodyLine, '<', 1, emailBodyLine.indexOf('>')-16);
                System.debug(LOGGINGLEVEL.ERROR, 'request.extShiftId: ' + request.extShiftId);
                System.debug(LOGGINGLEVEL.ERROR, 'request.shiftURL: ' + request.shiftURL);
                continue;
            }
            if(counter == 4){
                // Facility Name
                // facilityName =  VMSShiftUtilities.getData(emailBodyLine, 'Facility Name: ', 15, emailBodyLine.length());
                facilityName =  emailBodyLine.substringAfter(': ');
                System.debug(LOGGINGLEVEL.ERROR, 'facilityName: ' + facilityName);
                continue;
            }
            if(counter == 9){
                // Role 
                // primaryRole = VMSShiftUtilities.getData(emailBodyLine, 'Role Description: ', 18, emailBodyLine.length());
                primaryRole =  emailBodyLine.substringAfter(': ');
                System.debug(LOGGINGLEVEL.ERROR, 'primaryRole: ' + primaryRole);
                continue;
            }
            if(counter == 10){
                // Alt Role 
                // secondaryRole = VMSShiftUtilities.getData(emailBodyLine, 'Alt Role Description: ', 22, emailBodyLine.length());
                secondaryRole =  emailBodyLine.substringAfter(': ');
                System.debug(LOGGINGLEVEL.ERROR, 'secondaryRole: ' + secondaryRole);
                continue;
            }
            if(counter == 11){
                // Shift Date 
                // String shiftDate = VMSShiftUtilities.getData(emailBodyLine, 'Shift Date: ', 12, emailBodyLine.length());
                // dtShiftDate = date.parse(shiftDate);
                // System.debug(LOGGINGLEVEL.ERROR, 'dtShiftDate: ' + dtShiftDate);
                // request.day = date.parse(shiftDate);
                request.day = date.parse(emailBodyLine.substringAfter(': '));
                System.debug(LOGGINGLEVEL.ERROR, 'request.day: ' + request.day);
                continue;
            }
            if(counter == 12){
                // Start Time
                // String shiftStartTime = VMSShiftUtilities.getData(emailBodyLine, 'Start Time: ', 12, emailBodyLine.length());
                // startTime = convertShiftTimeToTime(shiftStartTime);
                // System.debug(LOGGINGLEVEL.ERROR, 'startTime: ' + startTime);
                // request.startTime = VMSShiftUtilities.convertShiftTimeToTime(shiftStartTime);
                request.startTime = VMSShiftUtilities.convertShiftTimeToTime(emailBodyLine.substringAfter(': '));
                System.debug(LOGGINGLEVEL.ERROR, 'request.startTime: ' + request.startTime);
                continue;
            }
            if(counter == 13){
                // End Time 
                // String shiftEndTime = VMSShiftUtilities.getData(emailBodyLine, 'End Time: ', 10, emailBodyLine.length());
                // endTime = convertShiftTimeToTime(shiftEndTime);
                // System.debug(LOGGINGLEVEL.ERROR, 'endTime: ' + endTime);
                // request.endTime = VMSShiftUtilities.convertShiftTimeToTime(shiftEndTime);
                request.endTime = VMSShiftUtilities.convertShiftTimeToTime(emailBodyLine.substringAfter(': '));
                System.debug(LOGGINGLEVEL.ERROR, 'request.endTime: ' + request.endTime);
                continue;
            }
            if(counter == 14){
                // Meal break 
                // shiftMealBreak = Integer.valueOf(getData(emailBodyLine, 'Meal break: ', 12, emailBodyLine.length()));
                // System.debug(LOGGINGLEVEL.ERROR, 'shiftMealBreak: ' + shiftMealBreak);
                // request.breakLengthInMinutes = Integer.valueOf(VMSShiftUtilities.getData(emailBodyLine, 'Meal break: ', 12, emailBodyLine.length()));
                request.breakLengthInMinutes = Integer.valueOf(emailBodyLine.substringAfter(': '));
                System.debug(LOGGINGLEVEL.ERROR, 'request.breakLengthInMinutes: ' + request.breakLengthInMinutes);
                continue;
            }
            if(counter == 17){
                // Allocated Employee 
                System.debug(LOGGINGLEVEL.ERROR, 'Allocated Employee: ' );
                continue;
            }
            if(counter == 18){
                // Notes and comments 
                // shiftComments = getData(emailBodyLine, 'Notes and comments: ', 20, emailBodyLine.length());
                // System.debug(LOGGINGLEVEL.ERROR, 'shiftComments: ' + shiftComments);
                // request.comments = VMSShiftUtilities.getData(emailBodyLine, 'Notes and comments: ', 20, emailBodyLine.length());
                request.comments = emailBodyLine.substringAfter(': ');
                System.debug(LOGGINGLEVEL.ERROR, 'request.comments: ' + request.comments);
                continue;
            }
        }

        // request.site = VMSShiftUtilities.findSite(facilityName, '/', ' ');
        // // Split Facility Name into separate parts
        // List<String> facilityAddressParts = facilityName.split('/');
        // System.debug(LOGGINGLEVEL.ERROR, 'facilityAddressParts: ' + facilityAddressParts);

        // List<List<SObject>> facilitySites = [FIND :facilityAddressParts[0] IN NAME FIELDS RETURNING sirenum__Site__c(Id, Name, WFM_Contract__c)];
        // System.debug(LOGGINGLEVEL.ERROR, 'facilitySites: ' + facilitySites);

        // If (facilitySites.size() == 1){
        //     siteId = facilitySites[0][0].Id;
        //     System.debug(LOGGINGLEVEL.ERROR, 'siteId: ' + siteId);
        //     contractId = (string)facilitySites[0][0].get('WFM_Contract__c');
        //     System.debug(LOGGINGLEVEL.ERROR, 'contractId: ' + contractId);
        // } else {
        //     System.debug(LOGGINGLEVEL.ERROR, 'Unable to determine Site.');
        // }

        // request.contract = VMSShiftUtilities.findContract(request.site);

        // request.jobRole = VMSShiftUtilities.findJobRole(primaryRole, request.contract);

        // Original call 
        // List<sirenum__Site__c> sites = VMSShiftUtilities.findSite(facilityName, '/', ' ');
        // System.debug(LOGGINGLEVEL.ERROR, 'sites: ' + sites);

        // if (sites.size() == 1){
        //     request.site = sites[0].Id;
        //     request.contract = sites[0].WFM_Contract__c;
        //     request.jobRole = VMSShiftUtilities.findJobRole(primaryRole, sites[0].sirenum__Operating_Company__c, request.source);
        // }

        // GET SITES FROM SITE MAPPING OBJECT 
        VMS_Facility_Mapping__c vmsFacility = VMSShiftUtilities.mapFacility(facilityName, request.source);
        if(vmsFacility != null){
            request.site = vmsFacility.Site__c;
            request.contract = vmsFacility.WFM_Contract__c;
            request.jobRole = VMSShiftUtilities.findJobRole(primaryRole, vmsFacility.Facility__c, vmsFacility.WFM_Contract__c, request.source);
        } else {
            System.debug(LOGGINGLEVEL.ERROR, 'Get Default Site');
            sirenum__Site__c defaultSite = VMSShiftUtilities.getDefaultSite(facilityName, ', ', ' ');
            if(defaultSite != null){
                request.site = defaultSite.Id;
                request.contract = defaultSite.WFM_Contract__c;
                request.jobRole = VMSShiftUtilities.findJobRole(primaryRole, defaultSite.sirenum__Operating_Company__c, defaultSite.WFM_Contract__c, request.source);
            }
        }

        return request;
    }

    private ShiftService.CreateShiftRequest cancelRequest(List<String> emailBodyLines, ShiftService.CreateShiftRequest request){
        Integer counter = 0;
        for (String emailBodyLine : emailBodyLines){
            counter++;
            System.debug(LOGGINGLEVEL.ERROR, 'Line Nbr / emailBodyLine / length: ' + counter + ' / ' + emailBodyLine + ' / ' + emailBodyLine.length());
            if(counter == 3){
                request.extShiftId = VMSShiftUtilities.getData(emailBodyLine, 'Shift Id: ', 11, 17);
                System.debug(LOGGINGLEVEL.ERROR, 'request.shiftURL: ' + request.shiftURL);
                continue;
            }
        }
        return request;
    }

    // MOVE TO UTILITY CLASS

    // taken from ShiftMatchService for now 
    // private static Time convertShiftTimeToTime(String shiftTime) {
    //     String[] timeSplit = shiftTime.split(':');
    //     Integer hour = Integer.valueOf(timeSplit[0]);
    //     Integer minute = Integer.valueOf(timeSplit[1]);
    //     return Time.newInstance(hour, minute, 0, 0);
    // }

    // // private Integer getPosition(String str, String strSearch){
    // // return str.indexOf(strSearch);
    // // }
    // private String getData(String str, String strSearch, Integer startPosition, Integer endPositon){
    //     System.debug(LOGGINGLEVEL.ERROR, 'VMSParserStaffCentral getPosition strSearch / startPosition / endPositon: ' +  strSearch  + ' / ' + startPosition  + ' / ' + endPositon);
    //     Integer position = str.indexOf(strSearch);
    //     return str.substring(position+startPosition, position+endPositon); 
    // }
    
}