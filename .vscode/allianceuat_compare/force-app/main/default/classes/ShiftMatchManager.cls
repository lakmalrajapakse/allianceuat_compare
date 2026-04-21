public inherited sharing class ShiftMatchManager {
    public static final String SHIFTMATCH_VMS_SOURCE = 'ShiftMatch';
    public static final String SKILL_STATUS_MANDATORY = 'Mandatory';
    public static final String SKILL_STATUS_MANDATORY_INDUCTION = 'Mandatory Induction';
    public static final String SKILL_STATUS_OPTIONAL = 'Optional';
    public static final String SKILL_STATUS_IGNORE = 'Ignore Skill';

    private static SIM_General_Settings__c setting =  SIM_General_Settings__c.getInstance();

    @testvisible
    private Map<id, ShiftMatchAccount> accountsToProcess;

    private List<Shiftmatch_Setting__mdt> getSettings(Id accountId) {
        //get active Shiftmatch accounts
        List<Shiftmatch_Setting__mdt> shiftMatchSetttings = [
            select Authorization__c
            from Shiftmatch_Setting__mdt 
            where Account_Id__c = :accountId
        ];

        if(Test.isRunningTest()){

            Shiftmatch_Setting__mdt setting = new Shiftmatch_Setting__mdt();
            setting.Account_Id__c = accountId;
            setting.Authorization__c = 'TestAuth';
            setting.Full_Sync__c = 5;
            setting.Poll_Start_Time_UTC__c = '00:00';
            setting.Poll_End_Time_UTC__c = '23:59';
            setting.Poll_Frequency_Mins__c = 60;
            setting.Shift_Type_Map__c = '[{"type": "AM", "from": "06:00", "to": "12:00"}, {"type": "PM", "from": "12:00", "to": "18:00"}, {"type": "ND", "from": "18:00", "to": "06:00"}]';
            setting.Active__c = true;
            shiftMatchSetttings.add(setting);
                
        }

        return shiftMatchSetttings;        
    }

    public void refreshShiftmatchLocationMapData(Id accountId) {
        //get active Shiftmatch accounts
        List<Shiftmatch_Setting__mdt> shiftMatchSetttings = getSettings(accountId);

        if (shiftMatchSetttings.isEmpty()) {
            return;
        }

        //perform callout
        ShiftMatchWebserviceStub.BridgeImplPort ws = new ShiftMatchWebserviceStub.BridgeImplPort(setting.Shiftmatch_Endpoint__c, shiftMatchSetttings[0].Authorization__c);
        ShiftMatchWebserviceStub.bridgeResponse response = ws.getLocations_Http();

        if (response.success != null && !response.success) {
            throw new ShiftMatchException(response.mainMessage);            
        }

        Map<String, ShiftMatchLocation> locations = handleLocations(null, response.dataList.locationData[0]);

        //get all grading for account        
        Map<String, Shiftmatch_Location__c> locationMap = new Map<String, Shiftmatch_Location__c>();
        for (Shiftmatch_Location__c g : [
            select name, Abbreviation__c, Level__c, Parent_Location__c, id, Parent_Location__r.name, Description__c
            from Shiftmatch_Location__c
            where Account__c = :accountId
        ]) {
            locationMap.put(g.name, g);
        }

        List<Shiftmatch_Location__c> toDelete = new List<Shiftmatch_Location__c>();
        List<Shiftmatch_Location__c> toUpdate = new List<Shiftmatch_Location__c>();
        List<Shiftmatch_Location__c> toInsert = new List<Shiftmatch_Location__c>();        

        for (ShiftMatchLocation l : locations.values()) {
            Shiftmatch_Location__c rec = locationMap.get(l.pkid);
            
            if (rec == null) {
                rec = new Shiftmatch_Location__c(                    
                    name = l.pkid, 
                    Abbreviation__c = l.abbreviation,
                    Description__c = l.description, 
                    Level__c = l.level,
                    Parent_Location__c = null,
                    Account__c = accountId
                );
                l.locationRecord = rec;
                toInsert.add(rec);
            } else if (rec.Abbreviation__c != l.abbreviation || rec.Description__c != l.description || rec.Level__c != l.level) {
                rec.Abbreviation__c = l.abbreviation;
                rec.Description__c = l.description;
                rec.Level__c = l.level;
                l.locationRecord = rec;
                toUpdate.add(rec);
            }
        }

        for (String pkid : locationMap.keyset()) {
            if (locations.get(pkid) == null) {
                toDelete.add(locationMap.get(pkid));
            }            
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }

        if (!toDelete.isEmpty()) {
            delete toDelete;
        }

        toUpdate = new List<Shiftmatch_Location__c>();
        for (ShiftMatchLocation l : locations.values()) {
            if (l.locationRecord == null) {
                continue;
            }

            if ((l.parentPkid != null && l.locationRecord.Parent_Location__c == null) || 
                 (l.locationRecord.Parent_Location__c != null && l.parentPkid == null) || 
                 (l.parentPkid != null && l.locationRecord.Parent_Location__r != null && l.locationRecord.Parent_Location__r.name !=  l.parentPkid)) {
                l.locationRecord.Parent_Location__c =  ((l.parentPkid == null) ? null : locations.get(l.parentPkid).locationRecord.id);
                toUpdate.add(l.locationRecord);
            }            
            Shiftmatch_Location__c rec = locationMap.get(l.pkid);
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
    
    private Map<String, ShiftMatchLocation> handleLocations(ShiftMatchLocation parentLocation, ShiftMatchWebserviceStub.bridgeLocation bridgeLocation) {
        Map<String, ShiftMatchLocation> locations = new Map<String, ShiftMatchLocation>();
        ShiftMatchLocation location = new ShiftMatchLocation(parentLocation, bridgeLocation);
        locations.put(location.pkid, location);
        
        if (bridgeLocation.child != null) {
            for (ShiftMatchWebserviceStub.bridgeLocation childLocation : bridgeLocation.child) {
                locations.putAll(handleLocations(location, childLocation));
            }
        }

        return locations;
    }

    //gets locations from shiftmatch and upserts the Shiftmatch Grading object
    public void refreshShiftmatchGradingMapData(Id accountId) {
        //get active Shiftmatch accounts
        List<Shiftmatch_Setting__mdt> shiftMatchSetttings = getSettings(accountId);

        if (shiftMatchSetttings.isEmpty()) {
            return;
        }

        //perform callout
        ShiftMatchWebserviceStub.BridgeImplPort ws = new ShiftMatchWebserviceStub.BridgeImplPort(setting.Shiftmatch_Endpoint__c, shiftMatchSetttings[0].Authorization__c);
        ShiftMatchWebserviceStub.bridgeResponse response = ws.getGradings_Http();

        if (response.success != null && !response.success) {
            throw new ShiftMatchException(response.mainMessage);
        }

        //get all grading for account        
        Map<String, Shiftmatch_Grading__c> gradingsMap = new Map<String, Shiftmatch_Grading__c>();
        for (Shiftmatch_Grading__c g : [
            select name, Short_Description__c, Priority__c, Long_Description__c, id 
            from Shiftmatch_Grading__c            
            where Account__c = :accountId
        ]) {
            gradingsMap.put(g.name, g);
        }

        List<Shiftmatch_Grading__c> toDelete = new List<Shiftmatch_Grading__c>();
        List<Shiftmatch_Grading__c> toUpdate = new List<Shiftmatch_Grading__c>();
        List<Shiftmatch_Grading__c> toInsert = new List<Shiftmatch_Grading__c>();
        Set<String> pkids = new Set<String>();

        for (ShiftMatchWebserviceStub.bridgeGrading g : response.dataList.gradingData) {
            Shiftmatch_Grading__c rec = gradingsMap.get(g.pkid);
            
            if (rec == null) {
                rec = new Shiftmatch_Grading__c(
                    name = g.pkid, 
                    Short_Description__c = g.shortDescription, 
                    Priority__c = g.priority, 
                    Long_Description__c = g.longDescription,
                    Account__c = accountId
                );
                toInsert.add(rec);
            } else if (rec.Short_Description__c != g.shortDescription || rec.Priority__c != g.priority || rec.Long_Description__c != g.longDescription) {
                rec.Short_Description__c = g.shortDescription;
                rec.Priority__c = g.priority;
                rec.Long_Description__c = g.longDescription;
                toUpdate.add(rec);
            }

            pkids.add(g.pkid);
        }

        for (String pkid : gradingsMap.keyset()) {
            if (!pkids.contains(pkid)) {
                toDelete.add(gradingsMap.get(pkid));
            }            
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }

        if (!toDelete.isEmpty()) {
            delete toDelete;
        }
    }

    public void refreshShiftmatchSkillMapData(Id accountId) {
        //get active Shiftmatch accounts
        List<Shiftmatch_Setting__mdt> shiftMatchSetttings = getSettings(accountId);

        if (shiftMatchSetttings.isEmpty()) {
            return;
        }

        //perform callout
        ShiftMatchWebserviceStub.BridgeImplPort ws = new ShiftMatchWebserviceStub.BridgeImplPort(setting.Shiftmatch_Endpoint__c, shiftMatchSetttings[0].Authorization__c);
        ShiftMatchWebserviceStub.bridgeResponse response = ws.getSkills_Http();

        if (response.success != null && !response.success) {
            throw new ShiftMatchException(response.mainMessage);
        }

        //get all grading for account        
        Map<String, Shiftmatch_Skill__c> skillsMap = new Map<String, Shiftmatch_Skill__c>();
        for (Shiftmatch_Skill__c s : [
            select name, Description__c, Priority__c, id 
            from Shiftmatch_Skill__c            
            where Account__c = :accountId
        ]) {
            skillsMap.put(s.name, s);
        }

        List<Shiftmatch_Skill__c> toDelete = new List<Shiftmatch_Skill__c>();
        List<Shiftmatch_Skill__c> toUpdate = new List<Shiftmatch_Skill__c>();
        List<Shiftmatch_Skill__c> toInsert = new List<Shiftmatch_Skill__c>();
        Set<String> pkids = new Set<String>();

        for (ShiftMatchWebserviceStub.bridgeSkill s : response.dataList.skillData) {
            Shiftmatch_Skill__c rec = skillsMap.get(String.valueOf(s.pkid));
            
            if (rec == null) {
                rec = new Shiftmatch_Skill__c(
                    name = String.valueOf(s.pkid), 
                    Description__c = s.description, 
                    Priority__c = s.priority, 
                    Account__c = accountId,
                    Status__c = SKILL_STATUS_MANDATORY
                );
                toInsert.add(rec);
            } else if (rec.Description__c != s.description || rec.Priority__c != s.priority) {
                rec.Description__c = s.description;
                rec.Priority__c = s.priority;                
                toUpdate.add(rec);
            }

            pkids.add(String.valueOf(s.pkid));
        }

        for (String pkid : skillsMap.keyset()) {
            if (!pkids.contains(pkid)) {
                toDelete.add(skillsMap.get(pkid));
            }            
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }

        if (!toDelete.isEmpty()) {
            delete toDelete;
        }
    }

    public void refreshShiftmatchCandidates(Id accountId) {
        //get active Shiftmatch accounts
        List<Shiftmatch_Setting__mdt> shiftMatchSetttings = getSettings(accountId);

        if (shiftMatchSetttings.isEmpty()) {
            return;
        }

        //perform callout
        ShiftMatchWebserviceStub.BridgeImplPort ws = new ShiftMatchWebserviceStub.BridgeImplPort(setting.Shiftmatch_Endpoint__c, shiftMatchSetttings[0].Authorization__c);
        ShiftMatchWebserviceStub.bridgeResponse response = ws.getUsers_Http();

        if (response.success != null && !response.success) {
            throw new ShiftMatchException(response.mainMessage);
        }

        //get all grading for account        
        Map<String, VMS_Candidate__c> candMap = new Map<String, VMS_Candidate__c>();
        for (VMS_Candidate__c s : [
            select name, email__c, first_name__c, last_name__c,  id, candidate_info__c 
            from VMS_Candidate__c            
            where VMS_Account__c = :accountId
            and VMS_Source__c = :SHIFTMATCH_VMS_SOURCE
        ]) {
            candMap.put(s.name, s);
        }

        List<VMS_Candidate__c> toDelete = new List<VMS_Candidate__c>();
        List<VMS_Candidate__c> toUpdate = new List<VMS_Candidate__c>();
        List<VMS_Candidate__c> toInsert = new List<VMS_Candidate__c>();
        Set<String> pkids = new Set<String>();
        
        for (ShiftMatchWebserviceStub.bridgeUser s : response.dataList.userData) {
            VMS_Candidate__c rec = candMap.get(String.valueOf(s.pkid));
            
            if (rec == null) {
                rec = new VMS_Candidate__c(
                    name = String.valueOf(s.pkid), 
                    last_name__c = s.contactInformation.lastName, 
                    first_name__c = s.contactInformation.firstName, 
                    email__c = s.contactInformation.email,
                    VMS_Source__c = SHIFTMATCH_VMS_SOURCE,
                    candidate_info__c = (s.grading + ' | ' + s.role).left(255),
                    VMS_Account__c  = accountId
                );
                toInsert.add(rec);
            } else if (rec.first_name__c != s.contactInformation.firstname || rec.last_name__c != s.contactInformation.lastname || rec.email__c != s.contactInformation.email ) {
                rec.last_name__c = s.contactInformation.lastName;
                rec.first_name__c = s.contactInformation.firstName;
                rec.email__c = s.contactInformation.email;
                rec.candidate_info__c = (s.grading + ' | ' + s.role).left(255);
                toUpdate.add(rec);
            }

            pkids.add(String.valueOf(s.pkid));
        }

        for (String pkid : candMap.keyset()) {
            if (!pkids.contains(pkid)) {
                toDelete.add(candMap.get(pkid));
            }            
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }

        if (!toDelete.isEmpty()) {
            delete toDelete;
        }
    }

    public List<Id> getAccountIdsToProcess() {
        List<id> accountIds = new List<id>();
        accountIds.addAll(this.accountsToProcess.keyset());
        return accountIds;
    }

    public void processShortfalls() {
        //check if batch running 
        if (Async_Utils.isAnotherBatchActive(ShiftMatchShortfallBatch.class.getName(), null)) {
            return;
        }

        //get active Shiftmatch accounts
        List<Shiftmatch_Setting__mdt> shiftMatchSetttings = [
            select Account_Id__c, Authorization__c, Full_Sync__c, Poll_End_Time_UTC__c, Poll_Frequency_Mins__c, 
                   Poll_Start_Time_UTC__c, Shift_Type_Map__c
            from Shiftmatch_Setting__mdt where Active__c = true
        ];

        if(Test.isRunningTest()){
            Account testAcc = [select id from Account limit 1];
            shiftMatchSetttings = getSettings(testAcc.Id);
        }
        
        
        Map<id, Shiftmatch_Setting__mdt> settingsMap = new Map<id, Shiftmatch_Setting__mdt>();
        this.accountsToProcess = new Map<id, ShiftMatchAccount>();
        for (Shiftmatch_Setting__mdt s: shiftMatchSetttings) {            
            settingsMap.put(s.Account_Id__c, s);
        }        

        //get accounts details
        for (Account a : [
            select id, Shiftmatch_Counter__c, Shiftmatch_Last_Sync_Date__c
            from Account
            where id in :settingsMap.keyset()
        ]) {
            Shiftmatch_Setting__mdt s = settingsMap.get(a.id);
            String process = this.processAccount(s, a);

            if (process == 'NO') {
                continue;
            }
            
            this.accountsToProcess.put(
                a.id, 
                new ShiftMatchAccount()
                    .setAccount(a)
                    .setSetting(s)
                    .setFullSync(process == 'FULL')
            );
        }

        if (this.accountsToProcess.isEmpty()) { 
            return;
        }
        
        Database.executeBatch(new ShiftMatchShortfallBatch(this), 1);
    }

    public void processShortfall(Id accountId) {
        //retrieve settings 
        ShiftMatchAccount shiftMatchAccount = this.accountsToProcess.get(accountId);

        //perform callout
        ShiftMatchWebserviceStub.BridgeImplPort ws = new ShiftMatchWebserviceStub.BridgeImplPort(setting.Shiftmatch_Endpoint__c, shiftMatchAccount.setting.Authorization__c);
        
        try {
            ShiftMatchWebserviceStub.bridgeResponse response = ws.getShortfalls_Http(shiftMatchAccount.fullSync ? 'False' : 'True');

            if (!response.success) {
                ShiftMatchUtility.logError(accountId, response.mainMessage);
                return;
            }

            handleShortfall(shiftMatchAccount, response);

            update new Account(
                id = accountId,
                Shiftmatch_Last_Sync_Date__c = DateTime.now(),
                Shiftmatch_Counter__c = (shiftMatchAccount.account.Shiftmatch_Counter__c == null) ? 0 : Math.mod(Integer.valueOf(shiftMatchAccount.account.Shiftmatch_Counter__c) + 1, Integer.valueOf(shiftMatchAccount.setting.Full_Sync__c))
            );
        } catch (Exception e) {
            ShiftMatchUtility.logError(accountId, (e.getMessage() + ' | ' + e.getStackTraceString()).left(120000));
        }
    }

    public void reprocessShortfalls(List<Id> payloadIds) {
        List<VMS_Shift_Payload__c> payloads = getPayloadsById(payloadIds);
        Map<String, List<ShiftMatchWebserviceStub.bridgeShortfall>> shortfallsToProcess = new Map<String, List<ShiftMatchWebserviceStub.bridgeShortfall>>();

        List<VMS_Shift_Payload__c> expiredPayloads = new List<VMS_Shift_Payload__c>();
        for (VMS_Shift_Payload__c payload : payloads) {
            if (payload.Body__c == null || payload.status__c == 'Success' || payload.shift__r.sirenum__Cancelled__c) {
                continue;
            }

            ShiftMatchWebserviceStub.bridgeShortfall shortfall = (ShiftMatchWebserviceStub.bridgeShortfall) JSON.deserialize(payload.Body__c, ShiftMatchWebserviceStub.bridgeShortfall.class);
            
            if (DateTime.now() < ShiftMatchUtility.convertShiftDateToDateTime(shortfall.deadline)) {
                String accountId = payload.External_Shift_ID__c.split('_')[0];
                List<ShiftMatchWebserviceStub.bridgeShortfall> shortfalls = shortfallsToProcess.get(accountId);
                if (shortfalls == null) {
                    shortfallsToProcess.put(accountId, new List<ShiftMatchWebserviceStub.bridgeShortfall> {shortfall});
                } else {
                    shortfalls.add(shortfall);
                }
            } else {
                payload.Status__c = 'Expired';
                expiredPayloads.add(payload);
            }
        }

        if (!expiredPayloads.isEmpty()) {
            update expiredPayloads; 
        }

        if (shortfallsToProcess.isEmpty()) {
            return;
        }

        List<Shiftmatch_Setting__mdt> shiftMatchSetttings = [
            select Account_Id__c, Authorization__c, Full_Sync__c, Poll_End_Time_UTC__c, Poll_Frequency_Mins__c, 
                   Poll_Start_Time_UTC__c, Shift_Type_Map__c
            from Shiftmatch_Setting__mdt where Active__c = true
            and Account_Id__c in :shortfallsToProcess.keySet() 
        ];

        
        if(Test.isRunningTest()){

            Shiftmatch_Setting__mdt setting = new Shiftmatch_Setting__mdt();
            setting.Account_Id__c = payloads[0].VMS_Account__c;
            setting.Authorization__c = 'TestAuth';
            setting.Full_Sync__c = 5;
            setting.Poll_Start_Time_UTC__c = '0000';
            setting.Poll_End_Time_UTC__c = '2359';
            setting.Poll_Frequency_Mins__c = 60;
            setting.Shift_Type_Map__c = '[{"type":"AM","startTime":"06:00:00.000Z","endTime":"12:00:00.000Z"},{"type":"PM","startTime":"12:00:00.000Z","endTime":"18:00:00.000Z"},{"type":"ND","startTime":"18:00:00.000Z","endTime":"06:00:00.000Z"}]';
            shiftMatchSetttings.add(setting);
                
        }
                
        Map<id, ShiftMatchAccount> accountsToProcess = new Map<id, ShiftMatchAccount>();
        for (Shiftmatch_Setting__mdt s: shiftMatchSetttings) {            
            accountsToProcess.put(s.Account_Id__c, 
                new ShiftMatchAccount()
                    .setAccount(new Account(id=s.Account_Id__c))
                    .setSetting(s)
                    .setFullSync(false)
            );
        } 

        for (String accountId : accountsToProcess.keySet()) {
            handleShortfall(accountsToProcess.get(accountId), shortfallsToProcess.get(accountId), true);
        }
    }

    private void handleShortfall(ShiftMatchAccount shiftMatchAccount, ShiftMatchWebserviceStub.bridgeResponse response) {
        handleShortfall(shiftMatchAccount, response.dataList.shortfallData, false);        
    }

    private void handleShortfall(ShiftMatchAccount shiftMatchAccount, List<ShiftMatchWebserviceStub.bridgeShortfall> shortfalls, Boolean isRetry) {
        Map<String, ShiftMatchShift> shiftData = new Map<String, ShiftMatchShift>();
        String accountId = shiftMatchAccount.account.id;

        // if there is data
        if (shortfalls != null && !shortfalls.isEmpty()) {
            for (ShiftMatchWebserviceStub.bridgeShortfall s : shortfalls) {            
                shiftData.put(accountId + '_' + s.pkid, new ShiftMatchShift(shiftMatchAccount, s));
            }

            //get existing matching payloads
            Map<String, VMS_Shift_Payload__c> payloadMap = getExistingPayloadInfo(shiftData.keyset());
            Map<String, sirenum__Shift__c> shiftMap = getExistingShifts(shiftData.keyset());
            
            for (String externalShiftId : shiftData.keyset()) {
                shiftData.get(externalShiftId).setPayload(payloadMap.get(externalShiftId), isRetry);
                shiftData.get(externalShiftId).setShift(shiftMap.get(externalShiftId));
            }
            
            Set<String> locations = new Set<String>();
            Set<String> gradings = new Set<String>();
            Set<String> skills = new Set<String>();

            for (ShiftMatchShift s : shiftData.values()) {
                if (s.status == 'NO CHANGE') {
                    continue;
                }

                if (s.shortfall.locationPkid0 != null && s.shortfall.locationPkid0 != 0) {
                    locations.add(String.valueOf(s.shortfall.locationPkid0));
                }
                if (s.shortfall.locationPkid1 != null && s.shortfall.locationPkid1 != 0) {
                    locations.add(String.valueOf(s.shortfall.locationPkid1));
                }
                if (s.shortfall.locationPkid2 != null && s.shortfall.locationPkid2 != 0) {
                    locations.add(String.valueOf(s.shortfall.locationPkid2));
                }
                if (s.shortfall.locationPkid3 != null && s.shortfall.locationPkid3 != 0) {
                    locations.add(String.valueOf(s.shortfall.locationPkid3));
                }
                if (s.shortfall.locationPkid4 != null && s.shortfall.locationPkid4 != 0) {
                    locations.add(String.valueOf(s.shortfall.locationPkid4));
                }

                if (s.shortfall.gradingMax != null) {
                    gradings.add(s.shortfall.gradingMax);
                }

                if (s.shortfall.gradingMin != null) {
                    gradings.add(s.shortfall.gradingMin);
                }

                if (s.shortfall.skillPkids != null && s.shortfall.skillPkids.idCollection != null && !s.shortfall.skillPkids.idCollection.isEmpty()) {
                    for (Integer skillPkid : s.shortfall.skillPkids.idCollection) {
                        skills.add(String.valueOf(skillPkid));
                    }
                }
            }
            
            if (!locations.isEmpty() && !gradings.isEmpty()) {
                Map<String, Shiftmatch_Location__c> locationMap = getLocationData(accountId, locations);
                Map<String, Shiftmatch_Grading__c> gradingMap = getGradingData(accountId, gradings);
                Map<String, Shiftmatch_Skill__c> skillMap = getSkillData(accountId, skills);
                Map<Id, Job_Type_Rank__c> jobTypeRankMap = getJobTypeRanks(accountId);

                Set<Id> accountIds = new Set<Id> {accountId};
                Set<Id> aClassficationIds = new Set<Id>();                
                Set<Id> jobTypeIds = new Set<Id>();
                Set<Id> jobRoleIds = new Set<Id>();

                for (ShiftMatchShift shift : shiftData.values()) {            
                    shift.mapLocationData(locationMap);
                    shift.mapGradingData(gradingMap, jobTypeRankMap);                                

                    if (shift.workSiteAccount != null) {
                        accountIds.add(shift.workSiteAccount);
                    }

                    if (shift.gradeMax != null && shift.gradeMax.classification != null && (shift.gradeJobTypes == null ||shift.gradeJobTypes.size() <= 1)) {
                        aClassficationIds.add(shift.gradeMax.classification);
                        jobTypeIds.add(shift.gradeMax.classification);
                    } else if (shift.gradeJobTypes != null && shift.gradeJobTypes.size() > 1) {
                        jobTypeIds.addAll(shift.gradeJobTypes);
                    }


                }

                Map<String, List<sirenum__Team__c>> jobRoleData = new Map<String, List<sirenum__Team__c>>();
                Map<Id, List<ShiftMatch_Skill__c>> jobTypeSkills = new Map<Id, List<ShiftMatch_Skill__c>>();
                if (!aClassficationIds.isEmpty()) {
                    jobRoleData = getJobRoleData(accountIds, aClassficationIds);                    
                }

                if (!jobTypeIds.isEmpty()) {
                    jobTypeSkills = getJobTypeSkills(accountId, jobTypeIds);
                }

                Map<id, id> multiJobRoles = getMultiJobRoles(accountids);
                

                List<sirenum__Shift__c> shiftsToUpsert = new List<sirenum__Shift__c>();
                for (ShiftMatchShift shift : shiftData.values()) { 
                    if (shift.gradeJobTypes != null && shift.gradeJobTypes.size() > 1) {
                        continue;
                    }

                    shift.mapJobRoleData(jobRoleData);
                    
                    if (shift.jobRoles == null) {
                        continue;
                    }

                    for (sirenum__Team__c j : shift.jobRoles) {
                        if (j.sirenum__Job_Type__c != null) {
                            jobTypeIds.add(j.sirenum__Job_Type__c);
                        }
                        jobRoleIds.add(j.id);
                    }                        
                }

                Map<Id, Set<Id>> compentencyMap = new Map<Id, Set<Id>>();
                if (!jobRoleIds.isEmpty() || !jobTypeIds.isEmpty()) {
                    compentencyMap = getCompetencyData(jobTypeIds, jobRoleIds);    
                }
                
                List<sirenum__CompetencyBundle__c> competenciesBundleToInsert = new List<sirenum__CompetencyBundle__c>();
                List<sirenum__CompetencyBundleItem__c> competenciesBundleItemsToInsert = new List<sirenum__CompetencyBundleItem__c>();
                Set<id> competencyIds = new Set<id>();

                for (ShiftMatchShift shift : shiftData.values()) {            
                    shift.mapJobRoleDataFinal(compentencyMap, multiJobRoles, skillMap, jobTypeSkills);
                    shift.processShift();

                    if (shift.shift != null) {                                                
                        if (!shift.skillCompetencyBundleItems.isEmpty()) {                            
                            for (sirenum__CompetencyBundleItem__c  c : shift.skillCompetencyBundleItems) {
                                competencyIds.add(c.sirenum__Competency__c);
                            }                            
                        }

                        if (!shift.skillOptionalCompetencyBundleItems.isEmpty()) {                            
                            for (sirenum__CompetencyBundleItem__c  c : shift.skillOptionalCompetencyBundleItems) {
                                competencyIds.add(c.sirenum__Competency__c);
                            }                            
                        }

                        if (!shift.jobTypeCompetencyBundleItems.isEmpty()) {
                            for (sirenum__CompetencyBundleItem__c  c : shift.jobTypeCompetencyBundleItems) {
                                competencyIds.add(c.sirenum__Competency__c);
                            }                            
                        }

                        shiftsToUpsert.add(shift.shift);
                    }                    
                }

                Map<id, List<sirenum__CompetencyBundleItem__c>> templateCompetencies = getCompetencyBundleTemplates(competencyIds);
                for (ShiftMatchShift shift : shiftData.values()) { 
                    if (shift.shift == null) {
                        continue;
                    }           
                    shift.assignCompetencyTemplate(templateCompetencies);                    
                    if (!shift.skillCompetencyBundleItems.isEmpty() && shift.shift.sirenum__CompetencyBundle__c == null) {                                                
                        competenciesBundleToInsert.add(shift.skillCompetencyBundle);
                        competenciesBundleItemsToInsert.addAll(shift.skillCompetencyBundleItems);
                    }

                    if (!shift.skillOptionalCompetencyBundleItems.isEmpty() && shift.shift.Skill_Attribute_OR_Bundle__c == null) {                                                
                        competenciesBundleToInsert.add(shift.skillOptionalCompetencyBundle);
                        competenciesBundleItemsToInsert.addAll(shift.skillOptionalCompetencyBundleItems);
                    }

                    if (!shift.jobTypeCompetencyBundleItems.isEmpty() && shift.shift.Role_OR_Bundle__c == null) {
                        competenciesBundleToInsert.add(shift.jobTypeCompetencyBundle);
                        competenciesBundleItemsToInsert.addAll(shift.jobTypeCompetencyBundleItems);
                    }                    
                }


                if (!competenciesBundleToInsert.isEmpty()) {
                    insert competenciesBundleToInsert;
                }

                for (sirenum__CompetencyBundleItem__c cbi : competenciesBundleItemsToInsert) {
                    cbi.sirenum__CompetencyBundle__c = cbi.sirenum__CompetencyBundle__r.id;
                }

                for (sirenum__Shift__c shift : shiftsToUpsert) {
                    if (shift.Skill_Attribute_OR_Bundle__r != null && shift.Skill_Attribute_OR_Bundle__c == null) {
                        shift.Skill_Attribute_OR_Bundle__c = shift.Skill_Attribute_OR_Bundle__r.id;
                    }

                    if (shift.sirenum__CompetencyBundle__r != null && shift.sirenum__CompetencyBundle__c == null) {
                        shift.sirenum__CompetencyBundle__c = shift.sirenum__CompetencyBundle__r.id;
                    }

                    if (shift.Role_OR_Bundle__r != null && shift.Role_OR_Bundle__c == null) {
                        shift.Role_OR_Bundle__c = shift.Role_OR_Bundle__r.id;
                    }                           
                }
                            
                if (!competenciesBundleItemsToInsert.isEmpty()) {
                    insert competenciesBundleItemsToInsert;
                }

                if (!shiftsToUpsert.isEmpty()) {
                    List<Database.UpsertResult> srList = Database.upsert(shiftsToUpsert, false);                

                    for (Integer i = 0; i < shiftsToUpsert.size(); i++) {
                        Database.UpsertResult sr = srList[i];
                        if (!sr.isSuccess()) {
                            ShiftMatchShift shift = shiftData.get(shiftsToUpsert[i].VMS_External_Id__c);
                            shift.recordDatabaseError(sr);                
                        } 
                    }
                }

                List<VMS_Shift_Payload__c> payLoadstoUpsert = new List<VMS_Shift_Payload__c>();
                for (ShiftMatchShift shift : shiftData.values()) {            
                    VMS_Shift_Payload__c payload = shift.createPayLoad();
                    
                    if (payload != null) {
                        payLoadstoUpsert.add(payload);
                    }
                }

                if (!payLoadstoUpsert.isEmpty()) {
                    upsert payLoadstoUpsert;
                }
            }
        }
        
        //handle cancelled  shift - fullsync 
        if (shiftMatchAccount.fullSync) {
            List<sirenum__Shift__c> cancelShifts = getShiftsToCancel(accountId, shiftData.keyset());
            if (cancelShifts.isEmpty()) {
                return;
            }

            Set<Id> shiftIds = new Set<Id>();
            for (sirenum__Shift__c s : cancelShifts) {
                shiftIds.add(s.id);
            }

            Map<id, sirenum__Shift__c> relatedShifts = getShiftsBelongingToDemand(shiftIds);
            List<sirenum__Shift__c> toUpdate = new List<sirenum__Shift__c>();
            Set<Id> cancelShiftIds = new Set<Id>();

            for (sirenum__Shift__c cancelShift : cancelShifts) {
                if (relatedShifts.get(cancelShift.id) != null) {
                    continue;
                }

                cancelShiftIds.add(cancelShift.id);
                toUpdate.add(new sirenum__Shift__c(
                    id = cancelShift.id,
                    sirenum__Cancelled__c = true,
                    sirenum__CancellationReason__c = 'VMS Cancellation'));                
            }
            

            List<sirenum__Shift_Invitation__c> updateJobOffers = new List<sirenum__Shift_Invitation__c>();

            if (!toUpdate.isEmpty()) {                
                for (sirenum__Shift_Invitation__c si : [
                    select id, sirenum__Status__c
                    from sirenum__Shift_Invitation__c
                    where sirenum__Shift__c in :cancelShiftIds
                    and sirenum__Status__c = 'Broadcasting'
                ]) {
                    si.sirenum__Status__c = 'Stale';
                    updateJobOffers.add(si);     
                }

                update toUpdate;
            }       
            
            if (!updateJobOffers.isEmpty()) {
                update updateJobOffers;
            }
        }
    }

    private Map<Id, Job_Type_Rank__c>  getJobTypeRanks(Id accountid) {
        Map<Id, Job_Type_Rank__c> jobTypeRankMap = new Map<Id, Job_Type_Rank__c>();

        for (Job_Type_Rank__c j : [
                select id, Rank__c, Job_Type__c
                from Job_Type_Rank__c
                where Account__c = :accountid
                and Rank__c != null
                ]) {
            jobTypeRankMap.put(j.Job_Type__c, j);
        }

        return jobTypeRankMap;
    }

    private Map<Id, List<Shiftmatch_Skill__c>>  getJobTypeSkills(Id accountid, Set<Id> jobTypeIds) {
        Map<Id, List<Shiftmatch_Skill__c>> jobTypeSkills = new Map<Id, List<Shiftmatch_Skill__c>>();

        for (Shiftmatch_Skill_Job_Type__c j : [
                select Shiftmatch_Skill__r.id, Shiftmatch_Skill__r.name, Shiftmatch_Skill__r.Competency__c, Shiftmatch_Skill__r.Status__c, Job_Type__c
                from Shiftmatch_Skill_Job_Type__c
                where Shiftmatch_Skill__r.Account__c = :accountid
                and Job_Type__c in :jobTypeIds                
                ]) {
            if (jobTypeSkills.containsKey(j.Job_Type__c)) {
                jobTypeSkills.get(j.Job_Type__c).add(j.Shiftmatch_Skill__r);
            } else {
                jobTypeSkills.put(j.Job_Type__c, new List<Shiftmatch_Skill__c> {j.Shiftmatch_Skill__r});
            }            
        }

        return jobTypeSkills;
    }

    private Map<String, Shiftmatch_Grading__c>  getGradingData(Id accountid, Set<String> gradings) {
        Map<String, Shiftmatch_Grading__c> gradingMap = new Map<String, Shiftmatch_Grading__c>();

        for (Shiftmatch_Grading__c g : [
                select id, name, Award_Classification__c, Job_Type__c, (select Award_Level__c, Award_Level__r.Rank__c from ShiftMatch_Grading_Award_Levels__r)
                from Shiftmatch_Grading__c
                where Account__c = :accountid
                and name in :gradings
                ]) {
            gradingMap.put(g.name, g);
        }

        return gradingMap;
    }

    private Map<String, Shiftmatch_Skill__c>  getSkillData(Id accountid, Set<String> skills) {
        Map<String, Shiftmatch_Skill__c> skillMap = new Map<String, Shiftmatch_Skill__c>();

        for (Shiftmatch_Skill__c s : [
                select id, name, Competency__c, Status__c, Ignore_Skill__c,
                          (select Competency__c from ShiftMatch_Additional_Competencies__r),
                          (select Shiftmatch_Location__c, Shiftmatch_Location__r.name, Replacement_Skill__r.id, Replacement_Skill__r.name, Replacement_Skill__r.Competency__c, Replacement_Skill__r.Status__c from Replacement_Skills_By_Location__r)
                from Shiftmatch_Skill__c
                where Account__c = :accountid
                and name in :skills
                ]) {
            skillMap.put(s.name, s);
        }

        return skillMap;
    }

    private Map<String, Shiftmatch_Location__c>  getLocationData(Id accountid, Set<String> locations) {
        Map<String, Shiftmatch_Location__c> locationMap = new Map<String, Shiftmatch_Location__c>();

        for (Shiftmatch_Location__c l : [
                select id, name, Child_Account__c, Site__c, Location__c
                from Shiftmatch_Location__c
                where Account__c = :accountid
                and name in :locations
                ]) {
            locationMap.put(l.name, l);
        }

        return locationMap;
    }

    @testvisible
    private Map<String, List<sirenum__Team__c>>  getJobRoleData(Set<Id> accountids, Set<id> awardClassificationIds) {
        Map<String, List<sirenum__Team__c>> jobRoleMap = new Map<String, List<sirenum__Team__c>>();

        for (sirenum__Team__c j : [
                select id, sirenum__Account__r.sirenum__Client__c, sirenum__Job_Type__c, default_job_role__c                       
                from sirenum__Team__c
                where sirenum__Job_Type__c in :awardClassificationIds
                and sirenum__Account__r.sirenum__Client__c in :accountIds
                ]) {
            List<sirenum__Team__c> jobRoles = jobRoleMap.get(j.sirenum__Account__r.sirenum__Client__c + '_' + j.sirenum__Job_Type__c);
            if (jobRoles != null) {
                jobRoles.add(j);
            } else {
                jobRoleMap.put(j.sirenum__Account__r.sirenum__Client__c + '_' + j.sirenum__Job_Type__c, new List<sirenum__Team__c> {j});
            }
        }

        return jobRoleMap;
    }

    private Map<Id, id> getMultiJobRoles(Set<Id> accountids) {
        Map<Id, id> jobRoleMap = new Map<Id, id>();

        for (sirenum__Team__c j : [
                select id, sirenum__Account__r.sirenum__Client__c
                from sirenum__Team__c
                where Name = 'Multi'
                and sirenum__Account__r.sirenum__Client__c in :accountIds
                ]) {
            
            jobRoleMap.put(j.sirenum__Account__r.sirenum__Client__c, j.id);
        }

        return jobRoleMap;
    }    

    
    private Map<Id, List<sirenum__CompetencyBundleItem__c>> getCompetencyBundleTemplates(Set<Id> competencyIds) {
        Map<Id, List<sirenum__CompetencyBundleItem__c>> templateCompetencies = new Map<Id, List<sirenum__CompetencyBundleItem__c>>();

        Set<id> competencies = new Set<id>(); 
        for (AggregateResult ar : [
            SELECT sirenum__CompetencyBundle__c
            FROM sirenum__CompetencyBundleItem__c 
            where sirenum__CompetencyBundle__r.Is_Template__c = true 
            and sirenum__CompetencyBundle__r.Template_Status__c  = 'Active'
            and sirenum__Competency__c in :competencyIds
            group by sirenum__CompetencyBundle__c]) {

            competencies.add((Id) ar.get('sirenum__CompetencyBundle__c'));
        }
        
        if (competencies.size() == 0) {
            return templateCompetencies;
        }
        
        for (sirenum__CompetencyBundleItem__c c : [
            SELECT Id, sirenum__CompetencyBundle__c, sirenum__CompetencyBundle__r.Is_Role_Bundle__c, sirenum__Competency__c
            FROM sirenum__CompetencyBundleItem__c 
            where sirenum__CompetencyBundle__c = :competencies]) {
            List<sirenum__CompetencyBundleItem__c> items = templateCompetencies.get(c.sirenum__CompetencyBundle__c);
            if (items == null) {
               templateCompetencies.put(c.sirenum__CompetencyBundle__c, new List<sirenum__CompetencyBundleItem__c> {c});
            } else {
               items.add(c);
            }            
        }

        return templateCompetencies;
    }

    private Map<Id, Set<Id>>  getCompetencyData(Set<Id> jobTypeIds, Set<Id> jobRoleIds) {        
        Map<Id, Set<Id>> competencyMap = new Map<Id, Set<Id>>();

        if (jobTypeIds.isEmpty() && jobRoleIds.isEmpty()) {
            return competencyMap;
        }

        String sql = 'select id, sirenum__TicketType__c, sirenum__Team__c, sirenum__Job_Type__c from sirenum__Sirenum_Condition_Membership__c where id = null ';
        if (!jobTypeIds.isEmpty()) {
            sql += ' or sirenum__Job_Type__c in :jobTypeIds';
        }
        if (!jobRoleIds.isEmpty()) {
            sql += ' or sirenum__Team__c in :jobRoleIds';
        }        
        

        for (sirenum__Sirenum_Condition_Membership__c c : Database.query(sql)) {
            if (c.sirenum__Team__c != null) {
                Set<Id> jobRoleSet = competencyMap.get(c.sirenum__Team__c);
                if (jobRoleSet == null) {
                    competencyMap.put(c.sirenum__Team__c, new Set<Id> {c.sirenum__TicketType__c});
                } else {
                    jobRoleSet.add(c.sirenum__TicketType__c);   
                }
            }


            if (c.sirenum__Job_Type__c != null) {
                Set<Id> jobTypeSet = competencyMap.get(c.sirenum__Job_Type__c);
                if (jobTypeSet == null) {                    
                    competencyMap.put(c.sirenum__Job_Type__c, new Set<Id> {c.sirenum__TicketType__c});
                } else {
                    jobTypeSet.add(c.sirenum__TicketType__c);
                }
            }
        }
        
        return competencyMap;
    }
    
    private Map<String, VMS_Shift_Payload__c>  getExistingPayloadInfo(Set<String> externalIds) {
        Map<String, VMS_Shift_Payload__c> payloadMap = new Map<String, VMS_Shift_Payload__c>();

        for (VMS_Shift_Payload__c p : [
                select id, External_Shift_ID__c, Body__c, Status__c, Shift__c, VMS_Account__c
                from VMS_Shift_Payload__c
                where VMS_Source__c = :SHIFTMATCH_VMS_SOURCE
                and External_Shift_ID__c in :externalIds
                ]) {
            payloadMap.put(p.External_Shift_ID__c, p);
        }

        return payloadMap;
    }
    
    @testVisible
    private List<VMS_Shift_Payload__c>  getPayloadsById(List<Id> payloadIds) {
        return  [
                select id, External_Shift_ID__c, Body__c, Status__c, Shift__r.id, Shift__r.sirenum__Cancelled__c, VMS_Account__c
                from VMS_Shift_Payload__c
                where VMS_Source__c = :SHIFTMATCH_VMS_SOURCE
                and id in :payloadIds
        ];            
    }

    @testvisible
    private Map<String, sirenum__Shift__c>  getExistingShifts(Set<String> externalIds) {
        Map<String, sirenum__Shift__c> shiftMap = new Map<String, sirenum__Shift__c>();

        for (sirenum__Shift__c s : [
                select id, VMS_External_Id__c
                from sirenum__Shift__c
                where VMS_Source__c = :SHIFTMATCH_VMS_SOURCE
                and VMS_External_Id__c in :externalIds
                and sirenum__Contact__c = null
                ]) {
            shiftMap.put(s.VMS_External_Id__c, s);
        }

        return shiftMap;
    }

    private List<sirenum__Shift__c>  getShiftsToCancel(Id accountId, Set<String> externalIds) {
        String externalLike = String.valueOf(accountId) + '_%';        
        DateTime currentDate = DateTime.now();

        Set<String> enrichedExternalIds = externalIds;
        if (enrichedExternalIds == null || enrichedExternalIds.size() == 0) {
            enrichedExternalIds = new Set<String> {''};
        }

        return  [
                select id, VMS_External_Id__c, sirenum__Cancelled__c
                from sirenum__Shift__c
                where VMS_Source__c = :SHIFTMATCH_VMS_SOURCE
                and VMS_External_Id__c not in :enrichedExternalIds
                and VMS_External_Id__c like :externalLike
                and sirenum__Contact__c = null
                and sirenum__Scheduled_Start_Time__c > :currentDate
                and sirenum__Cancelled__c = false
                and Schedule_Display_Status__c = 'Waiting'
                ];
    }


    @Testvisible
    private Map<id, sirenum__Shift__c>  getShiftsBelongingToDemand(Set<Id> shiftIds) {
        Map<id, sirenum__Shift__c> shiftMap = new Map<id, sirenum__Shift__c>();

        for (sirenum__Shift__c s: 
                [
                    select id, sirenum__ShiftDemand__c
                    from sirenum__Shift__c
                    where sirenum__ShiftDemand__c in :shiftIds
                    and sirenum__Cancelled__c = false
                    and sirenum__Contact__c != null
                ]) {
            shiftMap.put(s.sirenum__ShiftDemand__c, s);
        }
        return shiftMap;
    }

    public void reprocessFilledShifts(List<Id> filledShiftIds) {
        List<VMS_Filled_Shift__c> filledShifts = [
            select id, Shift__c, Status__c, VMS_Account__c, VMS_Source__c from VMS_Filled_Shift__c
            where id in :filledShiftIds
            and Status__c = 'Error'
        ];

        if (filledShifts.isEmpty()) {
            return;
        }

        System.enqueueJob(new ShiftMatchFilledShiftsQueue(filledShifts));        
    }

    public void handlePublishedShiftsTrigger() {
        if (setting.ShiftMatch_Disable_Fill_Flow__c) {
            return;
        }
        
        Map<id, sirenum__Shift__c> shiftMap = (Map<id, sirenum__Shift__c>) Trigger.newMap;
        Map<id, sirenum__Shift__c> oldMap = (Map<id, sirenum__Shift__c>) Trigger.oldMap;

        List<sirenum__Shift__c> toProcess = new List<sirenum__Shift__c>();
        Set<id> toProcessIds = new Set<id>();
        for (sirenum__Shift__c s : shiftMap.values()) {
            if (s.VMS_Source__c != SHIFTMATCH_VMS_SOURCE || s.VMS_Send_Status__c != 'Ready To Send'
                || s.VMS_External_Id__c == null || s.sirenum__Contact__c == null || oldMap.get(s.id).VMS_Send_Status__c == 'Ready To Send') {
                continue;
            }

            toProcess.add(s);
            toProcessIds.add(s.id);                    
        }

        
        Map<id, VMS_Filled_Shift__c> filledShiftMap =  getFilledShifts(toProcessIds);
        List<VMS_Filled_Shift__c> filledShifts = new List<VMS_Filled_Shift__c>();

        for (sirenum__Shift__c s : toProcess) {
            if (filledShiftMap.get(s.id) != null) {
                continue;
            }

            filledShifts.add(
                new VMS_Filled_Shift__c(
                    Shift__c = s.id,
                    Status__c = 'New',
                    VMS_Account__c = s.VMS_External_Id__c.split('_')[0],
                    VMS_Source__c = SHIFTMATCH_VMS_SOURCE
                )
            );            
        }

        if (filledShifts.isEmpty()) {
            return;
        }

        insert filledShifts;

        System.enqueueJob(new ShiftMatchFilledShiftsQueue(filledShifts));
    }

    private Map<id, VMS_Filled_Shift__c> getFilledShifts(Set<id> shiftIds) {
        Map<id, VMS_Filled_Shift__c> filledShiftMap = new Map<id, VMS_Filled_Shift__c>();

        for (VMS_Filled_Shift__c fs : [select Shift__c from VMS_Filled_Shift__c
                                       where Shift__c = :shiftIds
                                       and VMS_Source__c = :SHIFTMATCH_VMS_SOURCE]) {
                filledShiftMap.put(fs.Shift__c, fs);
        }

        return filledShiftMap;
    }
        

    //returns YES / NO / FULL
    @testvisible
    private String processAccount(Shiftmatch_Setting__mdt setting, Account account) {
        Datetime now = System.now();
        Datetime startTime = DateTime.newInstanceGmt(now.dateGmt(), (setting.Poll_Start_Time_UTC__c != null) ? ShiftMatchUtility.convertShiftTimeToTime(setting.Poll_Start_Time_UTC__c) : Time.newInstance(0,0,0,0));
        Datetime endTime = DateTime.newInstanceGmt(now.dateGmt(), (setting.Poll_End_Time_UTC__c != null) ? ShiftMatchUtility.convertShiftTimeToTime(setting.Poll_End_Time_UTC__c) : Time.newInstance(23,59,59,999));

        String returnValue = 'NO';

        

        if ((account.Shiftmatch_Last_Sync_Date__c == null || account.Shiftmatch_Last_Sync_Date__c.addMinutes(Integer.valueOf(setting.Poll_Frequency_Mins__c)) < now) &&
            ((startTime > endtime) && (now >= startTime || now <= endTime) ||
             (startTime <= endtime) && (now >= startTime && now <= endTime))) {
            returnValue = 'YES';
            
            if (account.Shiftmatch_Last_Sync_Date__c == null 
                || account.Shiftmatch_Counter__c == null 
                || Math.mod(Integer.valueOf(account.Shiftmatch_Counter__c) + 1, Integer.valueOf(setting.Full_Sync__c)) == 0) {
                returnValue = 'FULL';
            }
        }

        return returnValue;
    }

    public enum ErrorLevel {WARNING, ERROR, FATAL}    
    public class ShiftMatchShift {
        ShiftMatchWebserviceStub.bridgeShortfall shortfall;
        sirenum__Shift__c shift;
        
        sirenum__CompetencyBundle__c skillCompetencyBundle;
        List<sirenum__CompetencyBundleItem__c> skillCompetencyBundleItems = new List<sirenum__CompetencyBundleItem__c>();
        
        sirenum__CompetencyBundle__c skillOptionalCompetencyBundle;
        List<sirenum__CompetencyBundleItem__c> skillOptionalCompetencyBundleItems = new List<sirenum__CompetencyBundleItem__c>();

        sirenum__CompetencyBundle__c jobTypeCompetencyBundle;
        List<sirenum__CompetencyBundleItem__c> jobTypeCompetencyBundleItems = new List<sirenum__CompetencyBundleItem__c>();

        Boolean optionalSkills = false;

        String status;  

        ErrorLevel severity;
        List<String> errors = new List<String>();

        Id shiftId;
        Id workSiteAccount;
        Id site;
        Id location;

        List<ShiftMatch_Skill__c> skills = new List<ShiftMatch_Skill__c>();
        List<sirenum__Team__c> jobRoles = new List<sirenum__Team__c>();
        Id jobRole; 
        Map<id, Set<id>> jobRoleCompetencies = new Map<id, Set<id>>();
        
        Id accountId;
        ShiftMatchAccount account;

        Id payloadId;

        ShiftMatchGrade gradeMax;
        ShiftMatchGrade gradeMin;    
        Set<Id> gradeJobTypes = new Set<Id>();            
        

        public ShiftMatchShift(ShiftMatchAccount shiftMatchAccount, ShiftMatchWebserviceStub.bridgeShortfall shortfall) {
            this.shortfall = shortfall;
            this.accountId = shiftMatchAccount.account.id;
            this.account = shiftMatchAccount;
            this.status = 'NEW';
        }

        public void recordDatabaseError(Database.UpsertResult results) {
            severity = ErrorLevel.FATAL;
            for(Database.Error err : results.getErrors()) {
                errors.add('[FATAL]: ' + err.getMessage());                    
            }
        }  

        public VMS_Shift_Payload__c createPayLoad() {
            if (status == 'NO CHANGE') {
                return null;
            }

            String errorMessage = null;
            if (errors.size() > 0) {
                for (String error : errors) {
                    errorMessage = (errorMessage == null) ?  error : errorMessage + '\n' + error;
                }
            }
            VMS_Shift_Payload__c payload = new VMS_Shift_Payload__c(
                Body__c = JSON.serializePretty(this.shortfall),
                External_Shift_ID__c = this.accountId + '_' + this.shortfall.pkid,
                Error_Message__c = errorMessage,
                Shift__c = (shift != null) ? shift.id : null,
                VMS_Source__c = SHIFTMATCH_VMS_SOURCE,
                Status__c = (severity == null) ? 'Success': ((severity == ErrorLevel.WARNING) ? 'Warning': 'Error'),
                VMS_Account__c = this.accountId
            );

            if (payloadId != null) {
                payload.id = payloadId;
            }

            return payload;
        }

        public void setPayload(VMS_Shift_Payload__c payload) {
            setPayload(payload, false);            
        }  

        public void setPayload(VMS_Shift_Payload__c payload, Boolean retry) {
            if (payload != null) {
                this.payloadId = payload.id;
                if (!retry && payload.Body__c == JSON.serializePretty(this.shortfall)) {
                    this.status = 'NO CHANGE';
                } else {
                    this.status = 'UPDATED';            
                }
            }
        }        

        public void setShift(sirenum__Shift__c shift) {
            if (shift != null) {
                this.shiftId = shift.id;
            }
        }
        
        public void processShift() {
            if ((status == 'NO CHANGE') || (severity != null && severity != ErrorLevel.WARNING)) {
                return;
            }
            
            
            shift = new sirenum__Shift__c();
            if (shiftId != null) {
                shift.id  = shiftId;                
            }
            shift.sirenum__Scheduled_Local_Start_Date__c = ShiftMatchUtility.convertShiftDateToDate(this.shortfall.day);
            shift.sirenum__Scheduled_Local_Start_Time__c = ShiftMatchUtility.convertShiftTimeToTime(this.shortfall.shiftStart);
            shift.sirenum__Scheduled_Local_End_Time__c = ShiftMatchUtility.convertShiftTimeToTime(this.shortfall.shiftEnd);
            
            shift.VMS_External_Id__c = this.accountId + '_' + this.shortfall.pkid;
            
            shift.sirenum__Site__c = this.site;
            shift.sirenum__Team__c = this.jobRole;
            shift.sirenum__Broadcasts__c = 1;
            shift.VMS_Source__c = SHIFTMATCH_VMS_SOURCE;
            shift.Client_Facility__c = workSiteAccount;
            shift.sirenum__Comments__c = this.shortfall.agencyNotes;
            // shift.Max_Award_Level_Rank__c = gradeMax.rank;
            // shift.Min_Award_Level_Rank__c = gradeMin.rank;            
            shift.Booked_By__c = this.shortfall.pkidKey;
            shift.Shift_Type__c = this.account.shiftTypes.getShiftType(shift.sirenum__Scheduled_Local_Start_Time__c);   
            
            if (!skillCompetencyBundleItems.isEmpty()) {
                shift.sirenum__CompetencyBundle__r = skillCompetencyBundle;
            }

            if (!skillOptionalCompetencyBundleItems.isEmpty()) {
                shift.Skill_Attribute_OR_Bundle__r = skillOptionalCompetencyBundle;                
            }
            
            if (!jobTypeCompetencyBundleItems.isEmpty()) {
                shift.Role_OR_Bundle__r = jobTypeCompetencyBundle;                
            }

            String notes = '';
            if (this.shortfall.gradingMin != null || this.shortfall.gradingMax != null) {                
               notes = this.shortfall.gradingMin + ' - ' + this.shortfall.gradingMax;
            }

            if (notes != '' && this.shortfall.skills != null && this.shortfall.skills.entry.size() > 0) {
                notes += ' / ';
            }

            if (this.shortfall.skills != null && this.shortfall.skills.entry.size() > 0) {
                notes += String.join(this.shortfall.skills.entry, ',');                
            }

            if (notes != '') {
                notes += ' / ';
            }

            notes += this.shortfall.pkidKey;

            if (notes != '' && this.shortfall.agencyNotes != null) {
                notes += '\n';
            }

            if (this.shortfall.agencyNotes != null) {
                notes += this.shortfall.agencyNotes;
            }
            
            if (notes != '') {
                shift.Notes_Internal_Only__c = notes.left(255);
            }
        }
                
        public void mapGradingData(Map<String, Shiftmatch_Grading__c> gradingMap, Map<Id, Job_Type_Rank__c> jobTypeRankMap) {
            this.gradeMax = processGrading(shortfall.gradingMax, gradingMap);

            if (this.gradeMax == null) {
                errors.add('[FATAL]: No map found for Shiftmatch Grade (' + shortfall.gradingMax + ')');
                severity = ErrorLevel.Fatal;
                return;
            }

            if (shortfall.gradingMax != shortfall.gradingMin) { 
                this.gradeMin = processGrading(shortfall.gradingMin, gradingMap);
                if (this.gradeMin == null) {
                    errors.add('[WARNING]: No map found for Shiftmatch Grade (' + shortfall.gradingMin + ')');
                    severity = (severity == null) ? ErrorLevel.Warning : severity;
                    this.gradeMin = new ShiftMatchGrade(this.gradeMax.classification, null);
                }                
                
                if (this.gradeMax.classification != this.gradeMin.classification) {
                    Job_Type_Rank__c jtrMin = jobTypeRankMap.get(this.gradeMin.classification);
                    Job_Type_Rank__c jtrMax = jobTypeRankMap.get(this.gradeMax.classification);

                    if (jtrMax != null && jtrMin != null && jtrMax.rank__c != null && jtrMin.rank__c != null && jtrMax.rank__c > jtrMin.rank__c) {
                        for (Job_Type_Rank__c j : jobTypeRankMap.values()) {
                            if (j.Rank__c != null && j.Rank__c >= jtrMin.rank__c && j.Rank__c <= jtrMax.rank__c) {
                                gradeJobTypes.add(j.Job_Type__c);
                            }
                        }
                    } else {
                        gradeJobTypes.add(this.gradeMin.classification);
                        gradeJobTypes.add(this.gradeMax.classification);
                    }                    
                }
            } else {
                this.gradeMin = this.gradeMax;                
            }  
        }

        public void mapSkillsData(Map<String, Shiftmatch_Skill__c> skillMap, Map<Id, List<Shiftmatch_Skill__c>> jobTypeSkills) {
            if (status == 'NO CHANGE' || (severity != null && severity != ErrorLevel.WARNING)) {
                return;
            }

            if (shortfall.skillPkids == null || shortfall.skillPkids.idCollection == null || shortfall.skillPkids.idCollection.isEmpty()) {
                return;
            }
                        
            if (!gradeJobTypes.isEmpty()) {
                for (Id gradeJobType : gradeJobTypes) {
                    if (jobTypeSkills.containsKey(gradeJobType)) {
                        for (ShiftMatch_Skill__c skill : jobTypeSkills.get(gradeJobType)) {
                            if (skill.Status__c != SKILL_STATUS_IGNORE) {
                                skills.add(skill);
                            }
                        }
                    }
                }
            } else if (gradeMax != null && jobTypeSkills.containsKey(gradeMax.classification)) {
                for (ShiftMatch_Skill__c skill : jobTypeSkills.get(gradeMax.classification)) {
                    if (skill.Status__c != SKILL_STATUS_IGNORE) {
                        skills.add(skill);
                    }
                }                
            }
            
            for (Integer pkid: shortfall.skillPkids.idCollection) {
                Shiftmatch_Skill__c skill =  skillMap.get(String.valueOf(pkid));
                if (skill == null) {
                    errors.add('[FATAL]: No map found for Shiftmatch Skill (' + pkid + ')');
                    severity = ErrorLevel.Fatal;
                    return;
                }

                if (skill.Status__c == SKILL_STATUS_IGNORE) {
                    continue;
                }

                skills.add(skill);
            }                        
        }

        public void mapJobRoleDataFinal(Map<Id, Set<Id>> competencies, Map<id, id> multiJobRoles, 
                                        Map<String, Shiftmatch_Skill__c> skillMap, Map<Id, List<Shiftmatch_Skill__c>> jobTypeSkills) {
            if (status == 'NO CHANGE' || (severity != null && severity != ErrorLevel.WARNING)) {
                return;
            }

            mapSkillsData(skillMap, jobTypeSkills);

            if (status == 'NO CHANGE' || (severity != null && severity != ErrorLevel.WARNING)) {
                return;
            }

            
            if (!jobRoles.isEmpty()) {
                assignJobRole(competencies);
            } else {
                handleMultiRole(competencies, multiJobRoles);  
            }            
        }        
        
        private void handleMultiRole(Map<Id, Set<Id>> competencies, Map<id, id> multiJobRoles) {
            jobRole = multiJobRoles.get(workSiteAccount);
            if (jobRole == null) {
                jobRole = multiJobRoles.get(accountId);
            }

            if (jobRole == null) {
                errors.add('[FATAL]: Cannot find a suitable Multi Job Role.');
                severity = ErrorLevel.Fatal;      
                return;       
            }            

            skillCompetencyBundle = new sirenum__CompetencyBundle__c(
                name = UUID.randomUUID().toString()
            );

            skillOptionalCompetencyBundle = new sirenum__CompetencyBundle__c(
                name = UUID.randomUUID().toString()
            );

            jobTypeCompetencyBundle = new sirenum__CompetencyBundle__c(
                name = UUID.randomUUID().toString(),
                Is_Role_Bundle__c = true
            );

            Map<Id, sirenum__CompetencyBundleItem__c> mandatorySkills = new Map<Id, sirenum__CompetencyBundleItem__c>();
            Map<Id, sirenum__CompetencyBundleItem__c> orSkills = new Map<Id, sirenum__CompetencyBundleItem__c>();
            Map<Id, sirenum__CompetencyBundleItem__c> orRoles = new Map<Id, sirenum__CompetencyBundleItem__c>();

            Boolean hasMandatory = false;
            for (ShiftMatch_Skill__c skill : skills) {
                if (skill.competency__c == null && (skill.Status__c == SKILL_STATUS_MANDATORY || skill.Status__c == SKILL_STATUS_MANDATORY_INDUCTION)) {
                    errors.add('[FATAL]: Skill (' + skill.name + ') not mapped to a competency.');                    
                    severity = ErrorLevel.FATAL;                    
                    break;
                }

                if (skill.Status__c == SKILL_STATUS_MANDATORY || skill.Status__c == SKILL_STATUS_MANDATORY_INDUCTION) {
                    hasMandatory = hasMandatory || skill.Status__c == SKILL_STATUS_MANDATORY;
                    mandatorySkills.put(skill.competency__c, new sirenum__CompetencyBundleItem__c(
                        sirenum__CompetencyBundle__r = skillCompetencyBundle,
                        sirenum__Severity__c = 'Fatal',
                        sirenum__Competency__c = skill.competency__c                        
                    ));                    
                }
            }

            if (!hasMandatory) {           
                //check replacement skills
                for (ShiftMatch_Skill__c skill : skills) {
                    List<ShiftMatch_Skill__c> replacementSkills = getReplacementSkill(skill);
                    if (replacementSkills.isEmpty()) {
                        continue;
                    }

                    for (ShiftMatch_Skill__c replacementSkill : replacementSkills) {
                        mandatorySkills.put(replacementSkill.competency__c, new sirenum__CompetencyBundleItem__c(
                            sirenum__CompetencyBundle__r = skillCompetencyBundle,
                            sirenum__Severity__c = 'Fatal',
                            sirenum__Competency__c = replacementSkill.competency__c                        
                        ));                         
                    }
                    hasMandatory = true;

                    break;
                }
            }

            if (!hasMandatory) {           
                for (ShiftMatch_Skill__c skill : skills) {
                    if (skill.competency__c != null && skill.Status__c == SKILL_STATUS_OPTIONAL) {
                        optionalSkills = true;
                        orSkills.put(skill.competency__c, new sirenum__CompetencyBundleItem__c(
                            sirenum__CompetencyBundle__r = skillOptionalCompetencyBundle,
                            sirenum__Severity__c = 'Fatal',
                            sirenum__Competency__c = skill.competency__c                        
                        )); 

                    //     if (skill.ShiftMatch_Additional_Competencies__r != null && !skill.ShiftMatch_Additional_Competencies__r.isEmpty()) {
                    //         for (ShiftMatch_Additional_Competency__c ac : skill.ShiftMatch_Additional_Competencies__r) {
                    //             orSkills.put(ac.competency__c, new sirenum__CompetencyBundleItem__c(
                    //                 sirenum__CompetencyBundle__r = skillOptionalCompetencyBundle,
                    //                 sirenum__Severity__c = 'Fatal',
                    //                 sirenum__Competency__c = ac.competency__c                        
                    //             )); 
                            
                    //         }
                    //     }
                    }
                }
            }

            if (severity == ErrorLevel.FATAL) {
                return;
            } 
            
            Set<id> jobRoleCompetencies = new Set<Id>();
            for (Id jobType : gradeJobTypes) {
                if (competencies.containsKey(jobType)) {
                    jobRoleCompetencies.addAll(competencies.get(jobType));
                }
            }
            
            if (jobRoleCompetencies.isEmpty()) {
                errors.add('[FATAL]: No competencies attached to the Job Types..');                    
                severity = ErrorLevel.FATAL;                
            }

            for (Id competency : jobRoleCompetencies) {
                orRoles.put(competency, new sirenum__CompetencyBundleItem__c(
                        sirenum__CompetencyBundle__r = jobTypeCompetencyBundle,
                        sirenum__Severity__c = 'Fatal',
                        sirenum__Competency__c = competency
                ));                
            }

            skillCompetencyBundleItems = mandatorySkills.values();
            skillOptionalCompetencyBundleItems = orSkills.values();
            jobTypeCompetencyBundleItems = orRoles.values();
        }

        public void assignCompetencyTemplate(Map<id, List<sirenum__CompetencyBundleItem__c>> templateComptencies) {            
            for (List<sirenum__CompetencyBundleItem__c> c : templateComptencies.values()) {                
                Set<Id> competencies = new Set<Id>();
                for (sirenum__CompetencyBundleItem__c ti : c) {
                    competencies.add(ti.sirenum__Competency__c);
                }
                
                
                if (skillCompetencyBundleItems.size() == c.size() && shift.sirenum__CompetencyBundle__c == null) {
                    Boolean found = true;
                    for (sirenum__CompetencyBundleItem__c i : skillCompetencyBundleItems) {                        
                        if (!competencies.contains(i.sirenum__Competency__c)) {
                            found = false;
                            break;
                        }                        
                    }

                    if (found) {
                        shift.sirenum__CompetencyBundle__c = c[0].sirenum__CompetencyBundle__c;                                                    
                        shift.sirenum__CompetencyBundle__r = null;
                        continue;
                    }
                }

                if (skillOptionalCompetencyBundleItems.size() == c.size() && shift.Skill_Attribute_OR_Bundle__c == null) {
                    Boolean found = true;
                    for (sirenum__CompetencyBundleItem__c i : skillOptionalCompetencyBundleItems) {
                        if (!competencies.contains(i.sirenum__Competency__c)) {
                            found = false;
                            break;
                        }                        
                    }

                    if (found) {
                        shift.Skill_Attribute_OR_Bundle__c = c[0].sirenum__CompetencyBundle__c;  
                        shift.Skill_Attribute_OR_Bundle__r = null;                      
                        continue;
                    }
                }

                if (jobTypeCompetencyBundleItems.size() == c.size() && shift.Role_OR_Bundle__c == null) {
                    Boolean found = true;
                    for (sirenum__CompetencyBundleItem__c i : jobTypeCompetencyBundleItems) {
                        if (!competencies.contains(i.sirenum__Competency__c)) {
                            found = false;
                            break;
                        }                        
                    }
                    
                    if (found) {
                        shift.Role_OR_Bundle__c = c[0].sirenum__CompetencyBundle__c;                        
                        shift.Role_OR_Bundle__r = null;                                                
                    }
                }                  
            }              
        }

        private void assignJobRole(Map<Id, Set<Id>> competencies) {            

            for (sirenum__Team__c j : jobRoles) {
                Set<id> jobCompetencies = new Set<Id>();

                if (j.sirenum__Job_Type__c != null && competencies.containsKey(j.sirenum__Job_Type__c)) {
                    jobCompetencies.addAll(competencies.get(j.sirenum__Job_Type__c));
                }                 
                
                if (competencies.containsKey(j.id)) {
                    jobCompetencies.addAll(competencies.get(j.id));
                }                

                jobRoleCompetencies.put(j.id, jobCompetencies);                
            }

            if (skills.isEmpty()) {
                if (jobRoles.size() == 1) {
                    jobRole = jobRoles[0].id;
                    return;
                }

                for (sirenum__Team__c j : jobRoles) {
                    if (j.default_job_role__c) {
                        jobRole = j.id;
                        break;
                    }
                }                
                
                if (jobRole == null) {
                    errors.add('[FATAL]: Multiple Job Roles found matching requirement and no default Job Role defined.');
                    severity = ErrorLevel.Fatal;                    
                }                

                return;
            }

            Boolean skillMissing = false;            
            Boolean hasMandatory = false;            

            for (ShiftMatch_Skill__c skill : skills) {
                if (skill.competency__c == null && (skill.Status__c == SKILL_STATUS_MANDATORY || skill.Status__c == SKILL_STATUS_MANDATORY_INDUCTION)) {
                    errors.add('[FATAL]: Skill (' + skill.name + ') not mapped to a competency.');                    
                    severity = ErrorLevel.FATAL;
                    skillMissing = true;
                    break;
                }
            
                if (skill.Status__c != SKILL_STATUS_MANDATORY && skill.Status__c != SKILL_STATUS_MANDATORY_INDUCTION) {
                    continue;
                }

                hasMandatory = hasMandatory || skill.Status__c == SKILL_STATUS_MANDATORY;

                for (Integer i = (jobRoles.size()-1) ; i>= 0 ; i--){            
                    sirenum__Team__c jobRole = jobRoles[i];
                    Set<Id> c = jobRoleCompetencies.get(jobRole.id);                    

                    if (c == null) {
                        jobRoles.remove(i);
                        continue;
                    }

                    if (!c.contains(skill.competency__c)) {
                        Boolean found = false;
                        for (ShiftMatch_Additional_Competency__c ac : skill.ShiftMatch_Additional_Competencies__r) {
                            if (c.contains(ac.Competency__c)) {
                                found = true;
                                continue;
                            }
                        }

                        if (!found) {
                            jobRoles.remove(i);                            
                        }
                    }                    
                }                 
            }                                            

            if (jobRoles.isEmpty()) {
                errors.add('[FATAL]: No job roles found matching required skills.');
                severity = ErrorLevel.Fatal;
                return;
            }

            if (skillMissing) {
                return;
            }

            //Replacement Skill logic            
            if (!hasMandatory) {                
                for (Integer j = (skills.size()-1) ; j>= 0 ; j--){
                    List<ShiftMatch_Skill__c> replacementSkills = getReplacementSkill(skills[j]);
                    if (replacementSkills.isEmpty()) {
                        continue;
                    }
                    
                    //remove optional skill
                    skills.remove(j);

                    for (ShiftMatch_Skill__c skill : replacementSkills) {
                        for (Integer i = (jobRoles.size()-1) ; i>= 0 ; i--){            
                            sirenum__Team__c jobRole = jobRoles[i];
                            Set<Id> c = jobRoleCompetencies.get(jobRole.id);                    

                            if (c == null) {
                                jobRoles.remove(i);
                                continue;
                            }

                            if (!c.contains(skill.competency__c)) {
                                Boolean found = false;
                                for (ShiftMatch_Additional_Competency__c ac : skill.ShiftMatch_Additional_Competencies__r) {
                                    if (c.contains(ac.Competency__c)) {
                                        found = true;
                                        continue;
                                    }
                                }

                                if (!found) {
                                    jobRoles.remove(i);                            
                                }
                            }                    
                        }
                    }                 

                    if (!replacementSkills.isEmpty()) {
                        break;
                    }
                }
            }

            if (jobRoles.isEmpty()) {
                errors.add('[FATAL]: No job roles found matching required skills.');
                severity = ErrorLevel.Fatal;
                return;
            }            
            
            Integer maxCount = 0;
            for (sirenum__Team__c j : jobRoles) {                                        
                Set<Id> c = jobRoleCompetencies.get(j.id);                

                Integer opCount = 0;
                for (ShiftMatch_Skill__c skill : skills) {
                    if (skill.Status__c != SKILL_STATUS_OPTIONAL) {
                        continue;
                    }

                    if (c.contains(skill.competency__c)) {
                        opCount++;
                        continue;
                    }

                    for (ShiftMatch_Additional_Competency__c ac : skill.ShiftMatch_Additional_Competencies__r) {
                        if (c.contains(ac.Competency__c)) {
                            opCount++;
                            continue;
                        }
                    }
                }

                if (opCount > maxCount || (j.default_job_role__c && opCount == maxCount) || jobRole == null) {
                    jobRole = j.id;
                }
            }            
        }

        public void mapJobRoleData(Map<String, List<sirenum__Team__c>> jobRoleMap) {
            if (status == 'NO CHANGE' || (severity != null && severity != ErrorLevel.WARNING)) {
                return;
            }
            
            jobRoles = jobRoleMap.get(workSiteAccount + '_' + gradeMax.classification);
            if (jobRoles == null) {
                jobRoles = jobRoleMap.get(accountId + '_' + gradeMax.classification);
            }

            if (jobRoles == null) {
                errors.add('[FATAL]: Cannot find an appropriate Job Role.');
                severity = ErrorLevel.Fatal;             
            }
            else {
                jobRoles = jobRoles.clone();
            }
        }

                //return true if valid mapping exists
        private List<Shiftmatch_Skill__c> getReplacementSkill(Shiftmatch_Skill__c skill) {
            List<Shiftmatch_Skill__c> replacementSkills = new List<Shiftmatch_Skill__c>();

            if (skill.Status__c != SKILL_STATUS_OPTIONAL || skill.Replacement_Skills_By_Location__r == null || skill.Replacement_Skills_By_Location__r.isEmpty()) {
                return replacementSkills;
            }
            
            for (Replacement_Skill__c rs : skill.Replacement_Skills_By_Location__r) {
                if (rs.Replacement_Skill__r.Status__c != SKILL_STATUS_MANDATORY) {
                    continue;
                }
                
                if (rs.Shiftmatch_Location__r.name == String.valueOf(shortfall.locationPkid0)
                    || rs.Shiftmatch_Location__r.name == String.valueOf(shortfall.locationPkid1)
                    || rs.Shiftmatch_Location__r.name == String.valueOf(shortfall.locationPkid2)
                    || rs.Shiftmatch_Location__r.name == String.valueOf(shortfall.locationPkid3)
                    || rs.Shiftmatch_Location__r.name == String.valueOf(shortfall.locationPkid4)) {
                    replacementSkills.add(rs.Replacement_Skill__r);                    
                }
            }

            return replacementSkills;            
        }

        public void mapLocationData(Map<String, Shiftmatch_Location__c> locationMap) {
            Boolean mapFound = false;
            if (shortfall.locationPkid4 != null && shortfall.locationPkid4 != 0) {
                mapFound = processLocation(shortfall.locationPkid4, locationMap);
                if (!mapFound) {
                    errors.add('[WARNING]: No map found for Shiftmatch location (' + shortfall.locationPkid4 + ')');
                    severity = (severity == null) ? ErrorLevel.Warning : severity;
                }
            }

            if (!mapFound && shortfall.locationPkid3 != null && shortfall.locationPkid3 != 0) {
                mapFound = processLocation(shortfall.locationPkid3, locationMap);
                if (!mapFound ) {
                    errors.add('[WARNING]: No map found for location (' + shortfall.locationPkid3 + ')');
                    severity = (severity == null) ? ErrorLevel.Warning : severity;
                }
            }

            if (!mapFound &&  shortfall.locationPkid2 != null && shortfall.locationPkid2 != 0) {
                mapFound = processLocation(shortfall.locationPkid2, locationMap);
                if (!mapFound) {
                    errors.add('[WARNING]: No map found for location (' + shortfall.locationPkid2 + ')');
                    severity = (severity == null) ? ErrorLevel.Warning : severity;
                }
            }

            if (!mapFound && shortfall.locationPkid1 != null && shortfall.locationPkid1 != 0) {
                mapFound = processLocation(shortfall.locationPkid1, locationMap);
                if (!mapFound) {
                    errors.add('[WARNING]: No map found for location (' + shortfall.locationPkid1 + ')');
                    severity = (severity == null) ? ErrorLevel.Warning : severity;
                }
            }

            if (!mapFound && shortfall.locationPkid0 != null && shortfall.locationPkid0 != 0) {
                mapFound = processLocation(shortfall.locationPkid0, locationMap);
                if (!mapFound) {
                    errors.add('[FATAL]: No map found for location (' + shortfall.locationPkid0 + ')');
                    severity = ErrorLevel.Fatal;
                }
            }
        }

        //return true if valid mapping exists
        private ShiftMatchGrade processGrading(String shiftmatchPKID, Map<String, Shiftmatch_Grading__c> gradingMap) {
            Shiftmatch_Grading__c grading = gradingMap.get(shiftmatchPKID);
            if (grading == null) {
                return null;
            }

            
            if (grading.Job_Type__c == null) {
                return null;
            }
            
            Integer rank = null;            
            // for (ShiftMatch_Grading_Award_Level__c gl : grading.ShiftMatch_Grading_Award_Levels__r) {
            //     if (rank == null || (rank < gl.Award_Level__r.Rank__c && maxGrade) || (rank > gl.Award_Level__r.Rank__c && !maxGrade)) {
            //         rank = Integer.valueOf(gl.Award_Level__r.Rank__c);
            //     }
            // }

            return new ShiftMatchGrade(grading.Job_Type__c, rank);
        }

        //return true if valid mapping exists
        private boolean processLocation(Integer shiftmatchPKID, Map<String, Shiftmatch_Location__c> locationMap) {
            Shiftmatch_Location__c location = locationMap.get(String.valueOf(shiftmatchPKID));
            if (location == null) {
                return false;
            }

            
            if (location.Child_Account__c == null) {
                return false;
            }
            
            this.workSiteAccount = location.Child_Account__c;
            this.site = location.Site__c;
            this.location = location.Location__c;

            return true;
        }

    }

    public class ShiftMatchGrade  {
        public Id classification;
        public integer rank;

        public ShiftMatchGrade(Id classification, integer rank) {
            this.classification = classification;
            this.rank = rank;
        }
    }
    public class ShiftMatchAccount  {
        public Account account;
        public Shiftmatch_Setting__mdt setting;
        public Boolean fullSync;
        @testvisible
        public ShiftTypes shiftTypes;

        public ShiftMatchAccount setAccount(Account account) {
            this.account = account;
            return this;
        }

        public ShiftMatchAccount setSetting(Shiftmatch_Setting__mdt setting) {
            this.setting = setting;
            this.shiftTypes = new ShiftTypes(this.setting.Shift_Type_Map__c);
            return this;
        }

        public ShiftMatchAccount setFullSync(boolean fullSync) {
            this.fullSync = fullSync;
            return this;
        }
    }
 
    @testvisible
    public class ShiftTypes {
		List<ShiftType> shiftTypes;		

        @testvisible
        private ShiftTypes(List<ShiftType> shiftTypes) {
            this.shiftTypes = shiftTypes;
        }

        public ShiftTypes(String shiftTypes) {
            if (shiftTypes == null) {
                this.shiftTypes = defaultShiftTypes();
            }

            try {
                this.shiftTypes = (List<ShiftType>)JSON.deserializeStrict(shiftTypes, List<SIM_Option>.class);
            } catch (Exception e) {
                this.shiftTypes = defaultShiftTypes();
            }
        }

        public List<ShiftType> defaultShiftTypes () {
            return new List<ShiftType> {
                new ShiftType('AM', Time.newInstance(6, 0, 0, 0), Time.newInstance(12, 0, 0, 0)), 
                new ShiftType('PM', Time.newInstance(12, 0, 0, 0), Time.newInstance(18, 0, 0, 0)), 
                new ShiftType('ND', Time.newInstance(18, 0, 0, 0), Time.newInstance(6, 0, 0, 0))
            };
        }      
        
        public String getShiftType(Time startTime) {
            for (ShiftType shiftType : shiftTypes) {
                if (startTime >= shiftType.startTime && (startTime < shiftType.endTime || shiftType.startTime > shiftType.endTime)) {
                    return shiftType.type;
                }
            }

            return null;
        }
    }

    public class ShiftType {
        public String type;
        public Time startTime;
        public Time endTime;

        public ShiftType(String type, Time startTime, Time endTime) {
            this.startTime = startTime;
            this.endTime = endTime;
            this.type = type;
        }
    }

    public class ShiftMatchLocation {
		public String abbreviation;
		public String parentPkid;
		public String description;
		public Integer level;
		public String pkid;
        public Shiftmatch_Location__c locationRecord;

        @testvisible
        ShiftMatchLocation(ShiftMatchLocation parentLocation, ShiftMatchWebserviceStub.bridgeLocation bridgeLocation) {
            this.abbreviation = bridgeLocation.abbreviation;
            this.parentPkid = (parentLocation != null)? parentLocation.pkid : null;
            this.description = bridgeLocation.description;
            this.level = bridgeLocation.level;
            this.pkid = String.valueOf(bridgeLocation.pkid);
        }
    }

    public class ShiftMatchException extends Exception {
    }

}