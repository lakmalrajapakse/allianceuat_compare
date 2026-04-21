@isTest
private class PDF_CVTemplateExtension_test {
    public static Account acc = new Account();
    public static Contact cont = new Contact();
    public static Account clientAcc = new Account();
    public static Contact clientCont = new Contact();
    public static List<TR1__EmploymentHistory__c> empHists = new List<TR1__EmploymentHistory__c>();
    public static List<TR1__EducationHistory__c> educHists = new List<TR1__EducationHistory__c>();
    public static TR1__Master_Skill__c masterSkill = new TR1__Master_Skill__c();
    public static List<TR1__Skills__c> skills = new List<TR1__Skills__c>();
    public static b3o__Certificate_Type__c certType = new b3o__Certificate_Type__c();
    public static List<b3o__Certificate__c> certs = new List<b3o__Certificate__c>();
    public static sirenum__ProActiveContract__c  contract = new sirenum__ProActiveContract__c();
    public static sirenum__Team__c jobRole = new sirenum__Team__c();
    public static sirenum__Site__c site = new sirenum__Site__c();
    public static List<sirenum__Shift__c> shifts = new List<sirenum__Shift__c>();
    public static Branch__c branch; // = new Branch__c();
    public static Branch_Email__c branchEmail; // = new Branch_Email__c();

    public static Date startDate;
    public static Date endDate;
    public static Date todayDate;
    public static DateTime shiftStartTime;
    public static DateTime shiftEndTime;

    @isTest
    static void generatePDFTest() {
        startDate = System.today().addDays(-30);
        endDate = System.today().addDays(90);
        todayDate = System.today();
        Time startTime = Time.newInstance(9,0,0,0);
        Time endTime = Time.newInstance(17,0,0,0);
        shiftStartTime = DateTime.newInstance(todayDate, startTime);
        shiftEndTime = DateTime.newInstance(todayDate, endTime);

        createData();
        PageReference pageRef = Page.PDF_CVTemplate;
        Test.setCurrentPage(pageRef);

        ApexPages.StandardController sController1 = new ApexPages.StandardController(cont);

        Test.startTest();
        PDF_CVTemplateExtension controller1 = new PDF_CVTemplateExtension(sController1);
        Test.stopTest();

        System.debug('controller1.ahpraNumbers ' + controller1.ahpraNumbers);
        System.debug('controller1.employmentHist ' + controller1.employmentHist);
        System.debug('controller1.educationHist ' + controller1.educationHist);
        System.debug('controller1.clinicalSkills ' + controller1.clinicalSkills);
        System.debug('controller1.profDev ' + controller1.profDev);
        System.debug('controller1.recentContracts ' + controller1.recentContracts);
        System.debug('controller1.recentContracts ' + controller1.branchEmailAddress);

        String ahpraTest = 'RN0001 / RN0002 / RN0003';
        // String emplHistTest = '<tr class="standardtext"><td class="td40">Employer Name, Testbourne</td><td class="td35">Job Title</td><td class="td25">1/3/2023 - 1/2/2025</td></tr>';
        String emplHistTest = '<tr class="standardtext" style="page-break-inside:avoid;"><td class="td40">Employer Name, Testbourne</td><td class="td35">Job Title</td><td class="td12">1/3/2023</td><td class="td12">1/2/2025</td></tr>';
        // String educHistTest = '<tr class="standardtext"><td class="td75">BA Test - Test University, Testville</td><td class="td25">1/3/2019 - 1/11/2022</td></tr>';
        String educHistTest = '<tr class="standardtext" style="page-break-inside:avoid;"><td class="td75">BA Test - Test University, Testville</td><td class="td12">1/3/2019</td><td class="td12">1/11/2022</td></tr>';
        String skillsTest = '<tr class="standardtext" style="page-break-inside:avoid;"><td>Test Master Skill</td>';
        String certsTest = '<tr class="standardtext" style="page-break-inside:avoid;"><td class="td75">Test Type</td><td class="td25">' + startDate.format() + '</td></tr>';
        // String shiftsTest ='<tr class="standardtext"><td class="td25">Test Contract</td><td class="td25">Test Site</td><td class="td25">Test Job Role</td><td class="td25">13/03/2025 - 13/03/2025</td></tr>';
        String shiftsTest ='<tr class="standardtext" style="page-break-inside:avoid;"><td class="td25">Test Contract</td><td class="td25">Test Site</td><td class="td25">Test Job Role</td><td class="td25">' + shiftStartTime.format('dd/MM/yyyy') + ' - ' + shiftEndTime.format('dd/MM/yyyy') + '</td></tr>';
        String branchEmailTest = 'testrecruitment@alliance.com.au';

        System.assertEquals(ahpraTest, controller1.ahpraNumbers, 'AHPRA');
        System.assertEquals(emplHistTest, controller1.employmentHist, 'Employment History');
        System.assertEquals(educHistTest, controller1.educationHist, 'Education History');
        System.assertEquals(skillsTest, controller1.clinicalSkills, 'Clinical Skills');
        System.assertEquals(certsTest, controller1.profDev, 'Certificates/Professional Development'); 
        System.assertEquals(shiftsTest, controller1.recentContracts, 'Recent Contracts');
        System.assertEquals(branchEmailTest, controller1.branchEmailAddress, 'Branch Email');
    }

    public static void createData(){
        branch = new Branch__c(
            Branch_Name__c = 'Test Branch',
            Branch_Code__c = 'AA',
            City__c = 'Testville'
        );
        insert branch;
        branchEmail = new Branch_Email__c(
            Branch__c = branch.Id,
            Email_Type__c = 'Recruitment',
            Email_Address__c = 'testrecruitment@alliance.com.au'
        );
        insert branchEmail;


        acc = SIM_TestDataFactory.genTestAccount('accountName', 'Candidate Pool', true);
        cont = SIM_TestDataFactory.genTestContact('LastName', acc.Id, 'Candidate', false);
        cont.FirstName = 'First';
        cont.Email = '1218-SFDC-Support@1218global.com';
        cont.LastName = 'LastName';
        cont.aa_AHPRA_Number__c = 'RN0001';
        cont.aa_AHPRA_Number_2__c = 'RN0002';
        cont.aa_AHPRA_Number_3__c = 'RN0003';
        cont.MailingStreet = '5 Test Street';
        cont.MailingCity = 'Testville';
        cont.Branch__c = branch.Id;
        insert cont; 

        clientAcc = SIM_TestDataFactory.genTestAccount('Client Account', 'Client', false);
        clientAcc.Payroll_Tax_Exempt__c = 'No';
        clientAcc.Approval_Type__c = 'Not Charged';
        insert clientAcc;
        clientCont = SIM_TestDataFactory.genTestContact('Client', clientAcc.Id, 'Client Contact', true);


        empHists = new List<TR1__EmploymentHistory__c>{
            new TR1__EmploymentHistory__c(
                TR1__Contact__c = cont.Id,
                TR1__Title__c = 'Job Title', 
                TR1__Startdate__c = '2023-03-01', 
                TR1__Enddate__c = '2025-02-01', 
                TR1__EmployerName__c = 'Employer Name', 
                TR1__OrganizationName__c = 'Org Name',
                TR1__City__c = 'Testbourne', 
                TR1__Verified__c = true
            )
        };
        insert empHists; 

        educHists = new List<TR1__EducationHistory__c> {
            new TR1__EducationHistory__c(
                TR1__Contact__c = cont.Id,
                TR1__SchoolName__c = 'Test University', 
                TR1__DegreeName__c = 'BA Test',
                TR1__City__c = 'Testville', 
                TR1__Startdate__c= '2019-03-01', 
                TR1__Enddate__c = '2022-11-01', 
                TR1__Verified__c = true
            )
        };
        insert educHists;
           
        masterSkill = new TR1__Master_Skill__c(
            TR1__Type__c = 'Classification',
            TR1__Master_Skill_Name__c = 'Test Master Skill',
            TR1__Skill_Code__c = 'Test123456'
        );
        insert masterSkill;
        skills = new List<TR1__Skills__c>{
            new TR1__Skills__c(
                TR1__Contact__c = cont.Id,
                TR1__Master_Skill__c = masterSkill.Id,
                TR1__Start_date__c = System.today().addDays(-30), 
                TR1__End_date__c = System.today().addDays(90), 
                TR1__Verified__c = true
            )
        };
        insert skills;

        // List<b3o__Certificate__c> certs 
        certType = new b3o__Certificate_Type__c(
            Name = 'Test Type'
        );
        insert certType;
        certs = new List<b3o__Certificate__c>{
            new b3o__Certificate__c(
                b3o__Contact__c = cont.Id,
                b3o__Certificate_Type__c = certType.Id, 
                b3o__Start_Date__c = startDate
            )
        };
        insert certs;


        // contract = SIM_TestDataFactory.genTestContract(clientAcc, clientCont, '', true);
        contract = SIM_TestDataFactory.genTestContract(clientAcc, false);
        contract.Name = 'Test Contract';
        insert contract;
        jobRole = SIM_TestDataFactory.genTestJobRole(contract, false);
        jobRole.Name = 'Test Job Role';
        insert jobRole;
        site = SIM_TestDataFactory.genTestSite(clientAcc, false);
        site.Name = 'Test Site';
        insert site;
        
        List<sirenum__Shift__c> shifts = new List<sirenum__Shift__c>{
            new sirenum__Shift__c(
                sirenum__Contact__c = cont.id, 
                sirenum__Site__c = site.id, 
                sirenum__Team__c = jobRole.id,
                sirenum__Contract__c = contract.id,  
                sirenum__Scheduled_Start_Time__c = shiftStartTime, 
                sirenum__Scheduled_End_Time__c = shiftEndTime //, 
            )//,
            // new sirenum__Shift__c(
            //     sirenum__Contact__c = cont.id, 
            //     sirenum__Site__c = site.id, 
            //     sirenum__Team__c = jobRole.id, 
            //     sirenum__Scheduled_Start_Time__c = DateTime.newInstance(Date.Today().AddDays(1), startTime), 
            //     sirenum__Scheduled_End_Time__c = DateTime.newInstance(Date.Today().AddDays(1), startTime), 
            // )
        };
        insert shifts;

    }
}