/*
********************************************************************************************************
* Developed By: Rishikesh
* Date: 30/10/2025
* Description: This is the test class for the ShiftStatusBatch batch class
********************************************************************************************************
*/
@isTest
private class ShiftStatusBatchTest {
    @TestSetup
    static void setupTestData() {
        // Create Account
        Account acc = new Account(
            Name = 'Test Account',
            Shiftmatch_Last_Sync_Date__c = null,
            Shiftmatch_Counter__c = 0,
            tc9_pr__Available_Payment_Methods__c = 'Payee Australian Bank',
            tc9_pr__Maximum_Payment_Distributions__c = '2'
        );
        insert acc;

        contact con = new contact(lastName='test data');
        insert con;
        
        tc9_et__Award_Classifications_and_Levels__c award = new tc9_et__Award_Classifications_and_Levels__c();
        insert award;

        sirenum__ProActiveContract__c contract = new sirenum__ProActiveContract__c(name = 'Text contract', sirenum__Client__c = acc.Id);
        insert contract;

        sirenum__Team__c jobRole = new sirenum__Team__c();
        jobRole.Name = 'Test Job Role';
        jobRole.sirenum__Account__c = contract.Id;
        jobRole.tc9_ext_sirint__Award_Classification__c = award.Id;
        insert jobRole;
        

           // Create a test shift
        sirenum__Shift__c shift = new sirenum__Shift__c(            
            sirenum__Team__c = jobRole.Id,
            sirenum__Scheduled_Start_Time__c = System.now().addDays(5),
            sirenum__Scheduled_End_Time__c = System.now().addDays(5).addHours(8),
            sirenum__Broadcasts__c =1
        );
        insert shift;
    }


    @isTest
    static void testBatchWithOrgDataSingleExecute() {
        // Run the batch with batch size = number of records to avoid multiple execute calls
        Test.startTest();
        Database.executeBatch(new ShiftStatusBatch(), 200);
        Test.stopTest();

        // Verify that Schedule_Status__c now matches Schedule_Display_Status__c
        List<sirenum__Shift__c> shifts = [
            SELECT Id, Schedule_Display_Status__c, Schedule_Status__c
            FROM sirenum__Shift__c
        ];

        for (sirenum__Shift__c s : shifts) {
            System.assertEquals(
                s.Schedule_Display_Status__c,
                s.Schedule_Status__c,
                'Schedule_Status__c should match Schedule_Display_Status__c after batch'
            );
        }
    }


    @isTest
    static void testSchedule() {
        Test.startTest();    
        String cronExp = '0 0 0 1 1 ? 2026';
        System.schedule('ShiftStatusSchedulerOrgTestJob', cronExp, new ShiftStatusScheduler());
        Test.stopTest();
    }
}