public with sharing class ShiftMatchFilledShiftsQueue implements Queueable, Database.AllowsCallouts{
    List<VMS_Filled_Shift__c> thisBatch; 
    Map<String, Shiftmatch_Setting__mdt> settings = new Map<String, Shiftmatch_Setting__mdt>();
    Map<String, List<sirenum__Ticket__c>> candidatePayData = new Map<String, List<sirenum__Ticket__c>>();
    Map<id, sirenum__Shift__c> shiftData = new Map<id, sirenum__Shift__c>();
    Map<String, List<Shiftmatch_Grading__c>> payGradingData = new Map<String, List<Shiftmatch_Grading__c>>();
    Map<String, VMS_Candidate__c> vmsCandidateData = new Map<String, VMS_Candidate__c>();

    public ShiftMatchFilledShiftsQueue(List<VMS_Filled_Shift__c>  thisBatch){
        this.thisBatch = thisBatch;        
        fetchSettings();
        fetchShiftData();
        fetchCandidatePayInfo();
        fetchShiftMatchPayGrading();
        fetchVMSCandidates();
    }

    private void fetchSettings() {
        Set<String> accountIds = new Set<String>();
        for (VMS_Filled_Shift__c s : thisBatch) {
            accountIds.add(s.VMS_Account__c);
        }

        for (Shiftmatch_Setting__mdt s
             : [
               select Account_Id__c, Authorization__c, Requires_Resource_in_Shiftmatch__c
               from Shiftmatch_Setting__mdt 
               where Active__c = true
               and Account_Id__c in :accountIds
            ]) {
            settings.put(s.Account_Id__c, s);
        }

        
        if(Test.isRunningTest()){

                Shiftmatch_Setting__mdt setting = new Shiftmatch_Setting__mdt();
                setting.Account_Id__c = thisBatch[0].VMS_Account__c;
                setting.Authorization__c = 'TestAuth';
                setting.Full_Sync__c = 5;
                setting.Poll_Start_Time_UTC__c = '00:00';
                setting.Poll_End_Time_UTC__c = '23:59';
                setting.Poll_Frequency_Mins__c = 60;
                setting.Shift_Type_Map__c = '[{"type": "AM", "from": "06:00", "to": "12:00"}, {"type": "PM", "from": "12:00", "to": "18:00"}, {"type": "ND", "from": "18:00", "to": "06:00"}]';
                setting.Active__c = true;

                settings.put(thisBatch[0].VMS_Account__c,setting);           
        }
    }

    private void fetchShiftData() {
        Set<Id> shiftIds = new Set<Id>();
        for (VMS_Filled_Shift__c s : thisBatch) {
            shiftIds.add(s.Shift__c);
        }

        for (sirenum__Shift__c s
             : [
               select id, sirenum__Team__r.tc9_ext_sirint__Award_Classification__c, VMS_External_Id__c, sirenum__Contact__r.name, sirenum__Contact__c, sirenum__Shift_Date__c, sirenum__ShiftDemand__c
               from sirenum__Shift__c 
               where id in :shiftIds               
            ]) {
                shiftData.put(s.id, s);
        }
    }
    
    private void fetchCandidatePayInfo() {
        Set<Id> contactIds = new Set<Id>();
        Set<Id> awardClassificationsIds = new Set<Id>();

        for (sirenum__Shift__c s : shiftData.values()) {
            contactIds.add(s.sirenum__Contact__c);
            awardClassificationsIds.add(s.sirenum__Team__r.tc9_ext_sirint__Award_Classification__c);
        }
        
        for (sirenum__Ticket__c s
            : [
                SELECT sirenum__Valid_from__c, sirenum__Valid_until__c, sirenum__Owner__c, 
                       sirenum__TicketType__r.Award_Classification__c, sirenum__TicketType__r.Award_Level__c
                FROM sirenum__Ticket__c
                where sirenum__TicketType__r.Award_Classification__c in :awardClassificationsIds
                and sirenum__Owner__c in :contactIds
            ]) {
            List<sirenum__Ticket__c> payData = candidatePayData.get(s.sirenum__Owner__c + '_' + s.sirenum__TicketType__r.Award_Classification__c);
            if (payData != null) {
                payData.add(s);
            } else {
                candidatePayData.put(s.sirenum__Owner__c + '_' + s.sirenum__TicketType__r.Award_Classification__c, new List<sirenum__Ticket__c> {s});
            }
        }
    }

    private void fetchShiftMatchPayGrading() {
        Set<String> accountIds = new Set<String>();
        Set<Id> awardClassificationsIds = new Set<Id>();

        for (VMS_Filled_Shift__c s : thisBatch) {
            accountIds.add(s.VMS_Account__c);
        }

        for (List<sirenum__Ticket__c> ss : candidatePayData.values()) {            
            for (sirenum__Ticket__c s : ss) {
                awardClassificationsIds.add(s.sirenum__TicketType__r.Award_Classification__c);
            }
            
        }
        
        for (Shiftmatch_Grading__c s
            : [
                select id, Account__c, name, Award_Classification__c, Job_Type__c, (select Award_Level__c, Award_Level__r.Rank__c from ShiftMatch_Grading_Award_Levels__r)
                from Shiftmatch_Grading__c
                where Account__c in :accountids
                and Award_Classification__c in :awardClassificationsIds
            ]) {
            List<Shiftmatch_Grading__c> payData = payGradingData.get(s.Account__c + '_' + s.Award_Classification__c);
            if (payData != null) {
                payData.add(s);
            } else {
                payGradingData.put(s.Account__c + '_' + s.Award_Classification__c, new List<Shiftmatch_Grading__c> {s});
            }
        }
    }


    private void fetchVMSCandidates() {
        Set<String> accountIds = new Set<String>();
        Set<Id> contactIds = new Set<Id>();

        for (VMS_Filled_Shift__c s : thisBatch) {
            accountIds.add(s.VMS_Account__c);
        }

        for (sirenum__Shift__c s : shiftData.values()) {
            contactIds.add(s.sirenum__Contact__c);
        }
        
        for (VMS_Candidate__c s
            : [
                select id, VMS_Account__c, Candidate__c, name
                from VMS_Candidate__c
                where VMS_Account__c in :accountids
                and Candidate__c in :contactIds
                and VMS_Source__c = :ShiftMatchManager.SHIFTMATCH_VMS_SOURCE
            ]) {
            vmsCandidateData.put(s.VMS_Account__c + '_' + s.Candidate__c, s);            
        }
    }

    public void execute(QueueableContext context) { 
        processFilledShift(this.thisBatch[0]);
        this.thisBatch.remove(0);

        if (!this.thisBatch.isEmpty()) {
           System.enqueueJob(this);
        }        
    }

    private void processFilledShift(VMS_Filled_Shift__c filledShift) { 
        List<String> errors = new List<String>();

        Shiftmatch_Setting__mdt setting = settings.get(filledShift.VMS_Account__c);
        if (setting == null) {
            errors.add('Account settings not found.');
            processError(filledShift.id, errors);
            return; 
        }

        sirenum__Shift__c shift = shiftData.get(filledShift.Shift__c);

        String externalId;
        String payGrade;
        if (setting.Requires_Resource_in_Shiftmatch__c) {
            VMS_Candidate__c vmsCandidate = vmsCandidateData.get(filledShift.VMS_Account__c + '_' + shift.sirenum__Contact__c);            
            if (vmsCandidate == null) {
                errors.add('ShiftMatch id not found for candidate.');
                processError(filledShift.id, errors);
                return; 
            }

            externalId = vmsCandidate.name;
        } else {
            List<sirenum__Ticket__c> candidatePayTickets = candidatePayData.get(shift.sirenum__Contact__c + '_' + shift.sirenum__Team__r.tc9_ext_sirint__Award_Classification__c);
            sirenum__Ticket__c candidatePayTicket;
            if (candidatePayTickets != null) {
                for (sirenum__Ticket__c s : candidatePayTickets) {
                    if (s.sirenum__Valid_from__c <= shift.sirenum__Shift_Date__c && (s.sirenum__Valid_until__c >= shift.sirenum__Shift_Date__c || s.sirenum__Valid_until__c == null)) {
                        candidatePayTicket = s;
                        break;
                    }
                }
            }            

            if (candidatePayTicket != null) {
                List<Shiftmatch_Grading__c> payGrades = payGradingData.get(filledShift.VMS_Account__c + '_' + shift.sirenum__Team__r.tc9_ext_sirint__Award_Classification__c);

                if (payGrades != null) {
                    for (Shiftmatch_Grading__c p : payGrades) {
                        for (ShiftMatch_Grading_Award_Level__c gl : p.ShiftMatch_Grading_Award_Levels__r) {
                            if (gl.Award_Level__c == candidatePayTicket.sirenum__TicketType__r.Award_Level__c) {
                                payGrade = p.name;
                                break;
                            }
                        }

                        if (payGrade != null) {
                            break;
                        }
                    }
                }
            }
        }

        ShiftMatchWebserviceStub.BridgeImplPort ws = new ShiftMatchWebserviceStub.BridgeImplPort(setting.Authorization__c);
        
        try {
            ShiftMatchWebserviceStub.bridgeResponse response = ws.addUser_Http(
                shift.VMS_External_Id__c.split('_')[1], 
                externalId, 
                (externalId == null) ? shift.sirenum__Contact__r.name : null,
                payGrade);

            if (!response.success)  {
                if (response.mainMessage == 'That shortfall is already taken') {
                    update new sirenum__Shift__c(
                        id = shift.sirenum__ShiftDemand__c,
                        sirenum__Cancelled__c = true,
                        sirenum__CancellationReason__c = 'VMS Cancellation'
                    );
                } else {
                    errors.add(response.mainMessage);
                    processError(filledShift.id, errors);
                    return;
                }                
            }

            update new VMS_Filled_Shift__c(
                id = filledShift.id,
                status__c = 'Sent'                
            );

            if (response.success) {
                update new sirenum__Shift__c(
                    id = shift.id,
                    VMS_Send_Status__c = 'Sent',
                    Confirmed_With_Facility__c = true
                );
            }
        } catch (Exception e) {
            errors.add(e.getMessage());
            processError(filledShift.id, errors);
        }
        
    }

    private void processError(Id filledShiftId, List<String> errors) { 
        String errorMessage;
        for (String error : errors) {
            errorMessage = (errorMessage == null) ? error : errorMessage + '\n' + error;
        }

        update new VMS_Filled_Shift__c(
                id = filledShiftId,
                Error_Message__c = errorMessage,
                status__c = 'Error'                
            );

    }
}