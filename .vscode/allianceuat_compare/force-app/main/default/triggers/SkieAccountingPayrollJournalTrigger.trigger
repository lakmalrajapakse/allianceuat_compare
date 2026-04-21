trigger SkieAccountingPayrollJournalTrigger on tc9_bgl__Acc_Payroll_Journal__c (after update) {
    switch on Trigger.OperationType {
        when AFTER_UPDATE{
            SkieSplitJournalService.processSplitJournals(Trigger.new, Trigger.oldMap);
        }
    }
}