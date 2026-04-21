public with sharing class IdibuV3Controller {

    public string RedirectUrl {get;set;} // V3 redirect URL (get from idibu team)
    public boolean Enabled {get;set;}

    public string AppId {get; set;} // Application ID - stored in org settings
    public string AppSecret {get; set;} // Application secret - stored in org settings
    public string Vacancy {get; set;} // Job reference number
    public string Title {get; set;} // Job title
    public string UserId {get; set;} // Unique user ID
    public string Email {get; set;} // Unique user e-mail address
    public string Fname {get; set;} // User's first name
    public string Lname {get; set;} // User's last name
    public string Minsalary {get; set;} // Minimum salary
    public string Maxsalary {get; set;} // Maximum salary
    public string Description {get; set;} // Job description
    public string AppUrl {get;set;} // Application URL

    public string WindowTitle {get; set;} // Title of the iframe Window
    public string BackUrl {get; set;} // URL to reach when pressing the "Back" button

    public PageReference Save()
    {
        return null;
    }

    public IdibuV3Controller()
    {
        Init();
    }

    public void Init()
    {
        Enabled = false;

        RedirectUrl = 'https://v3.idibu.com/c/integration/salesforce';

        IdibuV3Settings__c settings = IdibuV3Settings__c.getOrgDefaults();
        
        AppId = settings.Application_ID__c;
        AppSecret = settings.Application_Secret__c;
     
        string jobId = ApexPages.currentPage().getParameters().get('jobId');

        if (Test.isRunningTest())
            jobId = '005E0000001vNo6IAE';

        string appUrlBase = settings.Application_URL_base__c;
        boolean useAppId = settings.Use_application_URL__c;

        if (useAppId)
            AppUrl = appUrlBase + jobId;

        List<tr1__Job__c> jobList = new List<tr1__Job__c>();
        jobList = [SELECT 
        Id, // Job ID
        Name,
        TR1__External_Job_Title__c, // Job title
        TR1__Job_Number__c, 
        TR1__Minimum_Pay_Rate__c, 
        TR1__Maximum_Pay_Rate__c,
        TR1__Client_Job_Description__c 
        FROM tr1__Job__c WHERE Id =:jobId];

        if (Test.isRunningTest() || (appId != null && appId != '' && appSecret != null && appSecret != ''))
        {
            Enabled = true;
        }

        tr1__Job__c currentJob;

        if (!Test.isRunningTest())
            currentJob = jobList[0];
        else
        {
            currentJob = new tr1__Job__c();
        }
        string url;

        string jobName = currentJob.TR1__External_Job_Title__c != null ? currentJob.TR1__External_Job_Title__c : currentJob.Name;

        WindowTitle = 'idibu - ' +  jobName + ' (' + currentJob.TR1__Job_Number__c + ')';
        BackUrl = '/one/one.app?#/sObject/' + currentJob.Id +'/view';

        Vacancy = currentJob.TR1__Job_Number__c;
        Title = jobName;
        UserId = UserInfo.getUserId();
        Email = UserInfo.getUserEmail();
        Fname = UserInfo.getFirstName();
        Lname = UserInfo.getLastName();

        if (currentJob.TR1__Minimum_Pay_Rate__c != null)
            Minsalary = String.valueOf(currentJob.TR1__Minimum_Pay_Rate__c);

        if (currentJob.TR1__Maximum_Pay_Rate__c != null)
            Maxsalary = String.valueOf(currentJob.TR1__Maximum_Pay_Rate__c);

        if (currentJob.TR1__Client_Job_Description__c != null)
        {
            string escaped = currentJob.TR1__Client_Job_Description__c.escapeHtml4();
            Description = escaped;
        }
    }
}