public without sharing class LeaveAccrualRevaluationSchedule implements Schedulable {

    tc9_bgl__GL_Configuration__c SETTING = tc9_bgl__GL_Configuration__c.getOrgDefaults();

    public void execute(SchedulableContext SC) {
        tc9_bgl__Acc_System_Setup__c acss = [SELECT Id, tc9_bgl__Default_Account_Leave_Accural__c, tc9_bgl__Default_Dept_Balance_Sheet__c,
                                             tc9_bgl__Default_Account_Leave_Liability__c
                                             FROM tc9_bgl__Acc_System_Setup__c 
                                             WHERE Id = :SETTING.tc9_bgl__Default_Accounting_System_Setup_Id__c LIMIT 1];

        // Get all Account Payment Entity records (Should be max 4 rows)
        List<tc9_bgl__Acc_Payment_Entity__c> accountPEDList = [SELECT Id, tc9_bgl__Payment_Entity__c, tc9_bgl__GL_Entity_Code__c  
                                                               FROM tc9_bgl__Acc_Payment_Entity__c 
                                                               WHERE tc9_bgl__Accounting_System__c = :acss.Id];

        Map<Id, tc9_bgl__Acc_Payment_Entity__c> accountPEDMap = new Map<Id, tc9_bgl__Acc_Payment_Entity__c>();

        //Store APED map by payment entity ids
        for(tc9_bgl__Acc_Payment_Entity__c accountPED : accountPEDList) {
            if(String.isNotBlank(accountPED?.tc9_bgl__Payment_Entity__c)) {
                accountPEDMap.put(accountPED.tc9_bgl__Payment_Entity__c, accountPED);
            }
        }

        List<Leave_Accrual_Revaluation__c> leaveAccrualRevaluationList = [SELECT Id, Payee_Leave_Rule__r.tc9_pr__Payee__r.tc9_pr__Payment_Entity__c 
                                                                          FROM Leave_Accrual_Revaluation__c 
                                                                          WHERE Accounting_Payroll_Journal__c = null
                                                                          AND Payee_Leave_Rule__r.tc9_pr__Payee__r.tc9_pr__Payment_Entity__c IN :accountPEDMap.keySet()];
    
        Map<String, Leave_Accrual_Revaluation__c> larMapByPaymentEntityId = new Map<String, Leave_Accrual_Revaluation__c>();
        for(Leave_Accrual_Revaluation__c lar : leaveAccrualRevaluationList) {
            if(larMapByPaymentEntityId.get(lar.Payee_Leave_Rule__r.tc9_pr__Payee__r.tc9_pr__Payment_Entity__c) == null) {
                larMapByPaymentEntityId.put(lar.Payee_Leave_Rule__r.tc9_pr__Payee__r.tc9_pr__Payment_Entity__c, lar);
            }
        }

        Map<Id, tc9_bgl__Acc_Payroll_Journal__c> accPayrollJournalMap = new Map<Id, tc9_bgl__Acc_Payroll_Journal__c>();

        for(tc9_bgl__Acc_Payment_Entity__c accountPED : accountPEDList) {
            if(String.isNotBlank(accountPED?.tc9_bgl__Payment_Entity__c) && larMapByPaymentEntityId.get(accountPED.tc9_bgl__Payment_Entity__c) != null) {
                tc9_bgl__Acc_Payroll_Journal__c accPayrollJournal = new tc9_bgl__Acc_Payroll_Journal__c();
                accPayrollJournal.tc9_bgl__Journal_date__c = System.Today();
                accPayrollJournal.tc9_bgl__Journal_Type__c = 'Leave Revaluation';
                accPayrollJournal.tc9_bgl__Accounting_System__c = acss.Id;
                accPayrollJournalMap.put(accountPED.tc9_bgl__Payment_Entity__c, accPayrollJournal);
            }
        }

        //pass variables to do remain LAR process in batch
        if(!accPayrollJournalMap.isEmpty()) {
            insert accPayrollJournalMap.values();
            Database.executeBatch(new LeaveAccrualRevaluationBatch(accountPEDMap, accPayrollJournalMap, acss), 20);
        }
    }
}