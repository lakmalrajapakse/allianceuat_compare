/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class VMS_InboundEmailHandlerTest {

    static Account acc;
    static Account acc2;
    static Contact cont;
    static Contact contDup;
    static sirenum__ProActiveContract__c contract;
    // static List<sirenum__Site__c> sites;
    static sirenum__Site__c site;
    static sirenum__Site__c defaultSite;
    static sirenum__Job_Type__c jobType;
    static sirenum__Team__c jobRole;
    static VMS_Facility_Mapping__c facilityMapping;
    static Shift_Job_Role_Mapping__c jrMapping;
    static String vmsFacilityName;
    static sirenum__Shift__c shift;

    /**     
    * StaffCentral Tests 
    **/
    @isTest
    static void inboundSCEmailCreate_valid(){
        System.debug(LOGGINGLEVEL.ERROR, 'BEGIN inboundEmailCreate_valid');
        vmsFacilityName = 'Regis Sandgate - Musgrave/Nursing Home/60 WAKEFIELD STREET SANDGATE QLD 4017';
        createTestData('StaffCentral');

        System.debug(LOGGINGLEVEL.ERROR, 'inboundEmailCreate_valid after createTestData');

        String emailBody = 'Edit Shift - Regis Sandgate - Musgrave, 16/10/2024, ShiftId - 311113';
        // Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEmail email = createEmail(emailBody, staffCentralEmailBodyCreate);
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        env.fromAddress = 'test@email.com';
        env.toAddress = 'test2@email.com';

        System.debug(LOGGINGLEVEL.ERROR, 'inboundEmailCreate_valid after email create');

        VMS_InboundEmailHandler inboundEmail = new VMS_InboundEmailHandler();

        Id [] fixedSearchResults = new Id[2];
        fixedSearchResults[0] = cont.Id;
        fixedSearchResults[1] = contDup.Id;
        Test.setFixedSearchResults(fixedSearchResults);
        List<List<sObject>> searchList = [FIND '1218-SFDC-Support@1218global.com'
                                            IN EMAIL FIELDS 
                                            RETURNING Contact(FirstName, LastName, Phone, Email, AccountId, OwnerId
                                            WHERE Email = '1218-SFDC-Support@1218global.com')]; 


        Test.startTest();
        Messaging.InboundEmailResult result = inboundEmail.handleInboundEmail(email, env);
        Test.stopTest();
    
        Assert.areEqual(result.success, true, 'Email not processed.');
        System.debug(LOGGINGLEVEL.ERROR, 'END inboundEmailCreate_valid');
    }

    @isTest
    static void inboundSCEmailCancel_valid(){
        System.debug(LOGGINGLEVEL.ERROR, 'BEGIN inboundEmailCancel_valid');

        vmsFacilityName = 'Regis Sandgate - Musgrave/Nursing Home/60 WAKEFIELD STREET SANDGATE QLD 4017';
        createTestData('StaffCentral');
        createTestShift('StaffCentral');

        String emailBody = 'Cancelled Shift - Regis Sandgate - Musgrave, 16/10/2024, ShiftId - 333333';
        // Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEmail email = createEmail(emailBody, staffCentralEmailBodyCancel);
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        env.fromAddress = 'test@email.com';
        env.toAddress = 'test2@email.com';

        System.debug(LOGGINGLEVEL.ERROR, 'inboundEmailCancel_valid after email create');

        VMS_InboundEmailHandler inboundEmail = new VMS_InboundEmailHandler();

        Id [] fixedSearchResults = new Id[2];
        fixedSearchResults[0] = cont.Id;
        fixedSearchResults[1] = contDup.Id;
        Test.setFixedSearchResults(fixedSearchResults);
        List<List<sObject>> searchList = [FIND '1218-SFDC-Support@1218global.com'
                                            IN EMAIL FIELDS 
                                            RETURNING Contact(FirstName, LastName, Phone, Email, AccountId, OwnerId
                                            WHERE Email = '1218-SFDC-Support@1218global.com')]; 


        Test.startTest();
        Messaging.InboundEmailResult result = inboundEmail.handleInboundEmail(email, env);
        Test.stopTest();
    
        Assert.areEqual(result.success, true, 'Email not processed.');
        System.debug(LOGGINGLEVEL.ERROR, 'END inboundEmailCancel_valid');
    }

    @isTest
    static void inboundEmailSCDefaultSiteCreate_valid(){
        System.debug(LOGGINGLEVEL.ERROR, 'BEGIN inboundEmailDefaultSiteCreate_valid');
        vmsFacilityName = 'Regis Sandgate - Musgrave/Nursing Home/60 WAKEFIELD STREET SANDGATE QLD 4017';
        createTestData('StaffCentral');

        System.debug(LOGGINGLEVEL.ERROR, 'inboundEmailDefaultSiteCreate_valid after createTestData');

        String emailBody = 'Edit Shift - Regis Sandgate - Musgrave, 16/10/2024, ShiftId - 311113';

        Messaging.InboundEmail email = createEmail(emailBody, staffCentralEmailBodyDefaultSiteCreate);
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        env.fromAddress = 'test@email.com';
        env.toAddress = 'test2@email.com';

        System.debug(LOGGINGLEVEL.ERROR, 'inboundEmailDefaultSiteCreate_valid after email create');

        VMS_InboundEmailHandler inboundEmail = new VMS_InboundEmailHandler();

        Id [] fixedSearchResults = new Id[2];
        fixedSearchResults[0] = cont.Id;
        fixedSearchResults[1] = contDup.Id;
        Test.setFixedSearchResults(fixedSearchResults);
        List<List<sObject>> searchList = [FIND '1218-SFDC-Support@1218global.com'
                                            IN EMAIL FIELDS 
                                            RETURNING Contact(FirstName, LastName, Phone, Email, AccountId, OwnerId
                                            WHERE Email = '1218-SFDC-Support@1218global.com')]; 


        Test.startTest();
        Messaging.InboundEmailResult result = inboundEmail.handleInboundEmail(email, env);
        Test.stopTest();
    
        Assert.areEqual(result.success, true, 'Email not processed.');
        System.debug(LOGGINGLEVEL.ERROR, 'END inboundEmailDefaultSiteCreate_valid');
    }

    @isTest
    static void inboundEmailSCDuplicate_valid(){
        System.debug(LOGGINGLEVEL.ERROR, 'BEGIN inboundEmailDuplicate_valid');
        vmsFacilityName = 'Regis Sandgate - Musgrave/Nursing Home/60 WAKEFIELD STREET SANDGATE QLD 4017';
        createTestData('StaffCentral');
        createTestShift('StaffCentral');

        System.debug(LOGGINGLEVEL.ERROR, 'inboundEmailCreate_valid after createTestData');

        String emailBody = 'Edit Shift - Regis Sandgate - Musgrave, 16/10/2024, ShiftId - 333333';
        Messaging.InboundEmail email = createEmail(emailBody, staffCentralEmailBodyDuplicate);
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        env.fromAddress = 'test@email.com';
        env.toAddress = 'test2@email.com';

        System.debug(LOGGINGLEVEL.ERROR, 'inboundEmailCreate_valid after email create');

        VMS_InboundEmailHandler inboundEmail = new VMS_InboundEmailHandler();

        Id [] fixedSearchResults = new Id[2];
        fixedSearchResults[0] = cont.Id;
        fixedSearchResults[1] = contDup.Id;
        Test.setFixedSearchResults(fixedSearchResults);
        List<List<sObject>> searchList = [FIND '1218-SFDC-Support@1218global.com'
                                            IN EMAIL FIELDS 
                                            RETURNING Contact(FirstName, LastName, Phone, Email, AccountId, OwnerId
                                            WHERE Email = '1218-SFDC-Support@1218global.com')]; 


        Test.startTest();
        Messaging.InboundEmailResult result = inboundEmail.handleInboundEmail(email, env);
        Test.stopTest();
    
        Assert.areEqual(result.success, true, 'Email not processed.');
        System.debug(LOGGINGLEVEL.ERROR, 'END inboundEmailCreate_valid');
    }

    @isTest
    static void inboundEmailSCCreate_invalid(){
        System.debug(LOGGINGLEVEL.ERROR, 'BEGIN inboundEmailCreate_invalidRole');
        vmsFacilityName = 'Regis Sandgate - Musgrave/Nursing Home/60 WAKEFIELD STREET SANDGATE QLD 4017';
        createTestData('StaffCentral');

        System.debug(LOGGINGLEVEL.ERROR, 'inboundEmailCreate_valid after createTestData');

        String emailBody = 'Edit Shift - Regis Sandgate - Musgrave, 16/10/2024, ShiftId - 311113';
        // Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEmail email = createEmail(emailBody, staffCentralEmailBodyInvalidRole);
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        env.fromAddress = 'test@email.com';
        env.toAddress = 'test2@email.com';

        System.debug(LOGGINGLEVEL.ERROR, 'inboundEmailCreate_invalid after email create');

        VMS_InboundEmailHandler inboundEmail = new VMS_InboundEmailHandler();

        Id [] fixedSearchResults = new Id[2];
        fixedSearchResults[0] = cont.Id;
        fixedSearchResults[1] = contDup.Id;
        Test.setFixedSearchResults(fixedSearchResults);
        List<List<sObject>> searchList = [FIND '1218-SFDC-Support@1218global.com'
                                            IN EMAIL FIELDS 
                                            RETURNING Contact(FirstName, LastName, Phone, Email, AccountId, OwnerId
                                            WHERE Email = '1218-SFDC-Support@1218global.com')]; 


        Test.startTest();
        Messaging.InboundEmailResult result = inboundEmail.handleInboundEmail(email, env);
        Test.stopTest();
    
        Assert.areEqual(result.success, true, 'Email not processed.');
        System.debug(LOGGINGLEVEL.ERROR, 'END inboundEmailCreate_invalid');
    }

    /**     
    * Emprevo Tests 
    **/
    @isTest
    static void inboundEMPEmailCreate_valid(){
        System.debug(LOGGINGLEVEL.ERROR, 'BEGIN inboundEMPEmailCreate_valid');
        vmsFacilityName = 'Regis Sandgate - Musgrave/Nursing Home/60 WAKEFIELD STREET SANDGATE QLD 4017';
        createTestData('Emprevo');

        System.debug(LOGGINGLEVEL.ERROR, 'inboundEMPEmailCreate_valid after createTestData');

        String emailBody = 'We have a new shift for you! EMPREVO';
        // Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEmail email = createEmail(emailBody, emprevoEmailBodyCreate);
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        env.fromAddress = 'test@email.com';
        env.toAddress = 'test2@email.com';

        System.debug(LOGGINGLEVEL.ERROR, 'inboundEMPEmailCreate_valid after email create');

        VMS_InboundEmailHandler inboundEmail = new VMS_InboundEmailHandler();

        Id [] fixedSearchResults = new Id[2];
        fixedSearchResults[0] = cont.Id;
        fixedSearchResults[1] = contDup.Id;
        Test.setFixedSearchResults(fixedSearchResults);
        List<List<sObject>> searchList = [FIND '1218-SFDC-Support@1218global.com'
                                            IN EMAIL FIELDS 
                                            RETURNING Contact(FirstName, LastName, Phone, Email, AccountId, OwnerId
                                            WHERE Email = '1218-SFDC-Support@1218global.com')]; 


        Test.startTest();
        Messaging.InboundEmailResult result = inboundEmail.handleInboundEmail(email, env);
        Test.stopTest();
    
        Assert.areEqual(result.success, true, 'Email not processed.');
        System.debug(LOGGINGLEVEL.ERROR, 'END inboundEMPEmailCreate_valid');
    }

    @isTest
    static void inboundEmailEMPCreate_invalid(){
        System.debug(LOGGINGLEVEL.ERROR, 'BEGIN inboundEmailEMPCreate_invalid');
        vmsFacilityName = 'Regis Sandgate - Musgrave/Nursing Home/60 WAKEFIELD STREET SANDGATE QLD 4017';
        createTestData('Emprevo');

        System.debug(LOGGINGLEVEL.ERROR, 'inboundEmailEMPCreate_invalid after createTestData');

        String emailBody = 'We have a new shift for you! EMPREVO';
        // Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEmail email = createEmail(emailBody, emprevoEmailBodyInvalidRole);
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        env.fromAddress = 'test@email.com';
        env.toAddress = 'test2@email.com';

        System.debug(LOGGINGLEVEL.ERROR, 'inboundEmailEMPCreate_invalid after email create');

        VMS_InboundEmailHandler inboundEmail = new VMS_InboundEmailHandler();

        Id [] fixedSearchResults = new Id[2];
        fixedSearchResults[0] = cont.Id;
        fixedSearchResults[1] = contDup.Id;
        Test.setFixedSearchResults(fixedSearchResults);
        List<List<sObject>> searchList = [FIND '1218-SFDC-Support@1218global.com'
                                            IN EMAIL FIELDS 
                                            RETURNING Contact(FirstName, LastName, Phone, Email, AccountId, OwnerId
                                            WHERE Email = '1218-SFDC-Support@1218global.com')]; 


        Test.startTest();
        Messaging.InboundEmailResult result = inboundEmail.handleInboundEmail(email, env);
        Test.stopTest();
    
        Assert.areEqual(result.success, true, 'Email not processed.');
        System.debug(LOGGINGLEVEL.ERROR, 'END inboundEmailEMPCreate_invalid');
    }

    @isTest
    static void inboundEMPEmailCancel_valid(){
        System.debug(LOGGINGLEVEL.ERROR, 'BEGIN inboundEMPEmailCancel_valid');

        vmsFacilityName = 'Regis Sandgate - Musgrave/Nursing Home/60 WAKEFIELD STREET SANDGATE QLD 4017';
        createTestData('Emprevo');
        createTestShift('Emprevo');

        String emailBody = 'Your shift has been cancelled EMPREVO';
        // Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEmail email = createEmail(emailBody, emprevoEmailBodyCancel);
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        env.fromAddress = 'test@email.com';
        env.toAddress = 'test2@email.com';

        System.debug(LOGGINGLEVEL.ERROR, 'inboundEMPEmailCancel_valid after email create');

        VMS_InboundEmailHandler inboundEmail = new VMS_InboundEmailHandler();

        Id [] fixedSearchResults = new Id[2];
        fixedSearchResults[0] = cont.Id;
        fixedSearchResults[1] = contDup.Id;
        Test.setFixedSearchResults(fixedSearchResults);
        List<List<sObject>> searchList = [FIND '1218-SFDC-Support@1218global.com'
                                            IN EMAIL FIELDS 
                                            RETURNING Contact(FirstName, LastName, Phone, Email, AccountId, OwnerId
                                            WHERE Email = '1218-SFDC-Support@1218global.com')]; 


        Test.startTest();
        Messaging.InboundEmailResult result = inboundEmail.handleInboundEmail(email, env);
        Test.stopTest();
    
        Assert.areEqual(result.success, true, 'Email not processed.');
        System.debug(LOGGINGLEVEL.ERROR, 'END inboundEMPEmailCancel_valid');
    }

    @isTest
    static void inboundEMPEmail_DefaultSite(){
        System.debug(LOGGINGLEVEL.ERROR, 'BEGIN inboundEMPEmail_DefaultSite');
        vmsFacilityName = 'Regis Sandgate - Musgrave/Nursing Home/60 WAKEFIELD STREET SANDGATE QLD 4017';
        createTestData('Emprevo');

        System.debug(LOGGINGLEVEL.ERROR, 'inboundEMPEmail_DefaultSite after createTestData');

        String emailBody = 'We have a new shift for you! EMPREVO';
        // Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEmail email = createEmail(emailBody, emprevoEmailBodyDefaultSite);
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        env.fromAddress = 'test@email.com';
        env.toAddress = 'test2@email.com';

        System.debug(LOGGINGLEVEL.ERROR, 'inboundEMPEmail_DefaultSite after email create');

        VMS_InboundEmailHandler inboundEmail = new VMS_InboundEmailHandler();

        Id [] fixedSearchResults = new Id[2];
        fixedSearchResults[0] = cont.Id;
        fixedSearchResults[1] = contDup.Id;
        Test.setFixedSearchResults(fixedSearchResults);
        List<List<sObject>> searchList = [FIND '1218-SFDC-Support@1218global.com'
                                            IN EMAIL FIELDS 
                                            RETURNING Contact(FirstName, LastName, Phone, Email, AccountId, OwnerId
                                            WHERE Email = '1218-SFDC-Support@1218global.com')]; 


        Test.startTest();
        Messaging.InboundEmailResult result = inboundEmail.handleInboundEmail(email, env);
        Test.stopTest();
    
        Assert.areEqual(result.success, true, 'Email not processed.');
        System.debug(LOGGINGLEVEL.ERROR, 'END inboundEMPEmail_DefaultSite');
    }

    
    @isTest
    static void inboundEmail_invalid(){
        System.debug(LOGGINGLEVEL.ERROR, 'BEGIN inboundEmail_invalid');
        vmsFacilityName = 'Regis Sandgate - Musgrave/Nursing Home/60 WAKEFIELD STREET SANDGATE QLD 4017';
        createTestData('Emprevo');

        System.debug(LOGGINGLEVEL.ERROR, 'inboundEmail_invalid after createTestData');

        String emailBody = 'Test Email no Data';
        // Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEmail email = createEmail(emailBody, emprevoEmailBodyInvalidRole);
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        env.fromAddress = 'test@email.com';
        env.toAddress = 'test2@email.com';

        System.debug(LOGGINGLEVEL.ERROR, 'inboundEmailEMPCreate_invalid after email create');

        VMS_InboundEmailHandler inboundEmail = new VMS_InboundEmailHandler();

        Id [] fixedSearchResults = new Id[2];
        fixedSearchResults[0] = cont.Id;
        fixedSearchResults[1] = contDup.Id;
        Test.setFixedSearchResults(fixedSearchResults);
        List<List<sObject>> searchList = [FIND '1218-SFDC-Support@1218global.com'
                                            IN EMAIL FIELDS 
                                            RETURNING Contact(FirstName, LastName, Phone, Email, AccountId, OwnerId
                                            WHERE Email = '1218-SFDC-Support@1218global.com')]; 


        Test.startTest();
        Messaging.InboundEmailResult result = inboundEmail.handleInboundEmail(email, env);
        Test.stopTest();
    
        Assert.areEqual(result.success, true, 'Email not processed.');
        System.debug(LOGGINGLEVEL.ERROR, 'END inboundEmail_invalid');
    }

    /** 
    * @description Create Test Data
    * @author Nick Donovan | 18-12-2024
    * @return void
    **/
    static void createTestData(String vmsName){
        System.debug(LOGGINGLEVEL.ERROR, 'BEGIN createTestData');
        // Account
        acc = SIM_TestDataFactory.genTestAccount('accountName', 'Client', false);
        acc.BillingStreet = '60 WAKEFIELD STREET';
        acc.BillingCity = 'SANDGATE';
        acc.BillingState = 'QLD';
        acc.BillingPostalCode = '4017';
        acc.Approval_Type__c = 'Not Charged';
        acc.Payroll_Tax_Exempt__c = 'Yes - Workcover Only';
        insert acc;
        acc2 = SIM_TestDataFactory.genTestAccount('accountName', 'Client', false);
        acc2.Approval_Type__c = 'Not Charged';
        acc2.Payroll_Tax_Exempt__c = 'Yes - Workcover Only';
        insert acc2;
        // Contact
        cont = SIM_TestDataFactory.genTestContact('Test-Contact', acc.Id, 'Client Contact', true);
        contDup = SIM_TestDataFactory.genTestContact('Test-Contact2', acc2.Id, 'Client Contact', false);
        contDup.Email = '1218-SFDC-Support_01@1218global.com';
        insert contDup;
        // Contract
        contract = SIM_TestDataFactory.genTestContract(acc, cont, acc, true);
        // Site 
        site = SIM_TestDataFactory.genTestSite(acc, false);
        site.WFM_Contract__c = contract.Id;
        site.sirenum__Street_Address__c = '60 WAKEFIELD STREET';
        site.sirenum__City__c = 'SANDGATE';
        site.sirenum__State__c = 'QLD';
        site.sirenum__Postal_Code__c = '4017';
        site.sirenum__Timezone__c = 'Australia/Brisbane';

        defaultSite = SIM_TestDataFactory.genTestSite(acc, false);
        defaultSite.Name = 'Default Site';
        defaultSite.VMS_Default_Site__c = true;
        defaultSite.WFM_Contract__c = contract.Id;
        defaultSite.sirenum__Street_Address__c = '60 WAKEFIELD STREET';
        defaultSite.sirenum__City__c = 'SANDGATE';
        defaultSite.sirenum__State__c = 'QLD';
        defaultSite.sirenum__Postal_Code__c = '4017';
        defaultSite.sirenum__Timezone__c = 'Australia/Brisbane';
        List<sirenum__Site__c> sites = new List<sirenum__Site__c>();
        sites.add(site);
        sites.add(defaultSite);
        insert sites;
        // Job Type / Job Role 
        jobType = SIM_TestDataFactory.genTestJobType('Registered Nurse', true);
        jobRole = SIM_TestDataFactory.genTestJobRole(contract, false);
        jobRole.Name = 'Test Job';
        jobRole.sirenum__Job_Type__c = jobType.Id;
        insert jobRole;
        // Facility Mapping 
        facilityMapping = SIM_TestDataFactory.genTestFacilityMapping(vmsName, vmsFacilityName, acc, contract, site, true);
        // Job Role Mapping 
        jrMapping = SIM_TestDataFactory.genTestJobRoleMapping(vmsName, acc, contract, 'Example Job', jobType, jobRole, true);
        System.debug(LOGGINGLEVEL.ERROR, 'END createTestData');
    }

    static void createTestShift(String vmsName){
        System.debug(LOGGINGLEVEL.ERROR, 'BEGIN createTestShift');
        // Shift - for Cancel testing
        shift = new sirenum__Shift__c(
            sirenum__Contract__c = contract.Id,
            sirenum__Site__c = site.Id,
            sirenum__Team__c = jobRole.Id,
            VMS_Source__c = vmsName,
            sirenum__FMS_Shift_ID__c = '333333',
            sirenum__Scheduled_Local_Start_Date__c = Date.today().addDays(1),
            sirenum__Scheduled_Local_End_Date__c = Date.today().addDays(1),
            sirenum__Scheduled_Local_Start_Time__c = VMSShiftUtilities.convertShiftTimeToTime('10:30'),
            sirenum__Scheduled_Local_End_Time__c = VMSShiftUtilities.convertShiftTimeToTime('17:30') 
        );
        insert shift;
        System.debug(LOGGINGLEVEL.ERROR, 'END createTestShift');
    }


    /** 
    * @description Create Email
    * @author Nick Donovan | 18-12-2024
    * @param String emailSubject - Email Subject
    * @param String emailBody - Email Body
    * @return Messaging.InboundEmail
    **/
    static Messaging.InboundEmail createEmail(String emailSubject, String emailBody){
        System.debug(LOGGINGLEVEL.ERROR, 'BEGIN createEmail');

        List<String> toAddress = new List<String>();
        toAddress.add('test@email.com');

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromName = cont.Name;
        email.fromAddress = cont.Email;
        email.toAddresses = toAddress;
        email.subject = emailSubject;
        email.plainTextBody = emailBody;
        email.htmlBody = emailBody;

        email.headers = new List<Messaging.InboundEmail.Header>();
        List<String> emailReferences = new List<String>();
        emailReferences.add('Test Ref 1');
        email.references = emailReferences;

        System.debug(LOGGINGLEVEL.ERROR, 'END createEmail');
        return email;
    }

    static Messaging.InboundEmail createInvalidEmail(String emailSubject, String emailBody){
        System.debug(LOGGINGLEVEL.ERROR, 'BEGIN createInvalidEmail');

        List<String> toAddress = new List<String>();
        toAddress.add('test@email.com');

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromName = cont.Name;
        email.fromAddress = cont.Email;
        email.toAddresses = toAddress;
        email.subject = emailSubject;
        email.plainTextBody = emailBody;
        email.htmlBody = emailBody;

        email.headers = new List<Messaging.InboundEmail.Header>();
        List<String> emailReferences = new List<String>();
        emailReferences.add('Test Ref 1');
        email.references = emailReferences;

        System.debug(LOGGINGLEVEL.ERROR, 'END createInvalidEmail');
        return email;
    }

    private static String staffCentralEmailBodyCancel {
        get{
        String scEmailCancelBody = 'Dear Alliance,\n';
        scEmailCancelBody += 'This shift has been cancelled and is no longer required. \n';
        scEmailCancelBody += 'Shift ID: ' + '333333<https://regis.staffcentral.com.au/Shift/View/251353>\n'; 
        scEmailCancelBody += 'Facility Name: Regis Sandgate - Musgrave/Nursing Home/60 WAKEFIELD STREET SANDGATE QLD 4017\n';
        scEmailCancelBody += 'Award: RN\n';
        scEmailCancelBody += 'Alt Award: EN\n';
        scEmailCancelBody += 'Role: RN\n';
        scEmailCancelBody += 'Alt Role: EN\n';
        scEmailCancelBody += 'Role Description: Example Job\n';
        scEmailCancelBody += 'Alt Role Description: Enrolled Nurse\n'; 
        scEmailCancelBody += 'Shift Date: 12/12/2024\n';
        scEmailCancelBody += 'Start Time: 08:00\n';
        scEmailCancelBody += 'End Time: 14:00\n';
        scEmailCancelBody += 'Meal break: 30\n';
        scEmailCancelBody += 'Total hours: 5.50\n'; 
        scEmailCancelBody += 'In charge times: \n';
        scEmailCancelBody += 'Allocated Employee: \n';
        scEmailCancelBody += 'Notes and comments: ' + 'RN : at least two (2) years post registration aged care experience or equivalent Note : Employee should present – Original Police Clearance or NDIS clearance\n';
        scEmailCancelBody += '\n';
        scEmailCancelBody += 'Thankyou\n';
        scEmailCancelBody += 'Regis Sandgate - Musgrave\n';
        scEmailCancelBody += 'https://regis.staffcentral.com.au/\n';
        scEmailCancelBody += 'Please do not reply to this email. ';
        return scEmailCancelBody;
        }
    } 

    private static String staffCentralEmailBodyCreate {
        get{
        String scEmailCreateBody = 'Dear Alliance,\n';
        scEmailCreateBody += 'This shift has been edited, please login to the supplier portal to ensure this shift is still suitable.\n';
        scEmailCreateBody += 'Shift ID: ' + '311113<https://regis.staffcentral.com.au/Shift/View/251353>\n'; 
        scEmailCreateBody += 'Facility Name: Regis Sandgate - Musgrave/Nursing Home/60 WAKEFIELD STREET SANDGATE QLD 4017\n';
        scEmailCreateBody += 'Award: RN\n';
        scEmailCreateBody += 'Alt Award: EN\n';
        scEmailCreateBody += 'Role: RN\n';
        scEmailCreateBody += 'Alt Role: EN\n';
        scEmailCreateBody += 'Role Description: Example Job\n';
        scEmailCreateBody += 'Alt Role Description: Enrolled Nurse\n'; 
        scEmailCreateBody += 'Shift Date: 12/12/2024\n';
        scEmailCreateBody += 'Start Time: 08:00\n';
        scEmailCreateBody += 'End Time: 14:00\n';
        scEmailCreateBody += 'Meal break: 30\n';
        scEmailCreateBody += 'Total hours: 5.50\n'; 
        scEmailCreateBody += 'In charge times: \n';
        scEmailCreateBody += 'Allocated Employee: \n';
        scEmailCreateBody += 'Notes and comments: ' + 'RN : at least two (2) years post registration aged care experience or equivalent Note : Employee should present – Original Police Clearance or NDIS clearance\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'Thankyou\n';
        scEmailCreateBody += 'Regis Sandgate - Musgrave\n';
        scEmailCreateBody += 'https://regis.staffcentral.com.au/\n';
        scEmailCreateBody += 'Please do not reply to this email. ';
        return scEmailCreateBody;
        }
    } 

    private static String staffCentralEmailBodyDefaultSiteCreate {
        get{
            String scEmailCreateBody = 'Dear Alliance,\n';
            scEmailCreateBody += 'This shift has been edited, please login to the supplier portal to ensure this shift is still suitable. \n';
            scEmailCreateBody += 'Shift ID: ' + '311113<https://regis.staffcentral.com.au/Shift/View/251353>\n'; 
            scEmailCreateBody += 'Facility Name: TEST DEFAULT SITE - Musgrave/Nursing Home/60 WAKEFIELD STREET SANDGATE QLD 4017\n';
            scEmailCreateBody += 'Award: RN\n';
            scEmailCreateBody += 'Alt Award: EN\n';
            scEmailCreateBody += 'Role: RN\n';
            scEmailCreateBody += 'Alt Role: EN\n';
            scEmailCreateBody += 'Role Description: Example Job\n';
            scEmailCreateBody += 'Alt Role Description: Enrolled Nurse\n'; 
            scEmailCreateBody += 'Shift Date: 12/12/2024\n';
            scEmailCreateBody += 'Start Time: 08:00\n';
            scEmailCreateBody += 'End Time: 14:00\n';
            scEmailCreateBody += 'Meal break: 30\n';
            scEmailCreateBody += 'Total hours: 5.50\n'; 
            scEmailCreateBody += 'In charge times: \n';
            scEmailCreateBody += 'Allocated Employee: \n';
            scEmailCreateBody += 'Notes and comments: ' + 'RN : at least two (2) years post registration aged care experience or equivalent Note : Employee should present – Original Police Clearance or NDIS clearance\n';
            scEmailCreateBody += '\n';
            scEmailCreateBody += 'Thankyou\n';
            scEmailCreateBody += 'Regis Sandgate - Musgrave\n';
            scEmailCreateBody += 'https://regis.staffcentral.com.au/\n';
            scEmailCreateBody += 'Please do not reply to this email. ';
        return scEmailCreateBody;
        }
    } 

    private static String staffCentralEmailBodyDuplicate {
        get{
        String scEmailCreateBody = 'Dear Alliance,\n';
        scEmailCreateBody += 'This shift has been edited, please login to the supplier portal to ensure this shift is still suitable.\n';
        scEmailCreateBody += 'Shift ID: ' + '333333<https://regis.staffcentral.com.au/Shift/View/251353>\n'; 
        scEmailCreateBody += 'Facility Name: Regis Sandgate - Musgrave/Nursing Home/60 WAKEFIELD STREET SANDGATE QLD 4017\n';
        scEmailCreateBody += 'Award: RN\n';
        scEmailCreateBody += 'Alt Award: EN\n';
        scEmailCreateBody += 'Role: RN\n';
        scEmailCreateBody += 'Alt Role: EN\n';
        scEmailCreateBody += 'Role Description: Example Job\n';
        scEmailCreateBody += 'Alt Role Description: Enrolled Nurse\n'; 
        scEmailCreateBody += 'Shift Date: 12/12/2024\n';
        scEmailCreateBody += 'Start Time: 08:00\n';
        scEmailCreateBody += 'End Time: 14:00\n';
        scEmailCreateBody += 'Meal break: 30\n';
        scEmailCreateBody += 'Total hours: 5.50\n'; 
        scEmailCreateBody += 'In charge times: \n';
        scEmailCreateBody += 'Allocated Employee: \n';
        scEmailCreateBody += 'Notes and comments: ' + 'RN : at least two (2) years post registration aged care experience or equivalent Note : Employee should present – Original Police Clearance or NDIS clearance\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'Thankyou\n';
        scEmailCreateBody += 'Regis Sandgate - Musgrave\n';
        scEmailCreateBody += 'https://regis.staffcentral.com.au/\n';
        scEmailCreateBody += 'Please do not reply to this email. ';
        return scEmailCreateBody;
        }
    } 

    private static String staffCentralEmailBodyInvalidRole {
        get{
        String scEmailCreateBody = 'Dear Alliance,\n';
        scEmailCreateBody += 'This shift has been edited, please login to the supplier portal to ensure this shift is still suitable.\n';
        scEmailCreateBody += 'Shift ID: ' + '311113<https://regis.staffcentral.com.au/Shift/View/251353>\n'; 
        scEmailCreateBody += 'Facility Name: Regis Sandgate - Musgrave/Nursing Home/60 WAKEFIELD STREET SANDGATE QLD 4017\n';
        scEmailCreateBody += 'Award: RN\n';
        scEmailCreateBody += 'Alt Award: EN\n';
        scEmailCreateBody += 'Role: RN\n';
        scEmailCreateBody += 'Alt Role: EN\n';
        scEmailCreateBody += 'Role Description: INVALID ROLE\n';
        scEmailCreateBody += 'Alt Role Description: Enrolled Nurse\n'; 
        scEmailCreateBody += 'Shift Date: 12/12/2024\n';
        scEmailCreateBody += 'Start Time: 08:00\n';
        scEmailCreateBody += 'End Time: 14:00\n';
        scEmailCreateBody += 'Meal break: 30\n';
        scEmailCreateBody += 'Total hours: 5.50\n'; 
        scEmailCreateBody += 'In charge times: \n';
        scEmailCreateBody += 'Allocated Employee: \n';
        scEmailCreateBody += 'Notes and comments: ' + 'RN : at least two (2) years post registration aged care experience or equivalent Note : Employee should present – Original Police Clearance or NDIS clearance\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'Thankyou\n';
        scEmailCreateBody += 'Regis Sandgate - Musgrave\n';
        scEmailCreateBody += 'https://regis.staffcentral.com.au/\n';
        scEmailCreateBody += 'Please do not reply to this email. ';
        return scEmailCreateBody;
        }
    } 


    /*
    * Emprevo Email Body
    */
    private static String emprevoEmailBodyCreate {
        get{
        String scEmailCreateBody = 'We need someone like you to fill a shift that has just become available.\n';
        scEmailCreateBody += '[Emprevo]<https://www.emprevo.com/>.\n';
        scEmailCreateBody += 'Available Shift\n'; 
        scEmailCreateBody += 'Hi Alliance Nursing VIC\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'A new shift has just become available. Check it out and apply before its snapped up.\n';
        scEmailCreateBody += 'Open details in app<https://work.emprevo.com/my-shifts/detail/9382177?expiringToken=e07955a3ea954b5bafd18b7e77f76a70&date=2024-10-16&facility=12753>\n';
        scEmailCreateBody += 'Details\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'ID: ND32111112\n'; 
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'Example Job\n';
        scEmailCreateBody += '01:00 PM to 09:30 PM\n';
        scEmailCreateBody += 'Sat 21/12/24\n';
        scEmailCreateBody += '\n'; 
        scEmailCreateBody += '1 shift available\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'Regis Sandgate - Musgrave/Nursing Home/60 WAKEFIELD STREET SANDGATE QLD 4017\n';
        scEmailCreateBody += 'Contact: P: +61394117286\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'https://work.emprevo.com/my-shifts/detail/9382177?expiringToken=e07955a3ea954b5bafd18b7e77f76a70&date=2024-10-16&facility=12753\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'Cheers,\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'The Emprevo Team\n';
        scEmailCreateBody += 'Need more help?\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'Contact our support team<https://support.emprevo.com/support/tickets/new>\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'This message was sent to vic.bookings@alliancenursing.com.au<mailto:vic.bookings@alliancenursing.com.au>. If you do not wish to receive these email notifications from Emprevo in the future, please unsubscribe<http://help.emprevo.com/> by contacting us from our support page.\n';
        scEmailCreateBody += 'Terms of use<https://www.emprevo.com/terms-of-use/> | Privacy Policy<https://www.emprevo.com/privacy/>';
        return scEmailCreateBody;
        }
    } 

    private static String emprevoEmailBodyInvalidRole {
        get{
        String scEmailCreateBody = 'We need someone like you to fill a shift that has just become available.\n';
        scEmailCreateBody += '[Emprevo]<https://www.emprevo.com/>.\n';
        scEmailCreateBody += 'Available Shift\n'; 
        scEmailCreateBody += 'Hi Alliance Nursing VIC\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'A new shift has just become available. Check it out and apply before its snapped up.\n';
        scEmailCreateBody += 'Open details in app<https://work.emprevo.com/my-shifts/detail/9382177?expiringToken=e07955a3ea954b5bafd18b7e77f76a70&date=2024-10-16&facility=12753>\n';
        scEmailCreateBody += 'Details\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'ID: ND32111112\n'; 
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'INVALID ROLE\n';
        scEmailCreateBody += '01:00 PM to 09:30 PM\n';
        scEmailCreateBody += 'Sat 21/12/24\n';
        scEmailCreateBody += '\n'; 
        scEmailCreateBody += '1 shift available\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'Regis Sandgate - Musgrave/Nursing Home/60 WAKEFIELD STREET SANDGATE QLD 4017\n';
        scEmailCreateBody += 'Contact: P: +61394117286\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'https://work.emprevo.com/my-shifts/detail/9382177?expiringToken=e07955a3ea954b5bafd18b7e77f76a70&date=2024-10-16&facility=12753\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'Cheers,\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'The Emprevo Team\n';
        scEmailCreateBody += 'Need more help?\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'Contact our support team<https://support.emprevo.com/support/tickets/new>\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'This message was sent to vic.bookings@alliancenursing.com.au<mailto:vic.bookings@alliancenursing.com.au>. If you do not wish to receive these email notifications from Emprevo in the future, please unsubscribe<http://help.emprevo.com/> by contacting us from our support page.\n';
        scEmailCreateBody += 'Terms of use<https://www.emprevo.com/terms-of-use/> | Privacy Policy<https://www.emprevo.com/privacy/>';
        return scEmailCreateBody;
        }
    } 

    private static String emprevoEmailBodyCancel {
        get{
        String scEmailCreateBody = 'Shift cancelled.\n';
        scEmailCreateBody += '[Emprevo]<https://www.emprevo.com/>.\n';
        scEmailCreateBody += 'Shift cancelled\n'; 
        scEmailCreateBody += 'Hi Alliance Nursing VIC\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'This shift has been cancelled and you are no longer required to attend this shift. Please contact a manager at the facility if you believe this is in error or have any questions.\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'Shift details\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'ID: 333333\n'; 
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'Example Job\n';
        scEmailCreateBody += '01:00 PM to 09:30 PM\n';
        scEmailCreateBody += 'Sat 21/12/24\n';
        scEmailCreateBody += '\n'; 
        scEmailCreateBody += '1 shift available\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'Regis Sandgate - Musgrave/Nursing Home/60 WAKEFIELD STREET SANDGATE QLD 4017\n';
        scEmailCreateBody += 'Contact: P: +61394117286\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'https://work.emprevo.com/my-shifts/detail/9382177?expiringToken=e07955a3ea954b5bafd18b7e77f76a70&date=2024-10-16&facility=12753\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'Cheers,\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'The Emprevo Team\n';
        scEmailCreateBody += 'Need more help?\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'Contact our support team<https://support.emprevo.com/support/tickets/new>\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'This message was sent to vic.bookings@alliancenursing.com.au<mailto:vic.bookings@alliancenursing.com.au>. If you do not wish to receive these email notifications from Emprevo in the future, please unsubscribe<http://help.emprevo.com/> by contacting us from our support page.\n';
        scEmailCreateBody += 'Terms of use<https://www.emprevo.com/terms-of-use/> | Privacy Policy<https://www.emprevo.com/privacy/>';
        return scEmailCreateBody;
        }
    } 

    private static String emprevoEmailBodyDefaultSite {
        get{
        String scEmailCreateBody = 'We need someone like you to fill a shift that has just become available.\n';
        scEmailCreateBody += '[Emprevo]<https://www.emprevo.com/>.\n';
        scEmailCreateBody += 'Available Shift\n'; 
        scEmailCreateBody += 'Hi Alliance Nursing VIC\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'A new shift has just become available. Check it out and apply before its snapped up.\n';
        scEmailCreateBody += 'Open details in app<https://work.emprevo.com/my-shifts/detail/9382177?expiringToken=e07955a3ea954b5bafd18b7e77f76a70&date=2024-10-16&facility=12753>\n';
        scEmailCreateBody += 'Details\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'ID: ND32111112\n'; 
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'Example Job\n';
        scEmailCreateBody += '01:00 PM to 09:30 PM\n';
        scEmailCreateBody += 'Sat 21/12/24\n';
        scEmailCreateBody += '\n'; 
        scEmailCreateBody += '1 shift available\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'INVALID - Musgrave/Nursing Home/60 WAKEFIELD STREET SANDGATE QLD 4017\n';
        scEmailCreateBody += 'Contact: P: +61394117286\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'https://work.emprevo.com/my-shifts/detail/9382177?expiringToken=e07955a3ea954b5bafd18b7e77f76a70&date=2024-10-16&facility=12753\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'Cheers,\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'The Emprevo Team\n';
        scEmailCreateBody += 'Need more help?\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'Contact our support team<https://support.emprevo.com/support/tickets/new>\n';
        scEmailCreateBody += '\n';
        scEmailCreateBody += 'This message was sent to vic.bookings@alliancenursing.com.au<mailto:vic.bookings@alliancenursing.com.au>. If you do not wish to receive these email notifications from Emprevo in the future, please unsubscribe<http://help.emprevo.com/> by contacting us from our support page.\n';
        scEmailCreateBody += 'Terms of use<https://www.emprevo.com/terms-of-use/> | Privacy Policy<https://www.emprevo.com/privacy/>';
        return scEmailCreateBody;
        }
    } 
}