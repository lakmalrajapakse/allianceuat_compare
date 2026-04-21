/*
 * Copyright Sirenum (c) 2021.
 */
@IsTest
private class CustomRules_Test {

    @IsTest
    static void testNoShifts() {
        List<sirenum.SirenumEngine.Shift> shifts = new List<sirenum.SirenumEngine.Shift>();
        CustomRules testClass = new CustomRules();
        List<sirenum__LogEntry__c> logEntries = testClass.execute(shifts);
        System.assertEquals(0, logEntries.size());
    }

    @IsTest
    static void testFail() {
        /*
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
                City__c='test',
                Brand_c__c = 'Nursing'
        );
        insert branch;

        //Client Account
        Id clientRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('Client')
                .getRecordTypeId();
        Account account = new Account(
                Name = 'Test Account',
                RecordTypeId = clientRecordTypeId,
                Branch__c = branch.Id
        );
        insert account;


         */
        //########################################################################################################

        sirenum__CompetencyBundle__c roleBundle = new sirenum__CompetencyBundle__c(Name='Test Comp Bundle ROLE', Is_Role_Bundle__c=true);
        sirenum__CompetencyBundle__c skillBundle = new sirenum__CompetencyBundle__c(Name='Test Comp Bundle SKILL');
        insert new List<sirenum__CompetencyBundle__c>{roleBundle, skillBundle};

        sirenum__TicketType__c competencyRole1 = new sirenum__TicketType__c(
                Name='Nursing T1',
                Is_Role_Competency__c = true
        );
        sirenum__TicketType__c competencyRole2 = new sirenum__TicketType__c(
                Name='Nursing T2',
                Is_Role_Competency__c = true
        );
        sirenum__TicketType__c competencySkill1 = new sirenum__TicketType__c(
                Name='Reading'
        );
        sirenum__TicketType__c competencySkill2 = new sirenum__TicketType__c(
                Name='Writing'
        );
        insert new List<sirenum__TicketType__c>{competencyRole1, competencyRole2, competencySkill1, competencySkill2};

        sirenum__CompetencyBundleItem__c bundleItemRole1 = new sirenum__CompetencyBundleItem__c(
                sirenum__CompetencyBundle__c = roleBundle.Id,
                sirenum__Competency__c = competencyRole1.Id
        );
        sirenum__CompetencyBundleItem__c bundleItemRole2 = new sirenum__CompetencyBundleItem__c(
                sirenum__CompetencyBundle__c = roleBundle.Id,
                sirenum__Competency__c = competencyRole2.Id
        );
        sirenum__CompetencyBundleItem__c bundleItemSkill1 = new sirenum__CompetencyBundleItem__c(
                sirenum__CompetencyBundle__c = skillBundle.Id,
                sirenum__Competency__c = competencySkill1.Id
        );
        sirenum__CompetencyBundleItem__c bundleItemSkill2 = new sirenum__CompetencyBundleItem__c(
                sirenum__CompetencyBundle__c = skillBundle.Id,
                sirenum__Competency__c = competencySkill2.Id
        );
        insert new List<sirenum__CompetencyBundleItem__c>{bundleItemRole1, bundleItemRole2, bundleItemSkill1, bundleItemSkill2};

        Contact contact = new Contact(
                FirstName = 'Test',
                LastName = 'Contact');
        insert contact;

        sirenum__Shift__c shift = new sirenum__Shift__c(
                sirenum__Contact__c = contact.Id,
                sirenum__Scheduled_Start_Time__c = Datetime.newInstance(2021, 1, 1, 9, 0, 0),
                sirenum__Scheduled_End_Time__c = Datetime.newInstance(2021, 1, 1, 17, 0, 0),
                Role_OR_Bundle__c = roleBundle.Id,
                Skill_Attribute_OR_Bundle__c = skillBundle.Id
        );

        sirenum.SirenumEngine.Shift engineShift = new sirenum.SirenumEngine.Shift(shift);
        engineShift.isChecked = true;
        CustomRules testClass = new CustomRules();
        List<sirenum__LogEntry__c> logEntries = testClass.execute(new List<sirenum.SirenumEngine.Shift>{engineShift});
        System.assertEquals(2, logEntries.size());

/*
        Contact con1 = new Contact(FirstName = 'Candy', LastName = 'Date 1', AccountId = account.Id);
        insert con1;
        sirenum__Shift__c shift1 = new sirenum__Shift__c(
                sirenum__Contact__c = con1.Id,
                sirenum__Scheduled_Start_Time__c = Datetime.newInstance(2021, 1, 1, 9, 0, 0),
                sirenum__Scheduled_End_Time__c = Datetime.newInstance(2021, 1, 1, 17, 0, 0)
        );
        sirenum__Shift__c shift2 = new sirenum__Shift__c(
                sirenum__Scheduled_Start_Time__c = Datetime.newInstance(2021, 1, 1, 9, 0, 0),
                sirenum__Scheduled_End_Time__c = Datetime.newInstance(2021, 1, 1, 17, 0, 0)
        );
        List<sirenum.SirenumEngine.Shift> shifts = new List<sirenum.SirenumEngine.Shift>{
                new sirenum.SirenumEngine.Shift(shift1),
                new sirenum.SirenumEngine.Shift(shift2)
        };
        shifts[0].isExcluded = true;
        CustomRules testClass = new CustomRules();
        List<sirenum__LogEntry__c> logEntries = testClass.execute(shifts);
        System.assertEquals(0, logEntries.size());

 */
    }

    @IsTest
    static void testPass1(){
        sirenum__CompetencyBundle__c roleBundle = new sirenum__CompetencyBundle__c(Name='Test Comp Bundle ROLE', Is_Role_Bundle__c=true);
        sirenum__CompetencyBundle__c skillBundle = new sirenum__CompetencyBundle__c(Name='Test Comp Bundle SKILL');
        insert new List<sirenum__CompetencyBundle__c>{roleBundle, skillBundle};

        sirenum__TicketType__c competencyRole1 = new sirenum__TicketType__c(
                Name='Nursing T1',
                Competency_Category__c = 'Job Type',
                Is_Role_Competency__c = true
        );
        sirenum__TicketType__c competencyRole2 = new sirenum__TicketType__c(
                Name='Nursing T2',
                Competency_Category__c = 'Job Type',
                Is_Role_Competency__c = true
        );
        sirenum__TicketType__c competencySkill1 = new sirenum__TicketType__c(
                Name='Reading',
                Competency_Category__c = 'Skills'
        );
        sirenum__TicketType__c competencySkill2 = new sirenum__TicketType__c(
                Name='Writing',
                Competency_Category__c = 'Skills'
        );
        insert new List<sirenum__TicketType__c>{competencyRole1, competencyRole2, competencySkill1, competencySkill2};

        sirenum__CompetencyBundleItem__c bundleItemRole1 = new sirenum__CompetencyBundleItem__c(
                sirenum__CompetencyBundle__c = roleBundle.Id,
                sirenum__Competency__c = competencyRole1.Id
        );
        sirenum__CompetencyBundleItem__c bundleItemRole2 = new sirenum__CompetencyBundleItem__c(
                sirenum__CompetencyBundle__c = roleBundle.Id,
                sirenum__Competency__c = competencyRole2.Id
        );
        sirenum__CompetencyBundleItem__c bundleItemSkill1 = new sirenum__CompetencyBundleItem__c(
                sirenum__CompetencyBundle__c = skillBundle.Id,
                sirenum__Competency__c = competencySkill1.Id
        );
        sirenum__CompetencyBundleItem__c bundleItemSkill2 = new sirenum__CompetencyBundleItem__c(
                sirenum__CompetencyBundle__c = skillBundle.Id,
                sirenum__Competency__c = competencySkill2.Id
        );
        insert new List<sirenum__CompetencyBundleItem__c>{bundleItemRole1, bundleItemRole2, bundleItemSkill1, bundleItemSkill2};

        Contact contact = new Contact(
                FirstName = 'Test',
                LastName = 'Contact');
        insert contact;

        sirenum__Ticket__c roleTicket = new sirenum__Ticket__c(
                sirenum__TicketType__c = competencyRole1.Id,
                sirenum__Owner__c = contact.Id
        );
        sirenum__Ticket__c skillTicket = new sirenum__Ticket__c(
                sirenum__TicketType__c = competencySkill1.Id,
                sirenum__Owner__c = contact.Id
        );

        insert new List<sirenum__Ticket__c>{roleTicket, skillTicket};
        roleTicket.sirenum__Revoked__c = false;
        skillTicket.sirenum__Revoked__c = false;
        update new List<sirenum__Ticket__c>{roleTicket, skillTicket};

        sirenum__Shift__c shift = new sirenum__Shift__c(
                sirenum__Contact__c = contact.Id,
                sirenum__Scheduled_Start_Time__c = Datetime.newInstance(2021, 1, 1, 9, 0, 0),
                sirenum__Scheduled_End_Time__c = Datetime.newInstance(2021, 1, 1, 17, 0, 0),
                Role_OR_Bundle__c = roleBundle.Id,
                Skill_Attribute_OR_Bundle__c = skillBundle.Id
        );

        sirenum.SirenumEngine.Shift engineShift = new sirenum.SirenumEngine.Shift(shift);
        engineShift.isChecked = true;
        CustomRules testClass = new CustomRules();
        List<sirenum__LogEntry__c> logEntries = testClass.execute(new List<sirenum.SirenumEngine.Shift>{engineShift});
        System.assertEquals(0, logEntries.size());
    }

    @IsTest
    static void testPassMulti(){
        sirenum__CompetencyBundle__c roleBundle = new sirenum__CompetencyBundle__c(Name='Test Comp Bundle ROLE', Is_Role_Bundle__c=true);
        sirenum__CompetencyBundle__c skillBundle = new sirenum__CompetencyBundle__c(Name='Test Comp Bundle SKILL');
        insert new List<sirenum__CompetencyBundle__c>{roleBundle, skillBundle};

        sirenum__TicketType__c competencyRole1 = new sirenum__TicketType__c(
                Name='Nursing T1',
                Competency_Category__c = 'Job Type',
                Is_Role_Competency__c = true
        );
        sirenum__TicketType__c competencyRole2 = new sirenum__TicketType__c(
                Name='Nursing T2',
                Competency_Category__c = 'Job Type',
                Is_Role_Competency__c = true
        );
        sirenum__TicketType__c competencySkill1 = new sirenum__TicketType__c(
                Name='Reading',
                Competency_Category__c = 'Skills'
        );
        sirenum__TicketType__c competencySkill2 = new sirenum__TicketType__c(
                Name='Writing',
                Competency_Category__c = 'Skills'
        );
        insert new List<sirenum__TicketType__c>{competencyRole1, competencyRole2, competencySkill1, competencySkill2};

        sirenum__CompetencyBundleItem__c bundleItemRole1 = new sirenum__CompetencyBundleItem__c(
                sirenum__CompetencyBundle__c = roleBundle.Id,
                sirenum__Competency__c = competencyRole1.Id
        );
        sirenum__CompetencyBundleItem__c bundleItemRole2 = new sirenum__CompetencyBundleItem__c(
                sirenum__CompetencyBundle__c = roleBundle.Id,
                sirenum__Competency__c = competencyRole2.Id
        );
        sirenum__CompetencyBundleItem__c bundleItemSkill1 = new sirenum__CompetencyBundleItem__c(
                sirenum__CompetencyBundle__c = skillBundle.Id,
                sirenum__Competency__c = competencySkill1.Id
        );
        sirenum__CompetencyBundleItem__c bundleItemSkill2 = new sirenum__CompetencyBundleItem__c(
                sirenum__CompetencyBundle__c = skillBundle.Id,
                sirenum__Competency__c = competencySkill2.Id
        );
        insert new List<sirenum__CompetencyBundleItem__c>{bundleItemRole1, bundleItemRole2, bundleItemSkill1, bundleItemSkill2};

        Contact contact = new Contact(
                FirstName = 'Test',
                LastName = 'Contact');
        insert contact;

        sirenum__Ticket__c roleTicket1 = new sirenum__Ticket__c(
                sirenum__TicketType__c = competencyRole1.Id,
                sirenum__Owner__c = contact.Id
        );
        sirenum__Ticket__c roleTicket2 = new sirenum__Ticket__c(
                sirenum__TicketType__c = competencyRole2.Id,
                sirenum__Owner__c = contact.Id
        );
        sirenum__Ticket__c skillTicket1 = new sirenum__Ticket__c(
                sirenum__TicketType__c = competencySkill1.Id,
                sirenum__Owner__c = contact.Id
        );
        sirenum__Ticket__c skillTicket2 = new sirenum__Ticket__c(
                sirenum__TicketType__c = competencySkill2.Id,
                sirenum__Owner__c = contact.Id
        );
        insert new List<sirenum__Ticket__c>{roleTicket1, roleTicket2, skillTicket1, skillTicket2};
        roleTicket1.sirenum__Revoked__c = false;
        skillTicket1.sirenum__Revoked__c = false;
        roleTicket2.sirenum__Revoked__c = false;
        skillTicket2.sirenum__Revoked__c = false;
        update new List<sirenum__Ticket__c>{roleTicket1, skillTicket1, roleTicket2, skillTicket2};

        sirenum__Shift__c shift = new sirenum__Shift__c(
                sirenum__Contact__c = contact.Id,
                sirenum__Scheduled_Start_Time__c = Datetime.newInstance(2021, 1, 1, 9, 0, 0),
                sirenum__Scheduled_End_Time__c = Datetime.newInstance(2021, 1, 1, 17, 0, 0),
                Role_OR_Bundle__c = roleBundle.Id,
                Skill_Attribute_OR_Bundle__c = skillBundle.Id
        );

        sirenum.SirenumEngine.Shift engineShift = new sirenum.SirenumEngine.Shift(shift);
        engineShift.isChecked = true;
        CustomRules testClass = new CustomRules();
        List<sirenum__LogEntry__c> logEntries = testClass.execute(new List<sirenum.SirenumEngine.Shift>{engineShift});
        System.assertEquals(0, logEntries.size());
    }
}