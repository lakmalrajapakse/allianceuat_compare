public with sharing class SkieSplitJournalService {

    public static void processSplitJournals(List<tc9_bgl__Acc_Payroll_Journal__c> newJournals, Map<Id, tc9_bgl__Acc_Payroll_Journal__c> oldJournals) {
    
        Set<String> accountingSystemIds = new Set<String>();
        Set<String> paymentEntityIds = new Set<String>();
        Set<String> paybatchIds = new Set<String>();

        Set<Id> journalIds = new Set<id>();
        for(tc9_bgl__Acc_Payroll_Journal__c journal : newJournals) {
            if(journal.Trigger_Splits__c && journal.Trigger_Splits__c != oldJournals.get(journal.Id).Trigger_Splits__c){
                   journalIds.add(journal.Id);
            }
        }

        if(journalIds.isEmpty()) {
            return;
        }

        List<tc9_bgl__Acc_Payroll_Journal__c> existingJournals = [SELECT Id, tc9_bgl__Pay_Batch__r.tc9_pr__Payment_Entity__c, tc9_bgl__Accounting_System__c 
                                                                  FROM tc9_bgl__Acc_Payroll_Journal__c 
                                                                  WHERE Id IN :journalIds
        ];

        for(tc9_bgl__Acc_Payroll_Journal__c journal : existingJournals) {
            accountingSystemIds.add(journal.tc9_bgl__Accounting_System__c);
            paymentEntityIds.add(journal.tc9_bgl__Pay_Batch__r.tc9_pr__Payment_Entity__c);
            paybatchIds.add(journal.tc9_bgl__Pay_Batch__c);
        }

        Set<Id> entityIds = new Set<Id>();
        Set<Id> departmentIds = new Set<Id>();
        Map<String, tc9_bgl__Acc_Payment_Entity__c> paymentEntMap = new Map<String, tc9_bgl__Acc_Payment_Entity__c>();
        for(tc9_bgl__Acc_Payment_Entity__c entityDefault : [SELECT Id, tc9_bgl__GL_Entity_Code__c, tc9_bgl__Payment_Entity__c, tc9_bgl__GL_Bank_Account_Department__c, tc9_bgl__GL_Bank_Account_Number__c 
                                                            FROM tc9_bgl__Acc_Payment_Entity__c 
                                                            WHERE tc9_bgl__Payment_Entity__c IN :paymentEntityIds]){
            entityIds.add(entityDefault.tc9_bgl__GL_Entity_Code__c);
            departmentIds.add(entityDefault.tc9_bgl__GL_Bank_Account_Department__c);
            paymentEntMap.put(entityDefault.tc9_bgl__Payment_Entity__c, entityDefault);
        }
        
        Map<String, List<tc9_pr__Pay_Transaction_Distribution__c>> ptdWorkcoverMap = getWorkCoverPayTrnDistributionMap(paybatchIds);
        Map<String, List<tc9_pr__Pay_Transaction_Distribution__c>> ptdPayrollTaxMap = getPayrollTaxPayTrnDistributionMap(paybatchIds);

        System.debug('[INFO] ptdWorkcoverMap.size=' + ptdWorkcoverMap.size());
        System.debug('[INFO] ptdPayrollTaxMap.size=' + ptdPayrollTaxMap.size());

        Set<String> naturalAccs = new Set<String>();
        Map<Id,tc9_bgl__Acc_System_Setup__c> accSystemSetupMap = new Map<Id, tc9_bgl__Acc_System_Setup__c>();
        for(tc9_bgl__Acc_System_Setup__c systemSetup : [SELECT Id, Work_Cover_Liability_ACT__c, Work_Cover_Liability_NSW__c, Work_Cover_Liability_NT__c, tc9_bgl__Default_Account_WorkCover_Liability__c,
                                                        Work_Cover_Liability_QLD__c, Work_Cover_Liability_SA__c, Work_Cover_Liability_TAS__c, Work_Cover_Liability_VIC__c, 
                                                        Work_Cover_Liability_WA__c, Split_Workcover_by_State__c, Split_Payroll_Tax_by_State__c, tc9_bgl__Default_Account_Payroll_Tax_Liability__c,
                                                        Payroll_Tax_Liability_ACT__c, Payroll_Tax_Liability_NSW__c, Payroll_Tax_Liability_NT__c, Payroll_Tax_Liability_VIC__c, 
                                                        Payroll_Tax_Liability_QLD__c, Payroll_Tax_Liability_SA__c, Payroll_Tax_Liability_TAS__c, Payroll_Tax_Liability_WA__c
                                                        FROM tc9_bgl__Acc_System_Setup__c 
                                                        WHERE Id IN :accountingSystemIds
        ]) {
            accSystemSetupMap.put(systemSetup?.Id, systemSetup);
            naturalAccs.addAll(getLocalitySet(systemSetup));
        }

        Map<String, tc9_bgl__Acc_Payroll_Journal_Lines__c> payrollJournalLineMap = new Map<String, tc9_bgl__Acc_Payroll_Journal_Lines__c>();
        for(tc9_bgl__Acc_Payroll_Journal_Lines__c jl : [SELECT Id, tc9_bgl__Natural_Account__c, tc9_bgl__Accounting_Payroll_Journal__c, tc9_bgl__Credit__c,
                                                            tc9_bgl__Entity__c, tc9_bgl__Department__c
                                                        FROM tc9_bgl__Acc_Payroll_Journal_Lines__c
                                                        WHERE tc9_bgl__Accounting_Payroll_Journal__c IN :existingJournals
                                                        AND Location_Based_Created__c = true
                                                        AND tc9_bgl__Entity__c IN: entityIds
                                                        AND tc9_bgl__Department__c IN : departmentIds
                                                        AND tc9_bgl__Natural_Account__c IN :naturalAccs
        ]) {
            String key = jl.tc9_bgl__Accounting_Payroll_Journal__c + '-' + jl.tc9_bgl__Entity__c + '-' + jl.tc9_bgl__Department__c + '-' + jl.tc9_bgl__Natural_Account__c;
            if(!payrollJournalLineMap.containsKey(key)) {
                payrollJournalLineMap.put(key, jl);

            } 
        }

        List<tc9_bgl__Acc_Payroll_Journal_Lines__c> insReversalLines = new List<tc9_bgl__Acc_Payroll_Journal_Lines__c>();
        for(tc9_bgl__Acc_Payroll_Journal__c journal : existingJournals) {
            tc9_bgl__Acc_System_Setup__c setup = accSystemSetupMap.get(journal.tc9_bgl__Accounting_System__c);
            tc9_bgl__Acc_Payment_Entity__c entityDefault = paymentEntMap.get(journal.tc9_bgl__Pay_Batch__r.tc9_pr__Payment_Entity__c);

            if(setup != null && setup.Split_Workcover_by_State__c) {
                Double workCoverTotal = processSplitWorkCover(journal, setup, entityDefault, payrollJournalLineMap, ptdWorkcoverMap);
                System.debug('[INFO] workCoverTotal=' + workCoverTotal + ', journal='  + journal.Id);

                // Create reversal
                if(workCoverTotal != null) {
                    tc9_bgl__Acc_Payroll_Journal_Lines__c reversalJL = buildCreateReversalJournalLineData(journal, entityDefault, workCoverTotal, setup.tc9_bgl__Default_Account_WorkCover_Liability__c, 'Workcover Liab - Location Reversal');
                    insReversalLines.add(reversalJL);
                }

            }

            if(setup != null && setup.Split_Payroll_Tax_by_State__c) {
                Double payrollTaxTotal = processSplitPayrollTax(journal, setup, entityDefault, payrollJournalLineMap, ptdPayrollTaxMap);
                System.debug('[INFO] payrollTaxTotal=' + payrollTaxTotal + ', journal='  + journal.Id);
                
                // Create reversal
                if(payrollTaxTotal != null) {
                    tc9_bgl__Acc_Payroll_Journal_Lines__c reversalJL = buildCreateReversalJournalLineData(journal, entityDefault, payrollTaxTotal, setup.tc9_bgl__Default_Account_Payroll_Tax_Liability__c, 'Payroll Tax Liab - Location Reversal');
                    insReversalLines.add(reversalJL);
                }

            }
        }

        System.debug('[INFO] payrollJournalLineMapSize=' + payrollJournalLineMap.size() + ', payrollJournalLineMap=' + payrollJournalLineMap.values());
        upsert payrollJournalLineMap.values();

        System.debug('[INFO] insReversalLinesSize=' + insReversalLines.size() + ', insReversalLines=' + insReversalLines);
        insert insReversalLines;

        Map<String, List<tc9_bgl__Acc_Payroll_Journal_Lines__c>> negCreditJournalLineMap = new Map<String, List<tc9_bgl__Acc_Payroll_Journal_Lines__c>>();
        Map<String, List<tc9_bgl__Acc_Payroll_Journal_Lines__c>> negDebitJournalLineMap = new Map<String, List<tc9_bgl__Acc_Payroll_Journal_Lines__c>>();

        for(tc9_bgl__Acc_Payroll_Journal_Lines__c jl : [SELECT Id, tc9_bgl__Natural_Account__c, tc9_bgl__Accounting_Payroll_Journal__c, tc9_bgl__Credit__c, tc9_bgl__Debit__c
                                                        FROM tc9_bgl__Acc_Payroll_Journal_Lines__c
                                                        WHERE tc9_bgl__Accounting_Payroll_Journal__c IN :existingJournals
                                                        AND Location_Based_Created__c = true
                                                        AND (tc9_bgl__Credit__c < 0 OR tc9_bgl__Debit__c < 0) ]) {
            if (jl.tc9_bgl__Credit__c < 0) {
                if (!negCreditJournalLineMap.containsKey(jl.tc9_bgl__Accounting_Payroll_Journal__c)) {
                    negCreditJournalLineMap.put(jl.tc9_bgl__Accounting_Payroll_Journal__c, new List<tc9_bgl__Acc_Payroll_Journal_Lines__c>{jl});
                } else {
                    negCreditJournalLineMap.get(jl.tc9_bgl__Accounting_Payroll_Journal__c).add(jl);
                }
            }

            if (jl.tc9_bgl__Debit__c < 0) {
                if (!negDebitJournalLineMap.containsKey(jl.tc9_bgl__Accounting_Payroll_Journal__c)) {
                    negDebitJournalLineMap.put(jl.tc9_bgl__Accounting_Payroll_Journal__c, new List<tc9_bgl__Acc_Payroll_Journal_Lines__c>{jl});
                } else {
                    negDebitJournalLineMap.get(jl.tc9_bgl__Accounting_Payroll_Journal__c).add(jl);
                }
            }
        }

        List<tc9_bgl__Acc_Payroll_Journal_Lines__c> upsertWorkcoverJLs = new List<tc9_bgl__Acc_Payroll_Journal_Lines__c>();
        for(tc9_bgl__Acc_Payroll_Journal__c journal : existingJournals) {
            List<tc9_bgl__Acc_Payroll_Journal_Lines__c> creditJLs = negCreditJournalLineMap.get(journal.Id);
            if(creditJLs != null) {
                for(tc9_bgl__Acc_Payroll_Journal_Lines__c jl : creditJLs) {
                    upsertWorkcoverJLs.add(new tc9_bgl__Acc_Payroll_Journal_Lines__c(Id=jl.Id, tc9_bgl__Credit__c = null, tc9_bgl__Debit__c = jl.tc9_bgl__Credit__c * -1));
                }
            }
    
            List<tc9_bgl__Acc_Payroll_Journal_Lines__c> debitJLs = negDebitJournalLineMap.get(journal.Id);
            if(debitJLs != null) {
                for(tc9_bgl__Acc_Payroll_Journal_Lines__c jl : debitJLs) {
                    upsertWorkcoverJLs.add(new tc9_bgl__Acc_Payroll_Journal_Lines__c(Id=jl.Id, tc9_bgl__Credit__c = jl.tc9_bgl__Debit__c * -1, tc9_bgl__Debit__c = null));
                }
            }
        
            journal.Trigger_Splits__c = false;
        }

        upsert upsertWorkcoverJLs;
        update existingJournals;
    }

    private static Decimal processSplitWorkCover(tc9_bgl__Acc_Payroll_Journal__c journal, tc9_bgl__Acc_System_Setup__c setup, tc9_bgl__Acc_Payment_Entity__c entityDefault, Map<String, tc9_bgl__Acc_Payroll_Journal_Lines__c> payrollJournalLineMap, Map<String, List<tc9_pr__Pay_Transaction_Distribution__c>> ptdWorkcoverMap) {
        Decimal workCoverTotal;

        if(ptdWorkcoverMap != null && ptdWorkcoverMap.containsKey(journal.tc9_bgl__Pay_Batch__c)) {
            workCoverTotal = 0;

            for(tc9_pr__Pay_Transaction_Distribution__c ptd : ptdWorkcoverMap.get(journal.tc9_bgl__Pay_Batch__c)) {
                String vLocality = ptd?.Workcover_Locality__c?.left(3);
                String naturalAccId;

                try {
                    naturalAccId = (String)setup.get('Work_Cover_Liability_' + vLocality + '__c');
                }
                catch (Exception ex) {
                    System.debug('[ERROR] SkieSplitJournalService.processSplitWorkCover error=' + ex.getMessage() + ' stackTrace=' + ex.getStackTraceString());
                }

                String key = journal.Id + '-' + entityDefault.tc9_bgl__GL_Entity_Code__c + '-' + entityDefault.tc9_bgl__GL_Bank_Account_Department__c + '-' + naturalAccId;
                if(naturalAccId == null) {
                    key += 'DEFAULT_WORKCOVER';
                }

                tc9_bgl__Acc_Payroll_Journal_Lines__c journalLine = payrollJournalLineMap.get(key);

                if(journalLine == null) {
                    tc9_bgl__Acc_Payroll_Journal_Lines__c jl = buildCreateWorkCoverLineData(journal, entityDefault, ptd.tc9_pr__WorkCover_Total__c, naturalAccId, ptd?.Workcover_Locality__c);
                    payrollJournalLineMap.put(key, jl);
                    
                }  else {
                    tc9_bgl__Acc_Payroll_Journal_Lines__c jl = payrollJournalLineMap.get(key);
                    Double credit = jl.tc9_bgl__Credit__c == null ? 0 : jl.tc9_bgl__Credit__c;
                    Double ptdWorkConverTotal = ptd.tc9_pr__WorkCover_Total__c != null ? ptd.tc9_pr__WorkCover_Total__c : 0;
                    jl.Id = journalLine?.Id;
                    jl.tc9_bgl__Credit__c = credit + ptdWorkConverTotal;
                }


                Double ptdWorkConverTotal = ptd.tc9_pr__WorkCover_Total__c != null ? ptd.tc9_pr__WorkCover_Total__c : 0;
                workCoverTotal += ptdWorkConverTotal;
            }
        }

        return workCoverTotal?.setScale(2);
    }

    private static Decimal processSplitPayrollTax(tc9_bgl__Acc_Payroll_Journal__c journal, tc9_bgl__Acc_System_Setup__c setup, tc9_bgl__Acc_Payment_Entity__c entityDefault, Map<String, tc9_bgl__Acc_Payroll_Journal_Lines__c> payrollJournalLineMap, Map<String, List<tc9_pr__Pay_Transaction_Distribution__c>> ptdPayrollTaxMap) {
        Decimal payrollTaxTotal;

        if(ptdPayrollTaxMap != null && ptdPayrollTaxMap.containsKey(journal.tc9_bgl__Pay_Batch__c)) {
            payrollTaxTotal = 0;

            for(tc9_pr__Pay_Transaction_Distribution__c ptd : ptdPayrollTaxMap.get(journal.tc9_bgl__Pay_Batch__c)) {
                String vLocality = ptd?.Payroll_Tax_Locality__c?.left(3);
                String naturalAccId;

                try {
                    naturalAccId = (String)setup.get('Payroll_Tax_Liability_' + vLocality + '__c');
                }
                catch (Exception ex) {
                    System.debug('[ERROR] SkieSplitJournalService.processSplitPayrollTax error=' + ex.getMessage() + ' stackTrace=' + ex.getStackTraceString());
                }

                String key = journal.Id + '-' + entityDefault.tc9_bgl__GL_Entity_Code__c + '-' + entityDefault.tc9_bgl__GL_Bank_Account_Department__c + '-' + naturalAccId;
                if(naturalAccId == null) {
                    key += 'DEFAULT_PAYROLL_TAX'; // to prevent both workcover and payroll tax natural acc is null.
                }

                tc9_bgl__Acc_Payroll_Journal_Lines__c journalLine = payrollJournalLineMap.get(key);

                if(journalLine == null) {
                    tc9_bgl__Acc_Payroll_Journal_Lines__c jl = buildCreatePayrollTaxLineData(journal, entityDefault, ptd.tc9_pr__Payroll_Tax_Total__c, naturalAccId, ptd?.Payroll_Tax_Locality__c);
                    payrollJournalLineMap.put(key, jl);
                    
                }  else {
                    tc9_bgl__Acc_Payroll_Journal_Lines__c jl = payrollJournalLineMap.get(key);
                    Double credit = jl.tc9_bgl__Credit__c == null ? 0 : jl.tc9_bgl__Credit__c;
                    Double ptdPayrollTaxTotal = ptd.tc9_pr__Payroll_Tax_Total__c != null ? ptd.tc9_pr__Payroll_Tax_Total__c : 0;
                    jl.Id = journalLine?.Id;
                    jl.tc9_bgl__Credit__c = credit + ptdPayrollTaxTotal;
                }

                Double ptdPayrollTaxTotal = ptd.tc9_pr__Payroll_Tax_Total__c != null ? ptd.tc9_pr__Payroll_Tax_Total__c : 0;
                payrollTaxTotal += ptdPayrollTaxTotal;
            }
        }

        return payrollTaxTotal?.setScale(2);
    }

    private static Map<String, List<tc9_pr__Pay_Transaction_Distribution__c>> getWorkCoverPayTrnDistributionMap(Set<String> paybatchIds) {
        Map<String, List<tc9_pr__Pay_Transaction_Distribution__c>> ptdMap = new Map<String, List<tc9_pr__Pay_Transaction_Distribution__c>>();
        for(tc9_pr__Pay_Transaction_Distribution__c ptd : [SELECT Id,Workcover_Locality__c, tc9_pr__Pay_Batch__c,tc9_pr__WorkCover_Total__c 
                                                           FROM tc9_pr__Pay_Transaction_Distribution__c 
                                                           WHERE tc9_pr__Pay_Batch__c IN :paybatchIds 
                                                           AND tc9_pr__WorkCover_Total__c != 0 
                                                           ORDER BY Workcover_Locality__c]) {

            if(!ptdMap.containsKey(ptd.tc9_pr__Pay_Batch__c)) {
                ptdMap.put(ptd.tc9_pr__Pay_Batch__c, new List<tc9_pr__Pay_Transaction_Distribution__c>{ptd});

            } else {
                ptdMap.get(ptd.tc9_pr__Pay_Batch__c).add(ptd);
            }
        }

        return ptdMap;
    }

    private static Map<String, List<tc9_pr__Pay_Transaction_Distribution__c>> getPayrollTaxPayTrnDistributionMap(Set<String> paybatchIds) {
        Map<String, List<tc9_pr__Pay_Transaction_Distribution__c>> ptdMap = new Map<String, List<tc9_pr__Pay_Transaction_Distribution__c>>();
        for(tc9_pr__Pay_Transaction_Distribution__c ptd : [SELECT Id, Payroll_Tax_Locality__c, tc9_pr__Pay_Batch__c, tc9_pr__Payroll_Tax_Total__c 
                                                           FROM tc9_pr__Pay_Transaction_Distribution__c 
                                                           WHERE tc9_pr__Pay_Batch__c IN :paybatchIds 
                                                           AND tc9_pr__Payroll_Tax_Total__c != 0 
                                                           ORDER BY Payroll_Tax_Locality__c]) {

            if(!ptdMap.containsKey(ptd.tc9_pr__Pay_Batch__c)) {
                ptdMap.put(ptd.tc9_pr__Pay_Batch__c, new List<tc9_pr__Pay_Transaction_Distribution__c>{ptd});

            } else {
                ptdMap.get(ptd.tc9_pr__Pay_Batch__c).add(ptd);
            }
        }

        return ptdMap;
    }

    private static Set<String> getLocalitySet(tc9_bgl__Acc_System_Setup__c systemSetup) {
        Set<String> localitySet = new Set<String>();
        localitySet.add(systemSetup?.Work_Cover_Liability_NSW__c);
        localitySet.add(systemSetup?.Work_Cover_Liability_QLD__c);
        localitySet.add(systemSetup?.Work_Cover_Liability_VIC__c);
        localitySet.add(systemSetup?.Work_Cover_Liability_SA__c);
        localitySet.add(systemSetup?.Work_Cover_Liability_WA__c);
        localitySet.add(systemSetup?.Work_Cover_Liability_NT__c);
        localitySet.add(systemSetup?.Work_Cover_Liability_TAS__c);
        localitySet.add(systemSetup?.Work_Cover_Liability_ACT__c);

        localitySet.add(systemSetup?.Payroll_Tax_Liability_NSW__c);
        localitySet.add(systemSetup?.Payroll_Tax_Liability_QLD__c);
        localitySet.add(systemSetup?.Payroll_Tax_Liability_VIC__c);
        localitySet.add(systemSetup?.Payroll_Tax_Liability_SA__c);
        localitySet.add(systemSetup?.Payroll_Tax_Liability_WA__c);
        localitySet.add(systemSetup?.Payroll_Tax_Liability_NT__c);
        localitySet.add(systemSetup?.Payroll_Tax_Liability_TAS__c);
        localitySet.add(systemSetup?.Payroll_Tax_Liability_ACT__c);

        return localitySet;
    }

    public static tc9_bgl__Acc_Payroll_Journal_Lines__c buildJournalLineData(tc9_bgl__Acc_Payroll_Journal__c journal, tc9_bgl__Acc_Payment_Entity__c entityDefault) {
        tc9_bgl__Acc_Payroll_Journal_Lines__c journalLine = new tc9_bgl__Acc_Payroll_Journal_Lines__c();
        journalLine.tc9_bgl__Accounting_Payroll_Journal__c = journal.Id;
        journalLine.tc9_bgl__Entity__c = entityDefault.tc9_bgl__GL_Entity_Code__c;
        journalLine.tc9_bgl__Department__c = entityDefault.tc9_bgl__GL_Bank_Account_Department__c;

        return journalLine;
    }
    
    public static tc9_bgl__Acc_Payroll_Journal_Lines__c buildCreateWorkCoverLineData(tc9_bgl__Acc_Payroll_Journal__c journal, tc9_bgl__Acc_Payment_Entity__c entityDefault, Decimal workCoverTotal, String naturalAccId, String vLocality) {
        tc9_bgl__Acc_Payroll_Journal_Lines__c journalLine = buildJournalLineData(journal, entityDefault);
        journalLine.tc9_bgl__Natural_Account__c = naturalAccId;
        journalLine.tc9_bgl__Description__c = 'Workcover Liab - ' + vLocality;
        journalLine.Location_Based_Created__c = true;
        journalLine.tc9_bgl__Credit__c = workCoverTotal;
        journalLine.tc9_bgl__Debit__c = null;
        return journalLine;
    }
    
    public static tc9_bgl__Acc_Payroll_Journal_Lines__c buildCreatePayrollTaxLineData(tc9_bgl__Acc_Payroll_Journal__c journal, tc9_bgl__Acc_Payment_Entity__c entityDefault, Decimal payrollTaxTotal, String naturalAccId, String vLocality) {
        tc9_bgl__Acc_Payroll_Journal_Lines__c journalLine = buildJournalLineData(journal, entityDefault);
        journalLine.tc9_bgl__Natural_Account__c = naturalAccId;
        journalLine.tc9_bgl__Description__c = 'Payroll Tax Liab - ' + vLocality;
        journalLine.Location_Based_Created__c = true;
        journalLine.tc9_bgl__Credit__c = payrollTaxTotal;
        journalLine.tc9_bgl__Debit__c = null;
        return journalLine;
    }
    
    public static tc9_bgl__Acc_Payroll_Journal_Lines__c buildCreateReversalJournalLineData(tc9_bgl__Acc_Payroll_Journal__c journal, tc9_bgl__Acc_Payment_Entity__c entityDefault, Decimal debit, String naturalAccId, String description) {
        tc9_bgl__Acc_Payroll_Journal_Lines__c journalLine = buildJournalLineData(journal, entityDefault);
        journalLine.tc9_bgl__Natural_Account__c = naturalAccId;
        journalLine.tc9_bgl__Description__c = description;
        journalLine.Location_Based_Created__c = true;

        if(debit < 0) {
            journalLine.tc9_bgl__Debit__c = null;
            journalLine.tc9_bgl__Credit__c = (debit * -1).setScale(2);
        } else {
            journalLine.tc9_bgl__Debit__c = debit?.setScale(2);
            journalLine.tc9_bgl__Credit__c = null;
        }
        
        return journalLine;
    }
}