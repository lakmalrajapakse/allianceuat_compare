/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_b3o_CertificateTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_b3o_CertificateTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new b3o__Certificate__c());
    }
}