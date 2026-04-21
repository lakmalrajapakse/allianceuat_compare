public with sharing class PDF_CVTemplateExtension {
    public Contact record {get;set;}
    public List<TR1__EmploymentHistory__c> empHists {get;set;}
    public List<TR1__EducationHistory__c> educHists {get;set;}
    public List<TR1__Skills__c> skills {get;set;}
    public List<b3o__Certificate__c> certs {get;set;}
    public List<sirenum__Shift__c> shifts {get;set;}
    public List<AggregateResult> aggShifts {get;set;}
    public List<Branch_Email__c> branchEmails {get;set;}

    public PDF_CVTemplateExtension(ApexPages.StandardController stdController) {
        System.debug(LOGGINGLEVEL.ERROR, stdController.getId());

        this.record = [SELECT Id, 
            Name, 
            FirstName, 
            LastName, 
            aa_AHPRA_Number__c,
            aa_AHPRA_Number_2__c,
            aa_AHPRA_Number_3__c,
            MailingStreet, 
            MailingCity, 
            Branch__c,
            Resume__c
            FROM Contact 
            WHERE Id = :stdController.getId()];

        List<TR1__EmploymentHistory__c> empHists = [
            SELECT Id, 
                Name, 
                TR1__Title__c, 
                TR1__Start_date__c, 
                TR1__End_date__c, 
                TR1__EmployerName__c, 
                TR1__OrganizationName__c,
                TR1__City__c, 
                TR1__Verified__c
            FROM TR1__EmploymentHistory__c
            WHERE TR1__Contact__c = :stdController.getId()
            // AND TR1__Verified__c = true
            ];
        this.empHists = empHists;

        List<TR1__EducationHistory__c> educHists = [
            SELECT Id, 
                Name, 
                TR1__SchoolName__c, 
                TR1__DegreeName__c,
                TR1__Start_date__c, 
                TR1__End_date__c, 
                TR1__City__c, 
                TR1__Verified__c
            FROM TR1__EducationHistory__c
            WHERE TR1__Contact__c = :stdController.getId()
            ];
        this.educHists = educHists;
        
        List<TR1__Skills__c> skills = [
            SELECT Id, 
                Name, 
                TR1__Master_Skill_Name__c, 
                TR1__Type__c , 
                TR1__Start_date__c, 
                TR1__End_date__c, 
                TR1__Verified__c
            FROM TR1__Skills__c
            WHERE TR1__Contact__c = :stdController.getId() 
            AND TR1__Type__c IN ('Classification','Skill','Skill Area')
            AND TR1__Verified__c = true
            ];
        this.skills = skills;

        List<b3o__Certificate__c> certs = [
            SELECT Id, 
                Name, 
                b3o__Certificate_Type__r.Name, 
                b3o__Start_Date__c, 
                b3o__Status__c
            FROM b3o__Certificate__c
            WHERE b3o__Contact__c = :stdController.getId() 
            AND b3o__Status__c = 'Valid' 
            AND b3o__Certificate_Type__r.Name != 'Right to work'
            ];
        this.certs = certs;

        Date startingDate = Date.today();
        List<AggregateResult> shifts = [
        // List<sirenum__Shift__c> shifts = [
            SELECT Id, 
                sirenum__Contract__c,
                sirenum__Contract__r.Name,
                sirenum__Contact__c,
                // sirenum__Site__c,
                // sirenum__Team__c,
                sirenum__Site__r.Name SiteName,
                sirenum__Team__r.Name JobRoleName,
                // Site_Name__c, 
                // Job_Role_Name__c,
                MIN(sirenum__Absolute_Local_Start_Date__c) minDate, 
                MAX(sirenum__Absolute_Local_End_Date__c) maxDate
            FROM sirenum__Shift__c 
            WHERE sirenum__Contact__c = :stdController.getId() 
            AND sirenum__Date__c <= :startingDate 
            GROUP BY Id, sirenum__Contract__c, sirenum__Contract__r.Name, sirenum__Contact__c, sirenum__Site__r.Name, sirenum__Team__r.Name
            // GROUP BY Id, sirenum__Contract__c, sirenum__Contract__r.Name, sirenum__Contact__c, sirenum__Site__c, sirenum__Team__c
            // GROUP BY Id, sirenum__Contract__c, sirenum__Contract__r.Name, sirenum__Contact__c, Site_Name__c, Job_Role_Name__c
            ORDER BY MIN(sirenum__Absolute_Local_Start_Date__c) DESC
            LIMIT 5
            ];
        // this.shifts = shifts;
        System.debug('shifts: ' + shifts);
        this.aggShifts = shifts;

        List<Branch_Email__c> branchEmails = [SELECT Id, 
                Email_Address__c, 
                Email_Type__c  
                FROM Branch_Email__c 
                WHERE Email_Type__c = 'Recruitment' 
                AND Branch__c = :this.record.Branch__c
                LIMIT 1];
        this.branchEmails  = branchEmails;

    }

    public string branchEmailAddress {
        get {
            String result = '';
            // if (this.branchEmails.size() > 0){
                result += this.branchEmails.size() > 0 ? this.branchEmails[0].Email_Address__c : 'Branch not assigned to Candidate';
            // }
            return result;
        }
    }

    public string recentContracts {
        get {
            String result = '';
            // for (sirenum__Shift__c shift : this.shifts){
            for (AggregateResult shift : this.aggShifts){
                DateTime minDateTime = (DateTime) shift.get('minDate');
                DateTime maxDateTime = (DateTime) shift.get('maxDate');
                String minDate = minDateTime.format('dd/MM/yyyy');
                String maxDate = maxDateTime.format('dd/MM/yyyy');
                result += '<tr class="standardtext" style="page-break-inside:avoid;"><td class="td25">' + shift?.get('Name') + '</td>'; 
                result += '<td class="td25">' + shift?.get('SiteName') + '</td>' ; 
                result += '<td class="td25">' + shift?.get('JobRoleName') + '</td>' ;   
                result += '<td class="td25">' + minDate + ' - ' +  maxDate + '</td></tr>' ;  
                
            }
            System.debug('result: ' + result);
            return result;
        }
    }

    public String employmentHist {
        get {
            String result = '';
            for (TR1__EmploymentHistory__c empHist : this.empHists) {
                // result += empHist?.TR1__EmployerName__c + ' ' + empHist?.TR1__City__c + ' ' + empHist?.TR1__Title__c + ' ' + empHist?.TR1__Start_date__c.format() + ' - ' + empHist?.TR1__End_date__c.format() + '<br/>';
                String startDate = empHist?.TR1__Start_date__c != null  ? ('' + empHist?.TR1__Start_date__c.format()) : '';
                String endDate = empHist?.TR1__End_date__c != null  ? ('' + empHist?.TR1__End_date__c.format()) : '';
                // result += empHist?.TR1__EmployerName__c + ' ' + empHist?.TR1__City__c + ' ' + empHist?.TR1__Title__c + ' ' + empHist?.TR1__Start_date__c.format() + ' - ' + endDate + '<br/>';
                result += '<tr class="standardtext" style="page-break-inside:avoid;"><td class="td40">' + empHist?.TR1__EmployerName__c + ', ' + empHist?.TR1__City__c + '</td>' ;     
                result += '<td class="td35">' + empHist?.TR1__Title__c + '</td>' ;   
                // result += '<td class="td25">' + startDate + ' - ' + endDate + '</td></tr>' ;
                result += '<td class="td12">' + startDate + '</td>' ;
                result += '<td class="td12">' + endDate + '</td></tr>' ;
            }
            return result;
        }
    }

    public String clinicalSkills {
        get {
            String result = '';
            for (TR1__Skills__c skill : this.skills) {
                result += '<tr class="standardtext" style="page-break-inside:avoid;"><td>' + skill?.TR1__Master_Skill_Name__c + '</td>' ;      
            }
            return result;
        }
    }

    public String educationHist {
        get {
            String result = '';
            for (TR1__EducationHistory__c educHist : this.educHists) {
                // result += educHist.TR1__SchoolName__c + ' ' + educHist.TR1__DegreeName__c + ' ' + educHist.TR1__Start_date__c.format() + ' - ' + educHist.TR1__End_date__c.format() + '<br/>';
                String startDate = educHist?.TR1__Start_date__c != null  ? ('' + educHist?.TR1__Start_date__c.format()) : '';
                String endDate = educHist?.TR1__End_date__c != null  ? ('' + educHist?.TR1__End_date__c.format()) : '';
                result += '<tr class="standardtext" style="page-break-inside:avoid;"><td class="td75">' + educHist?.TR1__DegreeName__c + ' - ' + educHist?.TR1__SchoolName__c + ', ' + educHist?.TR1__City__c +'</td>' ;      
                // result += '<td class="td25">' + educHist?.TR1__Start_date__c.format() + ' - ' + educHist?.TR1__End_date__c.format() + '</td></tr>' ; 
                // result += '<td class="td25">' + startDate + ' - ' + endDate + '</td></tr>' ; 
                result += '<td class="td12">' + startDate + '</td>' ;
                result += '<td class="td12">' + endDate + '</td></tr>' ;     
            }
            return result;
        }
    }

    public String profDev {
        get {
            String result = '';
            for (b3o__Certificate__c cert : this.certs) {
                // result += educHist.TR1__SchoolName__c + ' ' + educHist.TR1__DegreeName__c + ' ' + educHist.TR1__Start_date__c.format() + ' - ' + educHist.TR1__End_date__c.format() + '<br/>';
                String startDate = cert?.b3o__Start_Date__c != null  ? ('' + cert?.b3o__Start_Date__c.format()) : '';
                result += '<tr class="standardtext" style="page-break-inside:avoid;"><td class="td75">' + cert?.b3o__Certificate_Type__r.Name + '</td>' ;      
                // result += '<td class="td25">' + cert?.b3o__Start_Date__c + '</td></tr>' ;
                result += '<td class="td25">' + startDate + '</td></tr>' ;      
            }
            return result;
        }
    }

    public String ahpraNumbers {
        get {
            List<String> listARPHANumbers = new List<String>();
            String result = '';
            if (!String.isEmpty(this.record.aa_AHPRA_Number__c)) {
                listARPHANumbers.add(this.record?.aa_AHPRA_Number__c);
            }
            if (!String.isEmpty(this.record.aa_AHPRA_Number_2__c)) {
                listARPHANumbers.add(this.record?.aa_AHPRA_Number_2__c);
            }
            if (!String.isEmpty(this.record.aa_AHPRA_Number_3__c)) {
                listARPHANumbers.add(this.record?.aa_AHPRA_Number_3__c);
            }

            return listARPHANumbers.toString().replace('(', '').replace(')', '').replace(',', ' /');
        }
    }

    public String resumeCV{
        get {
            String result = '';
            result += this.record.Resume__c;
            return result;
        }
    }
        
}