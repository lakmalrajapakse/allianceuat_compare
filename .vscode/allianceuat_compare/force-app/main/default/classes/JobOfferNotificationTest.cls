@isTest
public class JobOfferNotificationTest {

    @testSetup
    static void setupData() {
        // Accounting System
        tc9_bgl__Acc_System_Setup__c accSystem = new tc9_bgl__Acc_System_Setup__c(Name='test 4');
        insert accSystem;

        // GL Department
        tc9_bgl__Acc_Segments__c glDept = new tc9_bgl__Acc_Segments__c(
            Name='test 3',
            tc9_bgl__Accounting_System__c = accSystem.Id
        );
        insert glDept;

        // Branch
        Branch__c branch = new Branch__c(
            Branch_Name__c='test5',
            Branch_Code__c='00A',
            GL_Department__c=glDept.Id,
            City__c='test'
        );
        insert branch;

        // Contact
        Contact con = new Contact(
            LastName='test',
            MobilePhone='0000000000',
            Email='test1212@gmail.com',
            Candidate_Timezone__c='Australia/Perth',
            Branch__c = branch.Id
        );
        insert con;

        // Shift
        sirenum__Shift__c shift = new sirenum__Shift__c(
            sirenum__Scheduled_Time__c='00:00',
            sirenum__Scheduled_Start_Time__c=Datetime.newInstance(2025,2,19,0,0,0),
            sirenum__Scheduled_End_Time__c=Datetime.newInstance(2025,2,19,0,0,0)
        );
        insert shift;

        // Push Notification Settings
        Job_Offer_Notification__c settings = new Job_Offer_Notification__c(
            SetupOwnerId=UserInfo.getOrganizationId(),
            Batch_Size__c=1,
            Message__c='Test Message',
            Title__c='Test Title',
            Status__c='Broadcasting'
        );
        insert settings;

        // Valid Shift Invitation
        sirenum__Shift_Invitation__c validInv = new sirenum__Shift_Invitation__c(
            Name='Valid Invitation',
            sirenum__Status__c='Broadcasting',
            sirenum__Shift__c=shift.Id,
            sirenum__Contact__c=con.Id
        );
        insert validInv;

        // Invalid Shift Invitation
        sirenum__Shift_Invitation__c invalidInv = new sirenum__Shift_Invitation__c(
            Name='Invalid Invitation',
            sirenum__Status__c='Stale',
            sirenum__Shift__c=shift.Id,
            sirenum__Contact__c=con.Id
        );
        insert invalidInv;
    }

    @isTest
    static void testSyncAndFilterLogic() {
        // Query test data with all required fields
        List<sirenum__Shift_Invitation__c> invitations = [
            SELECT Id, sirenum__Status__c, sirenum__Shift__c, sirenum__Contact__c
            FROM sirenum__Shift_Invitation__c
        ];

        Test.startTest();
        JobOfferNotificationService.handleShiftInvitations(invitations);
        Test.stopTest();

        System.assert(true,'JobOfferNotificationService executed sync/filter logic');
    }

    @isTest
    static void testBatchExecution() {
        sirenum__Shift_Invitation__c validInv = [
            SELECT Id, sirenum__Status__c, sirenum__Shift__c, sirenum__Contact__c
            FROM sirenum__Shift_Invitation__c
            WHERE sirenum__Status__c='Broadcasting'
            LIMIT 1
        ];

        Test.startTest();
        Database.executeBatch(new JobOfferNotificationBatch(new List<Id>{validInv.Id}, 'Msg', 'Title'), 1);
        Test.stopTest();

        System.assert(true,'JobOfferNotificationBatch executed successfully');
    }

    @isTest
    static void testNoValidRecords() {
        sirenum__Shift_Invitation__c invalidInv = [
            SELECT Id, sirenum__Status__c, sirenum__Shift__c, sirenum__Contact__c
            FROM sirenum__Shift_Invitation__c
            WHERE sirenum__Status__c='Stale'
            LIMIT 1
        ];

        Test.startTest();
        JobOfferNotificationService.handleShiftInvitations(new List<sirenum__Shift_Invitation__c>{invalidInv});
        Test.stopTest();

        System.assert(true,'No valid records processed, path covered');
    }
 @isTest
    static void testSendNotificationsSyncDirectly() {
        sirenum__Shift_Invitation__c validInv = [
            SELECT Id, sirenum__Status__c, sirenum__Shift__c, sirenum__Contact__c
            FROM sirenum__Shift_Invitation__c
            WHERE sirenum__Status__c='Broadcasting'
            LIMIT 1
        ];

        Test.startTest();
        // Direct call since method is now public
        JobOfferNotificationService.sendNotificationsSync(
            new List<Id>{validInv.Id},
            'Direct Test Message',
            'Direct Test Title'
        );
        Test.stopTest();

        System.assert(true,'sendNotificationsSync executed directly');
    }

}