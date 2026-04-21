/**
 * PS-908 Store important Datetimes as local dates and times
 */

@IsTest
private class SetLocalTimes_Test {

    private static Account account;
    private static sirenum__Site__c siteAdelaide;
    private static sirenum__Site__c siteBrisbane;
    private static sirenum__Site__c siteNull;
    private static sirenum__Shift__c shift;
    private static Contact contact;

    private static void setClassVariables(){
        String invoiceAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Invoice Entity').getRecordTypeId();
        Account invoiceAccount = new Account(Name='SN TEST INVOICE ENTITY', RecordTypeId = invoiceAccountRecordTypeId);
        insert invoiceAccount;       

        String paymentAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Payment Entity').getRecordTypeId();
        Account paymentAccount = new Account(
            Name='SN TEST PAYMENT ENTITY',
            tc9_pr__Available_Payment_Methods__c = 'Payee Cash',
            tc9_pr__Maximum_Payment_Distributions__c = '2',
            RecordTypeId = paymentAccountRecordTypeId);
        insert paymentAccount;

        String payScheduleRecordTypeId = Schema.SObjectType.tc9_pr__Schedule__c.getRecordTypeInfosByName().get('Pay Schedule').getRecordTypeId();
        tc9_pr__Schedule__c paySchedule = new tc9_pr__Schedule__c(
            Name='TEST PAY SCHEDULE',
            RecordTypeId=payScheduleRecordTypeId,
            tc9_pr__Split_Option__c='No Split',
            tc9_pr__Period_Type__c='Monthly',
            tc9_pr__Payroll_Jurisdiction__c='Australia'
        );
        insert paySchedule;      

        account = new Account(
            Name='Test Account',
            Default_Invoice_Entity__c=invoiceAccount.Id,
            Default_Payment_Entity__c=paymentAccount.Id,
            tc9_et__Invoice_Group_By__c='Assignment',
            tc9_pr__Schedule__c = paySchedule.Id,
            Phone= '00000000000',
            tc9_pr__Available_Payment_Methods__c = 'Payee Cash',
            tc9_pr__Maximum_Payment_Distributions__c = '2'
        );
        insert account;

        siteAdelaide = new sirenum__Site__c(
                Name='Test Adelaide',
                sirenum__Operating_Company__c=account.Id,
                sirenum__Timezone__c='Australia/Adelaide',
                Site_s_Timezone__c = 'Australia/Adelaide',
                State__c='VIC');
        siteBrisbane = new sirenum__Site__c(
                Name='Test Brisbane',
                sirenum__Operating_Company__c=account.Id,
                sirenum__Timezone__c='Australia/Brisbane',
                Site_s_Timezone__c='Australia/Brisbane',
                State__c='VIC');
        siteNull = new sirenum__Site__c(Name='Test Null', sirenum__Operating_Company__c=account.Id, State__c='VIC');

//lines replaced by above lines without PI Entitiy due to request from 2C9 (Gaby Frydman, Bullhorn, 6/2/24
//
//        siteAdelaide = new sirenum__Site__c(Name='Test Adelaide', sirenum__Operating_Company__c=account.Id, sirenum__Timezone__c='Australia/Adelaide', PI_Entity__c='Edmen Pty Ltd', State__c='VIC');
//        siteBrisbane = new sirenum__Site__c(Name='Test Brisbane', sirenum__Operating_Company__c=account.Id, sirenum__Timezone__c='Australia/Brisbane', PI_Entity__c='Edmen Pty Ltd', State__c='VIC');
//        siteNull = new sirenum__Site__c(Name='Test Null', sirenum__Operating_Company__c=account.Id, PI_Entity__c='Edmen Pty Ltd', State__c='VIC');
        insert new List<sirenum__Site__c>{siteAdelaide, siteBrisbane, siteNull};
        

        shift = new sirenum__Shift__c(
                sirenum__Scheduled_Start_Time__c = Datetime.newInstanceGmt(
                        2023, 01, 23, 07, 0, 0
                ),
                sirenum__Scheduled_End_Time__c = Datetime.newInstanceGmt(
                        2023, 01, 23, 11, 0, 0
                ),
                sirenum__BreakStartTime__c = Datetime.newInstanceGmt(
                        2023, 01, 23, 08, 0, 0
                ),
                tc9_ext_sirint__Second_Break_Start_Time__c = Datetime.newInstanceGmt(
                        2023, 01, 23, 10, 0, 0
                ),
                sirenum__Site__c = siteAdelaide.Id
        );
        insert shift;

        contact = new Contact(FirstName='Test', LastName='Worker');
        insert contact;
    }

    @IsTest
    static void testShiftInsertion() {
        setClassVariables();

        shift.sirenum__BreakStartTime__c = shift.sirenum__BreakStartTime__c.addMinutes(30);
        shift.tc9_ext_sirint__Second_Break_Start_Time__c = shift.tc9_ext_sirint__Second_Break_Start_Time__c.addMinutes(30);
        update shift;

        shift = [SELECT tc9_ext_sirint__TSE_First_Break_Date__c, tc9_ext_sirint__TSE_First_Break_Time__c,
                        tc9_ext_sirint__TSE_Second_Break_Date__c, tc9_ext_sirint__TSE_Second_Break_Time__c
                 FROM sirenum__Shift__c
                 WHERE Id = :shift.Id];

        System.assertNotEquals(null, shift.tc9_ext_sirint__TSE_First_Break_Date__c);
        System.assertNotEquals(null, shift.tc9_ext_sirint__TSE_First_Break_Time__c);        

        //Adelaide should be 10.5 hours ahead
        System.assertEquals(23, shift.tc9_ext_sirint__TSE_First_Break_Date__c.day());
        System.assertEquals(19, shift.tc9_ext_sirint__TSE_First_Break_Time__c.hour());
        System.assertEquals(0, shift.tc9_ext_sirint__TSE_First_Break_Time__c.minute());
        
        System.assertEquals(23, shift.tc9_ext_sirint__TSE_Second_Break_Date__c.day());
        
        String siteTz = siteAdelaide.sirenum__Timezone__c;
        Datetime originalSecondBreak = Datetime.newInstanceGmt(2023, 01, 23, 10, 0, 0).addMinutes(30);
        String formatted = originalSecondBreak.format('yyyy-MM-dd HH:mm', siteTz);
        List<String> parts = formatted.split(' ')[1].split(':');
        
        Integer expectedHour = Integer.valueOf(parts[0]);
        Integer expectedMinute = Integer.valueOf(parts[1]);
        
        System.assertEquals(expectedHour, shift.tc9_ext_sirint__TSE_Second_Break_Time__c.hour());
        System.assertEquals(expectedMinute, shift.tc9_ext_sirint__TSE_Second_Break_Time__c.minute());
    }

    @IsTest
    static void testSiteChange() {
        setClassVariables();
        shift.sirenum__Site__c = siteBrisbane.Id;
        update shift;        

        shift = [SELECT tc9_ext_sirint__TSE_Second_Break_Date__c, tc9_ext_sirint__TSE_Second_Break_Time__c
                 FROM sirenum__Shift__c
                 WHERE Id = :shift.Id];

        //Brisbane should be 10 hours ahead
        //System.assertEquals(23, shift.tc9_ext_sirint__TSE_First_Break_Date__c.day());
        //System.assertEquals(18, shift.tc9_ext_sirint__TSE_First_Break_Time__c.hour());
        //System.assertEquals(0, shift.tc9_ext_sirint__TSE_First_Break_Time__c.minute());

        System.assertEquals(23, shift.tc9_ext_sirint__TSE_Second_Break_Date__c.day());
        System.assertEquals(20, shift.tc9_ext_sirint__TSE_Second_Break_Time__c.hour());
        System.assertEquals(0, shift.tc9_ext_sirint__TSE_Second_Break_Time__c.minute());
    }

    @IsTest
    static void testDatetimeChange1() {
        setClassVariables();
        shift.sirenum__BreakStartTime__c = shift.sirenum__BreakStartTime__c.addHours(1);
        shift.tc9_ext_sirint__Second_Break_Start_Time__c = shift.tc9_ext_sirint__Second_Break_Start_Time__c.addHours(1);
        update shift;

        shift = [SELECT tc9_ext_sirint__TSE_First_Break_Date__c, tc9_ext_sirint__TSE_First_Break_Time__c,
                        tc9_ext_sirint__TSE_Second_Break_Date__c, tc9_ext_sirint__TSE_Second_Break_Time__c
                 FROM sirenum__Shift__c
                 WHERE Id = :shift.Id];

        //Adelaide should be 10.5 hours ahead
        System.assertEquals(23, shift.tc9_ext_sirint__TSE_First_Break_Date__c.day());
        System.assertEquals(19, shift.tc9_ext_sirint__TSE_First_Break_Time__c.hour());
        System.assertEquals(30, shift.tc9_ext_sirint__TSE_First_Break_Time__c.minute());

        System.assertEquals(23, shift.tc9_ext_sirint__TSE_Second_Break_Date__c.day());
        System.assertEquals(21, shift.tc9_ext_sirint__TSE_Second_Break_Time__c.hour());
        System.assertEquals(30, shift.tc9_ext_sirint__TSE_Second_Break_Time__c.minute());
    }

    @IsTest
    static void testNullInsertTimezone(){
        setClassVariables();
        sirenum__Shift__c shiftNull = new sirenum__Shift__c(
            sirenum__Scheduled_Start_Time__c = Datetime.newInstanceGmt(2023, 01, 24, 08, 0, 0),
            sirenum__Scheduled_End_Time__c = Datetime.newInstanceGmt(2023, 01, 24, 10, 0, 0),
            sirenum__Site__c = siteNull.Id
        );
        insert shiftNull;

        shiftNull = [SELECT tc9_ext_sirint__TSE_Scheduled_Start_Date__c, tc9_ext_sirint__TSE_Scheduled_Start_Time__c,
                            tc9_ext_sirint__TSE_Scheduled_End_Date__c, tc9_ext_sirint__TSE_Scheduled_End_Time__c
                     FROM sirenum__Shift__c
                     WHERE Id = :shiftNull.Id];

        //All should be null because there is no TZ to convert to
        System.assertEquals(null, shiftNull.tc9_ext_sirint__TSE_Scheduled_Start_Date__c);
        System.assertEquals(null, shiftNull.tc9_ext_sirint__TSE_Scheduled_Start_Time__c);

        System.assertEquals(null, shiftNull.tc9_ext_sirint__TSE_Scheduled_End_Date__c);
        System.assertEquals(null, shiftNull.tc9_ext_sirint__TSE_Scheduled_End_Time__c);
    }

    @IsTest
    static void testNullInsertTimezoneAdhoc(){
        setClassVariables();
        sirenum__Shift__c shiftNull = new sirenum__Shift__c(
            sirenum__Actual_Start_Time__c = Datetime.newInstanceGmt(2023, 01, 24, 08, 0, 0),
            sirenum__Actual_End_Time__c = Datetime.newInstanceGmt(2023, 01, 24, 10, 0, 0),
            sirenum__Site__c = siteNull.Id
        );
        insert shiftNull;

        shiftNull = [SELECT tc9_ext_sirint__TSE_Scheduled_Start_Date__c, tc9_ext_sirint__TSE_Scheduled_Start_Time__c,
                            tc9_ext_sirint__TSE_Scheduled_End_Date__c, tc9_ext_sirint__TSE_Scheduled_End_Time__c
                     FROM sirenum__Shift__c
                     WHERE Id = :shiftNull.Id];

        //All should be null because there is no TZ to convert to
        System.assertEquals(null, shiftNull.tc9_ext_sirint__TSE_Scheduled_Start_Date__c);
        System.assertEquals(null, shiftNull.tc9_ext_sirint__TSE_Scheduled_Start_Time__c);

        System.assertEquals(null, shiftNull.tc9_ext_sirint__TSE_Scheduled_End_Date__c);
        System.assertEquals(null, shiftNull.tc9_ext_sirint__TSE_Scheduled_End_Time__c);
    }

    @IsTest
    static void testNullUpdateTimezone(){
        setClassVariables();
        shift.sirenum__Site__c = siteNull.Id;
        update shift;

        shift = [SELECT tc9_ext_sirint__TSE_Scheduled_Start_Date__c, tc9_ext_sirint__TSE_Scheduled_Start_Time__c,
                        tc9_ext_sirint__TSE_Scheduled_End_Date__c, tc9_ext_sirint__TSE_Scheduled_End_Time__c
                 FROM sirenum__Shift__c
                 WHERE Id = :shift.Id];

        //All should be null because there is no TZ to convert to
        System.assertEquals(null, shift.tc9_ext_sirint__TSE_Scheduled_Start_Date__c);
        System.assertEquals(null, shift.tc9_ext_sirint__TSE_Scheduled_Start_Time__c);

        System.assertEquals(null, shift.tc9_ext_sirint__TSE_Scheduled_End_Date__c);
        System.assertEquals(null, shift.tc9_ext_sirint__TSE_Scheduled_End_Time__c);
    }
}