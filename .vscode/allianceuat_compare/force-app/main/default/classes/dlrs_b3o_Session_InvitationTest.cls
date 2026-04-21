/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_b3o_Session_InvitationTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_b3o_Session_InvitationTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new b3o__Session_Invitation__c());
    }
}