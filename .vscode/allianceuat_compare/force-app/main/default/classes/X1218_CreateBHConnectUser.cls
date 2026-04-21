public without sharing class X1218_CreateBHConnectUser {

    Public static void processSubStatus(List<TR1__Sub_Status__c> triggerNew) {
    
        // Loop Sub Status, only Create if Sub Status = BH Connect
        List<TR1__Sub_Status__c> subStatusList = new List<TR1__Sub_Status__c>(); 
        for(TR1__Sub_Status__c ss : triggerNew) {
            if(ss.TR1__Value__c == 'BH_Connect' && ss.TR1__ATS_Stage__c == 'Contracting' && ss.TR1__Is_Active__c == true) {
                subStatusList.add(ss);
            }
        }
        if(subStatusList.size() > 0) {
            system.debug('SPC - subStatusList: ' + subStatusList);
            processUser(subStatusList);
        }
    }

    Public Static void processUser(List<TR1__Sub_Status__c> subStatusList) {
        
        // Get Profile Details
        List<Profile> profileList = new List<Profile>([
            SELECT Id, Name
            FROM Profile
            WHERE Name = 'Alliance Connect User'
        ]);
        system.debug('Profile List: ' + profileList);

        // Get Contact Id from Sub Status
        List<TR1__Sub_Status__c> subStatusContactListInfo = new List<TR1__Sub_Status__c>([
            Select Id, TR1__Application__r.TR1__Applicant__r.Id, TR1__Application__r.TR1__Applicant__r.FirstName,
            TR1__Application__r.TR1__Applicant__r.LastName, TR1__Application__r.TR1__Applicant__r.Email
            FROM TR1__Sub_Status__c
            WHERE Id IN :subStatusList AND
            TR1__Application__r.TR1__Applicant__r.Id != null
        ]);
        system.debug('subStatusContactListInfo: ' + subStatusContactListInfo);
        
        // create a map of subStatusContactListInfo
        Map<Id, TR1__Sub_Status__c> subStatusContactMapInfo = new Map<Id, TR1__Sub_Status__c>();
        for(TR1__Sub_Status__c ss : subStatusContactListInfo) {
            subStatusContactMapInfo.put(ss.Id, ss);
        }
        System.debug('subStatusContactMapInfo: ' + subStatusContactMapInfo);

        // Create a Map from subStatusContactList
        Map<Id, Id> subStatusContactMap = new Map<Id, Id>();
        for(TR1__Sub_Status__c ss : subStatusContactListInfo) {
            subStatusContactMap.put(ss.Id, ss.TR1__Application__r.TR1__Applicant__r.Id);
        }

        // Check if User exists
        List<User> userList = new List<User>([
            SELECT Id, Name, ContactId
            FROM User
            WHERE ContactId IN :subStatusContactMap.values() AND IsActive = true
        ]);
        System.debug('User List: ' + userList);

        Set<Id> contactIdUserList = new Set<Id>();
        for(User u : userList) {
            contactIdUserList.add(u.ContactId);
        }
        System.debug('contactIdUserList Existing User Contacts: ' + contactIdUserList);

        // Create new User List
        List<User> newUserListToCreate = new List<User>();
        for(TR1__Sub_Status__c ss : subStatusList) {
            TR1__Sub_Status__c conInfo = subStatusContactMapInfo.get(ss.Id);
            system.debug('conInfo ' + conInfo);
            system.debug('conInfo.Id ' + conInfo.TR1__Application__r.TR1__Applicant__r.Id);
            if(!contactIdUserList.contains(conInfo.TR1__Application__r.TR1__Applicant__r.Id)) {
                system.debug('Creating User');    
                User newUser = new User();
                newUser.Alias = conInfo.TR1__Application__r.TR1__Applicant__r.FirstName.substring(0, 1) + conInfo.TR1__Application__r.TR1__Applicant__r.LastName.substring(0, 1);
                newUser.ContactId = conInfo.TR1__Application__r.TR1__Applicant__r.Id;
                newUser.ProfileId = profileList[0].Id;
                newUser.FirstName = conInfo.TR1__Application__r.TR1__Applicant__r.FirstName;
                newUser.LastName = conInfo.TR1__Application__r.TR1__Applicant__r.LastName;
                newUser.Email = conInfo.TR1__Application__r.TR1__Applicant__r.Email;
                newUser.Username = conInfo.TR1__Application__r.TR1__Applicant__r.Email;                
                newUser.CommunityNickname = conInfo.TR1__Application__r.TR1__Applicant__r.FirstName + ss.TR1__Application__r.TR1__Applicant__r.LastName + Integer.valueof((Math.random() * 1000));
                newUser.TimeZoneSidKey = 'America/New_York';
                newUser.LocaleSidKey = 'en_US';
                newUser.EmailEncodingKey = 'UTF-8';
                newUser.LanguageLocaleKey = 'en_US';
                newUser.IsActive = true;
                newUserListToCreate.add(newUser);
            } else {
                system.debug('User already exists');
            }

        }
        if(newUserListToCreate.size() > 0) {
            insert newUserListToCreate;
            system.debug('SPC - user Created: ' + newUserListToCreate);
            Set<Id> userIdsCreated = (new Map<Id,User>(newUserListToCreate)).keySet();
            processSubStatusFuture(userIdsCreated);
        }
    }

    // create future method
    @future
    public static void processSubStatusFuture(Set<Id> userIdsCreated) {

        List<PermissionSet> permissionSetList = new List<PermissionSet>([
            SELECT Id, Name
            FROM PermissionSet
            WHERE Name = 'X1218_Shift_Approval_Connect_App' OR
                  Name = 'X2cloudnine_Standard_Objects_Permission_Set' OR
                  Name = 'Alliance_Mobile_Worker' OR                  
                  Name = 'X1218_SMS_Application_Connect_App' OR
                  Name = 'Employee_Community_Permission_Set'
        ]);
        system.debug('SPC permissionSetList ' + permissionSetList);

        // User List
        List<User> userList = new List<User>([
            SELECT Id, Name, ContactId
            FROM User
            WHERE Id IN :userIdsCreated
        ]);        

        // Link user to permission set
        List<PermissionSetAssignment> userPermissionSetAssignment = new List<PermissionSetAssignment>();
        for(User u : userList) {
            for(PermissionSet ps : permissionSetList) {
                PermissionSetAssignment psa = new PermissionSetAssignment();
                psa.PermissionSetId = ps.Id;
                psa.AssigneeId = u.Id;
                userPermissionSetAssignment.add(psa);
            }
        }
        insert userPermissionSetAssignment;
    }
    
}