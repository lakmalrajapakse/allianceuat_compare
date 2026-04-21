@isTest
public class SkieInvoicePDFBaseSetupTestTest {

    // Helper to safely get DeveloperName from RecordTypeId
    private static String getRecordTypeDeveloperName(Id rtId) {
        RecordType rt = [
            SELECT DeveloperName
            FROM RecordType
            WHERE Id = :rtId
            LIMIT 1
        ];
        return rt.DeveloperName;
    }

    @isTest
    static void test_prepareInvoiceSetting() {
        Account acc = SkieInvoicePDFBaseSetupTest.prepareClientAccount(null, 'Client', null);
        Account invoiceEntity = SkieInvoicePDFBaseSetupTest.prepareClientAccount(null, 'Invoice_Entity', null);

        if (Schema.SObjectType.Account.fields.getMap().containsKey('Approval_Type__c')) {
            acc.put('Approval_Type__c', 'Not Charged');
            invoiceEntity.put('Approval_Type__c', 'Not Charged');
        }
        if (Schema.SObjectType.Account.fields.getMap().containsKey('Payroll_Tax_Exempt__c')) {
            acc.put('Payroll_Tax_Exempt__c', 'No');
            invoiceEntity.put('Payroll_Tax_Exempt__c', 'No');
        }

        insert new List<Account>{ acc, invoiceEntity };

        tc9_et__Payment_Terms__c payTerm = SkieInvoicePDFBaseSetupTest.preparePaymentTerm();
        insert payTerm;

        tc9_et__Invoice_Setting__c invSet = SkieInvoicePDFBaseSetupTest.prepareInvoiceSetting(
            'Payroll_Items', 'Payroll_Items', acc.Id, invoiceEntity.Id, payTerm.Id
        );
        insert invSet;

        System.assertNotEquals(null, invSet.Id, 'Invoice Setting should be inserted');
        System.assertEquals(acc.Id, invSet.tc9_et__Account__c);
    }

    @isTest
    static void test_prepareEmployeeAndClientAccount() {
        Account clientAcc = SkieInvoicePDFBaseSetupTest.prepareClientAccount(null, 'Client', null);
        Account empAcc = SkieInvoicePDFBaseSetupTest.prepareEmployeeAccount(null);

        if (Schema.SObjectType.Account.fields.getMap().containsKey('Approval_Type__c')) {
            clientAcc.put('Approval_Type__c', 'Not Charged');
            empAcc.put('Approval_Type__c', 'Not Charged');
        }
        if (Schema.SObjectType.Account.fields.getMap().containsKey('Payroll_Tax_Exempt__c')) {
            clientAcc.put('Payroll_Tax_Exempt__c', 'No');
            empAcc.put('Payroll_Tax_Exempt__c', 'No');
        }

        insert new List<Account>{ clientAcc, empAcc };

        Contact emp = SkieInvoicePDFBaseSetupTest.prepareEmployee(empAcc);
        insert emp;

        System.assertEquals(emp.AccountId, empAcc.Id, 'Employee should be linked to employee account');
        System.assertEquals('Client', getRecordTypeDeveloperName(clientAcc.RecordTypeId), 'RecordType should be Client');
    }

    @isTest
    static void test_prepareInterpretationRule() {
        tc9_et__Interpretation_Rule__c rule = SkieInvoicePDFBaseSetupTest.prepareInterpretationRule(38, 30, 3, 4, 5, true);
        insert rule;

        System.assertNotEquals(null, rule.Id, 'Interpretation Rule should be inserted');
        System.assertEquals('Weekly', rule.tc9_et__Timesheet_Frequency__c);
    }

    @isTest
    static void test_getRandomString_uniqueness() {
        String rand1 = SkieInvoicePDFBaseSetupTest.getRandomString('Test');
        String rand2 = SkieInvoicePDFBaseSetupTest.getRandomString('Test');

        System.assertNotEquals(rand1, rand2, 'Each call to getRandomString should return a unique value');
        System.assert(rand1.startsWith('Test'), 'String should start with prefix');
    }

    @isTest
    static void test_prepareSetting() {
        tc9_pr__Override_TC9P_Validation__c setting = SkieInvoicePDFBaseSetupTest.prepareSetting();
        insert setting;

        System.assert(setting.tc9_et__OV_Invoice_Setting__c, 'Expected invoice setting override to be true');
        System.assertNotEquals(null, setting.Id, 'Setting should be inserted');
    }
}