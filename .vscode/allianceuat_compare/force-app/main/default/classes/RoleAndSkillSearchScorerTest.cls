/**
 * Test class for RoleAndSkillSearchScorer
 */

@IsTest
public class RoleAndSkillSearchScorerTest {

    @IsTest
    static void testGetRequiredShiftFields() {
        RoleAndSkillSearchScorer scorer = new RoleAndSkillSearchScorer();
        Set<String> shiftFields = scorer.getRequiredShiftFields();

        System.assert(shiftFields.contains('Skill_Attribute_OR_Bundle__c'));
        System.assert(shiftFields.contains('Role_OR_Bundle__c'));
    }

    @IsTest
    static void testGetRequiredContactFields() {
        RoleAndSkillSearchScorer scorer = new RoleAndSkillSearchScorer();
        Set<String> workerFields = scorer.getRequiredWorkerFields();

        System.assertEquals(true, workerFields.isEmpty());
    }

    @IsTest
    static void testScorer() {
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

        // Build the context
        sirenum.WorkerSearchScorerContext context =
                new sirenum.WorkerSearchScorerContextBuilder()
                        .setShiftTemplates(new List<sirenum__Shift__c>{shift})
                        .setWorkers(new List<Contact>{contact})
                        .build();

        //Score the worker
        String config = '{}';
        RoleAndSkillSearchScorer scorer = (RoleAndSkillSearchScorer)JSON.deserialize(config, RoleAndSkillSearchScorer.class);
        List<sirenum.WorkerSearchScore> scores = scorer.scoreWorkers(context);

        // Check that the one worker received two scores
        System.assertEquals(2, scores.size());

        Boolean foundRoleScore = false;
        Boolean foundSkillScore = false;

        for (sirenum.WorkerSearchScore score : scores){
            if (score.description.contains('Role')){
                foundRoleScore = true;
            }
            if (score.description.contains('Skill')){
                foundSkillScore = true;
            }
        }

        //Check specifically that the Role and Skill score were received
        System.assertEquals(true, foundRoleScore);
        System.assertEquals(true, foundSkillScore);

    }

}