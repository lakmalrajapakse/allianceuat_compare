@isTest
private class CandidateAvailabilityTriggerHandlerTest {
    @isTest
    static void onAfterInsertAll_givenTypeThatIsntMappedToEmployeeRequests_doesNothing() {
        // GIVEN
        Contact candidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert candidate;

        TR1__Candidate_Availability__c candidateAvailability = new TR1__Candidate_Availability__c(
            TR1__Type__c = 'Holiday',
            TR1__Start_Date__c = Date.newInstance(2025, 1, 1),
            TR1__End_Date__c = Date.newInstance(2025, 1, 1),
            TR1__Candidate__c = candidate.Id
        );

        // WHEN
        insert candidateAvailability;

        // THEN
        List<sirenum__Employee_Request__c> employeeRequests = [
            SELECT Id, sirenum__Type__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
        ];

        Assert.areEqual(
            0,
            employeeRequests.size(),
            'No Employee Requests should exist for this Candidate Availability Type'
        );
    }

    @isTest
    static void onAfterInsertAll_givenAvailableTypeOnCandidateAvailability_creates3EmployeeRequests() {
        // GIVEN
        Contact candidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert candidate;

        TR1__Candidate_Availability__c candidateAvailability = new TR1__Candidate_Availability__c(
            TR1__Type__c = 'Available',
            TR1__Start_Date__c = Date.newInstance(2025, 1, 1),
            TR1__End_Date__c = Date.newInstance(2025, 1, 1),
            TR1__Candidate__c = candidate.Id
        );

        // WHEN
        insert candidateAvailability;

        // THEN
        List<sirenum__Employee_Request__c> employeeRequests = [
            SELECT Candidate_Availability__c, sirenum__Type__c, sirenum__Local_Start_Date__c, sirenum__Contact__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
            ORDER BY sirenum__Type__c ASC
        ];

        Assert.areEqual(
            3,
            employeeRequests.size(),
            'Incorrect number of Employee Requests when inserting Candidate Availability'
        );

        {
            sirenum__Employee_Request__c actualRecord = employeeRequests.get(0);

            Assert.areEqual(
                candidateAvailability.Id,
                actualRecord.Candidate_Availability__c,
                'Unexpected value for Candidate_Availability__c'
            );
            Assert.areEqual(
                Constants.EMPLOYEE_REQUEST_AM_AVAILABLE,
                actualRecord.sirenum__Type__c,
                'Unexpected value for sirenum__Type__c'
            );
            Assert.areEqual(
                Date.newInstance(2025, 1, 1),
                actualRecord.sirenum__Local_Start_Date__c,
                'Unexpected value for sirenum__Local_Start_Date__c'
            );
            Assert.areEqual(candidate.Id, actualRecord.sirenum__Contact__c, 'Unexpected value for sirenum__Contact__c');
        }

        {
            sirenum__Employee_Request__c actualRecord = employeeRequests.get(1);

            Assert.areEqual(
                candidateAvailability.Id,
                actualRecord.Candidate_Availability__c,
                'Unexpected value for Candidate_Availability__c'
            );
            Assert.areEqual(
                Constants.EMPLOYEE_REQUEST_PM_AVAILABLE,
                actualRecord.sirenum__Type__c,
                'Unexpected value for sirenum__Type__c'
            );
            Assert.areEqual(
                Date.newInstance(2025, 1, 1),
                actualRecord.sirenum__Local_Start_Date__c,
                'Unexpected value for sirenum__Local_Start_Date__c'
            );
            Assert.areEqual(candidate.Id, actualRecord.sirenum__Contact__c, 'Unexpected value for sirenum__Contact__c');
        }

        {
            sirenum__Employee_Request__c actualRecord = employeeRequests.get(2);

            Assert.areEqual(
                candidateAvailability.Id,
                actualRecord.Candidate_Availability__c,
                'Unexpected value for Candidate_Availability__c'
            );
            Assert.areEqual(
                Constants.EMPLOYEE_REQUEST_ND_AVAILABLE,
                actualRecord.sirenum__Type__c,
                'Unexpected value for sirenum__Type__c'
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
    static void onAfterInsertAll_givenUnavailableTypeOnCandidateAvailability_creates3EmployeeRequests() {
        // GIVEN
        Contact candidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert candidate;

        TR1__Candidate_Availability__c candidateAvailability = new TR1__Candidate_Availability__c(
            TR1__Type__c = 'Unavailable',
            TR1__Start_Date__c = Date.newInstance(2025, 1, 1),
            TR1__End_Date__c = Date.newInstance(2025, 1, 1),
            TR1__Candidate__c = candidate.Id
        );

        // WHEN
        insert candidateAvailability;

        // THEN
        List<sirenum__Employee_Request__c> employeeRequests = [
            SELECT Candidate_Availability__c, sirenum__Type__c, sirenum__Local_Start_Date__c, sirenum__Contact__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
            ORDER BY sirenum__Type__c ASC
        ];

        Assert.areEqual(
            3,
            employeeRequests.size(),
            'Incorrect number of Employee Requests when inserting Candidate Availability'
        );

        {
            sirenum__Employee_Request__c actualRecord = employeeRequests.get(0);

            Assert.areEqual(
                candidateAvailability.Id,
                actualRecord.Candidate_Availability__c,
                'Unexpected value for Candidate_Availability__c'
            );
            Assert.areEqual(
                Constants.EMPLOYEE_REQUEST_AM_UNAVAILABLE,
                actualRecord.sirenum__Type__c,
                'Unexpected value for sirenum__Type__c'
            );
            Assert.areEqual(
                Date.newInstance(2025, 1, 1),
                actualRecord.sirenum__Local_Start_Date__c,
                'Unexpected value for sirenum__Local_Start_Date__c'
            );
            Assert.areEqual(candidate.Id, actualRecord.sirenum__Contact__c, 'Unexpected value for sirenum__Contact__c');
        }

        {
            sirenum__Employee_Request__c actualRecord = employeeRequests.get(1);

            Assert.areEqual(
                candidateAvailability.Id,
                actualRecord.Candidate_Availability__c,
                'Unexpected value for Candidate_Availability__c'
            );
            Assert.areEqual(
                Constants.EMPLOYEE_REQUEST_PM_UNAVAILABLE,
                actualRecord.sirenum__Type__c,
                'Unexpected value for sirenum__Type__c'
            );
            Assert.areEqual(
                Date.newInstance(2025, 1, 1),
                actualRecord.sirenum__Local_Start_Date__c,
                'Unexpected value for sirenum__Local_Start_Date__c'
            );
            Assert.areEqual(candidate.Id, actualRecord.sirenum__Contact__c, 'Unexpected value for sirenum__Contact__c');
        }

        {
            sirenum__Employee_Request__c actualRecord = employeeRequests.get(2);

            Assert.areEqual(
                candidateAvailability.Id,
                actualRecord.Candidate_Availability__c,
                'Unexpected value for Candidate_Availability__c'
            );
            Assert.areEqual(
                Constants.EMPLOYEE_REQUEST_ND_UNAVAILABLE,
                actualRecord.sirenum__Type__c,
                'Unexpected value for sirenum__Type__c'
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
    static void onAfterInsertAll_givenScheduledTypeOnCandidateAvailability_creates1EmployeeRequest() {
        // GIVEN
        Contact candidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert candidate;

        TR1__Candidate_Availability__c candidateAvailability = new TR1__Candidate_Availability__c(
            TR1__Type__c = 'Scheduled',
            TR1__Start_Date__c = Date.newInstance(2025, 1, 1),
            TR1__End_Date__c = Date.newInstance(2025, 1, 1),
            TR1__Candidate__c = candidate.Id
        );

        // WHEN
        insert candidateAvailability;

        // THEN
        List<sirenum__Employee_Request__c> employeeRequests = [
            SELECT
                Candidate_Availability__c,
                sirenum__Type__c,
                sirenum__Local_Start_Date__c,
                sirenum__Contact__c,
                sirenum__Availability__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
            ORDER BY sirenum__Type__c ASC
        ];

        Assert.areEqual(
            1,
            employeeRequests.size(),
            'Incorrect number of Employee Requests when inserting Candidate Availability'
        );

        {
            sirenum__Employee_Request__c actualRecord = employeeRequests.get(0);

            Assert.areEqual(
                candidateAvailability.Id,
                actualRecord.Candidate_Availability__c,
                'Unexpected value for Candidate_Availability__c'
            );
            Assert.areEqual(
                Constants.EMPLOYEE_REQUEST_SCHEDULED_ON_CONTRACT,
                actualRecord.sirenum__Type__c,
                'Unexpected value for sirenum__Type__c'
            );
            Assert.areEqual(
                Date.newInstance(2025, 1, 1),
                actualRecord.sirenum__Local_Start_Date__c,
                'Unexpected value for sirenum__Local_Start_Date__c'
            );
            Assert.areEqual(
                false,
                actualRecord.sirenum__Availability__c,
                'Should be false when Type is Scheduled on Contract'
            );
            Assert.areEqual(candidate.Id, actualRecord.sirenum__Contact__c, 'Unexpected value for sirenum__Contact__c');
        }
    }

    @isTest
    static void onAfterUpdateAll_givenUpdatedCAWithUnmappedType_doesNotUpdateERs() {
        // GIVEN
        Contact candidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert candidate;

        TR1__Candidate_Availability__c candidateAvailability = new TR1__Candidate_Availability__c(
            TR1__Type__c = 'Holiday',
            TR1__Start_Date__c = Date.newInstance(2025, 1, 1),
            TR1__End_Date__c = Date.newInstance(2025, 1, 1),
            TR1__Candidate__c = candidate.Id
        );

        insert candidateAvailability;

        List<sirenum__Employee_Request__c> employeeRequests = [
            SELECT Id, sirenum__Type__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
        ];

        Assert.areEqual(
            0,
            employeeRequests.size(),
            'No Employee Requests should exist for this Candidate Availability Type'
        );

        // WHEN
        candidateAvailability.TR1__Type__c = 'Interview';
        update candidateAvailability;

        // THEN
        Assert.areEqual(
            0,
            employeeRequests.size(),
            'No Employee Requests should exist for this Candidate Availability Type'
        );
    }

    @isTest
    static void onAfterUpdateAll_givenUpdatedCATypeFromAvailableToUnavailable_updatesERType() {
        // GIVEN
        Contact candidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert candidate;

        TR1__Candidate_Availability__c candidateAvailability = new TR1__Candidate_Availability__c(
            TR1__Type__c = 'Available',
            TR1__Start_Date__c = Date.newInstance(2025, 1, 1),
            TR1__End_Date__c = Date.newInstance(2025, 1, 1),
            TR1__Candidate__c = candidate.Id
        );

        insert candidateAvailability;

        List<sirenum__Employee_Request__c> employeeRequests = [
            SELECT Id, sirenum__Type__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
        ];

        Assert.areEqual(
            3,
            employeeRequests.size(),
            '3 Employee Requests should exist for this Candidate Availability Type'
        );

        // WHEN
        candidateAvailability.TR1__Type__c = 'Unavailable';
        update candidateAvailability;

        // THEN
        employeeRequests = [
            SELECT Candidate_Availability__c, sirenum__Type__c, sirenum__Local_Start_Date__c, sirenum__Contact__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
            ORDER BY sirenum__Type__c ASC
        ];

        Assert.areEqual(3, employeeRequests.size(), 'Incorrect number of Employee Requests fetched');

        {
            sirenum__Employee_Request__c actualRecord = employeeRequests.get(0);

            Assert.areEqual(
                candidateAvailability.Id,
                actualRecord.Candidate_Availability__c,
                'Unexpected value for Candidate_Availability__c'
            );
            Assert.areEqual(
                Constants.EMPLOYEE_REQUEST_AM_UNAVAILABLE,
                actualRecord.sirenum__Type__c,
                'Unexpected value for sirenum__Type__c'
            );
            Assert.areEqual(
                Date.newInstance(2025, 1, 1),
                actualRecord.sirenum__Local_Start_Date__c,
                'Unexpected value for sirenum__Local_Start_Date__c'
            );
            Assert.areEqual(candidate.Id, actualRecord.sirenum__Contact__c, 'Unexpected value for sirenum__Contact__c');
        }

        {
            sirenum__Employee_Request__c actualRecord = employeeRequests.get(1);

            Assert.areEqual(
                candidateAvailability.Id,
                actualRecord.Candidate_Availability__c,
                'Unexpected value for Candidate_Availability__c'
            );
            Assert.areEqual(
                Constants.EMPLOYEE_REQUEST_PM_UNAVAILABLE,
                actualRecord.sirenum__Type__c,
                'Unexpected value for sirenum__Type__c'
            );
            Assert.areEqual(
                Date.newInstance(2025, 1, 1),
                actualRecord.sirenum__Local_Start_Date__c,
                'Unexpected value for sirenum__Local_Start_Date__c'
            );
            Assert.areEqual(candidate.Id, actualRecord.sirenum__Contact__c, 'Unexpected value for sirenum__Contact__c');
        }

        {
            sirenum__Employee_Request__c actualRecord = employeeRequests.get(2);

            Assert.areEqual(
                candidateAvailability.Id,
                actualRecord.Candidate_Availability__c,
                'Unexpected value for Candidate_Availability__c'
            );
            Assert.areEqual(
                Constants.EMPLOYEE_REQUEST_ND_UNAVAILABLE,
                actualRecord.sirenum__Type__c,
                'Unexpected value for sirenum__Type__c'
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
    static void onAfterUpdateAll_givenUpdatedCATypeFromUnavailableToAvailable_updatesERType() {
        // GIVEN
        Contact candidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert candidate;

        TR1__Candidate_Availability__c candidateAvailability = new TR1__Candidate_Availability__c(
            TR1__Type__c = 'Unavailable',
            TR1__Start_Date__c = Date.newInstance(2025, 1, 1),
            TR1__End_Date__c = Date.newInstance(2025, 1, 1),
            TR1__Candidate__c = candidate.Id
        );

        insert candidateAvailability;

        List<sirenum__Employee_Request__c> employeeRequests = [
            SELECT Id, sirenum__Type__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
        ];

        Assert.areEqual(
            3,
            employeeRequests.size(),
            '3 Employee Requests should exist for this Candidate Availability Type'
        );

        // WHEN
        candidateAvailability.TR1__Type__c = 'Available';
        update candidateAvailability;

        // THEN
        employeeRequests = [
            SELECT Candidate_Availability__c, sirenum__Type__c, sirenum__Local_Start_Date__c, sirenum__Contact__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
            ORDER BY sirenum__Type__c ASC
        ];

        Assert.areEqual(3, employeeRequests.size(), 'Incorrect number of Employee Requests fetched');

        {
            sirenum__Employee_Request__c actualRecord = employeeRequests.get(0);

            Assert.areEqual(
                candidateAvailability.Id,
                actualRecord.Candidate_Availability__c,
                'Unexpected value for Candidate_Availability__c'
            );
            Assert.areEqual(
                Constants.EMPLOYEE_REQUEST_AM_AVAILABLE,
                actualRecord.sirenum__Type__c,
                'Unexpected value for sirenum__Type__c'
            );
            Assert.areEqual(
                Date.newInstance(2025, 1, 1),
                actualRecord.sirenum__Local_Start_Date__c,
                'Unexpected value for sirenum__Local_Start_Date__c'
            );
            Assert.areEqual(candidate.Id, actualRecord.sirenum__Contact__c, 'Unexpected value for sirenum__Contact__c');
        }

        {
            sirenum__Employee_Request__c actualRecord = employeeRequests.get(1);

            Assert.areEqual(
                candidateAvailability.Id,
                actualRecord.Candidate_Availability__c,
                'Unexpected value for Candidate_Availability__c'
            );
            Assert.areEqual(
                Constants.EMPLOYEE_REQUEST_PM_AVAILABLE,
                actualRecord.sirenum__Type__c,
                'Unexpected value for sirenum__Type__c'
            );
            Assert.areEqual(
                Date.newInstance(2025, 1, 1),
                actualRecord.sirenum__Local_Start_Date__c,
                'Unexpected value for sirenum__Local_Start_Date__c'
            );
            Assert.areEqual(candidate.Id, actualRecord.sirenum__Contact__c, 'Unexpected value for sirenum__Contact__c');
        }

        {
            sirenum__Employee_Request__c actualRecord = employeeRequests.get(2);

            Assert.areEqual(
                candidateAvailability.Id,
                actualRecord.Candidate_Availability__c,
                'Unexpected value for Candidate_Availability__c'
            );
            Assert.areEqual(
                Constants.EMPLOYEE_REQUEST_ND_AVAILABLE,
                actualRecord.sirenum__Type__c,
                'Unexpected value for sirenum__Type__c'
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
    static void onAfterUpdateAll_givenUpdatedCATypeFromAvailableToHoliday_deletesERs() {
        // GIVEN
        Contact candidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert candidate;

        TR1__Candidate_Availability__c candidateAvailability = new TR1__Candidate_Availability__c(
            TR1__Type__c = 'Available',
            TR1__Start_Date__c = Date.newInstance(2025, 1, 1),
            TR1__End_Date__c = Date.newInstance(2025, 1, 1),
            TR1__Candidate__c = candidate.Id
        );

        insert candidateAvailability;

        List<sirenum__Employee_Request__c> employeeRequests = [
            SELECT Id, sirenum__Type__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
        ];

        Assert.areEqual(
            3,
            employeeRequests.size(),
            '3 Employee Requests should exist for this Candidate Availability Type'
        );

        // WHEN
        candidateAvailability.TR1__Type__c = 'Holiday';
        update candidateAvailability;

        // THEN
        employeeRequests = [
            SELECT Candidate_Availability__c, sirenum__Type__c, sirenum__Local_Start_Date__c, sirenum__Contact__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
            ORDER BY sirenum__Type__c ASC
        ];

        Assert.areEqual(0, employeeRequests.size(), 'Incorrect number of Employee Requests fetched');
    }

    @isTest
    static void onAfterUpdateAll_givenUpdatedCATypeFromHolidayToAvailable_createsERs() {
        // GIVEN
        Contact candidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert candidate;

        TR1__Candidate_Availability__c candidateAvailability = new TR1__Candidate_Availability__c(
            TR1__Type__c = 'Holiday',
            TR1__Start_Date__c = Date.newInstance(2025, 1, 1),
            TR1__End_Date__c = Date.newInstance(2025, 1, 1),
            TR1__Candidate__c = candidate.Id
        );

        insert candidateAvailability;

        List<sirenum__Employee_Request__c> employeeRequests = [
            SELECT Id, sirenum__Type__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
        ];

        Assert.areEqual(0, employeeRequests.size(), 'Incorrect number of Employee Requests fetched');

        // WHEN
        candidateAvailability.TR1__Type__c = 'Available';
        update candidateAvailability;

        // THEN
        employeeRequests = [
            SELECT Candidate_Availability__c, sirenum__Type__c, sirenum__Local_Start_Date__c, sirenum__Contact__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
            ORDER BY sirenum__Type__c ASC
        ];

        Assert.areEqual(3, employeeRequests.size(), 'Incorrect number of Employee Requests fetched');

        {
            sirenum__Employee_Request__c actualRecord = employeeRequests.get(0);

            Assert.areEqual(
                candidateAvailability.Id,
                actualRecord.Candidate_Availability__c,
                'Unexpected value for Candidate_Availability__c'
            );
            Assert.areEqual(
                Constants.EMPLOYEE_REQUEST_AM_AVAILABLE,
                actualRecord.sirenum__Type__c,
                'Unexpected value for sirenum__Type__c'
            );
            Assert.areEqual(
                Date.newInstance(2025, 1, 1),
                actualRecord.sirenum__Local_Start_Date__c,
                'Unexpected value for sirenum__Local_Start_Date__c'
            );
            Assert.areEqual(candidate.Id, actualRecord.sirenum__Contact__c, 'Unexpected value for sirenum__Contact__c');
        }

        {
            sirenum__Employee_Request__c actualRecord = employeeRequests.get(1);

            Assert.areEqual(
                candidateAvailability.Id,
                actualRecord.Candidate_Availability__c,
                'Unexpected value for Candidate_Availability__c'
            );
            Assert.areEqual(
                Constants.EMPLOYEE_REQUEST_PM_AVAILABLE,
                actualRecord.sirenum__Type__c,
                'Unexpected value for sirenum__Type__c'
            );
            Assert.areEqual(
                Date.newInstance(2025, 1, 1),
                actualRecord.sirenum__Local_Start_Date__c,
                'Unexpected value for sirenum__Local_Start_Date__c'
            );
            Assert.areEqual(candidate.Id, actualRecord.sirenum__Contact__c, 'Unexpected value for sirenum__Contact__c');
        }

        {
            sirenum__Employee_Request__c actualRecord = employeeRequests.get(2);

            Assert.areEqual(
                candidateAvailability.Id,
                actualRecord.Candidate_Availability__c,
                'Unexpected value for Candidate_Availability__c'
            );
            Assert.areEqual(
                Constants.EMPLOYEE_REQUEST_ND_AVAILABLE,
                actualRecord.sirenum__Type__c,
                'Unexpected value for sirenum__Type__c'
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
    static void onAfterUpdateAll_givenUpdatedCATypeFromAvailableToScheduled_removes3ERsAndCreates1ER() {
        // GIVEN
        Contact candidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert candidate;

        TR1__Candidate_Availability__c candidateAvailability = new TR1__Candidate_Availability__c(
            TR1__Type__c = 'Available',
            TR1__Start_Date__c = Date.newInstance(2025, 1, 1),
            TR1__End_Date__c = Date.newInstance(2025, 1, 1),
            TR1__Candidate__c = candidate.Id
        );

        insert candidateAvailability;

        List<sirenum__Employee_Request__c> employeeRequests = [
            SELECT Id, sirenum__Type__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
        ];

        Assert.areEqual(3, employeeRequests.size(), 'Incorrect number of Employee Requests fetched');

        // WHEN
        candidateAvailability.TR1__Type__c = 'Scheduled';
        update candidateAvailability;

        // THEN
        employeeRequests = [
            SELECT
                Candidate_Availability__c,
                sirenum__Type__c,
                sirenum__Local_Start_Date__c,
                sirenum__Contact__c,
                sirenum__Availability__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
            ORDER BY sirenum__Type__c ASC
        ];

        Assert.areEqual(1, employeeRequests.size(), 'Incorrect number of Employee Requests fetched');

        {
            sirenum__Employee_Request__c actualRecord = employeeRequests.get(0);

            Assert.areEqual(
                candidateAvailability.Id,
                actualRecord.Candidate_Availability__c,
                'Unexpected value for Candidate_Availability__c'
            );
            Assert.areEqual(
                Constants.EMPLOYEE_REQUEST_SCHEDULED_ON_CONTRACT,
                actualRecord.sirenum__Type__c,
                'Unexpected value for sirenum__Type__c'
            );
            Assert.areEqual(
                Date.newInstance(2025, 1, 1),
                actualRecord.sirenum__Local_Start_Date__c,
                'Unexpected value for sirenum__Local_Start_Date__c'
            );
            Assert.areEqual(
                false,
                actualRecord.sirenum__Availability__c,
                'Should be false when Type is Scheduled on Contract'
            );
            Assert.areEqual(candidate.Id, actualRecord.sirenum__Contact__c, 'Unexpected value for sirenum__Contact__c');
        }
    }

    @isTest
    static void onAfterUpdateAll_givenUpdatedCATypeFromScheduledToAvailable_removes1ERAndCreates3ERs() {
        // GIVEN
        Contact candidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert candidate;

        TR1__Candidate_Availability__c candidateAvailability = new TR1__Candidate_Availability__c(
            TR1__Type__c = 'Scheduled',
            TR1__Start_Date__c = Date.newInstance(2025, 1, 1),
            TR1__End_Date__c = Date.newInstance(2025, 1, 1),
            TR1__Candidate__c = candidate.Id
        );

        insert candidateAvailability;

        List<sirenum__Employee_Request__c> employeeRequests = [
            SELECT Id, sirenum__Type__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
        ];

        Assert.areEqual(1, employeeRequests.size(), 'Incorrect number of Employee Requests fetched');

        // WHEN
        candidateAvailability.TR1__Type__c = 'Available';
        update candidateAvailability;

        // THEN
        employeeRequests = [
            SELECT Candidate_Availability__c, sirenum__Type__c, sirenum__Local_Start_Date__c, sirenum__Contact__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
            ORDER BY sirenum__Type__c ASC
        ];

        Assert.areEqual(3, employeeRequests.size(), 'Incorrect number of Employee Requests fetched');

        {
            sirenum__Employee_Request__c actualRecord = employeeRequests.get(0);

            Assert.areEqual(
                candidateAvailability.Id,
                actualRecord.Candidate_Availability__c,
                'Unexpected value for Candidate_Availability__c'
            );
            Assert.areEqual(
                Constants.EMPLOYEE_REQUEST_AM_AVAILABLE,
                actualRecord.sirenum__Type__c,
                'Unexpected value for sirenum__Type__c'
            );
            Assert.areEqual(
                Date.newInstance(2025, 1, 1),
                actualRecord.sirenum__Local_Start_Date__c,
                'Unexpected value for sirenum__Local_Start_Date__c'
            );
            Assert.areEqual(candidate.Id, actualRecord.sirenum__Contact__c, 'Unexpected value for sirenum__Contact__c');
        }

        {
            sirenum__Employee_Request__c actualRecord = employeeRequests.get(1);

            Assert.areEqual(
                candidateAvailability.Id,
                actualRecord.Candidate_Availability__c,
                'Unexpected value for Candidate_Availability__c'
            );
            Assert.areEqual(
                Constants.EMPLOYEE_REQUEST_PM_AVAILABLE,
                actualRecord.sirenum__Type__c,
                'Unexpected value for sirenum__Type__c'
            );
            Assert.areEqual(
                Date.newInstance(2025, 1, 1),
                actualRecord.sirenum__Local_Start_Date__c,
                'Unexpected value for sirenum__Local_Start_Date__c'
            );
            Assert.areEqual(candidate.Id, actualRecord.sirenum__Contact__c, 'Unexpected value for sirenum__Contact__c');
        }

        {
            sirenum__Employee_Request__c actualRecord = employeeRequests.get(2);

            Assert.areEqual(
                candidateAvailability.Id,
                actualRecord.Candidate_Availability__c,
                'Unexpected value for Candidate_Availability__c'
            );
            Assert.areEqual(
                Constants.EMPLOYEE_REQUEST_ND_AVAILABLE,
                actualRecord.sirenum__Type__c,
                'Unexpected value for sirenum__Type__c'
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
    static void onAfterUpdateAll_givenUpdatedCATypeFromHolidayToScheduled_creates1ER() {
        // GIVEN
        Contact candidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert candidate;

        TR1__Candidate_Availability__c candidateAvailability = new TR1__Candidate_Availability__c(
            TR1__Type__c = 'Holiday',
            TR1__Start_Date__c = Date.newInstance(2025, 1, 1),
            TR1__End_Date__c = Date.newInstance(2025, 1, 1),
            TR1__Candidate__c = candidate.Id
        );

        insert candidateAvailability;

        List<sirenum__Employee_Request__c> employeeRequests = [
            SELECT Id, sirenum__Type__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
        ];

        Assert.areEqual(0, employeeRequests.size(), 'Incorrect number of Employee Requests fetched');

        // WHEN
        candidateAvailability.TR1__Type__c = 'Scheduled';
        update candidateAvailability;

        // THEN
        employeeRequests = [
            SELECT Candidate_Availability__c, sirenum__Type__c, sirenum__Local_Start_Date__c, sirenum__Contact__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
            ORDER BY sirenum__Type__c ASC
        ];

        Assert.areEqual(1, employeeRequests.size(), 'Incorrect number of Employee Requests fetched');

        {
            sirenum__Employee_Request__c actualRecord = employeeRequests.get(0);

            Assert.areEqual(
                candidateAvailability.Id,
                actualRecord.Candidate_Availability__c,
                'Unexpected value for Candidate_Availability__c'
            );
            Assert.areEqual(
                Constants.EMPLOYEE_REQUEST_SCHEDULED_ON_CONTRACT,
                actualRecord.sirenum__Type__c,
                'Unexpected value for sirenum__Type__c'
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
    static void onAfterUpdateAll_givenUpdatedCATypeFromScheduledToHoliday_deletes1ER() {
        // GIVEN
        Contact candidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert candidate;

        TR1__Candidate_Availability__c candidateAvailability = new TR1__Candidate_Availability__c(
            TR1__Type__c = 'Scheduled',
            TR1__Start_Date__c = Date.newInstance(2025, 1, 1),
            TR1__End_Date__c = Date.newInstance(2025, 1, 1),
            TR1__Candidate__c = candidate.Id
        );

        insert candidateAvailability;

        List<sirenum__Employee_Request__c> employeeRequests = [
            SELECT Id, sirenum__Type__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
        ];

        Assert.areEqual(1, employeeRequests.size(), 'Incorrect number of Employee Requests fetched');

        // WHEN
        candidateAvailability.TR1__Type__c = 'Holiday';
        update candidateAvailability;

        // THEN
        employeeRequests = [
            SELECT Candidate_Availability__c, sirenum__Type__c, sirenum__Local_Start_Date__c, sirenum__Contact__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
            ORDER BY sirenum__Type__c ASC
        ];

        Assert.areEqual(0, employeeRequests.size(), 'Incorrect number of Employee Requests fetched');
    }

    @IsTest
    static void onBeforeDeleteAll_givenDeletedCAWithMappedType_deletesERs() {
        // GIVEN
        Contact candidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert candidate;

        TR1__Candidate_Availability__c candidateAvailability = new TR1__Candidate_Availability__c(
            TR1__Type__c = 'Available',
            TR1__Start_Date__c = Date.newInstance(2025, 1, 1),
            TR1__End_Date__c = Date.newInstance(2025, 1, 1),
            TR1__Candidate__c = candidate.Id
        );

        insert candidateAvailability;

        List<sirenum__Employee_Request__c> employeeRequests = [
            SELECT Id, sirenum__Type__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
        ];

        Assert.areEqual(
            3,
            employeeRequests.size(),
            '3 Employee Requests should exist for this Candidate Availability Type'
        );

        // WHEN
        delete candidateAvailability;

        // THEN
        employeeRequests = [
            SELECT Candidate_Availability__c, sirenum__Type__c, sirenum__Local_Start_Date__c, sirenum__Contact__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
            ORDER BY sirenum__Type__c ASC
        ];

        Assert.areEqual(0, employeeRequests.size(), 'Incorrect number of Employee Requests fetched');
    }

    @IsTest
    static void onBeforeDeleteAll_givenDeletedCAWithUnmappedType_doesNotDeleteERs() {
        // GIVEN
        Contact candidate = new Contact(FirstName = 'John', LastName = 'Doe');
        insert candidate;

        TR1__Candidate_Availability__c candidateAvailability = new TR1__Candidate_Availability__c(
            TR1__Type__c = 'Holiday',
            TR1__Start_Date__c = Date.newInstance(2025, 1, 1),
            TR1__End_Date__c = Date.newInstance(2025, 1, 1),
            TR1__Candidate__c = candidate.Id
        );

        insert candidateAvailability;

        sirenum__Employee_Request__c employeeRequest = new sirenum__Employee_Request__c(
            Candidate_Availability__c = candidateAvailability.Id,
            sirenum__Type__c = 'Holiday',
            sirenum__Local_Start_Date__c = candidateAvailability.TR1__Start_Date__c,
            sirenum__Contact__c = candidate.Id
        );

        insert employeeRequest;

        List<sirenum__Employee_Request__c> employeeRequests = [
            SELECT Id, sirenum__Type__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
        ];

        Assert.areEqual(1, employeeRequests.size(), 'Incorrect number of Employee Requests fetched');

        // WHEN
        delete candidateAvailability;

        // THEN
        employeeRequests = [
            SELECT Candidate_Availability__c, sirenum__Type__c, sirenum__Local_Start_Date__c, sirenum__Contact__c
            FROM sirenum__Employee_Request__c
            WITH SYSTEM_MODE
            ORDER BY sirenum__Type__c ASC
        ];

        Assert.areEqual(1, employeeRequests.size(), 'Incorrect number of Employee Requests fetched');
    }
}