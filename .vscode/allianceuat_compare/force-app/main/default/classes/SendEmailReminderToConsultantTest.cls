@IsTest
public class SendEmailReminderToConsultantTest {

    /* ============================================================
       TEST SETUP DATA (YOUR DATA + BRANCH EMAIL)
       ============================================================ */
    @testSetup
    static void setupData() {

        // Accounting System
        tc9_bgl__Acc_System_Setup__c accSystem =
            new tc9_bgl__Acc_System_Setup__c(Name = 'test 4');
        insert accSystem;

        // GL Department
        tc9_bgl__Acc_Segments__c glDept =
            new tc9_bgl__Acc_Segments__c(
                Name = 'test 3',
                tc9_bgl__Accounting_System__c = accSystem.Id
            );
        insert glDept;


        // Branch (EMAIL SET HERE)
        Branch__c branch = new Branch__c(
            Branch_Name__c = 'test5',
            Branch_Code__c = '00A',
            GL_Department__c = glDept.Id,
            City__c = 'test',
            Contact_Email__c = 'branch@test.com'
        );
        insert branch;
    }

    /* ============================================================
       SUCCESS SCENARIO
       ============================================================ */
    @IsTest
    static void testSendEmailUsingBranchEmail() {

        Branch__c branch = [
            SELECT Id, Contact_Email__c
            FROM Branch__c
            LIMIT 1
        ];

        System.assertNotEquals(
            null,
            branch.Contact_Email__c,
            'Branch email must be populated'
        );
        OrgWideEmailAddress singleOWEA = [
            SELECT Id, Address, DisplayName
            FROM OrgWideEmailAddress
            LIMIT 1
        ];

        EmailTemplate et = new EmailTemplate(
            Name = 'Branch Reminder Template',
            DeveloperName = 'Branch_Reminder_Template',
            FolderId = UserInfo.getUserId(),
            Subject = 'Branch Reminder',
            HtmlValue = '<html><body>Reminder for Branch</body></html>',
            TemplateType = 'custom'
        );
        insert et;

        SendEmailReminderToConsultant.Request req =
            new SendEmailReminderToConsultant.Request();

        req.templateId   = et.Id;
        req.whatId       = branch.Id;                 //Branch as whatId
        req.emailAddress = singleOWEA.Address;   //Branch email

        List<SendEmailReminderToConsultant.Request> reqList =
            new List<SendEmailReminderToConsultant.Request>{ req };

        Test.startTest();
        List<SendEmailReminderToConsultant.Response> responses =
            SendEmailReminderToConsultant.sendEmail(reqList);
        Test.stopTest();
        System.assertEquals(1, responses.size());
    }
}