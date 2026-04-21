@JsonAccess(serializable='never' deserializable='always')
global without sharing class SIM_SchedulerCustomScorer implements sirenum.WorkerSearchScorer {
    
    private Decimal availabilityBonus;
    private Decimal unavailabilityBonus;
    private Decimal newCandidateIncentiveNoWeeks;
    private Decimal newCandidateIncentiveBonus;
    private Decimal newCandidateIncentiveNoShiftsWorked; 
    private Decimal availabilityUpdateBonus;      

    /**
     * Constructor
     */
    global SIM_SchedulerCustomScorer() {
    }

    /**
     * @return Set of fields to be retrieved from the shift templates
     */
    global Set<String> getRequiredShiftFields() {
        return new Set<String> {
                'sirenum__Shift_Date__c',
                'Shift_Type__c',
                'sirenum__Allow_pay__c',
                'sirenum__Allow_charge__c'
        };
    }

    /**
     * @return No contact fields required
     */
    global Set<String> getRequiredWorkerFields() {
        return new Set<String> { 
        };
    }

    /**
     * Give bonus sores to workers that have "Available" Employee Requests that overlap the shift(s)
     *
     * @param context Worker Search Context (shifts and contacts)
     *
     * @return Scores
     */
    global List<sirenum.WorkerSearchScore> scoreWorkers(sirenum.WorkerSearchScorerContext context) {

        System.debug('Running the scoreWorker Plugin');
        this.availabilityBonus = this.availabilityBonus == null ? 1.0 : this.availabilityBonus;
        this.unavailabilityBonus = this.unavailabilityBonus == null ? 1.0 : this.unavailabilityBonus;
        this.newCandidateIncentiveNoWeeks = this.newCandidateIncentiveNoWeeks == null ? 4.0 : this.newCandidateIncentiveNoWeeks;
        this.newCandidateIncentiveBonus = this.newCandidateIncentiveBonus == null ? 1.0 : this.newCandidateIncentiveBonus;
        this.newCandidateIncentiveNoShiftsWorked = this.newCandidateIncentiveNoShiftsWorked == null ? 1.0 : this.newCandidateIncentiveNoShiftsWorked;       
        this.availabilityUpdateBonus = this.availabilityUpdateBonus == null ? 1.0 : this.availabilityUpdateBonus;               
        
        Set<Id> shiftIds = new set<id>{};
        Set<Date> shiftDates = new set<Date>{};

        for (sirenum__Shift__c shift : context.getShiftTemplates()) {            
            shiftIds.add(shift.Id);
            system.debug('SPC shift id > ' + shift.id);
            shiftDates.add(shift.sirenum__Scheduled_Start_Time__c.date());
            system.debug('SPC shift > ' + shift);
        }
        
        List<sirenum.WorkerSearchScore> scores = new List<sirenum.WorkerSearchScore>();        
        Map<Id, Contact> contactsMap = context.getWorkersById();

        // AVAILABILITY BONUS QUERY
        // If the candidate is abvailable on the shift date, then add the availability bonus
        Map<Id, List<sirenum__Employee_Request__c>> employeeRequestsByContactMap = new Map<Id, List<sirenum__Employee_Request__c>>();
        for (sirenum__Employee_Request__c employeeRequest : [
            SELECT Id, sirenum__Contact__c, sirenum__Date__c, sirenum__Type__c, sirenum__Availability__c
            FROM sirenum__Employee_Request__c
            WHERE sirenum__Contact__c IN :contactsMap.keySet() AND sirenum__Date__c IN :shiftDates
            and sirenum__Type__c != null
        ]) {
            // Add the contact and a list of employee requests to a map
            if(employeeRequestsByContactMap.containsKey(employeeRequest.sirenum__Contact__c)) {
                employeeRequestsByContactMap.get(employeeRequest.sirenum__Contact__c).add(employeeRequest);
            } else {
                employeeRequestsByContactMap.put(employeeRequest.sirenum__Contact__c, new List<sirenum__Employee_Request__c>{employeeRequest});
            }
            // System.debug('SPC employeeRequest: ' + employeeRequest);
        }

        for(Id workerId : employeeRequestsByContactMap.keySet()) {
            system.debug('SPC EmployeeRequest WorkerId: ' + workerId);
            for(sirenum__Employee_Request__c employeeRequest : employeeRequestsByContactMap.get(workerId)) {
                system.debug('SPC EmployeeRequest: ' + employeeRequest);
            }
        }

        if(employeeRequestsByContactMap.isEmpty()) {
            system.debug('SPC No employee requests found');
        }

        // NEW CANDIDATE INCENTIVE QUERY
        // Get the number of weeks since the contact was created
        List<Contact> contactList = [SELECT Id, CreatedDate FROM Contact WHERE Id IN: contactsMap.keySet()];
        Map<Id, Decimal> weeksSinceCreated = new Map<Id, Decimal>();
        
        for (Contact con : contactList) {
            Integer daysBetween = date.today().daysBetween(con.CreatedDate.date());
            Decimal weeksBetween = Math.abs(daysBetween)/7;
            weeksSinceCreated.put(con.Id, weeksBetween);
        }
        // system.debug('weeksSinceCreated > ' + weeksSinceCreated);
        // for(Id workerId : weeksSinceCreated.keySet()) {
        //     system.debug('SPC weeksSinceCreated WorkerId: ' + workerId + ' / ' + weeksSinceCreated.get(workerId));
        // }        

        // Aggregate query to count shifts per worker
        AggregateResult[] shiftsPerWorker = [
            SELECT sirenum__Contact__c, COUNT(Id) shiftCount 
            FROM sirenum__Shift__c 
            WHERE sirenum__Contact__c IN :contactsMap.keySet() 
            GROUP BY sirenum__Contact__c
        ];

        // Calculate the Number of Shifts the candidate has completed
        Map<Id, Integer> shiftsCompleted = new Map<Id, Integer>();
        // Store results in a map
        for (AggregateResult ar : shiftsPerWorker) {
            Id workerId = (Id) ar.get('sirenum__Contact__c');
            Integer shiftCount = (Integer) ar.get('shiftCount');
            shiftsCompleted.put(workerId, shiftCount);
        }
        // system.debug('shiftsCompleted > ' + shiftsCompleted);
        // for(Id workerId : shiftsCompleted.keySet()) {
        //     system.debug('SPC shiftsCompleted WorkerId: ' + workerId + ' / ' + shiftsCompleted.get(workerId));
        // }

        // AVAILABILITY UPDATE BONUS
        // If the candidate has updated their availability for the whole week then give a bonus.
        Date shiftStartofWeek;
        Date shiftEndofWeek;
        for(date d : shiftDates) {
            // Get the start of the week from the date
            shiftStartofWeek = d.toStartofWeek();
            shiftEndofWeek = shiftStartofWeek.addDays(6);
        }      

        // Aggregate query to count requests per worker
        AggregateResult[] candidateReqCount = [
            SELECT sirenum__Contact__c, COUNT(Id) reqCount 
            FROM sirenum__Employee_Request__c 
            WHERE sirenum__Contact__c IN :contactsMap.keySet() AND sirenum__Date__c >= :shiftStartofWeek AND sirenum__Date__c <= :shiftEndofWeek
            GROUP BY sirenum__Contact__c
        ];
        
        // Calculate the Number of Requests the candidate has completed
        Map<Id, Integer> reqsCompleted = new Map<Id, Integer>();
        for (AggregateResult ar : candidateReqCount) {
            Id workerId = (Id) ar.get('sirenum__Contact__c');
            Integer reqCount = (Integer) ar.get('reqCount');
            reqsCompleted.put(workerId, reqCount);
        }
        system.debug('reqsCompleted > ' + reqsCompleted);

        // Calculate scores      
        for (Id workerId : contactsMap.keyset()) {
            for (sirenum__Shift__c shift : context.getShiftTemplates()) {

                // Work out availability bonus
                if(employeeRequestsByContactMap.containsKey(workerId)) {
                    for(sirenum__Employee_Request__c employeeRequest : employeeRequestsByContactMap.get(workerId)) {
                        if (shift.Shift_Type__c == null) {
                            system.debug('SPC Shift Type is null for shift > ' + shift.Id);
                            continue;
                        }
                        
                        if(employeeRequest.sirenum__Date__c == shift.sirenum__Shift_Date__c && employeeRequest.sirenum__Type__c.contains(shift.Shift_Type__c) && employeeRequest.sirenum__Availability__c == true) {
                            system.debug('SPC Employee Request - Available');
                            sirenum.WorkerSearchScore availabilityBonusScore = new sirenum.WorkerSearchScore()
                            .withWorkerId(workerId)
                            .withScore(availabilityBonus)
                            .withDescription(String.format('Worker is available for the shift',
                                    new List<Object>{}
                            ));
                            scores.add(availabilityBonusScore);
                        } else if(employeeRequest.sirenum__Date__c == shift.sirenum__Shift_Date__c && employeeRequest.sirenum__Type__c.contains(shift.Shift_Type__c) && employeeRequest.sirenum__Availability__c == false) {
                            system.debug('SPC Employee Request - Unavailable');
                            sirenum.WorkerSearchScore unavailabilityBonusScore = new sirenum.WorkerSearchScore()
                            .withWorkerId(workerId)
                            .withScore(-unavailabilityBonus)
                            .withDescription(String.format('Worker is NOT available for the shift',
                                    new List<Object>{}
                            ));
                            scores.add(unavailabilityBonusScore);
                        }
                    }
                }
                // Work out new candidate incentive
                if(weeksSinceCreated.containsKey(workerId) && weeksSinceCreated.get(workerId) <= newCandidateIncentiveNoWeeks
                    && ((shiftsCompleted.containsKey(workerId) && shiftsCompleted.get(workerId) <= newCandidateIncentiveNoShiftsWorked)
                        || !shiftsCompleted.containsKey(workerId))) {
                    system.debug('Adding Incentive Bonues to worker > ' + workerId);
                    sirenum.WorkerSearchScore newCandidateIncentiveScore = new sirenum.WorkerSearchScore()
                    .withWorkerId(workerId)
                    .withScore(newCandidateIncentiveBonus)
                    .withDescription(String.format('New candidate incentive bonus',
                            new List<Object>{}
                    ));
                    scores.add(newCandidateIncentiveScore);
                }
            }    
            // AVAILABILITY UPDATE BONUS
            if(Test.isRunningTest()){
                // update the reqsCompleted map to simulate test data
                reqsCompleted.put(workerId, 7); // Simulate that the worker has completed
            }            

            if(reqsCompleted.containsKey(workerId) && reqsCompleted.get(workerId) >= 7) {
                system.debug('SPC Availability Update Bonus' + workerId + ' / ' + reqsCompleted.get(workerId));                
                sirenum.WorkerSearchScore availabilityUpdateScore = new sirenum.WorkerSearchScore()
                .withWorkerId(workerId)
                .withScore(availabilityUpdateBonus)
                .withDescription(String.format('Availability Update Bonus',
                        new List<Object>{}
                ));
                scores.add(availabilityUpdateScore);
            }                           
        }
        system.debug('SPC scores > ' + scores);
        return scores;
    }
}