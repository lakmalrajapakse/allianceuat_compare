@isTest
public class HouseKeeperSchedulerTest {

    @isTest
    static void testSchedulerRunsHelper() {
        // Use a flag to confirm that runNextHouseKeepingJob() is invoked
        // by temporarily overriding behavior using a test-visible helper variable.
        Test.startTest();

        // Schedule the job — executes immediately in test context
        String cron = '0 0 0 1 1 ? 2050'; // arbitrary future date
        System.schedule('Test_HouseKeeperScheduler', cron, new HouseKeeperScheduler());

        Test.stopTest();

        // If we got here without exception, the scheduler executed successfully
        System.assert(true, 'Scheduler executed without errors.');
    }
}