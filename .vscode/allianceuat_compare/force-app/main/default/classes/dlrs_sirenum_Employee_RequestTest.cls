/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_sirenum_Employee_RequestTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_sirenum_Employee_RequestTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new sirenum__Employee_Request__c());
    }
}