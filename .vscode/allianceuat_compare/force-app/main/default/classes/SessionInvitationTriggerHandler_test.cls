@isTest
private class SessionInvitationTriggerHandler_test {
    public static Account acc;
    public static Contact cont;
    public static b3o__Session__c session;
    public static b3o__Session_Schedule__c sessionSchedule;

    public static void createData(){
        acc = SIM_TestDataFactory.genTestAccount('accountName', 'Candidate Pool', true);
        cont = SIM_TestDataFactory.genTestContact('LastName', acc.Id, 'Candidate', false);
        cont.FirstName = 'First';
        cont.Email = '1218-SFDC-Support@1218global.com';
        cont.LastName = 'LastName';        
        insert cont; 

        Profile userProfile = [SELECT id FROM profile WHERE name = 'Minimum Access - API Only Integrations'];

        User standardUser = new User(
            Alias = 'stuse123',
            Email = 'standarduser123@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = userProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'standarduser123@example.com.test123'
        );
        insert standardUser;

        session = new b3o__Session__c(
            Name = 'Test Session',
            Timezone__c = 'Australia/Brisbane',
            b3o__Session_Leader__c = standardUser.id         
        );
        insert session;

        sessionSchedule = new b3o__Session_Schedule__c(
            b3o__Session__c = session.Id,
            b3o__Start_Time__c = Datetime.now().addDays(1),
            b3o__End_Time__c = Datetime.now().addDays(1).addMinutes(30),
            b3o__Openings__c = 1
        );
        insert sessionSchedule;
    }

    @isTest
    static void testInsert() {
        createData();

        b3o__Session_Invitation__c si = new b3o__Session_Invitation__c(
            b3o__Session__c = session.Id,
            b3o__Contact__c = cont.Id,
            b3o__Session_Schedule__c = sessionSchedule.Id
        );

        Test.startTest();
        insert si;
        Test.stopTest();

        si = [SELECT Booking_Time_Local__c FROM b3o__Session_Invitation__c WHERE b3o__Contact__c = :cont.Id];

        System.assert(si.Booking_Time_Local__c != null, 'Session Invitation local time not set.');
    }
}