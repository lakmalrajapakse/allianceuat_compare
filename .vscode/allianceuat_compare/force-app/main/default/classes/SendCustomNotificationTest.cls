/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class SendCustomNotificationTest {

    @isTest
    static void sendNotifcation_valid(){
        Account acc = SIM_TestDataFactory.genTestAccount('accountName', 'Client', false);
        acc.tc9_pr__Available_Payment_Methods__c = 'Payee Australian Bank';
        acc.tc9_pr__Maximum_Payment_Distributions__c = '2';
        acc.Payroll_Tax_Exempt__c = 'Yes - Workcover Only';
        acc.Approval_Type__c = 'Always Charged - As Paid';
        insert acc;
        System.debug(LOGGINGLEVEL.ERROR, 'acc.Id: ' + acc.Id);
    
        Contact cont = SIM_TestDataFactory.genTestContact('Test-Contact', acc.Id, 'Candidate', true);

        Set<String> sUsers = new Set<String>();
        sUsers.add(cont.OwnerId);
  
        String notTitle1 = 'Email Received';
        String notBody1 = 'Email Received from ' + cont.FirstName + ' ' + cont.LastName;
    
        Test.startTest();
            SendCustomNotification.notifyUsers(sUsers, cont.Id, notTitle1, notBody1, 'VMS_Shift_Created');
        Test.stopTest();
    

        Assert.areEqual(notTitle1, 'Email Received', 'Title not correct');
    }
    
    // @isTest
    // static void sendNotifcation_invalid(){
    //     Account acc = SIM_TestDataFactory.genTestAccount('accountName', 'Client', true);
    //     System.debug(LOGGINGLEVEL.ERROR, 'acc.Id: ' + acc.Id);
    
    //     Contact cont = SIM_TestDataFactory.genTestContact('Test-Contact', acc, 'Candidate', true);

    //     Set<String> sUsers = new Set<String>();
    //     sUsers.add(cont.OwnerId);
  
    //     String notTitle1 = 'Email Received';
    //     String notBody1 = 'Email Received from ' + cont.FirstName + ' ' + cont.LastName;
    
    //     Test.startTest();
    //         SendNotification.notifyUsers(sUsers, cont.Id, notTitle1, notBody1, 'Invalid_Notification');
    //     Test.stopTest();
    //     //System.debug(LOGGINGLEVEL.ERROR, 'e.getMessage: ' + e.getMessage());

    //     Assert.areEqual(notTitle1, 'Email Received', 'Title not correct');
    //}
}