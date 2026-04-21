@isTest
public class ShiftImportTool_Test {

    private static sirenum__Site__c site;
    private static sirenum__Rota__c rota;
    private static sirenum__Team__c team;
    private static sirenum__Team__c team2;    
    private static sirenum__Team__c team3;    
    private static Contact con;

    private static sirenum__Site__c site2;
    private static sirenum__Rota__c rota2;
    private static Contact con2;

    private static ShiftImportLog__c itdc;
    private static Account acc;
    private static ShiftImportSettings__c its;

    private static contract contract;
    private static sirenum__Payroll_Cycle__c paycycle;

    private static void createTestData() {
        //TEST RECORDS  
        site = new sirenum__Site__c(Name = 'test Site');
        insert site;
        rota = new sirenum__Rota__c(Name = 'test ROTA');
        insert rota;
        acc = new Account(Name = 'Test Account', TR1__Status__c = 'Live', tc9_pr__Available_Payment_Methods__c = 'Payee Australian Bank', tc9_pr__Maximum_Payment_Distributions__c = '1');
        insert acc;
        con = new Contact(FirstName = 'John', LastName = 'User', Email = 'test@sirenum.com', MobilePhone = '07583331473', AccountId = acc.Id);
        insert con;
        paycycle = new sirenum__Payroll_Cycle__c(Name = 'Sunday - Monday', sirenum__CyclePeriodUnits__c = 'Weeks', sirenum__periodLength__c = 1, sirenum__StartingDate__c = system.today());
        insert paycycle;
        contract = new Contract(Name = 'BBF Hull', AccountId = acc.Id, Status = 'Draft', StartDate = date.today(), ContractTerm = 1);
        insert contract;

        //Secondary Records
        site2 = new sirenum__Site__c(Name = 'test Site2');
        insert site2;
        rota2 = new sirenum__Rota__c(Name = 'test ROTA2');
        insert rota2;
        con2 = new Contact(FirstName = 'Jane', LastName = 'OtherUser', Email = 'test@sirenum.com', MobilePhone = '07583331473', AccountId = acc.Id);
        insert con2;

        Schema.DescribeFieldResult cancellationReasonsDescribe = sirenum__Shift__c.sirenum__CancellationReason__c.getDescribe();
        Schema.SObjectField T = cancellationReasonsDescribe.getSobjectField();
        List<PicklistEntry> entries = T.getDescribe().getPicklistValues();

        team = new sirenum__Team__c(Name = 'test TEAM');
        insert team;
        team2 = new sirenum__Team__c(Name = 'test TEAM2');
        insert team2;        


        //DB Object
        itdc = new ShiftImportLog__c();

        //Settings
        its = new ShiftImportSettings__c();
        its.Match_Accounts__c = 'Name';
        its.Match_Contacts__c = 'Name';
        its.Match_Job_Roles__c = 'Name';
        its.Match_Rotas__c = 'Name';
        its.Match_Shifts__c = 'sirenum__FMS_Shift_ID__c';
        its.Match_Sites__c = 'Name';
        its.Default_Cancellation_Reason__c = entries.get(0).getValue();

        insert its;

    }

    static testmethod void testFailures() {
        createTestData();
        //Settings
        its.Allow_Delete_Results__c = true;
        its.Allow_Quick_Create__c = true;
        its.Import_Demand__c = true;
        its.Import_Shifts__c = true;
        its.SetupOwnerId = UserInfo.getOrganizationId();
        update its;

        apexpages.StandardController sc = new apexPages.StandardController(itdc);
        ShiftImportTool controller = new ShiftImportTool(sc);

        //Improt shift demand against a worker
        String jsnString = '{"importFile": [{'+
                                '"REFERENCE": "1234",'+
                                '"PO NUMBER": "12345",'+
                                '"BOOKING DATE": "2016-01-01",'+
                                '"SCHEDULED DATE": "2016-01-01",'+
                                '"WORKER": "John User",'+
                                '"SITE": "test Site",'+
                                '"ROTA": "test ROTA",'+
                                '"JOB ROLE": "test TEAM",'+
                                '"START": "09:30",'+
                                '"END": "17:30",'+
                                '"REQUIRED SHIFTS": "2",'+
                                '"COMMENTS": "A comment",'+
                                '"CANCELLED": "FALSE",'+
                                '"TYPE": "PM",'+
                                '"BOOKED BY": "BOOKED BY"'+
                            '}]}';

        List<ShiftImportTool.infoRow> returnRows = ShiftImportTool.parse(jsnString);
        System.assertEquals(1, returnRows.size());
        System.assertEquals(true, returnRows[0].rawInfoMessage.containsIgnoreCase('cannot be assigned to'));

        //Now insert the demand
        jsnString = '{"importFile": [{'+
                                '"REFERENCE": "1234",'+
                                '"PO NUMBER": "12345",'+
                                '"BOOKING DATE": "2016-01-01",'+
                                '"SCHEDULED DATE": "2016-01-01",'+
                                '"WORKER": "",'+
                                '"SITE": "test Site",'+
                                '"ROTA": "test ROTA",'+
                                '"JOB ROLE": "test TEAM",'+
                                '"START": "09:30",'+
                                '"END": "17:30",'+
                                '"REQUIRED SHIFTS": "2",'+
                                '"COMMENTS": "A comment",'+
                                '"CANCELLED": "FALSE",'+
                                '"TYPE": "PM",'+
                                '"BOOKED BY": "BOOKED BY"'+
                            '}]}';
        returnRows = ShiftImportTool.parse(jsnString);
        System.assertEquals(1, returnRows.size());
        System.assertEquals('Inserted Shift Demand [Requirement]', returnRows[0].infoMessage);

        //Attempt to update shift demand - fail due to duplicate shifts with the reference number
        jsnString = '{"importFile": [{'+
                                '"REFERENCE": "1234",'+
                                '"PO NUMBER": "12345",'+
                                '"BOOKING DATE": "2016-01-01",'+
                                '"SCHEDULED DATE": "2016-01-01",'+
                                '"WORKER": "",'+
                                '"SITE": "test Site",'+
                                '"ROTA": "test ROTA",'+
                                '"JOB ROLE": "test TEAM",'+
                                '"START": "09:30",'+
                                '"END": "17:30",'+
                                '"REQUIRED SHIFTS": "2",'+
                                '"COMMENTS": "A comment",'+
                                '"CANCELLED": "FALSE",'+
                                '"TYPE": "PM",'+
                                '"BOOKED BY": "BOOKED BY"'+
                            '}]}';
        returnRows = ShiftImportTool.parse(jsnString);
        System.assertEquals(1, returnRows.size());

        //Duplicate Sites/Jobs/Rotas/Contacts
        sirenum__Site__c site3 = new sirenum__Site__c(Name = 'test Site');
        insert site3;
        sirenum__Rota__c rota3 = new sirenum__Rota__c(Name = 'test ROTA');
        insert rota3;
        team3 = new sirenum__Team__c(Name = 'test TEAM');
        insert team3;
        Contact con3 = new Contact(FirstName = 'John', LastName = 'User', Email = 'test2@sirenum.com', MobilePhone = '07583331470', AccountId = acc.Id);
        insert con3;

        jsnString = '{"importFile": [{'+
                                '"REFERENCE": "12345",'+
                                '"PO NUMBER": "12345",'+
                                '"BOOKING DATE": "2016-01-01",'+
                                '"SCHEDULED DATE": "2016-01-01",'+
                                '"WORKER": "",'+
                                '"SITE": "test Site",'+
                                '"ROTA": "test ROTA",'+
                                '"JOB ROLE": "test TEAM",'+
                                '"START": "09:30",'+
                                '"END": "17:30",'+
                                '"REQUIRED SHIFTS": "2",'+
                                '"COMMENTS": "A comment",'+
                                '"CANCELLED": "FALSE",'+
                                '"TYPE": "PM",'+
                                '"BOOKED BY": "BOOKED BY"'+
                            '}]}';
        returnRows = ShiftImportTool.parse(jsnString);
        System.assertEquals(1, returnRows.size());
    }

    static testmethod void testDataIntegrity() {
        createTestData();
        //Settings
        its.Allow_Delete_Results__c = true;
        its.Allow_Quick_Create__c = true;
        its.Import_Demand__c = true;
        its.Import_Shifts__c = true;
        its.SetupOwnerId = UserInfo.getOrganizationId();
        update its;

        apexpages.StandardController sc = new apexPages.StandardController(itdc);
        ShiftImportTool controller = new ShiftImportTool(sc);

        //Bad or missing data
        String jsnString = '{"importFile": [{'+
                                '"REFERENCE": "12345",'+
                                '"PO NUMBER": "12345",'+
                                '"BOOKING DATE": "2016-01-01",'+
                                '"SCHEDULED DATE": "2016-01-01",'+
                                '"WORKER": "",'+
                                '"SITE": "test Site",'+
                                '"ROTA": "test ROTA",'+
                                '"JOB ROLE": "test TEAM",'+
                                '"START": "",'+
                                '"END": "17:30",'+
                                '"REQUIRED SHIFTS": "2",'+
                                '"COMMENTS": "A comment",'+
                                '"CANCELLED": "FALSE",'+
                                '"TYPE": "PM",'+
                                '"BOOKED BY": "BOOKED BY"'+
                            '}]}';
        List<ShiftImportTool.infoRow> returnRows = ShiftImportTool.parse(jsnString);
        System.assertEquals(1, returnRows.size());
        // System.assertEquals(true, returnRows[0].rawInfoMessage.containsIgnoreCase('Invalid Date:'));
        System.assertEquals(true, returnRows[0].rawInfoMessage.containsIgnoreCase('No start time'));

        //Bad end time
        jsnString = '{"importFile": [{'+
                        '"REFERENCE": "12345",'+
                        '"PO NUMBER": "12345",'+
                        '"BOOKING DATE": "2016-01-01",'+
                        '"SCHEDULED DATE": "2016-01-01",'+
                        '"WORKER": "",'+
                        '"SITE": "test Site",'+
                        '"ROTA": "test ROTA",'+
                        '"JOB ROLE": "test TEAM",'+
                        '"START": "",'+
                        '"END": "",'+
                        '"REQUIRED SHIFTS": "2",'+
                        '"COMMENTS": "A comment",'+
                        '"CANCELLED": "FALSE",'+
                        '"TYPE": "PM",'+
                        '"BOOKED BY": "BOOKED BY"'+
                    '}]}';
        returnRows = ShiftImportTool.parse(jsnString);
        System.assertEquals(1, returnRows.size());
        System.assertEquals(false, returnRows[0].rawInfoMessage.containsIgnoreCase('Bad End time'));
        //Bad end time
        jsnString = '{"importFile": [{'+
                        '"REFERENCE": "12345",'+
                        '"PO NUMBER": "12345",'+
                        '"BOOKING DATE": "2016-01-01",'+
                        '"SCHEDULED DATE": "2016-01-01",'+
                        '"WORKER": "",'+
                        '"SITE": "test Site",'+
                        '"ROTA": "test ROTA",'+
                        '"JOB ROLE": "test TEAM",'+
                        '"START": "A",'+
                        '"END": "17:30",'+
                        '"REQUIRED SHIFTS": "2",'+
                        '"COMMENTS": "A comment",'+
                        '"CANCELLED": "FALSE",'+
                        '"TYPE": "PM",'+
                        '"BOOKED BY": "BOOKED BY"'+
                    '}]}';
        returnRows = ShiftImportTool.parse(jsnString);
        System.assertEquals(1, returnRows.size());
        System.assertEquals(true, returnRows[0].rawInfoMessage.containsIgnoreCase('Bad Start time'));

        its.Match_Shifts__c = 'Name';
        update its;
        //Bad Field
        jsnString = '{"importFile": [{'+
                                '"REFERENCE": "12345",'+
                                '"PO NUMBER": "12345",'+
                                '"BOOKING DATE": "2016-01-01",'+
                                '"SCHEDULED DATE": "2016-01-01",'+
                                '"WORKER": "",'+
                                '"SITE": "test Site",'+
                                '"ROTA": "test ROTA",'+
                                '"JOB ROLE": "test TEAM",'+
                                '"START": "09:30",'+
                                '"END": "B",'+
                                '"REQUIRED SHIFTS": "2",'+
                                '"COMMENTS": "A comment",'+
                                '"CANCELLED": "FALSE",'+
                                '"TYPE": "PM",'+
                                '"BOOKED BY": "BOOKED BY"'+
                            '}]}';
        try {
            returnRows = ShiftImportTool.parse(jsnString);
        } catch (Exception e) {
            System.assertEquals(true, e.getMessage().containsIgnoreCase('Field Name is not editable'));
        }
    }

    static testmethod void testBadInsert() {
        createTestData();
        //Settings
        its.Allow_Delete_Results__c = true;
        its.Allow_Quick_Create__c = true;
        its.Import_Demand__c = true;
        its.Import_Shifts__c = true;
        its.SetupOwnerId = UserInfo.getOrganizationId();
        update its;

        apexpages.StandardController sc = new apexPages.StandardController(itdc);
        ShiftImportTool controller = new ShiftImportTool(sc);

        //Bad or missing data
        //Now insert the demand
        String jsnString = '{"importFile": [{'+
                                '"REFERENCE": "1234",'+
                                '"PO NUMBER": "12345",'+
                                '"BOOKING DATE": "2016-01-01",'+
                                '"SCHEDULED DATE": "2016-01-01",'+
                                '"WORKER": "",'+
                                '"SITE": "test Site",'+
                                '"ROTA": "test ROTA",'+
                                '"JOB ROLE": "test TEAM",'+
                                '"START": "09:30",'+
                                '"END": "17:30",'+
                                '"REQUIRED SHIFTS": "2",'+
                                '"COMMENTS": "A comment",'+
                                '"CANCELLED": "FALSE",'+
                                '"TYPE": "PM",'+
                                '"BOOKED BY": "BOOKED BY"'+
                            '}]}';

        try {
            ShiftImportTool.throwTestException = true;
            List<ShiftImportTool.infoRow> returnRows = ShiftImportTool.parse(jsnString);
        } catch (Exception e) {
            System.assertEquals(true, e.getMessage().containsIgnoreCase('Shift Insert Error'));
        }
    }


}