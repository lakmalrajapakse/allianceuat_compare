/**
 * @description       : 
 * @author            : Simon Coles
 * @group             : 
 * @last modified on  : 20-11-2024
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   20-11-2024   Simon Coles   Initial Version
**/
@isTest
public with sharing class SIM_TimeApproval_test {
    static Account acc;
    static Account invAcc;
    static Contact con;
    static Contact clientContact;
    static sirenum__ProActiveContract__c contract;
    static sirenum__Site__c site;
    static sirenum__Team__c team;
    static TR1__Job__c job;
    static sirenum__Placement__c placement;
    

    static void createTestData(){
        acc = SIM_TestDataFactory.genTestAccount('Candidate Pool', 'Client', false);
        acc.Payroll_Tax_Exempt__c = 'No';
        acc.Approval_Type__c = 'Not Charged';
        insert acc;
        invAcc = SIM_TestDataFactory.genTestAccount('invoice entity', 'Client', false);
        invAcc.Payroll_Tax_Exempt__c = 'No';
        invAcc.Approval_Type__c = 'Not Charged';
        insert invAcc;        

        // NOTE set contact as client contact instead of candidate because of unknown validation rule
        // con = SIM_TestDataFactory.genTestContact('Ridge', acc, 'Client Contact', true);
        Id contactRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Candidate').getRecordTypeId();

        con = new Contact(FirstName = 'tot', LastName = 'brown', AccountId = acc.Id, RecordTypeId = contactRT, tc9_et__Timesheet_Notification_Email__c = 'Primary', email='abc@abc.com');
        clientContact = new Contact(FirstName = 'Ridge2', LastName = 'grwon', AccountId = acc.Id, RecordTypeId = contactRT, tc9_et__Timesheet_Notification_Email__c = 'Primary', email='abc@abc.com');
        insert new List<Contact> {con, clientContact};
        
        update con;

        site = SIM_TestDataFactory.genTestSite(acc, true);

        contract = SIM_TestDataFactory.genTestContract(acc, clientContact, invAcc, true);

        team = SIM_TestDataFactory.genTestJobRole(contract, true);
        
        Work_Address__c w = new Work_Address__c ();
		w.Account__c = acc.Id;
        w.Name = 'Test';
        insert w;
        
		// tc9_pr__Leave_Template__c lt = new tc9_pr__Leave_Template__c ();
		// lt.Name = 'Test';
        // lt.tc9_pr__Effective_Date__c = system.today();
        // lt.Abbreviated_Code__c = 'ABC';
        // insert lt;

        // job = SIM_TestDataFactory.genTestBHJob(acc, team, site, false);
        // job.CA_Branch__c = 'Adelaide';
        // job.CA_Division__c = 'LBH';
		// job.CA_Employment_Type__c = 'APP';
		// job.CA_Industry__c = 'Asphalt';
		// job.CA_Protech_Entity__c = 'Dreampath Recruitment Pty Ltd';
		// job.Special_Category__c = 'Coal';        
		// job.tempname__c = lt.id;        
		// job.Work_Address__c = w.id; 
        // insert job;

        sirenum__Rate_Card__c rateCard = new sirenum__Rate_card__c();
        insert rateCard;

        placement = SIM_TestDataFactory.genTestPlacement(con, contract, team, false);
        placement.sirenum__Contact__c = clientContact.Id;
        placement.sirenum__Rate_Card__c = rateCard.Id;
        placement.sirenum__End_Date__c = System.today().addDays(365);
        insert placement;
    }

    @isTest
    static void test_getSetup() {
        createTestData();

        DateTime testDateTime = dateTime.newInstance(2020, 11, 23, 9,0,0);

        List<sirenum__Payroll_Cycle__c> testCycles = new List<sirenum__Payroll_Cycle__c>{
            SIM_TestDataFactory.getTestCycle('Cycle 1')
        };
        insert testCycles;

        contract.sirenum__PayrollCycle__c = testCycles[0].id;
        update contract;

        List<sirenum__Week__c> testPeriods = new List<sirenum__Week__c>{
            SIM_TestDataFactory.getTestPeriod(testCycles[0].id, testDateTime.date())
        };
        insert testPeriods;

        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(SIM_TimeApproval.getSetup((String)con.Id));
        system.assertEquals(true, (Boolean)response.get('success'));
        Map<String, Object> responseObjectMap = (Map<String, Object>)response.get('responseObject');
        
        Map<String, Object> expectedResult = new Map<String, Object>{
            'canSeeWorker' => Schema.sObjectType.sirenum__Shift__c.fields.sirenum__Contact__c.isAccessible(),
            'canSeeSite' => Schema.sObjectType.sirenum__Shift__c.fields.sirenum__Site__c.isAccessible(),
            'canSeeJobRole' => Schema.sObjectType.sirenum__Shift__c.fields.sirenum__Site__c.isAccessible(),
            'canEnterBreaks' => Schema.sObjectType.sirenum__Shift__c.fields.sirenum__Break_Length__c.isUpdateable() && Schema.sObjectType.sirenum__Shift__c.fields.sirenum__BreakStartTime__c.isUpdateable(),
            'userType' => UserInfo.getUserType(),
            'userName' => UserInfo.getName(),
            'userId' => UserInfo.getUserId(),
            'currency' => UserInfo.getDefaultCurrency(), 
            'canSeePay' => Schema.sObjectType.sirenum__Shift__c.fields.Basic_Pay__c.isAccessible(),
            'canSeeCharge' => Schema.sObjectType.sirenum__Shift__c.fields.sirenum__Charge__c.isAccessible(),
            //'useTimeTypeOnShift' => Time_Approval_Settings__c.getInstance().Use_Time_Type_on_Shift__c,
            'canEnterExpenses' => Schema.sObjectType.sirenum__Expense__c.isUpdateable() && Schema.sObjectType.sirenum__Expense__c.isCreateable(),
            'canEnterAbsolute' => Schema.sObjectType.sirenum__Shift__c.fields.sirenum__Absolute_Start_Time__c.isUpdateable() && Schema.sObjectType.sirenum__Shift__c.fields.sirenum__Absolute_End_Time__c.isUpdateable(),        
            'canEnterActual' => Schema.sObjectType.sirenum__Shift__c.fields.sirenum__Actual_Start_Time__c.isUpdateable() && Schema.sObjectType.sirenum__Shift__c.fields.sirenum__Actual_End_Time__c.isUpdateable(),
            //'canEnterBreaks' => Schema.sObjectType.sirenum__Shift__c.fields.sirenum__Break_Length__c.isUpdateable() && Schema.sObjectType.sirenum__Shift__c.fields.sirenum__BreakStartTime__c.isUpdateable(),            
            'canEnterBillable' => Schema.sObjectType.sirenum__Shift__c.fields.sirenum__Billable_Start_Time__c.isUpdateable() && Schema.sObjectType.sirenum__Shift__c.fields.sirenum__Billable_End_Time__c.isUpdateable(),
            //'canEnterReported' => Schema.sObjectType.sirenum__Shift__c.fields.Client_Reported_Start__c.isUpdateable() && Schema.sObjectType.sirenum__Shift__c.fields.Client_Reported_End__c.isUpdateable(),
            //'canApprove' => Schema.sObjectType.sirenum__Shift__c.fields.Approved__c.isUpdateable(),
            'canApprovePay' => Schema.sObjectType.sirenum__Shift__c.fields.sirenum__Allow_pay__c.isUpdateable(),
            'canApproveCharge' => Schema.sObjectType.sirenum__Shift__c.fields.sirenum__Allow_charge__c.isUpdateable(),
            'canSubmit' => Schema.sObjectType.sirenum__Shift__c.fields.Submitted__c.isUpdateable(),
            'canSeeSubmit' => Schema.sObjectType.sirenum__Shift__c.fields.Submitted__c.isAccessible(),
            'canRejectShift' => Schema.sObjectType.sirenum__Shift__c.fields.Rejected__c.isUpdateable() && Schema.sObjectType.sirenum__Shift__c.fields.Rejection_Reason__c.isUpdateable(),
            // 'canSeeApprove' => Schema.sObjectType.sirenum__Shift__c.fields.Approved__c.isAccessible(),
            'canSeeApprovePay' => Schema.sObjectType.sirenum__Shift__c.fields.sirenum__Allow_pay__c.isAccessible(),
            'canSeeApproveCharge' => Schema.sObjectType.sirenum__Shift__c.fields.sirenum__Allow_pay__c.isUpdateable(),
            'userContactId' => (String)con.Id
        };
        
        //System.assertEquals(expectedResult, responseObjectMap, 'Unexpected setup retrieved');
    }

    @isTest
    static void test_getFullRecords_Pos() {
        createTestData();

        Date startDate = Date.today();
        Date endDate = Date.today().addDays(5);
        DateTime testDateTime = dateTime.newInstance(startDate.year(), startDate.month(), startDate.day(), 9, 0, 0);

        List<sirenum__Payroll_Cycle__c> testCycles = new List<sirenum__Payroll_Cycle__c>{
            SIM_TestDataFactory.getTestCycle('Cycle 1')
        };
        insert testCycles;

        contract.sirenum__PayrollCycle__c = testCycles[0].id;
        update contract;

        List<sirenum__Week__c> testPeriods = new List<sirenum__Week__c>{
            SIM_TestDataFactory.getTestPeriod(testCycles[0].id, testDateTime.date())
        };
        insert testPeriods;

        List<sirenum__Shift__c> testShifts = new List<sirenum__Shift__c>{
            new sirenum__Shift__c(
                sirenum__Scheduled_Start_Time__c = testDateTime,
                sirenum__Scheduled_End_Time__c = testDateTime.addHours(1),
                sirenum__Cancelled__c = false,
                sirenum__Contract__c = contract.Id,
                sirenum__Contact__c = con.Id
            ),
            new sirenum__Shift__c(
                sirenum__Scheduled_Start_Time__c = testDateTime.addDays(1),
                sirenum__Scheduled_End_Time__c = testDateTime.addDays(1).addHours(1),
                sirenum__Cancelled__c = false,
                sirenum__Contract__c = contract.Id,
                sirenum__Contact__c = con.Id
            )
        };

        insert testShifts;
 
        List<String> accs = new List<String>{acc.Id};
        List<String> cons = new List<String>{con.Id};
        String sDate = startDate.day() + '/' + startDate.month() + '/' + startDate.year();
        String eDate = endDate.day() + '/' + endDate.month() + '/' + endDate.year();

        //Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(SIM_TimeApproval.getData(null, testPeriods[0].id, null, null, null, null));
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(SIM_TimeApproval.getData(null, sDate, eDate, cons,null, null, null, null, null));

        system.assertEquals(true, (Boolean)response.get('success'), 'Result: ' + response);
        Map<String, Object> responseObjectMap = (Map<String, Object>)response.get('responseObject');

        List<Object> records = (List<Object>)responseObjectMap.get('records');
        system.assertEquals(0, records.size());
    }

    @isTest
    static void test_updateShifts_Pos() {
        createTestData();

        DateTime testDateTime = dateTime.newInstance(2020, 11, 23, 9,0,0);

        List<sirenum__Payroll_Cycle__c> testCycles = new List<sirenum__Payroll_Cycle__c>{
            SIM_TestDataFactory.getTestCycle('Cycle 1')
        };
        insert testCycles;

        contract.sirenum__PayrollCycle__c = testCycles[0].id;
        update contract;

        List<sirenum__Week__c> testPeriods = new List<sirenum__Week__c>{
            SIM_TestDataFactory.getTestPeriod(testCycles[0].id, testDateTime.date())
        };
        insert testPeriods;


        List<sirenum__Shift__c> testShifts = new List<sirenum__Shift__c>{
            new sirenum__Shift__c(sirenum__Contact__c = con.id, sirenum__Site__c = site.id, sirenum__Team__c = team.id, //s5m__BH4SFJob__c = job.id,      //Monday
            sirenum__Scheduled_Start_Time__c = testDateTime, sirenum__Scheduled_End_Time__c = testDateTime.addHours(1)),

            new sirenum__Shift__c(sirenum__Contact__c = con.id, sirenum__Site__c = site.id, sirenum__Team__c = team.id, //s5m__BH4SFJob__c = job.id,      //Tuesday
            sirenum__Scheduled_Start_Time__c = testDateTime.addDays(1), sirenum__Scheduled_End_Time__c = testDateTime.addDays(1).addHours(1))
        };

        insert testShifts;


        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(SIM_TimeApproval.updateShifts(JSON.serialize(testShifts)));
        system.assertEquals(true, (Boolean)response.get('success'));
        List<Object> responseObjectList = (List<Object>)response.get('responseObject');

        for(Object srObject : responseObjectList){
            Map<String,Object> saveResultMap = (Map<String,Object>)srObject;
            system.assertEquals(true, (Boolean)saveResultMap.get('success'));
        }
    }

    @isTest
    static void test_updateShifts_Neg() {
        createTestData();

        DateTime testDateTime = dateTime.newInstance(2020, 11, 23, 9,0,0);

        List<sirenum__Payroll_Cycle__c> testCycles = new List<sirenum__Payroll_Cycle__c>{
            SIM_TestDataFactory.getTestCycle('Cycle 1')
        };
        insert testCycles;

        contract.sirenum__PayrollCycle__c = testCycles[0].id;
        update contract;

        List<sirenum__Week__c> testPeriods = new List<sirenum__Week__c>{
            SIM_TestDataFactory.getTestPeriod(testCycles[0].id, testDateTime.date())
        };
        insert testPeriods;


        List<sirenum__Shift__c> testShifts = new List<sirenum__Shift__c>{
            new sirenum__Shift__c(sirenum__Contact__c = con.id, sirenum__Site__c = site.id, sirenum__Team__c = team.id, //s5m__BH4SFJob__c = job.id,      //Monday
            sirenum__Scheduled_Start_Time__c = testDateTime, sirenum__Scheduled_End_Time__c = testDateTime.addHours(1)),

            new sirenum__Shift__c(sirenum__Contact__c = con.id, sirenum__Site__c = site.id, sirenum__Team__c = team.id, //s5m__BH4SFJob__c = job.id,      //Tuesday
            sirenum__Scheduled_Start_Time__c = testDateTime.addDays(1), sirenum__Scheduled_End_Time__c = testDateTime.addDays(1).addHours(1))
        };

        insert testShifts;

        //Try to invoke error - a shift must have times
        for(sirenum__Shift__c shift : testShifts){
            //Should trigger standard validation rule "This shift ends before it starts"
            DateTime startTime = shift.sirenum__Scheduled_Start_Time__c;
            shift.sirenum__Scheduled_Start_Time__c = shift.sirenum__Scheduled_End_Time__c;
            shift.sirenum__Scheduled_End_Time__c = startTime;
        }


        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(SIM_TimeApproval.updateShifts(JSON.serialize(testShifts)));
        //system.assertEquals(null, response);
        system.assertEquals(false, (Boolean)response.get('success'));
        List<Object> responseObjectList = (List<Object>)response.get('responseObject');

        for(Object srObject : responseObjectList){
            Map<String,Object> saveResultMap = (Map<String,Object>)srObject;
            system.assertEquals(false, (Boolean)saveResultMap.get('success'));
        }
    }

}