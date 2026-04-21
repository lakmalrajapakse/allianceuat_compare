public with sharing class VMSParserEmprevo implements VMSShiftParser{
    
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
        
        ShiftService.CreateShiftRequest request = new ShiftService.CreateShiftRequest();
        
        request.source = 'Emprevo';
        String emailSubject = email.subject;
        System.debug(LOGGINGLEVEL.ERROR, 'emailSubject / length: ' + emailSubject + ' / ' + emailSubject.length());

        if(email.subject.indexOf('cancelled') > -1) {
            request.action = 'Cancel';
        }
        if(email.subject.indexOf('new shift') > -1) {
            request.action = 'Create';
        }

        String emailBody = email.plainTextBody;
        // need to work out end position - use lines? 
        List<String> emailBodyLines = emailBody.split('\n');

        If (request.action == 'Create'){
            createRequest(emailBodyLines, request);
        }
        If (request.action == 'Cancel'){
            cancelRequest(emailBodyLines, request);
        }
        return request;
    }

    private ShiftService.CreateShiftRequest createRequest(List<String> emailBodyLines, ShiftService.CreateShiftRequest request){
        // variables to set values
        String facilityName;
        String primaryRole;
        String secondaryRole;
        Integer counter = 0;
        for (String emailBodyLine : emailBodyLines){
            counter++;
            System.debug(LOGGINGLEVEL.ERROR, 'Line Nbr / emailBodyLine / length: ' + counter + ' / ' + emailBodyLine + ' / ' + emailBodyLine.length());
            if(counter == 10){
                // Shift Id 
                request.extShiftId = emailBodyLine.substringAfter(' ');
                System.debug(LOGGINGLEVEL.ERROR, 'request.extShiftId: ' + request.extShiftId);
                continue;
            }
            if(counter == 12){
                // Role 
                primaryRole = emailBodyLine;
                System.debug(LOGGINGLEVEL.ERROR, 'primaryRole: ' + primaryRole);
                continue;
            }
            if(counter == 13){
                // Start Time & End Time 
                // String shiftStartTime = emailBodyLine.substring(1, 8);
                // request.startTime = VMSShiftUtilities.convertShiftTimeToTime(shiftStartTime);
                System.debug(LOGGINGLEVEL.ERROR, 'emailBodyLine.substring(0, 8): ' + emailBodyLine.substring(0, 8));
                request.startTime = VMSShiftUtilities.convertShiftTimeToTime(emailBodyLine.substring(0, 8));
                System.debug(LOGGINGLEVEL.ERROR, 'request.startTime: ' + request.startTime);

                // String shiftEndTime = emailBodyLine.substring(13, emailBodyLine.length());
                // request.endTime = VMSShiftUtilities.convertShiftTimeToTime(shiftEndTime);
                System.debug(LOGGINGLEVEL.ERROR, 'emailBodyLine.substring(12, emailBodyLine.length(): ' + emailBodyLine.substring(12, emailBodyLine.length()));
                request.endTime = VMSShiftUtilities.convertShiftTimeToTime(emailBodyLine.substring(12, emailBodyLine.length()));
                System.debug(LOGGINGLEVEL.ERROR, 'request.endTime: ' + request.endTime);

                // System.debug(LOGGINGLEVEL.ERROR, 'shiftStartTime / shiftEndTime: ' + shiftStartTime + ' / ' + shiftEndTime);
                continue;
            }
            if(counter == 14){
                // Shift Date 
                // String shiftDate = emailBodyLine.substringAfter(' ');
                // System.debug(LOGGINGLEVEL.ERROR, 'date.parse(shiftDate): ' + date.parse(shiftDate));
                request.day = date.parse(emailBodyLine.substringAfter(' '));
                System.debug(LOGGINGLEVEL.ERROR, 'request.day: ' + request.day);
                continue;
            }
            if(counter == 16){
                // Number of Shifts  
                // String shiftCount = emailBodyLine.substringBefore(' ');
                request.numShifts = Integer.valueOf(emailBodyLine.substringBefore(' '));
                System.debug(LOGGINGLEVEL.ERROR, 'Number of Shifts: |' +  request.numShifts + '|');
                continue;
            }
            if(counter == 18){
                // Facility Name
                facilityName =  emailBodyLine;
                System.debug(LOGGINGLEVEL.ERROR, 'facilityName: ' + facilityName);
                continue;
            }
            if(counter == 21){
                // Shift URL
                request.shiftURL =  emailBodyLine;
                System.debug(LOGGINGLEVEL.ERROR, 'request.shiftURL: ' + request.shiftURL);
                continue;
            }
        }

        // request.site = VMSShiftUtilities.findSite(facilityName, ', ', ' ');
    
        // Original call 
        // List<sirenum__Site__c> sites = VMSShiftUtilities.findSite(facilityName, ', ', ' ');
        // System.debug(LOGGINGLEVEL.ERROR, 'sites: ' + sites);
        

        // if (sites.size() == 1){
        //     request.site = sites[0].Id;
        //     request.contract = sites[0].WFM_Contract__c;
        //     request.jobRole = VMSShiftUtilities.findJobRole(primaryRole, sites[0].sirenum__Operating_Company__c, request.source);
        // }
            
        
        // request.contract = VMSShiftUtilities.findContract(request.site);
        // request.contract = (string)sites[0][0].get('WFM_Contract__c');
        // request.contract = sites[0].WFM_Contract__c;

        // request.jobRole = VMSShiftUtilities.findJobRole(primaryRole, sites[0].sirenum__Operating_Company__c, request.source);

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
            if(counter == 10){
                // Shift Id 
                request.extShiftId = emailBodyLine.substringAfter(' ');
                System.debug(LOGGINGLEVEL.ERROR, 'request.extShiftId: ' + request.extShiftId);
                continue;
            }
        }
        return request;
    }

}