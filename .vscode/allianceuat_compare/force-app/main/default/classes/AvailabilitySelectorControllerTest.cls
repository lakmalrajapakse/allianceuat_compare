@isTest
private class AvailabilitySelectorControllerTest {
    @isTest
    static void saveAvailability_givenExistingAvailabilityIsRemovedFromDate_shouldDeleteER() {
        // GIVEN
        Contact candidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert candidate;

        sirenum__Employee_Request__c employeeRequestRecord = new sirenum__Employee_Request__c(
            sirenum__Type__c = Constants.EMPLOYEE_REQUEST_AM_AVAILABLE,
            sirenum__Local_Start_Date__c = Date.newInstance(2025, 1, 1),
            sirenum__Contact__c = candidate.Id
        );
        insert employeeRequestRecord;

        AvailabilitySelectorController.EmployeeRequest empReq = new AvailabilitySelectorController.EmployeeRequest();
        empReq.Available = null;
        empReq.Id = employeeRequestRecord.Id;
        empReq.Day = Date.newInstance(2025, 1, 1);
        empReq.Type = 1;

        List<AvailabilitySelectorController.EmployeeRequest> empReqs = new List<AvailabilitySelectorController.EmployeeRequest>{
            empReq
        };

        List<sirenum__Employee_Request__c> employeeRequests = [
            SELECT Id, sirenum__Type__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
        ];

        Assert.areEqual(1, employeeRequests.size(), '1 Employee Request should exist');

        // WHEN
        AvailabilitySelectorController.saveAvailability(candidate.Id, empReqs);

        // THEN
        employeeRequests = [
            SELECT Id, sirenum__Type__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
        ];

        Assert.areEqual(0, employeeRequests.size(), 'No Employee Requests should exist');
    }

    @isTest
    static void saveAvailability_givenNonExistentAvailabilityIsRemovedFromDate_shouldSkipRecord() {
        // GIVEN
        Contact candidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert candidate;

        AvailabilitySelectorController.EmployeeRequest empReq = new AvailabilitySelectorController.EmployeeRequest();
        empReq.Available = null;
        empReq.Id = null;
        empReq.Day = Date.newInstance(2025, 1, 1);
        empReq.Type = 1;

        List<AvailabilitySelectorController.EmployeeRequest> empReqs = new List<AvailabilitySelectorController.EmployeeRequest>{
            empReq
        };

        List<sirenum__Employee_Request__c> employeeRequests = [
            SELECT Id, sirenum__Type__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
        ];

        Assert.areEqual(0, employeeRequests.size(), 'No Employee Requests should exist');

        // WHEN
        AvailabilitySelectorController.saveAvailability(candidate.Id, empReqs);

        // THEN
        employeeRequests = [
            SELECT Id, sirenum__Type__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
        ];

        Assert.areEqual(0, employeeRequests.size(), 'No Employee Requests should exist');
    }

    @isTest
    static void saveAvailability_givenExgERAndAvailableChangedAndRequestTypeIs0_shouldUpdateERWithAMAvailable() {
        // GIVEN
        Contact candidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert candidate;

        sirenum__Employee_Request__c employeeRequestRecord = new sirenum__Employee_Request__c(
            sirenum__Type__c = Constants.EMPLOYEE_REQUEST_AM_UNAVAILABLE,
            sirenum__Local_Start_Date__c = Date.newInstance(2025, 1, 1),
            sirenum__Contact__c = candidate.Id
        );
        insert employeeRequestRecord;

        AvailabilitySelectorController.EmployeeRequest empReq = new AvailabilitySelectorController.EmployeeRequest();
        empReq.Available = true;
        empReq.Id = employeeRequestRecord.Id;
        empReq.Day = Date.newInstance(2025, 1, 1);
        empReq.Type = 0;

        List<AvailabilitySelectorController.EmployeeRequest> empReqs = new List<AvailabilitySelectorController.EmployeeRequest>{
            empReq
        };

        List<sirenum__Employee_Request__c> employeeRequests = [
            SELECT Id, sirenum__Type__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
        ];

        Assert.areEqual(1, employeeRequests.size(), '1 Employee Request should exist');
        Assert.areEqual(
            Constants.EMPLOYEE_REQUEST_AM_UNAVAILABLE,
            employeeRequests.get(0).sirenum__Type__c,
            'Unexpected value for sirenum__Type__c'
        );

        // WHEN
        AvailabilitySelectorController.saveAvailability(candidate.Id, empReqs);

        // THEN
        employeeRequests = [
            SELECT Id, sirenum__Type__c, sirenum__Local_Start_Date__c, sirenum__Contact__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
        ];

        Assert.areEqual(1, employeeRequests.size(), 'Incorrect number of Employee Requests');

        {
            sirenum__Employee_Request__c actualRecord = employeeRequests.get(0);

            Assert.areEqual(
                Constants.EMPLOYEE_REQUEST_AM_AVAILABLE,
                actualRecord.sirenum__Type__c,
                'Type should have been updated to AM - Available'
            );
            Assert.areEqual(
                Date.newInstance(2025, 1, 1),
                actualRecord.sirenum__Local_Start_Date__c,
                'Unexpected value for sirenum__Local_Start_Date__c'
            );
            Assert.areEqual(candidate.Id, actualRecord.sirenum__Contact__c, 'Unexpected value for sirenum__Contact__c');
        }
    }

    @isTest
    static void saveAvailability_givenNewERAndAvailableAndRequestTypeIs0_shouldCreateERWithAMAvailable() {
        // GIVEN
        Contact candidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert candidate;

        AvailabilitySelectorController.EmployeeRequest empReq = new AvailabilitySelectorController.EmployeeRequest();
        empReq.Available = true;
        empReq.Id = null;
        empReq.Day = Date.newInstance(2025, 1, 1);
        empReq.Type = 0;

        List<AvailabilitySelectorController.EmployeeRequest> empReqs = new List<AvailabilitySelectorController.EmployeeRequest>{
            empReq
        };

        // WHEN
        AvailabilitySelectorController.saveAvailability(candidate.Id, empReqs);

        // THEN
        List<sirenum__Employee_Request__c> employeeRequests = [
            SELECT Id, sirenum__Type__c, sirenum__Local_Start_Date__c, sirenum__Contact__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
        ];

        Assert.areEqual(1, employeeRequests.size(), 'Incorrect number of Employee Requests');

        {
            sirenum__Employee_Request__c actualRecord = employeeRequests.get(0);

            Assert.areEqual(
                Constants.EMPLOYEE_REQUEST_AM_AVAILABLE,
                actualRecord.sirenum__Type__c,
                'Type should have been updated to AM - Available'
            );
            Assert.areEqual(
                Date.newInstance(2025, 1, 1),
                actualRecord.sirenum__Local_Start_Date__c,
                'Unexpected value for sirenum__Local_Start_Date__c'
            );
            Assert.areEqual(candidate.Id, actualRecord.sirenum__Contact__c, 'Unexpected value for sirenum__Contact__c');
        }
    }

    @isTest
    static void saveAvailability_givenERIsNotAvailableAndRequestTypeIs0_shouldCreateERWithAMUnavailable() {
        // GIVEN
        Contact candidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert candidate;

        AvailabilitySelectorController.EmployeeRequest empReq = new AvailabilitySelectorController.EmployeeRequest();
        empReq.Available = false;
        empReq.Id = null;
        empReq.Day = Date.newInstance(2025, 1, 1);
        empReq.Type = 0;

        List<AvailabilitySelectorController.EmployeeRequest> empReqs = new List<AvailabilitySelectorController.EmployeeRequest>{
            empReq
        };

        // WHEN
        AvailabilitySelectorController.saveAvailability(candidate.Id, empReqs);

        // THEN
        List<sirenum__Employee_Request__c> employeeRequests = [
            SELECT Id, sirenum__Type__c, sirenum__Local_Start_Date__c, sirenum__Contact__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
        ];

        Assert.areEqual(1, employeeRequests.size(), 'Incorrect number of Employee Requests');

        {
            sirenum__Employee_Request__c actualRecord = employeeRequests.get(0);

            Assert.areEqual(
                Constants.EMPLOYEE_REQUEST_AM_UNAVAILABLE,
                actualRecord.sirenum__Type__c,
                'Type should have been updated to AM - Available'
            );
            Assert.areEqual(
                Date.newInstance(2025, 1, 1),
                actualRecord.sirenum__Local_Start_Date__c,
                'Unexpected value for sirenum__Local_Start_Date__c'
            );
            Assert.areEqual(candidate.Id, actualRecord.sirenum__Contact__c, 'Unexpected value for sirenum__Contact__c');
        }
    }

    @isTest
    static void saveAvailability_givenERIsAvailableAndRequestTypeIs1_shouldCreateERWithPMAvailable() {
        // GIVEN
        Contact candidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert candidate;

        AvailabilitySelectorController.EmployeeRequest empReq = new AvailabilitySelectorController.EmployeeRequest();
        empReq.Available = true;
        empReq.Id = null;
        empReq.Day = Date.newInstance(2025, 1, 1);
        empReq.Type = 1;

        List<AvailabilitySelectorController.EmployeeRequest> empReqs = new List<AvailabilitySelectorController.EmployeeRequest>{
            empReq
        };

        // WHEN
        AvailabilitySelectorController.saveAvailability(candidate.Id, empReqs);

        // THEN
        List<sirenum__Employee_Request__c> employeeRequests = [
            SELECT Id, sirenum__Type__c, sirenum__Local_Start_Date__c, sirenum__Contact__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
        ];

        Assert.areEqual(1, employeeRequests.size(), 'Incorrect number of Employee Requests');

        {
            sirenum__Employee_Request__c actualRecord = employeeRequests.get(0);

            Assert.areEqual(
                Constants.EMPLOYEE_REQUEST_PM_AVAILABLE,
                actualRecord.sirenum__Type__c,
                'Type should have been updated to AM - Available'
            );
            Assert.areEqual(
                Date.newInstance(2025, 1, 1),
                actualRecord.sirenum__Local_Start_Date__c,
                'Unexpected value for sirenum__Local_Start_Date__c'
            );
            Assert.areEqual(candidate.Id, actualRecord.sirenum__Contact__c, 'Unexpected value for sirenum__Contact__c');
        }
    }

    @isTest
    static void saveAvailability_givenERIsNotAvailableAndRequestTypeIs1_shouldCreateERWithPMUnavailable() {
        // GIVEN
        Contact candidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert candidate;

        AvailabilitySelectorController.EmployeeRequest empReq = new AvailabilitySelectorController.EmployeeRequest();
        empReq.Available = false;
        empReq.Id = null;
        empReq.Day = Date.newInstance(2025, 1, 1);
        empReq.Type = 1;

        List<AvailabilitySelectorController.EmployeeRequest> empReqs = new List<AvailabilitySelectorController.EmployeeRequest>{
            empReq
        };

        // WHEN
        AvailabilitySelectorController.saveAvailability(candidate.Id, empReqs);

        // THEN
        List<sirenum__Employee_Request__c> employeeRequests = [
            SELECT Id, sirenum__Type__c, sirenum__Local_Start_Date__c, sirenum__Contact__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
        ];

        Assert.areEqual(1, employeeRequests.size(), 'Incorrect number of Employee Requests');

        {
            sirenum__Employee_Request__c actualRecord = employeeRequests.get(0);

            Assert.areEqual(
                Constants.EMPLOYEE_REQUEST_PM_UNAVAILABLE,
                actualRecord.sirenum__Type__c,
                'Type should have been updated to AM - Available'
            );
            Assert.areEqual(
                Date.newInstance(2025, 1, 1),
                actualRecord.sirenum__Local_Start_Date__c,
                'Unexpected value for sirenum__Local_Start_Date__c'
            );
            Assert.areEqual(candidate.Id, actualRecord.sirenum__Contact__c, 'Unexpected value for sirenum__Contact__c');
        }
    }

    @isTest
    static void saveAvailability_givenERIsAvailableAndRequestTypeIs2_shouldCreateERWithNDAvailable() {
        // GIVEN
        Contact candidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert candidate;

        AvailabilitySelectorController.EmployeeRequest empReq = new AvailabilitySelectorController.EmployeeRequest();
        empReq.Available = true;
        empReq.Id = null;
        empReq.Day = Date.newInstance(2025, 1, 1);
        empReq.Type = 2;

        List<AvailabilitySelectorController.EmployeeRequest> empReqs = new List<AvailabilitySelectorController.EmployeeRequest>{
            empReq
        };

        // WHEN
        AvailabilitySelectorController.saveAvailability(candidate.Id, empReqs);

        // THEN
        List<sirenum__Employee_Request__c> employeeRequests = [
            SELECT Id, sirenum__Type__c, sirenum__Local_Start_Date__c, sirenum__Contact__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
        ];

        Assert.areEqual(1, employeeRequests.size(), 'Incorrect number of Employee Requests');

        {
            sirenum__Employee_Request__c actualRecord = employeeRequests.get(0);

            Assert.areEqual(
                Constants.EMPLOYEE_REQUEST_ND_AVAILABLE,
                actualRecord.sirenum__Type__c,
                'Type should have been updated to AM - Available'
            );
            Assert.areEqual(
                Date.newInstance(2025, 1, 1),
                actualRecord.sirenum__Local_Start_Date__c,
                'Unexpected value for sirenum__Local_Start_Date__c'
            );
            Assert.areEqual(candidate.Id, actualRecord.sirenum__Contact__c, 'Unexpected value for sirenum__Contact__c');
        }
    }

    @isTest
    static void saveAvailability_givenERIsNotAvailableAndRequestTypeIs2_shouldCreateERWithNDUnavailable() {
        // GIVEN
        Contact candidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert candidate;

        AvailabilitySelectorController.EmployeeRequest empReq = new AvailabilitySelectorController.EmployeeRequest();
        empReq.Available = false;
        empReq.Id = null;
        empReq.Day = Date.newInstance(2025, 1, 1);
        empReq.Type = 2;

        List<AvailabilitySelectorController.EmployeeRequest> empReqs = new List<AvailabilitySelectorController.EmployeeRequest>{
            empReq
        };

        // WHEN
        AvailabilitySelectorController.saveAvailability(candidate.Id, empReqs);

        // THEN
        List<sirenum__Employee_Request__c> employeeRequests = [
            SELECT Id, sirenum__Type__c, sirenum__Local_Start_Date__c, sirenum__Contact__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
        ];

        Assert.areEqual(1, employeeRequests.size(), 'Incorrect number of Employee Requests');

        {
            sirenum__Employee_Request__c actualRecord = employeeRequests.get(0);

            Assert.areEqual(
                Constants.EMPLOYEE_REQUEST_ND_UNAVAILABLE,
                actualRecord.sirenum__Type__c,
                'Type should have been updated to AM - Available'
            );
            Assert.areEqual(
                Date.newInstance(2025, 1, 1),
                actualRecord.sirenum__Local_Start_Date__c,
                'Unexpected value for sirenum__Local_Start_Date__c'
            );
            Assert.areEqual(candidate.Id, actualRecord.sirenum__Contact__c, 'Unexpected value for sirenum__Contact__c');
        }
    }

    @isTest
    static void saveAvailability_givenInvalidER_shouldThrowAuraHandledException() {
        // GIVEN
        Contact candidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert candidate;

        AvailabilitySelectorController.EmployeeRequest empReq = new AvailabilitySelectorController.EmployeeRequest();
        empReq.Available = false;
        empReq.Id = 'THIS_ISNT_A_REAL_ID';
        empReq.Day = Date.newInstance(2025, 1, 1);
        empReq.Type = 100;

        List<AvailabilitySelectorController.EmployeeRequest> empReqs = new List<AvailabilitySelectorController.EmployeeRequest>{
            empReq
        };

        String exType = '';

        // WHEN
        try {
            AvailabilitySelectorController.saveAvailability(candidate.Id, empReqs);
            Assert.fail('Shouldve thrown an AuraHandledException');
        } catch (Exception ex) {
            exType = ex.getTypeName();
        }

        // THEN
        Assert.areEqual('System.AuraHandledException', exType, 'Method shouldve thrown an AuraHandledException');
    }

    @IsTest
    static void getAvailabilityFrom_givenAMAvailableER_shouldReturnMappedToDto() {
        // GIVEN
        Contact candidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert candidate;

        sirenum__Employee_Request__c employeeRequest = new sirenum__Employee_Request__c(
            sirenum__Type__c = Constants.EMPLOYEE_REQUEST_AM_AVAILABLE,
            sirenum__Local_Start_Date__c = Date.newInstance(2025, 1, 2),
            sirenum__Contact__c = candidate.Id
        );
        insert employeeRequest;

        // WHEN
        List<AvailabilitySelectorController.EmployeeRequest> erDtos = AvailabilitySelectorController.getAvailabilityFrom(
            Date.newInstance(2025, 1, 1),
            candidate.Id,
            7
        );

        // THEN
        Assert.areEqual(1, erDtos.size(), 'Shouldve return 1 Dto');

        AvailabilitySelectorController.EmployeeRequest erDto = erDtos.get(0);
        Assert.areEqual(Date.newInstance(2025, 1, 2), erDto.Day, 'Incorrect date set on DTO');
        Assert.areEqual(employeeRequest.Id, erDto.Id, 'Incorrect Id set on DTO');
        Assert.areEqual(true, erDto.Available, 'Incorrect Availability set on DTO');
        Assert.areEqual(0, erDto.Type, 'Incorrect Type set on DTO');
    }

    @IsTest
    static void getAvailabilityFrom_givenPMUnavailableER_shouldReturnMappedToDto() {
        // GIVEN
        Contact candidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert candidate;

        sirenum__Employee_Request__c employeeRequest = new sirenum__Employee_Request__c(
            sirenum__Type__c = Constants.EMPLOYEE_REQUEST_PM_UNAVAILABLE,
            sirenum__Local_Start_Date__c = Date.newInstance(2025, 1, 2),
            sirenum__Contact__c = candidate.Id
        );
        insert employeeRequest;

        // WHEN
        List<AvailabilitySelectorController.EmployeeRequest> erDtos = AvailabilitySelectorController.getAvailabilityFrom(
            Date.newInstance(2025, 1, 1),
            candidate.Id,
            7
        );

        // THEN
        Assert.areEqual(1, erDtos.size(), 'Shouldve return 1 Dto');

        AvailabilitySelectorController.EmployeeRequest erDto = erDtos.get(0);
        Assert.areEqual(Date.newInstance(2025, 1, 2), erDto.Day, 'Incorrect date set on DTO');
        Assert.areEqual(employeeRequest.Id, erDto.Id, 'Incorrect Id set on DTO');
        Assert.areEqual(false, erDto.Available, 'Incorrect Availability set on DTO');
        Assert.areEqual(1, erDto.Type, 'Incorrect Type set on DTO');
    }

    @IsTest
    static void getAvailabilityFrom_givenNDAvailableER_shouldReturnMappedToDto() {
        // GIVEN
        Contact candidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert candidate;

        sirenum__Employee_Request__c employeeRequest = new sirenum__Employee_Request__c(
            sirenum__Type__c = Constants.EMPLOYEE_REQUEST_ND_AVAILABLE,
            sirenum__Local_Start_Date__c = Date.newInstance(2025, 1, 2),
            sirenum__Contact__c = candidate.Id
        );
        insert employeeRequest;

        // WHEN
        List<AvailabilitySelectorController.EmployeeRequest> erDtos = AvailabilitySelectorController.getAvailabilityFrom(
            Date.newInstance(2025, 1, 1),
            candidate.Id,
            7
        );

        // THEN
        Assert.areEqual(1, erDtos.size(), 'Shouldve return 1 Dto');

        AvailabilitySelectorController.EmployeeRequest erDto = erDtos.get(0);
        Assert.areEqual(Date.newInstance(2025, 1, 2), erDto.Day, 'Incorrect date set on DTO');
        Assert.areEqual(employeeRequest.Id, erDto.Id, 'Incorrect Id set on DTO');
        Assert.areEqual(true, erDto.Available, 'Incorrect Availability set on DTO');
        Assert.areEqual(2, erDto.Type, 'Incorrect Type set on DTO');
    }

    @IsTest
    static void getAvailabilityFrom_givenERAfterRange_shouldReturnEmptyList() {
        // GIVEN
        Contact candidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert candidate;

        sirenum__Employee_Request__c employeeRequest = new sirenum__Employee_Request__c(
            sirenum__Type__c = Constants.EMPLOYEE_REQUEST_ND_AVAILABLE,
            sirenum__Local_Start_Date__c = Date.newInstance(2025, 1, 10),
            sirenum__Contact__c = candidate.Id
        );
        insert employeeRequest;

        // WHEN
        List<AvailabilitySelectorController.EmployeeRequest> erDtos = AvailabilitySelectorController.getAvailabilityFrom(
            Date.newInstance(2025, 1, 1),
            candidate.Id,
            8
        );

        // THEN
        Assert.areEqual(0, erDtos.size(), 'Shouldve return no Dtos');
    }

    @IsTest
    static void getAvailabilityFrom_givenERBeforeRange_shouldReturnEmptyList() {
        // GIVEN
        Contact candidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert candidate;

        sirenum__Employee_Request__c employeeRequest = new sirenum__Employee_Request__c(
            sirenum__Type__c = Constants.EMPLOYEE_REQUEST_ND_AVAILABLE,
            sirenum__Local_Start_Date__c = Date.newInstance(2025, 1, 1),
            sirenum__Contact__c = candidate.Id
        );
        insert employeeRequest;

        // WHEN
        List<AvailabilitySelectorController.EmployeeRequest> erDtos = AvailabilitySelectorController.getAvailabilityFrom(
            Date.newInstance(2025, 1, 2),
            candidate.Id,
            7
        );

        // THEN
        Assert.areEqual(0, erDtos.size(), 'Shouldve return no Dtos');
    }

    @IsTest
    static void getAvailabilityFrom_givenEROnStartAndEndDates_shouldReturnDtos() {
        // GIVEN
        Contact candidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert candidate;

        List<sirenum__Employee_Request__c> employeeRequests = new List<sirenum__Employee_Request__c>{
            new sirenum__Employee_Request__c(
                sirenum__Type__c = Constants.EMPLOYEE_REQUEST_AM_AVAILABLE,
                sirenum__Local_Start_Date__c = Date.newInstance(2025, 1, 1),
                sirenum__Contact__c = candidate.Id
            ),
            new sirenum__Employee_Request__c(
                sirenum__Type__c = Constants.EMPLOYEE_REQUEST_ND_AVAILABLE,
                sirenum__Local_Start_Date__c = Date.newInstance(2025, 1, 5),
                sirenum__Contact__c = candidate.Id
            )
        };

        insert employeeRequests;

        // WHEN
        List<AvailabilitySelectorController.EmployeeRequest> erDtos = AvailabilitySelectorController.getAvailabilityFrom(
            Date.newInstance(2025, 1, 1),
            candidate.Id,
            4
        );

        // THEN
        Assert.areEqual(2, erDtos.size(), 'Shouldve return 2 Dtos');
    }

    @IsTest
    static void getAvailabilityFrom_givenERForAnotherContact_shouldReturnNoDtos() {
        // GIVEN
        Contact firstCandidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert firstCandidate;

        List<sirenum__Employee_Request__c> employeeRequests = new List<sirenum__Employee_Request__c>{
            new sirenum__Employee_Request__c(
                sirenum__Type__c = Constants.EMPLOYEE_REQUEST_AM_AVAILABLE,
                sirenum__Local_Start_Date__c = Date.newInstance(2025, 1, 1),
                sirenum__Contact__c = firstCandidate.Id
            ),
            new sirenum__Employee_Request__c(
                sirenum__Type__c = Constants.EMPLOYEE_REQUEST_ND_AVAILABLE,
                sirenum__Local_Start_Date__c = Date.newInstance(2025, 1, 5),
                sirenum__Contact__c = firstCandidate.Id
            )
        };

        insert employeeRequests;

        Contact selectedCandidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert selectedCandidate;

        // WHEN
        List<AvailabilitySelectorController.EmployeeRequest> erDtos = AvailabilitySelectorController.getAvailabilityFrom(
            Date.newInstance(2025, 1, 1),
            selectedCandidate.Id,
            4
        );

        // THEN
        Assert.areEqual(0, erDtos.size(), 'Should return no Dtos');
    }
}