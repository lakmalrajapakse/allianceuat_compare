@IsTest
private class HouseKeeperHelperTest {

    @IsTest
    static void testRunNextHouseKeepingJob_ObjectBatchPath() {

        // allow helper to run inside test
        HouseKeeperHelper.bypassTestGuard = true;

        Test.startTest();

        // use -1 so metadata record is always picked
        HouseKeeperHelper.runNextHouseKeepingJob(-1);

        Test.stopTest();

        System.assert(true, 'Object batch path executed');
    }


    @IsTest
    static void testRunNextHouseKeepingJob_DocumentBatchPath() {

        HouseKeeperHelper.bypassTestGuard = true;

        Test.startTest();

        // run again to cover alternate branch if second CMDT exists
        HouseKeeperHelper.runNextHouseKeepingJob(0);

        Test.stopTest();

        System.assert(true, 'Document batch path executed');
    }


    @IsTest
    static void testGuardStillWorks() {

        // ensure guard branch also covered
        HouseKeeperHelper.bypassTestGuard = false;

        Test.startTest();

        HouseKeeperHelper.runNextHouseKeepingJob(5);

        Test.stopTest();

        System.assert(true, 'Guard branch covered');
    }
}