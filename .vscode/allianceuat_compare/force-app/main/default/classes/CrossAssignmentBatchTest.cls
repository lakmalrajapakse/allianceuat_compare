@isTest
public class CrossAssignmentBatchTest extends CrossAssignmentBaseSetupTest {
    
    @TestSetup
    public static void setup(){
        tc9_pr__Override_TC9P_Validation__c setting = prepareSetting();
        insert setting;
        
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
        insert new List<Account>{acc, invoiceEntity, paymentEntity, candAcc};
            
        Contact clientCon = prepareClientContact(acc);
        insert clientCon;

        Contact employee = prepareEmployee(candAcc);
        insert employee;

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
        
        tc9_pr__Assignment__c assignment2 = prepareAssignment(tsCal.Id, acc.Id, clientCon.Id, schedule.Id, pubCal.Id, employee.Id, startDate.addDays(-30), endDate, intRule.Id, 'Temp', pterm.Id, payee.Id, scheduleInv.Id, paymentEntity.Id);
        assignment2.Cross_Assignment_Group_By_ID__c = 'reallylikesshiftwork';
        assignment2.tc9_pr__Assignment_Name__c = 'assignment2';
        insert assignment2;

        tc9_pr__Assignment__c assignment3 = prepareAssignment(tsCal.Id, acc.Id, clientCon.Id, schedule.Id, pubCal.Id, employee.Id, startDate.addDays(-30), endDate, intRule.Id, 'Temp', pterm.Id, payee.Id, scheduleInv.Id, paymentEntity.Id);
        assignment3.Cross_Assignment_Group_By_ID__c = 'reallylikesshiftwork';
        assignment3.Cross_Assignment_Timesheet_Status__c = 'Approved';
        assignment3.tc9_pr__Assignment_Name__c = 'assignment3';
        insert assignment3;
        
        tc9_pr__Pay_Code__c payCodeAllowance = preparePayCode('Allowance');
        insert payCodeAllowance;
        
        tc9_pr__Pay_Code__c payCodePayment = preparePayCode('Payment');
        insert payCodePayment;
        
        tc9_pr__Pay_Code__c payCodeUnpaidPayment = preparePayCode('Payment');
        insert payCodeUnpaidPayment;

        tc9_et__Timesheet__c tsApproved = prepareTimesheet(assignment.Id, employee.Id, payee.Id, Date.today(), Date.today().addDays(7), 'Approved');
        tsApproved.tc9_et__Transaction_Creation_Stage__c = '3';
        tsApproved.Cross_Assignment_Status__c = 'Pending Delete';
        insert tsApproved;

        tc9_et__Timesheet__c tsApprove2 = prepareTimesheet(assignment2.Id, employee.Id, payee.Id, Date.today(), Date.today().addDays(31), 'Approved');
        tsApprove2.tc9_et__Transaction_Creation_Stage__c = '5';
        tsApprove2.Cross_Assignment_Status__c = 'Pending Insert';
        insert tsApprove2;

        tc9_et__Timesheet_Entry__c tse1 = prepareTimesheetEntry(tsApproved.Id, assignment.Id, payee.Id, employee.Id, startDate);
        tse1.Cross_Assignment_Timesheet_Entry__c = true;
        insert tse1;

        tc9_et__Timesheet_Entry__c tse2 = prepareTimesheetEntry(tsApproved.Id, assignment.Id, payee.Id, employee.Id, startDate);
        tse2.Cross_Assignment_Timesheet_Entry__c = true;
        insert tse2;

        tc9_et__Timesheet_Entry__c tse3 = prepareTimesheetEntry(tsApproved.Id, assignment3.Id, payee.Id, employee.Id, startDate.addDays(5));
        tse3.tc9_et__Total_Hours__c = 15.00;
        tse3.tc9_et__Approval_Flag__c = true;
        tse3.Cross_Assignment_Timesheet_Entry__c = false;
        insert tse3;

        tc9_et__Timesheet_Entry__c tse4 = prepareTimesheetEntry(tsApprove2.Id, assignment3.Id, payee.Id, employee.Id, startDate.addDays(5));
        tse4.tc9_et__Total_Hours__c = 25.00;
        tse4.tc9_et__Approval_Flag__c = true;
        tse4.Cross_Assignment_Timesheet_Entry__c = true;
        insert tse4;

        tc9_et__Timesheet_Entry__c tse5 = prepareTimesheetEntry(tsApproved.Id, assignment3.Id, payee.Id, employee.Id, startDate.addDays(5));
        tse5.tc9_et__Total_Hours__c = 75.00;
        tse5.tc9_et__Approval_Flag__c = true;
        tse5.Cross_Assignment_Timesheet_Entry__c = true;
        insert tse5;

        tc9_pr__Pay_Transaction__c payt = preparePayTransaction(payee.Id, payCodePayment.Id, assignment.Id, 5100, 1100);
        payt.tc9_et__Timesheet_Entry__c = tse1.Id;
        payt.tc9_et__Timesheet__c = tsApproved.Id;
        insert payt;
    }

    @isTest
    public static void givenPayTransactionAndTimesheetEntry_whenCallCrossAssignmentDeleteBatch_thenDeleteSuccessfully() {
        Test.startTest();
        new CrossAssignmentDeleteBatch().execute(null);
        Test.stopTest();
        List<tc9_et__Timesheet_Entry__c> tses = [SELECT Id FROM tc9_et__Timesheet_Entry__c];
        Assert.areEqual(2, tses.size());
    }

    @isTest
    public static void givenTimesheetId_whenBuildDebugForDeleteTimesheetEntries_thenCreateDebugSuccessfully() {
        tc9_et__Timesheet__c ts = [SELECT Id FROM tc9_et__Timesheet__c LIMIT 1];
        Test.startTest();
        CrossAssignmentDeleteBatch.buildDebugHeader();
        CrossAssignmentDeleteBatch.buildDebugLog(ts.Id, 'Timesheet Entries', 'error message');
        Test.stopTest();
    }

    @isTest
    public static void givenTimesheetEntries_whenCallCrossAssignmentInsertBatch_thenCloneTimesheetEntrySuccessfully2() {
        Test.startTest();
        new CrossAssignmentInsertBatch().execute(null);
        Test.stopTest();
        List<tc9_et__Timesheet_Entry__c> tses = [SELECT Id FROM tc9_et__Timesheet_Entry__c];
        Assert.areEqual(5, tses.size());
    }

    @isTest
    public static void givenTimesheetEntries_whenCallCrossAssignmentInsertBatch_thenCloneTimesheetEntrySuccessfully3() {
        tc9_pr__Assignment__c assignment = [SELECT Id, Cross_Assignment_Timesheet_Status__c FROM tc9_pr__Assignment__c WHERE tc9_pr__Assignment_Name__c = 'assignment2' LIMIT 1];
        assignment.Cross_Assignment_Timesheet_Status__c = 'All';
        update assignment;

        Test.startTest();
        new CrossAssignmentInsertBatch().execute(null);
        Test.stopTest();
        List<tc9_et__Timesheet_Entry__c> tses = [SELECT Id FROM tc9_et__Timesheet_Entry__c];
        Assert.areEqual(5, tses.size());
    }

    @isTest
    public static void givenTimesheetEntries_whenCallCrossAssignmentInsertBatch_thenCloneTimesheetEntrySuccessfully() {
        Test.startTest();
        CrossAssignmentInsertBatch.insertCrossAssignment(null);
        Test.stopTest();
        List<tc9_et__Timesheet_Entry__c> tses = [SELECT Id FROM tc9_et__Timesheet_Entry__c];
        Assert.areEqual(5, tses.size());
    }

    @isTest
    public static void givenTimesheetId_whenBuildDebugForInsertTimesheetEntries_thenCreateDebugSuccessfully() {
        tc9_et__Timesheet__c ts = [SELECT Id FROM tc9_et__Timesheet__c LIMIT 1];
        Test.startTest();
        CrossAssignmentInsertBatch.buildDebugHeader();
        CrossAssignmentInsertBatch.buildDebugLog(ts.Id, 'Timesheet Entries', 'error message');
        Test.stopTest();
    }
}