/*
********************************************************************************************************
* Developed By: Rishikesh
* Date: 30/10/2025
* Description: This Scheduler class executes ShiftStatusBatch with Batch Size from Custom Setting using SOQL
********************************************************************************************************
*/
global class ShiftStatusScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Alliance_General_Settings__c settings = Alliance_General_Settings__c.getInstance();

        Integer batchSize = (settings.Batch_Size__c != null) ? settings.Batch_Size__c.intValue() : 200; // directly use Number field
        
        // Execute Batch with dynamic batch size
        ShiftStatusBatch batchJob = new ShiftStatusBatch();
        Database.executeBatch(batchJob, batchSize);
    }
}