public with sharing class ShiftBiddingService {
    private enum ShiftBiddingLoggingLevel {
        INFO,
        ERROR
    }

    private static final String LOGIC_SERVICE_REQUEST_STATUS_COMPLETE = 'Complete';
    private static final String LOGIC_SERVICE_REQUEST_STATUS_READY = 'Ready';
    private static final String LOGIC_SERVICE_REQUEST_STATUS_FAILED = 'Failed';
    private static final String LOGIC_SERVICE_REQUEST_STATUS_INVALID = 'Invalid';

    public static void autoBidShiftDemands(List<sirenum__Shift__c> shifts) {
        if (shifts == null || shifts.isEmpty() || !isAutoBiddingEnabled()) {
            logInfo('Either no shifts provided or Auto bidding is not enabled globally.');

            return;
        }

        List<sirenum__Shift__c> autoBiddableShiftDemands = filterToAutoBiddableShiftsOnly(shifts);
        if (autoBiddableShiftDemands.isEmpty()) {
            return;
        }

        List<sirenum__LogicServiceRequest__c> requests = createWfmLogicServiceRequests(autoBiddableShiftDemands);

        insertAutoBidShiftDemandsSummaryLog(
            autoBiddableShiftDemands.size(),
            autoBiddableShiftDemands.size(),
            autoBiddableShiftDemands,
            requests
        );
    }

    public static void processAutoBidCandidateSearchResults(List<sirenum__LogicServiceRequest__c> requests) {
        if (requests == null || requests.isEmpty() || !isAutoBiddingEnabled()) {
            logInfo('No LogicServiceRequests provided or Auto bidding is not enabled globally.');

            return;
        }

        List<sirenum__LogicServiceRequest__c> autoBidRequests = filterToCompletedAutoBidRequestsOnly(requests);
        if (autoBidRequests.isEmpty()) {
            return;
        }

        List<sirenum__LogicServiceDomain__c> matchingCandidates = findMatchingCandidates(autoBidRequests);

        List<sirenum__Shift_Invitation__c> jobOffers = insertJobOffers(matchingCandidates);

        insertAutoBidSearchResultsSummaryLog(
            requests.size(),
            autoBidRequests.size(),
            matchingCandidates.size(),
            requests,
            jobOffers
        );
    }

    private static Boolean isAutoBiddingEnabled() {
        sirenum__Candidate_Search_Settings__c settings = sirenum__Candidate_Search_Settings__c.getInstance();
        return (settings != null && settings.Auto_Shift_Bidding_Enabled__c);
    }

    private static List<sirenum__Shift__c> filterToAutoBiddableShiftsOnly(List<sirenum__Shift__c> shifts) {
        Id shiftDemandRecordTypeId = sirenum__Shift__c.SObjectType
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('Shift_Demand')
            .getRecordTypeId();

        List<sirenum__Shift__c> shiftDemands = new List<sirenum__Shift__c>();

        for (sirenum__Shift__c shift : shifts) {
            Boolean isNotShiftDemand = shift.RecordTypeId != shiftDemandRecordTypeId;
            Boolean isAutoBroadcast = shift.Auto_Broadcast__c;

            if (isNotShiftDemand || isAutoBroadcast == false) {
                logFine(
                    String.format(
                        'Skipping Shift: {0}. Not Shift Demand? {1}. Missing Site? {2}',
                        new List<Object>{ shift.Name, isNotShiftDemand, isAutoBroadcast }
                    )
                );

                continue;
            }

            shiftDemands.add(shift);
        }

        return shiftDemands;
    }

    private static Set<Id> getSiteIds(List<sirenum__Shift__c> shiftDemands) {
        Set<Id> siteIds = new Set<Id>();

        for (sirenum__Shift__c shiftDemand : shiftDemands) {
            siteIds.add(shiftDemand.sirenum__Site__c);
        }

        return siteIds;
    }
    @TestVisible
    private static List<sirenum__LogicServiceRequest__c> createWfmLogicServiceRequests(
        List<sirenum__Shift__c> shiftDemandsToProcess
    ) {
        List<sirenum__LogicServiceRequest__c> requestsToInsert = buildLogicServiceRequests(shiftDemandsToProcess);

        logFine(String.format('Inserting WFM LogicServiceRequest records: {0}', new List<Object>{ requestsToInsert }));

        Boolean commitAll = true;
        // SYSTEM_MODE is to ensure that Auto Shift Bidding can run regardless of User permissions, as this is a system process
        Database.insert(requestsToInsert, commitAll, AccessLevel.SYSTEM_MODE);

        return requestsToInsert;
    }
    
    private static List<sirenum__LogicServiceRequest__c> buildLogicServiceRequests(
        List<sirenum__Shift__c> shiftDemandsToProcess
    ) {
        List<sirenum__LogicServiceRequest__c> requestsToInsert = new List<sirenum__LogicServiceRequest__c>();

        for (sirenum__Shift__c shiftDemand : shiftDemandsToProcess) {
            sirenum__LogicServiceRequest__c req = new sirenum__LogicServiceRequest__c();
            req.Is_Auto_Shift_Bidding_Request__c = true;
            req.sirenum__Demand__c = shiftDemand.Id;
            req.sirenum__Type__c = 'Extended';
            req.sirenum__Status__c = LOGIC_SERVICE_REQUEST_STATUS_READY;
            req.sirenum__ShiftTemplateGenerator__c = null;
            requestsToInsert.add(req);
        }

        return requestsToInsert;
    }

    private static List<sirenum__LogicServiceRequest__c> filterToCompletedAutoBidRequestsOnly(
        List<sirenum__LogicServiceRequest__c> requests
    ) {
        List<sirenum__LogicServiceRequest__c> result = new List<sirenum__LogicServiceRequest__c>();
        List<sirenum__LogicServiceRequest__c> errorResults = new List<sirenum__LogicServiceRequest__c>();

        for (sirenum__LogicServiceRequest__c req : requests) {
            Boolean isAutoBidRequest = req.Is_Auto_Shift_Bidding_Request__c;
            Boolean isCompleted = req.sirenum__Status__c == LOGIC_SERVICE_REQUEST_STATUS_COMPLETE;
            Boolean isErrored =
                !String.isBlank(req.sirenum__ProcessingError__c) ||
                req.sirenum__Status__c == LOGIC_SERVICE_REQUEST_STATUS_FAILED ||
                req.sirenum__Status__c == LOGIC_SERVICE_REQUEST_STATUS_INVALID;
            logFine(
                String.format(
                    'LogicServiceRequest: {0}. Is Auto Shift Bidding Request? {1}. Is Completed? {2}. Is Errored? {3}',
                    new List<Object>{ req.Id, isAutoBidRequest, isCompleted, isErrored }
                )
            );

            if (isAutoBidRequest && isCompleted) {
                result.add(req);
            }

            if (isAutoBidRequest && isErrored) {
                errorResults.add(req);
            }
        }

        insertAutoBidSearchResultsErrorLog(errorResults);

        return result;
    }

    private static List<sirenum__LogicServiceDomain__c> findMatchingCandidates(
        List<sirenum__LogicServiceRequest__c> requests
    ) {
        List<Id> requestIds = new List<Id>(new Map<Id, sirenum__LogicServiceRequest__c>(requests).keySet());

        sirenum__Candidate_Search_Settings__c settings = sirenum__Candidate_Search_Settings__c.getInstance();
        Double minimumPercentageScore = settings?.Auto_Shift_Bidding_Matching_Percentage__c ?? 0;

        return ShiftBiddingSelector.getLogicServiceDomainResultsByRequestIdsWithMinScore(
            new List<Id>(requestIds),
            minimumPercentageScore
        );
    }

    private static List<sirenum__Shift_Invitation__c> insertJobOffers(
        List<sirenum__LogicServiceDomain__c> eligibleCandiates
    ) {
        List<sirenum__Shift_Invitation__c> invitations = new List<sirenum__Shift_Invitation__c>();

        for (sirenum__LogicServiceDomain__c candidate : eligibleCandiates) {
            sirenum__Shift_Invitation__c invitation = new sirenum__Shift_Invitation__c();
            invitation.sirenum__Contact__c = candidate.sirenum__Record__c;
            invitation.sirenum__Shift__c = candidate.sirenum__Request__r.sirenum__Demand__c;
            invitation.sirenum__Approval_Required__c = false;
            invitations.add(invitation);
        }

        Boolean commitAll = true;
        // SYSTEM_MODE is to ensure that Auto Shift Bidding can run regardless of User permissions, as this is a system process
        Database.insert(invitations, commitAll, AccessLevel.SYSTEM_MODE);

        return invitations;
    }

    private static void logInfo(String message) {
        log(LoggingLevel.INFO, message);
    }

    private static void logFine(String message) {
        log(LoggingLevel.FINE, message);
    }

    private static void log(LoggingLevel level, String message) {
        System.debug(level, 'ShiftBiddingService: ' + message);
    }
    @TestVisible
    private static void insertAutoBidShiftDemandsSummaryLog(
        Integer totalNumberOfShifts,
        Integer numberOfAutoBiddableShifts,
        List<sirenum__Shift__c> shiftDemandsToProcess,
        List<sirenum__LogicServiceRequest__c> requests
    ) {
        if (!isInfoLoggingEnabled()) {
            return;
        }

        Integer maxMessageLength = 4096; // Truncate to 4096 characters as reasonable limit
        String requestIdsMessage = String.join(
            new List<Id>(new Map<Id, sirenum__LogicServiceRequest__c>(requests).keySet()),
            ', '
        );
        requestIdsMessage = requestIdsMessage.length() > maxMessageLength
            ? requestIdsMessage.substring(0, maxMessageLength)
            : requestIdsMessage;

        String shiftDemandIdsMessage = String.join(
            new List<Id>(new Map<Id, sirenum__Shift__c>(shiftDemandsToProcess).keySet()),
            ', '
        );
        shiftDemandIdsMessage = shiftDemandIdsMessage.length() > maxMessageLength
            ? shiftDemandIdsMessage.substring(0, maxMessageLength)
            : shiftDemandIdsMessage;

        String message = String.format(
            'Auto Bid Shift Demands Summary:\nTotal Shifts Provided: {0}\nAuto Biddable Shifts: {1}.\nShift Demands with Auto Shift Bidding Enabled: {2} with Ids: {3}\nCreated LogicServiceRequests: {4} with Ids: {5}',
            new List<Object>{
                totalNumberOfShifts,
                numberOfAutoBiddableShifts,
                shiftDemandsToProcess.size(),
                shiftDemandIdsMessage,
                requests.size(),
                requestIdsMessage
            }
        );

        insertAutoShiftBidLog(ShiftBiddingLoggingLevel.INFO, message);
    }
    @TestVisible
    private static void insertAutoBidSearchResultsSummaryLog(
        Integer totalNumberOfRequests,
        Integer numberOfAutoBidRequests,
        Integer numberOfMatchingCandidates,
        List<sirenum__LogicServiceRequest__c> requests,
        List<sirenum__Shift_Invitation__c> invitations
    ) {
        if (!isInfoLoggingEnabled()) {
            return;
        }

        Integer invitationsCount = (invitations == null) ? 0 : invitations.size();

        Integer maxMessageLength = 4096; // Truncate to 4096 characters as reasonable limit

        String invitationIdsMessage = String.join(
            new List<Id>(new Map<Id, sirenum__Shift_Invitation__c>(invitations).keySet()),
            ', '
        );
        invitationIdsMessage = invitationIdsMessage.length() > maxMessageLength
            ? invitationIdsMessage.substring(0, maxMessageLength)
            : invitationIdsMessage;

        String requestIdsMessage = String.join(
            new List<Id>(new Map<Id, sirenum__LogicServiceRequest__c>(requests).keySet()),
            ', '
        );
        requestIdsMessage = requestIdsMessage.length() > maxMessageLength
            ? requestIdsMessage.substring(0, maxMessageLength)
            : requestIdsMessage;

        sirenum__Candidate_Search_Settings__c settings = sirenum__Candidate_Search_Settings__c.getInstance();
        Double minimumPercentageScore = settings?.Auto_Shift_Bidding_Matching_Percentage__c ?? 0;

        String message = String.format(
            'Auto Bid Search Results Summary:\nTotal LogicServiceRequests Provided: {0}\nNumber of Complete Auto Bid LogicServiceRequests: {1}\nMinimum Matching Score: {2}\nMatching Candidates Found: {3}\nLogicServiceRequests with Ids: {4}\nCreated Job Offers: {5} with Ids: {6}',
            new List<Object>{
                totalNumberOfRequests,
                numberOfAutoBidRequests,
                minimumPercentageScore,
                numberOfMatchingCandidates,
                requestIdsMessage,
                invitationsCount,
                invitationIdsMessage
            }
        );

        message = numberOfMatchingCandidates == 0
            ? message +
              '\nNo Candidates were found, review the LogicServiceDomain records associated with the LogicServiceRequests. This will show which candidates were evaluated as well as what impacted the score (via LogicServiceScoreContribution__c related records), note that the WorkerSearchScorer "Plugin" defined via Custom Metadata can heavily impact Candidate scoring.'
            : message;

        insertAutoShiftBidLog(ShiftBiddingLoggingLevel.INFO, message);
    }

    private static void insertAutoBidSearchResultsErrorLog(List<sirenum__LogicServiceRequest__c> erroredRequests) {
        if (erroredRequests.isEmpty()) {
            return;
        }

        List<String> messages = new List<String>();

        for (sirenum__LogicServiceRequest__c req : erroredRequests) {
            String message = String.format(
                'Auto Bid Search Results Error: LogicServiceRequest Id: {0}. Status: {1}. Processing Error: {2}',
                new List<Object>{ req.Id, req.sirenum__Status__c, req.sirenum__ProcessingError__c }
            );
            messages.add(message);
        }

        insertAutoShiftBidLog(ShiftBiddingLoggingLevel.ERROR, String.join(messages, '\n'));
    }

    private static void insertAutoShiftBidLog(ShiftBiddingLoggingLevel logLevel, String message) {
        Auto_Shift_Bidding_Log__c log = new Auto_Shift_Bidding_Log__c(
            Level__c = String.valueOf(logLevel),
            Message__c = message
        );

        Boolean commitAll = true;
        // SYSTEM_MODE is to ensure that Auto Shift Bidding Logs can be created regardless of User permissions, as this is a system process
        Database.insert(log, commitAll, AccessLevel.SYSTEM_MODE);
    }

    private static Boolean isInfoLoggingEnabled() {
        sirenum__Candidate_Search_Settings__c settings = sirenum__Candidate_Search_Settings__c.getInstance();
        return settings?.Auto_Shift_Bidding_Enable_Info_Logs__c ?? false;
    }
}