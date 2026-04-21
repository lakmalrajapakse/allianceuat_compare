@isTest
private class ReferenceCheckExtension_test {
    public static Account acc = new Account();
    public static Contact cont = new Contact();
    public static b3o__Reference__c ref = new b3o__Reference__c();

    @isTest
    static void generateReferenceTest() {
        createData();
        PageReference pageRef = Page.ReferenceCheck;
        Test.setCurrentPage(pageRef);

        ApexPages.StandardController sController1 = new ApexPages.StandardController(ref);

        Test.startTest();
        ReferenceCheckExtension controller1 = new ReferenceCheckExtension(sController1);
        Test.stopTest();

        System.debug('controller1.firstNameApos ' + controller1.firstNameApos);
        System.debug('controller1.ratingDailyTasks ' + controller1.ratingDailyTasks);
        System.debug('controller1.ratingCommSkills ' + controller1.ratingCommSkills);
        System.debug('controller1.ratingClinicalSkills ' + controller1.ratingClinicalSkills);
        System.debug('controller1.ratingEmergencySits ' + controller1.ratingEmergencySits);
        System.debug('controller1.respProvideRefs ' + controller1.respProvideRefs);
        System.debug('controller1.respDiscloseRefs ' + controller1.respDiscloseRefs);
        System.debug('controller1.respAHPRAInvDisps ' + controller1.respAHPRAInvDisps);
        System.debug('controller1.respApplUnsupervised ' + controller1.respApplUnsupervised);
        System.debug('controller1.respDailyTasks ' + controller1.respDailyTasks);
        System.debug('controller1.respHandlingMeds ' + controller1.respHandlingMeds);
        System.debug('controller1.respOHSGuidelines ' + controller1.respOHSGuidelines);
        System.debug('controller1.respRehireAppl ' + controller1.respRehireAppl);
        System.debug('controller1.respDailyTasks ' + controller1.respDailyTasks);
        System.debug('controller1.respCommSkills ' + controller1.respCommSkills);
        System.debug('controller1.respClinicalSkills ' + controller1.respClinicalSkills);
        System.debug('controller1.respEmergencySits ' + controller1.respEmergencySits);

        String firstNameAposTest = 'First\'s';
        Boolean ratingDailyTasksTest = true;
        Boolean ratingCommSkillsTest = true;
        Boolean ratingClinicalSkillsTest = false;
        Boolean ratingEmergencySitsTest = false;
        String respProvideRefsTest = '<b>Yes</b> | No';
        String respDiscloseRefsTest = '<b>Yes</b> | No';
        String respAHPRAInvDispsest = '<b>Yes</b> | No';
        String respApplUnsupervisedTest = 'Yes | <b>No</b>';
        String respDailyTasksTest = '<b>1</b> | 2 | 3 | 4 | 5';
        String respHandlingMedsTest = '<b>Yes</b> | No';
        String respOHSGuidelinesTest = '<b>Yes</b> | No';
        String respRehireApplTest = '<b>Yes</b> | No';
        String respCommSkillsTest = '1 | 2 | <b>3</b> | 4 | 5';
        String respClinicalSkillsTest = 'Highly skilled | <b>Competent</b> | Needing assistance | Not applicable';
        String respEmergencySitsTest = '1 | 2 | 3 | <b>4</b> | 5';

        System.assertEquals(firstNameAposTest, controller1.firstNameApos, 'First Name');
        System.assertEquals(ratingDailyTasksTest, controller1.ratingDailyTasks, 'Daily Tasks');
        System.assertEquals(ratingCommSkillsTest, controller1.ratingCommSkills, 'Comm Skills');
        System.assertEquals(ratingClinicalSkillsTest, controller1.ratingClinicalSkills, 'Clinical Skills');
        System.assertEquals(ratingEmergencySitsTest, controller1.ratingEmergencySits, 'Emergency Situations'); 
        System.assertEquals(respProvideRefsTest, controller1.respProvideRefs, 'Provide Refs');
        System.assertEquals(respAHPRAInvDispsest, controller1.respAHPRAInvDisps, 'AHPRA Investigations');
        System.assertEquals(respApplUnsupervisedTest, controller1.respApplUnsupervised, 'Unsupervised');
        System.assertEquals(respDailyTasksTest, controller1.respDailyTasks, 'Daily Tasks');
        System.assertEquals(respHandlingMedsTest, controller1.respHandlingMeds, 'Handling Meds');
        System.assertEquals(respOHSGuidelinesTest, controller1.respOHSGuidelines, 'OHS Guidelines');
        System.assertEquals(respRehireApplTest, controller1.respRehireAppl, 'Rehire');
        System.assertEquals(respCommSkillsTest, controller1.respCommSkills, 'Comm Skills Response');
        System.assertEquals(respClinicalSkillsTest, controller1.respClinicalSkills, 'Clinical Skills Response');
        System.assertEquals(respEmergencySitsTest, controller1.respEmergencySits, 'Emergency Situations Response');

    }

    public static void createData(){
        acc = SIM_TestDataFactory.genTestAccount('accountName', 'Candidate Pool', true);
        cont = SIM_TestDataFactory.genTestContact('LastName', acc.Id, 'Candidate', false);
        cont.FirstName = 'First';
        cont.Email = '1218-SFDC-Support@1218global.com';
        cont.LastName = 'LastName';
        insert cont; 

        // clientAcc = SIM_TestDataFactory.genTestAccount('Client Account', 'Client', true);
        // clientCont = SIM_TestDataFactory.genTestContact('Client', clientAcc.Id, 'Client Contact', true);

        ref = new b3o__Reference__c(
            b3o__Contact__c = cont.id,
            Rating_applicant_s_ability_to_do_tasks__c = '1',
            Communication_Documentation_Skills__c = '3',
            Clinical_Skills__c = 'Competent',
            Dealing_with_emergency_situation__c = '4',
            Happy_to_provide_References__c = 'Yes',
            Permission_to_disclose_reference_check__c = 'Yes',
            AHPRA_based_investigations_or_disputes__c = 'Yes',
            Applicant_can_work_unsupervised__c = 'No',
            Handling_medication_administration__c = 'Yes',
            Adhering_to_OHS_guidelines__c = 'Yes',
            Rehire_applicant_further_comments__c = 'Yes'
        );
        insert ref;



    }
}