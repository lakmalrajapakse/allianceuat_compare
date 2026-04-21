/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_b3o_Document_SubmissionTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_b3o_Document_SubmissionTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new b3o__Document_Submission__c());
    }
}