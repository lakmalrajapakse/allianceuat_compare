public inherited sharing class CandidateAvailabilityTriggerHandler {
    public static void onAfterInsertAll(Map<Id, TR1__Candidate_Availability__c> newCandidateAvailabilities) {
        createLinkedEmployeeRequests(newCandidateAvailabilities);
    }

    public static void onAfterUpdateAll(
        Map<Id, TR1__Candidate_Availability__c> oldCandidateAvailabilities,
        Map<Id, TR1__Candidate_Availability__c> newCandidateAvailabilities
    ) {
        updateLinkedEmployeeRequests(oldCandidateAvailabilities, newCandidateAvailabilities);
    }

    public static void onBeforeDeleteAll(Map<Id, TR1__Candidate_Availability__c> oldCandidateAvailabilities) {
        deleteLinkedEmployeeRequests(oldCandidateAvailabilities);
    }

    private static void createLinkedEmployeeRequests(
        Map<Id, TR1__Candidate_Availability__c> newCandidateAvailabilities
    ) {
        performEmployeeRequestsCreate(newCandidateAvailabilities.values());
    }

    private static void performEmployeeRequestsCreate(List<TR1__Candidate_Availability__c> newCandidateAvailabilities) {
        List<sirenum__Employee_Request__c> employeeRequests = new List<sirenum__Employee_Request__c>();

        for (TR1__Candidate_Availability__c candidateAvailability : newCandidateAvailabilities) {
            if (isTypeMappedToEmployeeRequest(candidateAvailability.TR1__Type__c)) {
                List<String> employeeRequestAvailableTypes = Constants.ER_TYPE_BY_PREFIX_AND_CA_TYPE
                    .get(candidateAvailability.TR1__Type__c)
                    .values();

                for (String employeeRequestAvailableType : employeeRequestAvailableTypes) {
                    employeeRequests.add(
                        new sirenum__Employee_Request__c(
                            Candidate_Availability__c = candidateAvailability.Id,
                            sirenum__Type__c = employeeRequestAvailableType,
                            sirenum__Local_Start_Date__c = candidateAvailability.TR1__Start_Date__c,
                            sirenum__Contact__c = candidateAvailability.TR1__Candidate__c
                        )
                    );
                }
            }
        }

        Database.insert(employeeRequests, AccessLevel.SYSTEM_MODE);
    }

    private static void updateLinkedEmployeeRequests(
        Map<Id, TR1__Candidate_Availability__c> oldCandidateAvailabilities,
        Map<Id, TR1__Candidate_Availability__c> newCandidateAvailabilities
    ) {
        List<TR1__Candidate_Availability__c> casWithEmployeeRequestTypesToUpdate = new List<TR1__Candidate_Availability__c>();
        List<TR1__Candidate_Availability__c> casWithEmployeeRequestsToDelete = new List<TR1__Candidate_Availability__c>();
        List<TR1__Candidate_Availability__c> casToCreateEmployeeRequestsFor = new List<TR1__Candidate_Availability__c>();

        // Get the Candidate Availabilities organised by whether they need their Employee Requests updating, creating or deleting
        for (TR1__Candidate_Availability__c newCandidateAvailability : newCandidateAvailabilities.values()) {
            TR1__Candidate_Availability__c oldCandidateAvailability = oldCandidateAvailabilities.get(
                newCandidateAvailability.Id
            );

            String newType = newCandidateAvailability.TR1__Type__c;
            String oldType = oldCandidateAvailability.TR1__Type__c;

            Boolean hasTypeChanged = oldType != newType;

            if (!hasTypeChanged) {
                continue;
            }

            Boolean isNewTypeMappedToEmployeeRequest = isTypeMappedToEmployeeRequest(newType);
            Boolean isOldTypeMappedToEmployeeRequest = isTypeMappedToEmployeeRequest(oldType);

            Boolean isNewTypeAvailableOrUnavailable = isAvailableType(newType) || isUnavailableType(newType);
            Boolean isOldTypeAvailableOrUnavailable = isAvailableType(oldType) || isUnavailableType(oldType);

            Boolean isNewTypeScheduled = isScheduledType(newType);
            Boolean isOldTypeScheduled = isScheduledType(oldType);

            if (isNewTypeAvailableOrUnavailable && isOldTypeAvailableOrUnavailable) {
                // Type has changed from Available -> Unavailable or vice versa, so update in-situ records
                casWithEmployeeRequestTypesToUpdate.add(newCandidateAvailability);
            } else if (
                (isNewTypeScheduled && isOldTypeAvailableOrUnavailable) ||
                (isNewTypeAvailableOrUnavailable && isOldTypeScheduled)
            ) {
                // Type has changed from Scheduled -> Available/Unavailable or vice versa
                // (requiring diff numbers of ER's) - recreating is simplest here
                casWithEmployeeRequestsToDelete.add(newCandidateAvailability);
                casToCreateEmployeeRequestsFor.add(newCandidateAvailability);
            } else if (isNewTypeMappedToEmployeeRequest && !isOldTypeMappedToEmployeeRequest) {
                // Type has changed from not requiring ER's to one that does, so create the ER's
                casToCreateEmployeeRequestsFor.add(newCandidateAvailability);
            } else if (!isNewTypeMappedToEmployeeRequest && isOldTypeMappedToEmployeeRequest) {
                // Type has changed from requiring ER's to one that does not, so delete the ER's
                casWithEmployeeRequestsToDelete.add(newCandidateAvailability);
            }
        }

        performEmployeeRequestsUpdate(casWithEmployeeRequestTypesToUpdate, newCandidateAvailabilities);

        // Order of operations is important here - delete and then create so that recreation works as expected
        performEmployeeRequestsDelete(casWithEmployeeRequestsToDelete);

        performEmployeeRequestsCreate(casToCreateEmployeeRequestsFor);
    }

    private static void deleteLinkedEmployeeRequests(
        Map<Id, TR1__Candidate_Availability__c> candidateAvailabilitiesById
    ) {
        List<TR1__Candidate_Availability__c> casToDelete = new List<TR1__Candidate_Availability__c>();

        for (TR1__Candidate_Availability__c candidateAvailability : candidateAvailabilitiesById.values()) {
            if (isTypeMappedToEmployeeRequest(candidateAvailability.TR1__Type__c)) {
                casToDelete.add(candidateAvailability);
            }
        }

        performEmployeeRequestsDelete(casToDelete);
    }

    private static void performEmployeeRequestsDelete(List<TR1__Candidate_Availability__c> candidateAvailabilities) {
        List<sirenum__Employee_Request__c> employeeRequestsToDelete = fetchEmployeeRequestsFromCandidateAvailabilities(
            candidateAvailabilities
        );

        Database.delete(employeeRequestsToDelete, true, AccessLevel.SYSTEM_MODE);
    }

    private static void performEmployeeRequestsUpdate(
        List<TR1__Candidate_Availability__c> casWithEmployeeRequestTypesToUpdate,
        Map<Id, TR1__Candidate_Availability__c> newCandidateAvailabilities
    ) {
        List<sirenum__Employee_Request__c> employeeRequestsToUpdateType = fetchEmployeeRequestsFromCandidateAvailabilities(
            casWithEmployeeRequestTypesToUpdate
        );

        List<sirenum__Employee_Request__c> updatedEmployeeRequests = new List<sirenum__Employee_Request__c>();

        for (sirenum__Employee_Request__c employeeRequestToUpdate : employeeRequestsToUpdateType) {
            TR1__Candidate_Availability__c candidateAvailability = newCandidateAvailabilities.get(
                employeeRequestToUpdate.Candidate_Availability__c
            );

            String exgPeriodPrefix = employeeRequestToUpdate.sirenum__Type__c.substring(0, 2);

            String updatedType = Constants.ER_TYPE_BY_PREFIX_AND_CA_TYPE
                .get(candidateAvailability.TR1__Type__c)
                .get(exgPeriodPrefix);

            updatedEmployeeRequests.add(
                new sirenum__Employee_Request__c(Id = employeeRequestToUpdate.Id, sirenum__Type__c = updatedType)
            );
        }

        Database.update(updatedEmployeeRequests, AccessLevel.SYSTEM_MODE);
    }

    private static Boolean isTypeMappedToEmployeeRequest(String candidateAvailabilitytype) {
        return isScheduledType(candidateAvailabilitytype) ||
            isAvailableType(candidateAvailabilitytype) ||
            isUnavailableType(candidateAvailabilitytype);
    }

    private static Boolean isScheduledType(String candidateAvailabilitytype) {
        return candidateAvailabilitytype == Constants.CANDIDATE_AVAILABILITY_SCHEDULED_TYPE;
    }

    private static Boolean isAvailableType(String candidateAvailabilitytype) {
        return candidateAvailabilitytype == Constants.CANDIDATE_AVAILABILITY_AVAILABLE_TYPE;
    }

    private static Boolean isUnavailableType(String candidateAvailabilitytype) {
        return candidateAvailabilitytype == Constants.CANDIDATE_AVAILABILITY_UNAVAILABLE_TYPE;
    }

    private static List<sirenum__Employee_Request__c> fetchEmployeeRequestsFromCandidateAvailabilities(
        List<TR1__Candidate_Availability__c> candidateAvailabilities
    ) {
        Set<Id> candidateAvailabilityIds = new Map<Id, TR1__Candidate_Availability__c>(candidateAvailabilities)
            .keySet();

        return [
            SELECT Id, sirenum__Type__c, Candidate_Availability__c
            FROM sirenum__Employee_Request__c
            WHERE Candidate_Availability__c IN :candidateAvailabilityIds
            WITH SYSTEM_MODE
        ];
    }
}