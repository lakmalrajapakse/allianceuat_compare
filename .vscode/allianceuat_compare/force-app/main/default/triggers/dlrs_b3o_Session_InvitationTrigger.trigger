/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_b3o_Session_InvitationTrigger on b3o__Session_Invitation__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(b3o__Session_Invitation__c.SObjectType);
}