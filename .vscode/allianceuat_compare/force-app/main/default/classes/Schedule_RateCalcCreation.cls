public class Schedule_RateCalcCreation implements Database.Batchable<sObject>, Schedulable, Database.Stateful {
    
    public List<Id> assignmentIds = new List<Id>();

    public void execute(SchedulableContext sc) {

        List<AsyncApexJob> jobs = [SELECT Id, ApexClassId, Status 
                                   FROM AsyncApexJob 
                                   WHERE ApexClassId IN (select id from ApexClass where Name = 'Schedule_RateCalcCreation' OR Name = 'Batch_CreateEmpSpecRateCalcs')
                                   AND Status NOT IN ('Aborted', 'Completed', 'Failed')
                                   AND JobType = 'BatchApex'];
        
        if(jobs.isEmpty()) {
            Schedule_RateCalcCreation batch = new Schedule_RateCalcCreation();
            Database.executeBatch(batch, 200);

        } else {
            System.debug('WARN with Schedule_RateCalcCreation: There is in-progress batch. jobId=' + jobs.get(0)?.Id);
        }
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('Schedule_RateCalcCreation.start');
        return Database.getQueryLocator([SELECT Id, tc9_et__Rate_Calculator__c
                                         FROM tc9_pr__Assignment__c
                                         WHERE Create_Rate_Calculator__c = true]);
    }

    public void execute(Database.BatchableContext bc, List<tc9_pr__Assignment__c> assignments) {
        System.debug('Schedule_RateCalcCreation.execute');

        for(tc9_pr__Assignment__c assignment : assignments) {
            assignment.Create_Rate_Calculator__c = false;

            assignmentIds.add(assignment.Id);
        }

        update assignments;
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Schedule_RateCalcCreation.finish');
        tc9_et.Invoke_RateCalcCreation.Invoke_RateCalcCreation(assignmentIds);
    }   
}