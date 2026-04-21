/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_TR1_Fixed_AssetsTrigger on TR1__Fixed_Assets__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(TR1__Fixed_Assets__c.SObjectType);
}