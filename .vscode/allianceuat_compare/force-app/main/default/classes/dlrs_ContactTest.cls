/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_ContactTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_b3o_Session_InvitationTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Contact());
    }
}