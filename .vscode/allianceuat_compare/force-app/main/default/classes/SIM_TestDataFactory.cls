/**
 * @description       : 
 * @author            : Zach Palmer
 * @group             : 
 * @last modified on  : 1/10/24
 * @last modified by  : Zach Palmer
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   1/10/24   Zach Palmer   Initial Version
**/
@IsTest
public class SIM_TestDataFactory {
    public static final String ACCOUNT_CUSTOMER_RT = 'Client';
    public static final String CONTACT_CANDIDATE_RT = 'Client Contact';
    public static final string JOB_SOURCING_RT = 'Sourcing Role';
    
    public static sirenum__Ticket__c genQualification(Contact con, Date validFrom, Date validUntil, Boolean comit) {
        sirenum__TicketType__c comp = new sirenum__TicketType__c(
            Name = 'tst',
            sirenum__Requires_Proof__c = false
        );
        insert comp;
        sirenum__Ticket__c qual = new sirenum__Ticket__c(
            sirenum__Owner__c = con.Id,
            sirenum__TicketType__c = comp.Id,
            sirenum__Valid_from__c = validFrom,
            sirenum__Valid_until__c = validUntil
        );

        if (comit) {
            insert qual;
        }

        return qual;
    }

    public static User genTestUser(
        String lastName,
        String email,
        String alias,
        Id profileId,
        Boolean comit
    ) {
        User newUser = new User();
        newUser.LastName = lastName;
        newUser.Email = email;
        newUser.Alias = alias;
        newUser.Username = email + '.test.invalid';
        newUser.TimeZoneSidKey = 'America/New_York';
        newUser.LocaleSidKey = 'en_US';
        newUser.EmailEncodingKey = 'UTF-8';
        newUser.LanguageLocaleKey = 'en_US';
        newUser.ProfileId = profileId;

        if (comit)
            insert newUser;
        return newUser;
    }

    public static sirenum__Shift__c genPastShift(Contact con, sirenum__Site__c site, sirenum__Placement__c placement, sirenum__ProActiveContract__c contract, String recType, Boolean comit) {
        // Id shiftRT = Schema.SObjectType.TR1__Job__c.getRecordTypeInfosByName().get(recType).getRecordTypeId();
        sirenum__Shift__c shift = new sirenum__Shift__c(
            sirenum__Contact__c = con.Id,
            sirenum__Scheduled_Start_Time__c = DateTime.newInstance(System.today().addDays(-1), Time.newInstance(1,0,0,0)),
            sirenum__Scheduled_End_Time__c = DateTime.newInstance(System.today().addDays(-1), Time.newInstance(11,0,0,0)),
            sirenum__Actual_Start_Time__c = DateTime.newInstance(System.today().addDays(-1), Time.newInstance(1,0,0,0)),
            sirenum__Actual_End_Time__c = DateTime.newInstance(System.today().addDays(-1), Time.newInstance(11,0,0,0)),
            sirenum__Site__c = site.Id,
            sirenum__Placement__c = placement.Id,
            sirenum__Contract__c = contract.Id,
            // RecordTypeId = shiftRT,
            Submitted__c = false
        );

        if (comit) {
            insert shift;
        }

        return shift;
    }

    public static sirenum__Shift__c genFutureShift(Contact con, sirenum__Site__c site, sirenum__Placement__c placement, sirenum__ProActiveContract__c contract, String recType, Boolean comit) {
        // Id shiftRT = Schema.SObjectType.TR1__Job__c.getRecordTypeInfosByName().get(recType).getRecordTypeId();
        sirenum__Shift__c shift = new sirenum__Shift__c(
            sirenum__Contact__c = con.Id,
            sirenum__Scheduled_Start_Time__c = DateTime.newInstance(System.today().addDays(2), Time.newInstance(1,0,0,0)),
            sirenum__Scheduled_End_Time__c = DateTime.newInstance(System.today().addDays(2), Time.newInstance(11,0,0,0)),
            sirenum__Actual_Start_Time__c = DateTime.newInstance(System.today().addDays(2), Time.newInstance(1,0,0,0)),
            sirenum__Actual_End_Time__c = DateTime.newInstance(System.today().addDays(2), Time.newInstance(11,0,0,0)),
            sirenum__Site__c = site.Id,
            sirenum__Placement__c = placement.Id,
            sirenum__Contract__c = contract.Id,
            // RecordTypeId = shiftRT,
            Submitted__c = false
        );

        if (comit) {
            insert shift;
        }

        return shift;
    }

    public static TR1__Job__c genTestBHJob(Account acc, sirenum__Team__c jobRole, sirenum__Site__c site, Boolean comit){
        return genTestBHJob(acc, jobRole, site, 'Permanent', comit);
    }
     
     public static TR1__Job__c genTestBHJob(Account acc, sirenum__Team__c jobRole, sirenum__Site__c site, String recordType, Boolean comit){
        Id jobRT = Schema.SObjectType.TR1__Job__c.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
        TR1__Job__c job = new TR1__Job__c(
            Name = 'BH Job',
            TR1__Account__r = acc,
            TR1__Account__c = acc.Id,
            //s5m__JobRole__c = jobRole.Id,
            //s5m__JobRole__r = jobRole,
            //s5m__Site__c = site.Id,
            TR1__Status__c = 'Open',
            TR1__Open_Date__c = system.today(),
            TR1__Estimated_Start_Date__c = system.today(),
            RecordTypeId = jobRT 
        );
        
        if(comit){
            insert job;
        }
        return job;
    }

    public static sirenum__Payroll_Cycle__c getTestCycle(String cycleName){
        return new sirenum__Payroll_Cycle__c(
                sirenum__periodLength__c = 7,
                sirenum__StartingDate__c = system.today().toStartOfWeek(),
                sirenum__CyclePeriodUnits__c = 'Weeks',
                Name = cycleName
        );
    }

    public static sirenum__Week__c getTestPeriod(Id cycleId, Date startDate){
        return getTestPeriod(cycleId, startDate, 7);
    }
    public static sirenum__Week__c getTestPeriod(Id cycleId, Date startDate, Integer daysLong){
        return getTestPeriod(cycleId, startDate, startDate.addDays(daysLong));
    }
    public static sirenum__Week__c getTestPeriod(Id cycleId, Date startDate, Date emdDate){
        return new sirenum__Week__c(
                sirenum__PayrollCycle__c = cycleId,
                sirenum__Start_Date__c = startDate,
                sirenum__Week_Ending__c = emdDate,
                Name = startDate.format() + ' - ' + emdDate.format()
        );
    }

    
    public static sirenum__Week__c genTestPayrollPeriod(string periodName, date startDate, date endDate, integer length, boolean comit) {
        sirenum__Payroll_Cycle__c cycle = new sirenum__Payroll_Cycle__c(
            Name = periodName,
            sirenum__StartingDate__c = startDate,
            sirenum__periodLength__c = length
        );
        insert cycle;
        sirenum__Week__c payrollPeriod = new sirenum__Week__c(
            Name = periodName,
            sirenum__Start_Date__c = startDate,
            sirenum__Week_Ending__c = endDate,
            sirenum__PayrollCycle__c = cycle.Id
        );
        if (comit) {
            insert payrollPeriod;
        }

        return payrollPeriod;
    }
    /**
    * @description Generates test account records for a given record type

    * @author Zach Palmer | 01-25-2022 
    * @param String accountName - Name of new account
    * @param String rt - record type developer name
    * @param Boolean comit - weather or not to insert the record in the db
    * @return Account - new account
    **/
    public static Account genTestAccount(String accountName, Boolean comit) {
        Account testAccount = new Account();
        testAccount.Name = accountName;
        //testAccount.tc9_pr__Available_Payment_Methods__c = Account.tc9_pr__Available_Payment_Methods__c.getDescribe().getPicklistValues().get(0).getValue();
        //testAccount.tc9_pr__Maximum_Payment_Distributions__c = Account.tc9_pr__Maximum_Payment_Distributions__c.getDescribe().getPicklistValues().get(0).getValue();
        // testAccount.Stage__c = 'Active';
        // testAccount.tc9_pr__ABN__c = '50916241108';
        testAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId();
        if(comit){
            insert testAccount;
        }
        return testAccount;

    }

    public static Account genTestAccount(String accountName, String rt, Boolean comit) {
        //Retrieve Account RecordType
        Id accountRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get((String.isNotBlank(rt) ? rt : ACCOUNT_CUSTOMER_RT)).getRecordTypeId();

        //Generate Test Account
        return genTestAccount(accountName, accountRT, comit);
    }
    public static Account genTestAccount(String name, Id rtId, Boolean comit) {
        Account testAccount = new Account();

        testAccount.Name = name;
        testAccount.RecordTypeId = rtId;
        // testAccount.tc9_pr__Available_Payment_Methods__c = Account.tc9_pr__Available_Payment_Methods__c.getDescribe().getPicklistValues().get(0).getValue();
        // testAccount.tc9_pr__Maximum_Payment_Distributions__c = Account.tc9_pr__Maximum_Payment_Distributions__c.getDescribe().getPicklistValues().get(0).getValue();
        // testAccount.Stage__c = 'Active';
        // testAccount.tc9_pr__ABN__c = '50916241108';

        if(comit){
            insert testAccount;
        }
        return testAccount;
    }

    public static sirenum__Timesheet__c genTestTimesheet(sirenum__Week__c workedPeriod, Id contactId, boolean comit) {
        sirenum__Timesheet__c timesheet = new sirenum__Timesheet__c(
            sirenum__Worked_Period__c = workedPeriod.Id,
            sirenum__Week__c = workedPeriod.Id,
            sirenum__Week_Ending__c = workedPeriod.sirenum__Week_Ending__c,
            sirenum__Worker__c = contactId
        );
        if (comit) {
            insert timesheet;
        }
        return timesheet;
    }

    public static sirenum__Timesheet_Line__c genTestTimesheetLine(Id timesheetId, integer hours, double charge, double rate, boolean comit) {
        sirenum__Timesheet_Line__c line = new sirenum__Timesheet_Line__c(
            sirenum__Timesheet__c = timesheetId,
            sirenum__Hours__c = hours,
            sirenum__Charge__c = charge,
            sirenum__Rate__c = rate
        );
        if (comit) {
            insert line;
        }

        return line;
    }

    public static sirenum__Expense_Type__c genTestExpenseType(string name, double value, boolean comit) {
        sirenum__Expense_Type__c expenseType = new sirenum__Expense_Type__c(
            Name = name,
            sirenum__Value__c = value
        );
        if (comit) {
            insert expenseType;
        }

        return expenseType;
    }

    public static sirenum__Expense__c genTestExpense(Id candidateId, Id expenseTypeId, double amount, double units, Date expenseDate, boolean comit) {
        sirenum__Expense__c expense = new sirenum__Expense__c(
            sirenum__Contact__c = candidateId,
            sirenum__Expense_Type__c = expenseTypeId,
            sirenum__Amount__c = amount,
            sirenum__Units__c = units,
            sirenum__Charge_Amount__c = amount,
            sirenum__Date_of_expense__c = expenseDate
        );
        if (comit) {
            insert expense;
        }
        return expense;
    }

    public static Contact genTestContact(
        String lastName,
        Id accId,
        Boolean comit
    ) {
        return genTestContact(lastName, accId, 'Candidate Contact', comit);        
    }

    public static Contact genTestContact(
        String lastName,
        Id accId,
        String recordType,
        Boolean comit
    ) { 

        // Id contactRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('WFM Employee').getRecordTypeId();
        // Id emergencyRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Emergency Contact').getRecordTypeId();

        // Contact emergencyContact = new Contact();
        // emergencyContact.recordTypeId = emergencyRT;
        // emergencyContact.LastName = 'emerg contact lastname';
        // emergencyContact.Email = 'emergencycontact@mail.com';
        //insert emergencyContact;

        // Id contactRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Employee').getRecordTypeId();
        Id contactRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
       
        Contact con = new Contact();
        con.accountId = accId;
        con.LastName = lastName;
        con.Email = lastName + '@mail.com';
        con.recordTypeId = contactRT;
        //con.tc9_pr__Emergency_Contact_of_Employee__c  = emergencyContact.Id;

        if (comit)
            insert con;
        return con;
    }

    public static sirenum__ProActiveContract__c genTestContract(Account acc, Boolean comit){
        sirenum__ProActiveContract__c contract = new sirenum__ProActiveContract__c(
                sirenum__Client__r = acc,
                sirenum__Client__c = acc.Id
                // tc9_ext_sirint__Invoice_To_Account__c=acc.Id  
        );

        if (comit) {
            insert contract;
        }

        return contract;
    }

    /**
    * @description Generates a test contract for a given Account
    * @author Zach Palmer | 01-25-2022 
    * @param Account acc - account to relate the contract to 
    * @param Boolean comit - weather or not to insert the record in the db
    * @return sirenum__ProActiveContract__c - new contract
    **/
    public static sirenum__ProActiveContract__c genTestContract(Account acc, Contact con, Account invAcc, Boolean comit){
        sirenum__ProActiveContract__c newContract = new sirenum__ProActiveContract__c(
                sirenum__Client__r = acc,
                sirenum__Client__c = acc.Id,
                sirenum__Account_Manager__c = con.Id
                // tc9_ext_sirint__Invoice_To_Account__c = invAcc.Id
                //Office_Number__c = sirenum__ProActiveContract__c.Office_Number__c.getDescribe().getPicklistValues().get(0).getValue()
        );
        if(comit){
            insert newContract;
        }
        return newContract;
    }

    /*
    public static b3o__Chat_Message__c genTestMessage(Boolean comit) {
        b3o__Chat_Message__c newMessage = new b3o__Chat_Message__c();
        newMessage.b3o__Body__c = 'Test';
        newMessage.Received_By__c = '12341234';
        newMessage.Sent_By__c = '43214321';

        if (comit) {
            insert newMessage;
        }
        return newMessage;
    }*/

    public static SIM_Response.Response deserializeSIMResponse(String jsonString, Type successRespObj, Type errorRespObj) {
        if (String.isEmpty(jsonString))
           return null;

           Boolean success = null;        
           String message = null;
           Object responseObject = null;
   
           JSONParser parser = JSON.createParser(jsonString);
           while (true) {
               JSONToken t = parser.nextToken();
               if (t == null) 
                   break;
               
               if (t == JSONToken.FIELD_NAME) {
                   String fieldName = parser.getCurrentName();
                   t = parser.nextValue();                
                   
                   if ('success'.equals(fieldName)) {
                      success = parser.getBooleanValue();                   
                   } else if ('responseObject'.equals(fieldName)) {
                       if (success && successRespObj != null && t == JSONToken.START_OBJECT)
                           responseObject = parser.readValueAs(successRespObj);
                       else if (!success && errorRespObj != null && t == JSONToken.START_OBJECT)
                           responseObject = parser.readValueAs(errorRespObj);
                   } else if ('message'.equals(fieldName)) {
                       message = parser.getText();
                   }
               }
           }
   
           if (success == null) {
               throw new StringException('success field not populated in response');
           }
   
           if (success) 
               return new SIM_Response.SuccessResponse(responseObject, message) ;
           else
               return new SIM_Response.ErrorResponse(responseObject, message) ;
       
    }

    public static SIM_General_Settings__c genSIMGeneralSettings(
        Boolean comit
    ) {
        SIM_General_Settings__c settings = new SIM_General_Settings__c();
        settings.Bulk_Shift_Upload_Batch_Size__c = 200;
        
        if (comit) {
            insert settings;
        }

        return settings;
    } 


    /**
    * @description Generates a test job type
    * @author Lakmnal Rajapakjse | 01-27-2023
    * @param String jobTypeName - name of the job Type
    * @param String awrGroup - name of the AWR Group
    * @param Boolean comit - weather or not to insert the record in the db
    * @return sirenum__Job_Type__c - new jobType
    **/
    public static sirenum__Job_Type__c genJobType(String jobTypeName, String awrGroup, Boolean comit){
        sirenum__Job_Type__c newType = new sirenum__Job_Type__c(
                Name = jobTypeName
                // AWR_Group__c = awrGroup
        );
        if(comit){
            insert newType;
        }
        return newType;
    }

    /**
    * @description Generates a test job type
    * @author Nick Donovan | 18-12-2024
    * @param String jobTypeName - name of the job Type
    * @param Boolean comit - weather or not to insert the record in the db
    * @return sirenum__Job_Type__c - new jobType
    **/
    public static sirenum__Job_Type__c genTestJobType(String jobTypeName, Boolean comit){
        sirenum__Job_Type__c jobType = new sirenum__Job_Type__c (
                Name = jobTypeName
        );

        if(comit){
            insert jobType;
        }

        return jobType;
    }

    /**
    * @description Generates a new Sirenum Job Role for a given Sirenum Contract
    * @author Zach Palmer | 01-25-2022 
    * @param sirenum__ProActiveContract__c contract - Sirenum contract to attach the job role to
    * @param Boolean comit - weather or not to insert the record in the db
    * @return sirenum__Team__c - new Sirenum Job Role
    **/
    public static sirenum__Team__c genTestJobRole(sirenum__ProActiveContract__c contract, Boolean comit){

        // tc9_et__Rate_Calculator__c rateCalc = new tc9_et__Rate_Calculator__c();
        // insert rateCalc;

        sirenum__Team__c jobRole = new sirenum__Team__c(
                Name = 'Job Role',
                sirenum__Account__r = contract,
                sirenum__Account__c = contract.Id
                // tc9_ext_sirint__Rate_Calculator__c = rateCalc.Id
        );

        if(comit){
            insert jobRole;
        }

        return jobRole;
    }

    /**
    * @description Generates a Sirenum Site for a given Account
    * @author Zach Palmer | 01-25-2022 
    * @param Account acc - Account to attach the new Site to 
    * @param Boolean comit - weather or not to insert the record in the db
    * @return sirenum__Site__c - new Sirenum Site
    **/
    public static sirenum__Site__c genTestSite(Account acc, Boolean comit){
        sirenum__Site__c site = new sirenum__Site__c (
                sirenum__Operating_Company__r = acc,
                sirenum__Operating_Company__c = acc.Id
                //Site_s_Timezone__c = 'Australia/Sydney'
        );

        if(comit){
            insert site;
        }

        return site;
    }
    
    public static sirenum__Placement__c genTestPlacement(Contact candidate, 
    sirenum__ProActiveContract__c contract,
    sirenum__Team__c jobRole,  Boolean comit){
        sirenum__Placement__c placement = new sirenum__Placement__c(
            sirenum__Contact__c = candidate.Id,
            sirenum__Contract__c = contract.Id,
            sirenum__Job_Role__c = jobRole.Id,
            sirenum__Start_Date__c = system.today().addDays(-365)
        );

        if(comit)
            insert placement;

        return placement;
    }

    public static TR1__Application_V2__c genTestApplication(TR1__Job__c job, Contact candidate, String recordType, Boolean comit) {
        Id recType = Schema.SObjectType.TR1__Application_V2__c.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
        return genTestApplication(job, candidate, recType, comit);
    }
  
    public static TR1__Application_V2__c genTestApplication(TR1__Job__c job, Contact candidate, Id recType, Boolean comit) {
        TR1__Application_V2__c app = new TR1__Application_V2__c(
            TR1__Job__c = job.Id,
            TR1__Applicant__c = candidate.Id,
            RecordTypeId = recType
        );   
        if (comit) {
            insert app;
        }
        return app;  
    }

    public static TR1__Job__c genTestJob(string name, string rt, Account aAccount, boolean comit) {
        Id jobRT = Schema.SObjectType.TR1__Job__c.getRecordTypeInfosByName().get((String.isNotBlank(rt) ? rt : JOB_SOURCING_RT)).getRecordTypeId();
        return genTestJob(name, jobRt, aAccount, comit);
    }

    public static TR1__Job__c genTestJob(string name, Id rtId, Account workLoc, boolean comit) {
        TR1__Job__c job = new TR1__Job__c(
            Name = name,
            RecordTypeId = rtId,
            TR1__Account__c = workLoc.Id
        );

        if (comit) {
            insert job;
        }
        return job;
    }

    public static sirenum__Employee_Job__c genEmployeeJob(Contact candidate, sirenum__Job_Type__c jobType,  Boolean comit){
        
        sirenum__Employee_Job__c empJob = new sirenum__Employee_Job__c(
                sirenum__Contact__c = candidate.Id,
                sirenum__Job_Type__c = jobType.Id
            );
    
            if(comit)
                insert empJob;
    
            return empJob;
    }

    /** 
    * @description Generates a Shift Job Role Mapping
    * @author Nick Donovan | 18-12-2024
    * @param String vmsName - name of the VMS
    * @param String acc - Account
    * @param String contract - Contract
    * @param String vmsJobName - name of the Job Role on VMS
    * @param String jobType - Job Type
    * @param String jobRole - Job Role
    * @param Boolean comit - whether or not to insert the record in the db
    * @return Shift_Job_Role_Mapping__c - new Shift Job Role Mapping
    **/
    public static Shift_Job_Role_Mapping__c genTestJobRoleMapping(String vmsName, Account acc, sirenum__ProActiveContract__c contract, String vmsJobName, sirenum__Job_Type__c jobType, sirenum__Team__c jobRole,  Boolean comit){
        Shift_Job_Role_Mapping__c jobRoleMap = new Shift_Job_Role_Mapping__c(
            VMS_Name__c = vmsName,
            Account__c = acc.Id,
            WFM_Contract__c = contract.Id,
            VMS_Job_Role__c = vmsJobName,
            Job_Role__c = jobRole.Id,
            Job_Type__c = jobType.Id
        );
        if (comit) {
            insert jobRoleMap;
        }

        return jobRoleMap;
    }

    /** 
    * @description Generates a Shift Job Role Mapping
    * @author Nick Donovan | 18-12-2024
    * @param String vmsName - name of the VMS
    * @param String vmsFacilityName - name of the VMS Facility
    * @param String acc - Account
    * @param String contract - Contract
    * @param String site - Site
    * @param Boolean comit - whether or not to insert the record in the db
    * @return Shift_Job_Role_Mapping__c - new Shift Job Role Mapping
    **/
    public static VMS_Facility_Mapping__c genTestFacilityMapping(String vmsName, String vmsFacilityName, Account acc, sirenum__ProActiveContract__c contract, sirenum__Site__c site, Boolean comit){
        VMS_Facility_Mapping__c facilityMap = new VMS_Facility_Mapping__c(
            VMS_Name__c = vmsName,
            Facility__c = acc.Id,
            WFM_Contract__c = contract.Id,
            VMS_Facility__c = vmsFacilityName,
            Site__c = site.Id
        );
        if (comit) {
            insert facilityMap;
        }

        return facilityMap;
    }

    public static String[] getPicklistValues(String object_name, String field_name) {
        String[] values = new String[]{};
        String[] types = new String[]{object_name};
        Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
        for(Schema.DescribeSobjectResult res : results) {
            for (Schema.PicklistEntry entry : res.fields.getMap().get(field_name).getDescribe().getPicklistValues()) {
                if (entry.isActive()) {
                    values.add(entry.getValue());
                }
            }
        }
        return values;
    }

}