@isTest
public with sharing class SIM_RouteEOISourcingRoleHandler_Test {

    @TestSetup
    static void setupData(){

        // Create Contact with matching source domain
        Contact c = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com',
            Source_domain__c = 'source'   // <-- must match mapping key
        );
        insert c;

        // Create a Form with routing enabled
        b3f__Form__c form = new b3f__Form__c(
            Name = 'RegForm',
            Parse_CV_on_this_form__c = true,
            CV_Upload_Field_Ref__c = 'CV Upload_a6556',
            Route_EOI_Sourcing_Role_to_Job__c = true  // <-- Critical
        );
        insert form;

        // Create FormResponse referencing the Contact + Form
        b3f__FormResponse__c fr = new b3f__FormResponse__c(
            b3f__Type__c = 'DRAFT',
            b3f__New_Record_ID__c = c.Id,
            b3f__Form__c = form.Id
        );
        insert fr;
    }


    @isTest
    static void testEOIRouting() {

        // Get the existing FormResponse
        b3f__FormResponse__c fr = [
            SELECT Id, b3f__Type__c, b3f__New_Record_ID__c, b3f__Form__c
            FROM b3f__FormResponse__c
            LIMIT 1
        ];

        // Create Branch
        Branch__c branch = new Branch__c(
            Branch_Name__c = 'Test Branch',
            Branch_Code__c = 'TST',
            City__c = 'Test City'
        );
        insert branch;

        // Create Job with RecordTypeId
        Id jobRT = Schema.SObjectType.TR1__Job__c
            .getRecordTypeInfosByName()
            .get('Sourcing Role')
            .getRecordTypeId();

        TR1__Job__c job = new TR1__Job__c(
            Name = 'TestJob',
            Branch__c = branch.Id,
            RecordTypeId = jobRT
        );
        insert job;        

        Test.startTest();

        fr.b3f__Type__c = 'COMPLETE';   // <-- triggers the routing handler
        update fr;

        Test.stopTest();

        // Validate Application was created
        List<TR1__Application_V2__c> apps = [
            SELECT Id, TR1__Applicant__c, TR1__Job__c, TR1__Stage__c
            FROM TR1__Application_V2__c
        ];

        system.debug('Applications created: ' + apps);

        System.assertEquals(1, apps.size(), 'One application should have been created');
        System.assertEquals('Application', apps[0].TR1__Stage__c);
    }
}