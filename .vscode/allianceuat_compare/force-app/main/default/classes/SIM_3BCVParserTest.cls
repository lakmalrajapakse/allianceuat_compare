@isTest
public class SIM_3BCVParserTest {

    Public static b3f__FormResponse__c formResponse;
    Public static Id contactId;
    Public static Boolean forceErrorInTest = false;

    @TestSetup
    static void setupData(){

        // Create a contact with matching Source_domain__c
        Contact c = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com',
            Source_domain__c = 'source'
        );
        insert c;

        b3f__Form__c form = new b3f__Form__c(
            Name = 'RegForm',
            Parse_CV_on_this_form__c = true,
            CV_Upload_Field_Ref__c = 'CV Upload_a6556',
            Route_EOI_Sourcing_Role_to_Job__c = true
        );
        insert form;

        b3f__FormResponse__c formResponse = new b3f__FormResponse__c(
            b3f__Type__c = 'DRAFT',
            b3f__New_Record_ID__c = c.Id,
            b3f__Form__c = form.id
        );
        insert formResponse;

        // Create ContentVersion, which will create ContentDocument
        ContentVersion version = new ContentVersion(
            Title = 'Response.json',
            PathOnClient = 'Response.json',
            VersionData = Blob.valueOf('{"CV Upload_a6556":[{"name":"IMG_2166.png","type":"image/png","content":"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAABSgAAAs0CAIAAAAE2BViAAAAAXNSR0IArs4c6QAAAPplWElmTU0AKgAAAAgABwEOAAIAAAALAAAAYgESAAMAAAABAAEAAAEaAAUAAAABAAAAbgEbAAUAAAABAAAAdgEoAAMAAAABAAIAAAEyAAIAAAAUAAAAfodpAAQAAAABAAAAkgAAAABTY3JlZW5zaG90AAAAAACQAAAAAQAAAJAAAAABMjAyNjowMjoyNiAwOTo0ODo1NQAABZADAAIAAAAUAAAA1JKGAAcAAAASAAAA6KABAAMAAAABAAEAAKACAAQAAAABAAAFKKADAAQAAAABAAALNAAAAAAyMDI2OjAyOjI2IDA5OjQ4OjU1AEFTQ0lJAAAAU2NyZWVuc2hvdBSlCV4AAAAJcEhZcwAAFiUAABYlAUlSJPAAAAOjaVRYdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA2LjAuMCI+CiAgIDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI"}]}'),
            FirstPublishLocationId = formResponse.Id // Associate ContentDocument with the FormResponse
        );
        insert version; 

        Branch__c branch = new Branch__c(Branch_Name__c = 'Test Branch', Branch_Code__c = 'TST', City__c = 'Test City');
        insert branch;
        
        // Create a Job
        Id jobRT = Schema.SObjectType.TR1__Job__c.getRecordTypeInfosByName().get('Sourcing Role').getRecordTypeId();
        TR1__Job__c testJob = new TR1__Job__c();
        testJob.Name = 'TestJob';
        testJob.RecordTypeId = jobRT;
        testJob.Branch__c = branch.Id;
        insert testJob;


    }

    @isTest
    static void testSendCVToParser() {

        // Update the Response To Complete
        List<b3f__FormResponse__c> formResponseList = [SELECT Id, b3f__Type__c, b3f__New_Record_ID__c, b3f__Form__c FROM b3f__FormResponse__c];
        formResponse = formResponseList[0];
        Test.startTest();
        formResponse.b3f__Type__c = 'COMPLETE';
        update formResponse;        
        try {
            SIM_3BCVParser.sendCVToParser(new List<List<b3f__FormResponse__c>>{new List<b3f__FormResponse__c>{formResponse}});
        }catch (Exception e) {

        }
        Test.stopTest();
        
        
    }    
}