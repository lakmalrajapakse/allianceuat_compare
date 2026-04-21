global class SIM_AhpraCandidateCheckSchedulable implements Schedulable  {

global void execute(SchedulableContext sc) {
        Integer batchSize = 10;
        SIM_AhpraCandidateCheckBatch batch = new SIM_AhpraCandidateCheckBatch();
        Database.executeBatch(batch, batchSize);
    }

}