@isTest
public class AlliancePayeePDFControllerTest {
    
    @testSetup
    static void setupData() {
        Account paymentEntity = new Account(
            Name = 'Test Payment Entity',
            BillingStreet = '123 Main Street',
            BillingCity = 'TestCity',
            BillingState = 'CA',
            BillingPostalCode = '12345',
            Phone = '1234567890',
            Payment_Entity_Email__c = 'test@test.com',
            tc9_pr__ABN__c = '15454545454',
            Trading_Name__c = 'TestTrading',
            tc9_pr__Available_Payment_Methods__c = 'Payee Australian Bank',
            tc9_pr__Maximum_Payment_Distributions__c = '5'
        );
        insert paymentEntity;
        
        Contact employee = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            MailingStreet = '456 Side St',
            MailingCity = 'TestCity',
            MailingState = 'CA',
            MailingPostalCode = '67890'
        );
        insert employee;
        
        tc9_pr__Payee__c payee = new tc9_pr__Payee__c(
            tc9_pr__Payment_Entity__c = paymentEntity.Id,
            tc9_pr__Employee__c = employee.Id,
            tc9_pr__Payroll_Start_Date__c = Date.today().addMonths(-2)
        );
        insert payee;
        
        Payee_Service__c service = new Payee_Service__c(
            Payee__c = payee.Id,
            Total_Hours__c = 40,
            Commencement_Date__c = Date.today().addMonths(-1)
        );
        insert service;
        
        tc9_pr__Pay_Advice__c advice = new tc9_pr__Pay_Advice__c(
            tc9_pr__Payee__c = payee.Id,
            tc9_pr__Period_End_Date__c = Date.today().addDays(-5)
        );
        insert advice;
        
        ContentVersion cv = new ContentVersion(
            Title = 'TestLogo',
            PathOnClient = 'TestLogo.png',
            VersionData = Blob.valueOf('Test Content')
        );
        insert cv;
        
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        
        ContentDocumentLink link = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = paymentEntity.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert link;
    }
    
    @isTest
    static void testControllerWithPayeeId() {
        tc9_pr__Payee__c payee = [SELECT Id FROM tc9_pr__Payee__c LIMIT 1];
        
        Test.startTest();
        PageReference pageRef = Page.AlliancePayeePDF;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('PayeeId', payee.Id);
        
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(new List<tc9_pr__Payee__c>{payee});
        AlliancePayeePDFController controller = new AlliancePayeePDFController(ssc);
        Test.stopTest();
        
        System.assertNotEquals(null, controller.payeeRecord, 'Payee record should not be null');
        System.assertNotEquals(null, controller.payeeServices, 'Payee services should not be null');
        System.assert(controller.mostRecentPayPeriodDate != null, 'Pay period date should be set');
    }
    
    @isTest
    static void testControllerWithPrintId() {
        tc9_pr__Payee__c payee = [SELECT Id FROM tc9_pr__Payee__c LIMIT 1];
        String printIdValue = payee.Id + '-' + payee.Id;
        
        Test.startTest();
        PageReference pageRef = Page.AlliancePayeePDF;
        Test.setCurrentPage(pageRef);
        
        // Pass both parameters
        ApexPages.currentPage().getParameters().put('printId', printIdValue);
        ApexPages.currentPage().getParameters().put('PayeeId', payee.Id);
        
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(new List<tc9_pr__Payee__c>{payee});
        AlliancePayeePDFController controller = new AlliancePayeePDFController(ssc);
        Test.stopTest();
        
        // Assertion
        System.assertNotEquals(null, controller.payeeRecord, 'Payee record should be initialized');
    }
    
    
}