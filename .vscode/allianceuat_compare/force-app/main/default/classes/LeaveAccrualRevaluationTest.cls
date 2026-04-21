/**
 * Created by Skie on 21/01/2025.
 *
 * Author: James
 * Purpose: Test Class for LeaveAccrualRevaluationSchedule
 *
 * Change History
    ******************************************************************************************************************************************
         SCRUM        Modified By           Date        Requested By        Description                              
    ******************************************************************************************************************************************
         NS-19          James            21/01/2025             
 */
@isTest
public without sharing class LeaveAccrualRevaluationTest extends LeaveAccrualRevaluationBaseSetupTest {
    @TestSetup
    static void makeData() {
        tc9_pr__Override_TC9P_Validation__c setting = prepareSetting();
        insert setting;
        
        tc9_bgl__Acc_System_Setup__c acss = new tc9_bgl__Acc_System_Setup__c();
        acss.Name = 'Accounting System Setup';
        insert acss;
        //LAR Process Setup
        tc9_bgl__Acc_Segments__c laSegment = new tc9_bgl__Acc_Segments__c();
        laSegment.tc9_bgl__Accounting_System__c = acss.Id;
        laSegment.tc9_bgl__Active_Inactive__c = true;
        laSegment.RecordTypeId = Schema.SObjectType.tc9_bgl__Acc_Segments__c.getRecordTypeInfosByDeveloperName().get('Natural_Account').getRecordTypeId();
        laSegment.Name = 'Leave Accrual';
        
        tc9_bgl__Acc_Segments__c llSegment = new tc9_bgl__Acc_Segments__c();
        llSegment.tc9_bgl__Accounting_System__c = acss.Id;
        llSegment.tc9_bgl__Active_Inactive__c  = true;
        llSegment.RecordTypeId = Schema.SObjectType.tc9_bgl__Acc_Segments__c.getRecordTypeInfosByDeveloperName().get('Natural_Account').getRecordTypeId();
        llSegment.Name = 'Leave Liability';
        
        tc9_bgl__Acc_Segments__c dbSegment = new tc9_bgl__Acc_Segments__c();
        dbSegment.tc9_bgl__Accounting_System__c = acss.Id;
        dbSegment.tc9_bgl__Active_Inactive__c  = true;
        dbSegment.RecordTypeId = Schema.SObjectType.tc9_bgl__Acc_Segments__c.getRecordTypeInfosByDeveloperName().get('Assignment_Department').getRecordTypeId();
        dbSegment.Name = 'Dept Balance Sheet';
        
        tc9_bgl__Acc_Segments__c assignmentDepartment = new tc9_bgl__Acc_Segments__c();
        assignmentDepartment.tc9_bgl__Accounting_System__c = acss.Id;
        assignmentDepartment.tc9_bgl__Active_Inactive__c  = true;
        assignmentDepartment.RecordTypeId = Schema.SObjectType.tc9_bgl__Acc_Segments__c.getRecordTypeInfosByDeveloperName().get('Assignment_Department').getRecordTypeId();
        assignmentDepartment.Name = 'Assignment Department';

        insert new List<tc9_bgl__Acc_Segments__c>{laSegment, llSegment, dbSegment, assignmentDepartment};

        acss.tc9_bgl__Default_Account_Leave_Accural__c = laSegment.Id;
        acss.tc9_bgl__Default_Account_Leave_Liability__c = llSegment.Id;
        acss.tc9_bgl__Default_Dept_Balance_Sheet__c = dbSegment.Id;
        upsert acss;

        tc9_bgl__GL_Configuration__c settingGL = new tc9_bgl__GL_Configuration__c();
        settingGL.tc9_bgl__Default_Accounting_System_Setup_Id__c = acss.Id;
        insert settingGL;

        //Payee Setup
        Date startDate = Date.today().toStartOfWeek();
        Date endDate = startDate.addDays(30);
        
        tc9_pr__Location__c location = prepareTaxLocation();
        insert location;
        
        tc9_et__Payment_Terms__c pterm = preaprePaymentTerm();
        insert pterm;
        
        tc9_et__Interpretation_Rule__c intRule = prepareInterpretationRule(38.0, 15.0, 5.0, 5.0, 5.0, false);
        insert intRule;
        
        tc9_pr__Schedule__c schedule = prepareSchedule('Weekly','W','Pay_Schedule');
        tc9_pr__Schedule__c scheduleInv = prepareSchedule('Weekly','W','Invoice_Schedule');
        
        List<tc9_pr__Schedule__c> schList = new List<tc9_pr__Schedule__c>{schedule, scheduleInv};
        insert schList;
        
        Account acc = prepareClientAccount(location.Id, 'Client', schedule.Id);        
        Account invoiceEntity = prepareClientAccount(location.Id, 'Invoice_Entity', schedule.Id);
        Account paymentEntity = prepareClientAccount(location.Id, 'Payment_Entity', schedule.Id);
        Account candAcc = prepareEmployeeAccount(location.Id);
        
        //ALN-344: Fixes
        for (Account a : new List<Account>{acc, invoiceEntity, paymentEntity, candAcc}) {
            a.Payroll_Tax_Exempt__c = 'No';
            a.Approval_Type__c = 'Not Charged';
        }
                
        insert new List<Account>{acc, invoiceEntity, paymentEntity, candAcc};
            
        Contact clientCon = prepareClientContact(acc);
        Contact employee = prepareEmployee(candAcc);
        insert new List<Contact>{clientCon, employee};
            
        /*Profile prof = [Select Name, Id From Profile p where Name = 'Employee Community User'];
        User commUser = preparePortalUser(prof, employee);
        insert commUser;
        
        System.runAs(commUser) {
            insert new PermissionSetAssignment (
                AssigneeId = UserInfo.getUserId(),
                PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Employee_Community_Permission_Set'][0].Id);
        }*/
        
        tc9_pr__Payee__c payee = preparePayee(schedule.Id, employee.Id, paymentEntity.Id,'PAYE');
        insert payee;
        
        tc9_pr__Calendar__c pubCal = preparePublicHolidayCalendar(schedule.Id, paymentEntity.Id);
        insert pubCal;
        
        tc9_pr__Calendar_Period__c pCalItem = prepareHoliday(pubCal.Id, startDate, startDate.addDays(1));
        insert pCalItem;
        
        tc9_pr__Calendar__c tsCal = prepareTimesheetCalendar(schedule.Id, paymentEntity.Id, true, startDate, 'Weekly', 'Start/End Times', 'Start/End Times', scheduleInv.Id, invoiceEntity.Id);
        insert tsCal;
        
        tc9_pr__Calendar_Period__c tsCalItem = prepareHoliday(tsCal.Id, startDate.addDays(-2), startDate.addDays(100));
        insert tsCalItem;
        
        tc9_pr__Assignment__c assignment = prepareAssignment(tsCal.Id, acc.Id, clientCon.Id, schedule.Id, pubCal.Id, employee.Id, startDate, endDate, intRule.Id, 'Temp', pterm.Id, payee.Id, scheduleInv.Id, paymentEntity.Id);
        insert assignment;
        
        tc9_pr__Pay_Code__c payCodeAllowance = preparePayCode('Allowance');
        insert payCodeAllowance;
        
        tc9_pr__Pay_Code__c payCodePayment = preparePayCode('Payment');
        insert payCodePayment;
        
        tc9_pr__Pay_Code__c payCodeUnpaidPayment = preparePayCode('Payment');
        insert payCodeUnpaidPayment;
        
        tc9_pr__Project_Code__c assProjectCode = prepareProjectCode('Assignment_Level', assignment.Id);
        insert assProjectCode;
        
        tc9_pr__Project_Code__c actAssProjectCode = prepareProjectCode('Timesheet_Activity_Assignment_Level', assignment.Id);
        insert actAssProjectCode;
        
        tc9_et__Timesheet__c tsNew = prepareTimesheet(assignment.Id, employee.Id, payee.Id, Date.today().addDays(1), Date.today().addDays(7), 'New');
        insert tsNew;
        
        tc9_et__Timesheet__c tsSubmitted = prepareTimesheet(assignment.Id, employee.Id, payee.Id, Date.today(), Date.today().addDays(7), 'Submitted');
        insert tsSubmitted;
        
        tc9_et__Timesheet__c tsApproved = prepareTimesheet(assignment.Id, employee.Id, payee.Id, Date.today(), Date.today().addDays(7), 'Approved');
        insert tsApproved;
        
        tc9_et__Timesheet__c tsRejected = prepareTimesheet(assignment.Id, employee.Id, payee.Id, Date.today(), Date.today().addDays(7), 'Rejected');
        insert tsRejected;
        
        tc9_et__Timesheet_Entry__c tse1 = prepareTimesheetEntry(tsNew.Id, assignment.Id, payee.Id, employee.Id, startDate);
        insert tse1;
        
        tc9_et__Timesheet_Entry__c tse2 = prepareTimesheetEntry(tsNew.Id, assignment.Id, payee.Id, employee.Id, startDate.addDays(1));
        insert tse2;
        
        tc9_et__Expense_Claim__c expClaimNew = prepareExpenseClaim(assignment.Id, payee.Id, employee.Id, 'New');
        insert expClaimNew;
        
        tc9_pr__Payee_Allowance_Record__c par = preparePayeeAllowanceRecord(payCodeAllowance.Id, payee.Id, paymentEntity.Id, employee.Id, assignment.Id);
        insert par;
            
        tc9_et__Timesheet_Item__c allowance = prepareTimesheetAllowanceRecord(tsNew.Id, assignment.Id, par.Id, payee.Id, employee.Id, 1);
        insert allowance;
        
        tc9_pr__Leave_Rule__c leaveRule = prepareLeaveRule('Time_Off_in_Lieu', payCodePayment.Id, payCodeUnpaidPayment.Id, startDate);
        insert leaveRule;
        
        tc9_pr__Payee_Leave_Rule__c payeeLeaveRule = new tc9_pr__Payee_Leave_Rule__c();
        payeeLeaveRule.tc9_pr__Assignment__c = assignment.Id;
        payeeLeaveRule.tc9_pr__Employee__c = employee.Id;
        payeeLeaveRule.tc9_pr__Payee__c = payee.Id;
        payeeLeaveRule.tc9_pr__Skip_Manager_Approval__c = 'No';
        payeeLeaveRule.tc9_pr__Effective_Date__c = startDate.addDays(-20);
        payeeLeaveRule.tc9_pr__Leave_Rule__c = leaveRule.Id;
        insert payeeLeaveRule;

        tc9_bgl__Acc_Payment_Entity__c accountPED = new tc9_bgl__Acc_Payment_Entity__c();
        accountPED.tc9_bgl__Payment_Entity__c = paymentEntity.Id;
        accountPED.tc9_bgl__Accounting_System__c = acss.Id;
        insert accountPED;

        tc9_pr__Assignment_Rate__c assignmentRate = new tc9_pr__Assignment_Rate__c();
        assignmentRate.tc9_pr__Assignment__c = assignment.Id;
        insert assignmentRate;

        tc9_bgl__Acc_Assignment_Depts__c aad = new tc9_bgl__Acc_Assignment_Depts__c();
        aad.tc9_bgl__Accounting_System__c = acss.Id;
        aad.tc9_bgl__Assignment__c = assignment.Id;
        aad.tc9_bgl__Department__c = assignmentDepartment.Id;
        aad.tc9_bgl__Percentage_Split__c = 92.57;
        insert aad;

        Leave_Accrual_Revaluation__c lar = new Leave_Accrual_Revaluation__c();
        lar.Payee_Leave_Rule__c = payeeLeaveRule.Id;
        //lar.Leave_Type__c = 'Time_Off_in_Lieu Rule';
        lar.Assignment_Rate__c = assignmentRate.Id;
        lar.Revaluation_Leave_Balance__c = 100.56;
        lar.New_Liability_Rate__c = 10.55;
        lar.Old_Liability_Rate__c = 5.55;
        insert lar;

        Leave_Accrual_Revaluation__c lar2 = new Leave_Accrual_Revaluation__c();
        lar2.Payee_Leave_Rule__c = payeeLeaveRule.Id;
        //lar2.Leave_Type__c = 'Time_Off_in_Lieu Rule';
        lar2.Assignment_Rate__c = assignmentRate.Id;
        lar2.Revaluation_Leave_Balance__c = 100.56;
        lar2.New_Liability_Rate__c = 10.55;
        lar2.Old_Liability_Rate__c = 5.55;
        insert lar2;
    }

    @isTest
    static void testLeaveAccrualRevaluationSchedule() {
        Test.startTest();
        LeaveAccrualRevaluationSchedule schedule = new LeaveAccrualRevaluationSchedule();
        schedule.execute(null);
        Test.stopTest();
    }
}