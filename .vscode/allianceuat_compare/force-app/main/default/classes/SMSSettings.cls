public class SMSSettings {
    public String providerType { get; private set; }
    public String authenticationToken { get; private set; }
    public String accountSID { get; private set; }
    public String senderPhoneNumber { get; private set; }
    public String apiEndpoint { get; private set; }
    public String apiSiteDomainUrl { get; private set; }
    public String defaultAdminId { get; private set; }
    public String defaultAdminName { get; private set; }
    public String defaultGreeting { get; private set; }
    public Boolean isActive { get; private set; }
    public String inboundHeader { get; private set; }
    public String inboundToken { get; private set; }

    private static final String TEXTUS_PROVIDER = 'TextUs';
    private static final String TWILIO_PROVIDER = 'Twilio';
    private static final String MM_PROVIDER = 'MessageMedia';

    private SMSSettings(Application_SMS_Configuration__mdt settings) {
        if (settings != null) {
            loadSettings(settings); // Generalized settings loading
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getInstance(String costCenter) {
        // if(String.isBlank(costCenter)){
        //     costCenter = [SELECT SMS_Cost_Center__c from User where Id = :UserInfo.getUserId() limit 1].SMS_Cost_Center__c;
        // }
        // System.debug('SMSSettings getInstance(String costCenter) costCenter: ' + costCenter);
        Application_SMS_Configuration__mdt settings = SettingsProvider.getSettings(costCenter);
        SMSSettings smsSettings = new SMSSettings(settings);
        Map<String, Object> result = new Map<String, Object>();
        result.put('defaultGreeting', smsSettings.defaultGreeting);
        return result;
    }

    // @AuraEnabled(cacheable=true)
    public static SMSSettings getInstance() {
        // String costCenter = [SELECT SMS_Cost_Center__c from User where Id = :UserInfo.getUserId() limit 1].SMS_Cost_Center__c;
        String costCenter = [SELECT Cost_Center__r.SMS_Cost_Center__c from Cost_Center_User__c where User__c = :UserInfo.getUserId() AND Is_Primary__c = true limit 1].Cost_Center__r.SMS_Cost_Center__c;
        System.debug('SMSSettings getInstance costCenter: ' + costCenter);
        Application_SMS_Configuration__mdt settings = SettingsProvider.getSettings(costCenter);
        return new SMSSettings(settings);
    }

    private void loadSettings(Application_SMS_Configuration__mdt config) {
        // Load configuration settings
        providerType = config.Provider_Name__c;
        authenticationToken = config.Authentication_Token__c;
        accountSID = config.Account_SID__c;
        senderPhoneNumber = config.Sender_Phone_Number__c;
        apiEndpoint = config.API_Endpoint__c;
        apiSiteDomainUrl = config.API_Site_Domain_URL__c;
        defaultAdminId = config.Default_Admin_Id__c;
        defaultAdminName = config.Default_Admin_Name__c;
        defaultGreeting = config.Default_Greetings_Message__c;
        isActive = config.isActive__c;
        inboundHeader = config.Inbound_Header__c;
        inboundToken = config.Inbound_Token__c;
    }

    // public String apiToken { get; private set; }
    // public String senderPhoneNumber { get; private set; }
    // public String apiUrl { get; private set; }
    // public Integer smsEventDescriptionLength { get; private set; }
    // public String greetings { get; private set; }
    // public String adminId { get; private set; }
    // public String adminName { get; private set; }
    // public String textUsPrivateKey { get; private set; }

    // public SMSSettings() {
    //     // Load configuration from TextIUS_Settings Custom Settings
    //     TextIUS_Settings__c settings = SettingsProvider.getSettings();
    //     apiToken = settings.API_Token__c;
    //     senderPhoneNumber = settings.Sender_Phone_Number__c;
    //     apiUrl = settings.API_URL__c;
    //     smsEventDescriptionLength = (Integer) settings.SMS_Event_Description_Length__c;
    //     greetings = settings.Greetings__c;
    //     adminId = settings.Default_Admin_Id__c;
    //     adminName = settings.Default_Name__c;
    //     textUsPrivateKey = settings.textus_privatekey__c;
    // }

    // public static SMSSettings getInstance() {
    //     return new SMSSettings();
    // }
}