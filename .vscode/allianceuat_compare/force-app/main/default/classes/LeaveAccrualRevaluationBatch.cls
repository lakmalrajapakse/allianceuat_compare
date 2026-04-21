public without sharing class LeaveAccrualRevaluationBatch implements Database.Batchable<SObject>, Database.Stateful {

    public Map<Id, tc9_bgl__Acc_Payroll_Journal__c> accPayrollJournalMap = new Map<Id, tc9_bgl__Acc_Payroll_Journal__c>();
    public Map<Id, tc9_bgl__Acc_Payment_Entity__c> accPEDMap = new Map<Id, tc9_bgl__Acc_Payment_Entity__c>();
    public tc9_bgl__Acc_System_Setup__c acss;
    public Set<Id> paymentEntityIds = new Set<Id>();

    public LeaveAccrualRevaluationBatch(Map<Id, tc9_bgl__Acc_Payment_Entity__c> accPEDMap, Map<Id, tc9_bgl__Acc_Payroll_Journal__c> accPayrollJournalMap, tc9_bgl__Acc_System_Setup__c acss) {
        this.accPEDMap = accPEDMap;
        this.accPayrollJournalMap = accPayrollJournalMap;
        this.paymentEntityIds = accPayrollJournalMap.keySet();
        this.acss = acss;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        String query = ' SELECT {0}, Payee_Leave_Rule__r.tc9_pr__Payee__r.tc9_pr__Payment_Entity__c, Assignment_Rate__r.tc9_pr__Assignment__c ' +
                       ' FROM Leave_Accrual_Revaluation__c ' +
                       ' WHERE Accounting_Payroll_Journal__c = null ' +
                       ' AND Payee_Leave_Rule__r.tc9_pr__Payee__r.tc9_pr__Payment_Entity__c IN :paymentEntityIds ' +
            		   ' AND Assignment_Rate__r.tc9_pr__Assignment__c != null ' +
                       ' ORDER BY Leave_Type__c ';
        String larFields = String.join(Schema.SObjectType.Leave_Accrual_Revaluation__c.fields.getMap().keySet(), ',');
        String formattedQuery = String.format(query, new List<Object>{ larFields });

        return Database.getQueryLocator(formattedQuery);
    }

    public void execute(Database.BatchableContext context, List<Leave_Accrual_Revaluation__c> leaveAccrualRevaluationList) {
        System.Debug('[START] LeaveAccrualRevaluationBatch.execute REQ: size=' + leaveAccrualRevaluationList.size() + 
                     ', leaveAccrualRevaluationList=' + leaveAccrualRevaluationList);

        Set<Id> assignmentId = new Set<Id>();
        Set<Id> accountJournalIdSet = new Set<Id>();
        Set<Id> glEntityCodes = new Set<Id>();
        Set<String> departmentSet = new Set<String>();
        Set<String> leaveTypeSet = new Set<String>();

        for(Leave_Accrual_Revaluation__c lar : leaveAccrualRevaluationList) {
            if(String.isNotBlank(lar?.Assignment_Rate__r?.tc9_pr__Assignment__c)) {
                assignmentId.add(lar.Assignment_Rate__r.tc9_pr__Assignment__c);
            }

            if(this.accPayrollJournalMap.get(lar.Payee_Leave_Rule__r.tc9_pr__Payee__r.tc9_pr__Payment_Entity__c) != null) {
                accountJournalIdSet.add(this.accPayrollJournalMap.get(lar.Payee_Leave_Rule__r.tc9_pr__Payee__r.tc9_pr__Payment_Entity__c).Id);
            }

            if(String.isNotBlank(lar?.Leave_Type__c)) {
                leaveTypeSet.add(lar.Leave_Type__c);
            }

            glEntityCodes.add(this.accPEDMap.get(lar.Payee_Leave_Rule__r.tc9_pr__Payee__r.tc9_pr__Payment_Entity__c)?.tc9_bgl__GL_Entity_Code__c);
        }

        Map<Id, List<tc9_bgl__Acc_Assignment_Depts__c>> aadMap = new Map<Id, List<tc9_bgl__Acc_Assignment_Depts__c>>();

        for(tc9_bgl__Acc_Assignment_Depts__c aad : [SELECT Id, tc9_bgl__Assignment__c, tc9_bgl__Department__c, tc9_bgl__Percentage_Split__c 
                                                    FROM tc9_bgl__Acc_Assignment_Depts__c 
                                                    WHERE tc9_bgl__Assignment__c IN :assignmentId]) {
            if(String.isNotBlank(aad.tc9_bgl__Department__c)) {
                departmentSet.add(aad.tc9_bgl__Department__c);
            }
            
            if(!aadMap.containsKey(aad.tc9_bgl__Assignment__c)) {
                aadMap.put(aad.tc9_bgl__Assignment__c, new List<tc9_bgl__Acc_Assignment_Depts__c>());   
            }
            aadMap.get(aad.tc9_bgl__Assignment__c).add(aad);
        }

        Map<String, tc9_bgl__Acc_Payroll_Journal_Lines__c> accPayrollJournalLineLAMap = getAccountJournalLinesMap(accountJournalIdSet, glEntityCodes, departmentSet, 
                                                                                                                  null, acss.tc9_bgl__Default_Account_Leave_Accural__c, 
                                                                                                                  leaveTypeSet);
        Map<String, tc9_bgl__Acc_Payroll_Journal_Lines__c> accPayrollJournalLineLLMap = getAccountJournalLinesMap(accountJournalIdSet, glEntityCodes, null, 
                                                                                                                  acss?.tc9_bgl__Default_Dept_Balance_Sheet__c, 
                                                                                                                  acss?.tc9_bgl__Default_Account_Leave_Liability__c, 
                                                                                                                  leaveTypeSet);

        for(Leave_Accrual_Revaluation__c lar : leaveAccrualRevaluationList) {

            tc9_bgl__Acc_Payroll_Journal__c accJournalPayroll = accPayrollJournalMap.get(lar.Payee_Leave_Rule__r.tc9_pr__Payee__r.tc9_pr__Payment_Entity__c);
 
            List<tc9_bgl__Acc_Assignment_Depts__c> currentAADList = aadMap.get(lar.Assignment_Rate__r.tc9_pr__Assignment__c);
            if(currentAADList == null) continue;
            
            for(tc9_bgl__Acc_Assignment_Depts__c assDept : currentAADList) {
                Id paymentEntityId = this.accPEDMap.get(lar.Payee_Leave_Rule__r.tc9_pr__Payee__r.tc9_pr__Payment_Entity__c)?.tc9_bgl__GL_Entity_Code__c;
                
                String larLeaveType = lar.Leave_Type__c;
                String departmentLA = assDept.tc9_bgl__Department__c;
                String departmentLL = acss.tc9_bgl__Default_Dept_Balance_Sheet__c;
                Id naturalAccountLA = acss.tc9_bgl__Default_Account_Leave_Accural__c;
                Id naturalAccountLL = acss.tc9_bgl__Default_Account_Leave_Liability__c;
                Decimal percensplit = assDept.tc9_bgl__Percentage_Split__c ?? 0.0;
                
                
                String apjLineLAKey = buildAccPayrollJournalLineKey(accJournalPayroll.Id, paymentEntityId, departmentLA, naturalAccountLA, larLeaveType);
                tc9_bgl__Acc_Payroll_Journal_Lines__c apjLineLA = accPayrollJournalLineLAMap.get(apjLineLAKey);
                Decimal debitLA = (lar.Revaluation_Amount__c ?? 0.0) * (percensplit / 100.0);
                Decimal creditLL = (lar.Revaluation_Amount__c ?? 0.0) * (percensplit / 100.0);
                
                if(apjLineLA != null) {
                    debitLA += apjLineLA.tc9_bgl__Debit__c ?? 0.0;
                }
                tc9_bgl__Acc_Payroll_Journal_Lines__c tempAPJLineLA = buildAccPayrollJournalLine(accJournalPayroll, paymentEntityId, 
                                                                                                 departmentLA, naturalAccountLA, larLeaveType, debitLA, null,  apjLineLA);
                accPayrollJournalLineLAMap.put(apjLineLAKey, tempAPJLineLA);
                
                String apjLineLLKey = buildAccPayrollJournalLineKey(accJournalPayroll.Id, paymentEntityId, departmentLL, naturalAccountLL, larLeaveType);
                tc9_bgl__Acc_Payroll_Journal_Lines__c apjLineLL = accPayrollJournalLineLLMap.get(apjLineLLKey);
                
                if(apjLineLL != null) {
                    creditLL += apjLineLL.tc9_bgl__Credit__c ?? 0.0;
                }
                tc9_bgl__Acc_Payroll_Journal_Lines__c tempAPJLineLL = buildAccPayrollJournalLine(accJournalPayroll, paymentEntityId, 
                                                                                                 departmentLL, naturalAccountLL, larLeaveType, null, creditLL, apjLineLL);
                accPayrollJournalLineLLMap.put(apjLineLLKey, tempAPJLineLL);
            }
            
            lar.Accounting_Payroll_Journal__c = accJournalPayroll.Id;
        	lar.Processed_Date_Time__c = System.now();
        }

        if(!accPayrollJournalLineLAMap.isEmpty()) {
            upsert accPayrollJournalLineLAMap.values();
        }

        if(!accPayrollJournalLineLLMap.isEmpty()) {
            upsert accPayrollJournalLineLLMap.values();
        }

        update leaveAccrualRevaluationList;
    }

    public static String buildAccPayrollJournalLineKey(String accJournalId, String entity, String department, String natural, String description) {
        return accJournalId + '-' + entity + '-' + department + '-' + natural + '-' + description;
    }

    public static tc9_bgl__Acc_Payroll_Journal_Lines__c buildAccPayrollJournalLine(tc9_bgl__Acc_Payroll_Journal__c accJournal, String entity, Id department, 
                                                                                   Id natural, String description, Decimal debit, Decimal credit, tc9_bgl__Acc_Payroll_Journal_Lines__c existApjLine) {
        tc9_bgl__Acc_Payroll_Journal_Lines__c apjLine = existApjLine ?? new tc9_bgl__Acc_Payroll_Journal_Lines__c();
        apjLine.tc9_bgl__Accounting_Payroll_Journal__c = accJournal.Id;
        apjLine.tc9_bgl__Entity__c = entity;
        apjLine.tc9_bgl__Department__c = department;
        apjLine.tc9_bgl__Natural_Account__c = natural;
        apjLine.tc9_bgl__Description__c = description;
        apjLine.tc9_bgl__Debit__c = debit;
        apjLine.tc9_bgl__Credit__c = credit;
        return apjLine;
    }

    public void finish(Database.BatchableContext context) {
        System.debug('Batch job completed');
    }
    
    public static Map<String, tc9_bgl__Acc_Payroll_Journal_Lines__c> getAccountJournalLinesMap(Set<Id> accountJournalIdSet, Set<Id> currentPaymentEntityIds, 
                                                                                     Set<String> departmentSet, Id departmentId, Id naturalaccountId, 
                                                                                     Set<String> leaveTypeSet) {
        String query = 'SELECT Id, tc9_bgl__Accounting_Payroll_Journal__c, tc9_bgl__Entity__c,' +
            ' tc9_bgl__Department__c, tc9_bgl__Natural_Account__c, tc9_bgl__Description__c, ' +
            ' tc9_bgl__Debit__c, tc9_bgl__Credit__c ' +
            ' FROM tc9_bgl__Acc_Payroll_Journal_Lines__c ' +
            ' WHERE tc9_bgl__Accounting_Payroll_Journal__c IN :accountJournalIdSet' +
            ' AND tc9_bgl__Entity__c IN :currentPaymentEntityIds';
            query += departmentSet != null ? ' AND tc9_bgl__Department__c IN :departmentSet' : ' AND tc9_bgl__Department__c = :departmentId';
            query += (' AND tc9_bgl__Natural_Account__c = :naturalaccountId' + ' AND tc9_bgl__Description__c IN :leaveTypeSet');
        
        List<tc9_bgl__Acc_Payroll_Journal_Lines__c> apjLines = database.query(query);
                
        Map<String, tc9_bgl__Acc_Payroll_Journal_Lines__c> apjLineMap = new Map<String, tc9_bgl__Acc_Payroll_Journal_Lines__c>();                                                                  
        for(tc9_bgl__Acc_Payroll_Journal_Lines__c apjLine : apjLines) {
            String apjLineKey = buildAccPayrollJournalLineKey(apjLine.tc9_bgl__Accounting_Payroll_Journal__c, apjLine.tc9_bgl__Entity__c, 
                                                          apjLine.tc9_bgl__Department__c, apjLine.tc9_bgl__Natural_Account__c, 
                                                          apjLine.tc9_bgl__Description__c);

            apjLineMap.put(apjLineKey, apjLine);
        }
                                                                                         
        return apjLineMap;
    }
}