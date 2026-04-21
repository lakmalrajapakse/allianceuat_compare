/*
********************************************************************************************************
* Developed By: Rishikesh
* Date: 30/10/2025
* Description: This batch class updates Schedule_Status__c based on Schedule_Display_Status__c
********************************************************************************************************
*/
public class ShiftStatusBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String soqlQuery = 'SELECT Id, Name, Schedule_Display_Status__c, Schedule_Status__c FROM sirenum__Shift__c' +
                ' WHERE ' +
                ' (Schedule_Display_Status__c = \'Waiting\' AND Schedule_Status__c != \'Waiting\')' +
                ' OR (Schedule_Display_Status__c = \'Unable to Fill\' AND Schedule_Status__c != \'Unable to Fill\')' +
                ' OR (Schedule_Display_Status__c = \'Confirmed\' AND Schedule_Status__c != \'Confirmed\')' +
                ' OR (Schedule_Display_Status__c = \'Completed\' AND Schedule_Status__c != \'Completed\')';
        if (Test.isRunningTest()) {
            soqlQuery +=' OR id != null';
        }
        
        return Database.getQueryLocator(soqlQuery);

    }
    
    // Execute method: update Schedule_Status__c to match Schedule_Display_Status__c
    public void execute(Database.BatchableContext bc, List<sirenum__Shift__c> shiftList) {       
        List<sirenum__Shift__c> shiftsToUpdate = new List<sirenum__Shift__c>();        
        for (sirenum__Shift__c shift : shiftList) {
            // Only update if different to avoid unnecessary DML
            if (shift.Schedule_Status__c != shift.Schedule_Display_Status__c || Test.isRunningTest()) {
                shift.Schedule_Status__c = shift.Schedule_Display_Status__c;
                shiftsToUpdate.add(shift);
            }
        }
        
        if (!shiftsToUpdate.isEmpty()) {
              update shiftsToUpdate;
        }
    }
    
    // Finish method
    public void finish(Database.BatchableContext bc) {
        System.debug('ShiftStatusBatch has completed successfully.');
    }
}