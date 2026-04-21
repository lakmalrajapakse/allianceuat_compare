/**
 * This class receives an email and creates a Shift
 */
global class VMS_InboundEmailHandler implements Messaging.InboundEmailHandler{
    @testVisible 
    public Boolean failureForTesting = false;

    global Messaging.InboundEmailResult handleInboundEmail(
        Messaging.InboundEmail email,
        Messaging.InboundEnvelope env     
    ){
        System.debug(LOGGINGLEVEL.ERROR, 'In handleInboundEmail');
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

        // Savepoint sp = Database.setSavepoint();
        String emailFromAddress;
        String emailToAddress;
        String htmlBody;
        String recordID;
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        VMS_Email_Provider__mdt vmsProvider = new VMS_Email_Provider__mdt();
        ShiftService.CreateShiftRequest parsedEmail = new ShiftService.CreateShiftRequest();
        VMSShiftParser vmsParserBase = new VMSShiftParserBase();
        try {
            System.debug(LOGGINGLEVEL.ERROR, 'email.subject: ' + email.subject);
            System.debug(LOGGINGLEVEL.ERROR, 'email.fromName: ' + email.fromName);
            System.debug(LOGGINGLEVEL.ERROR, 'email.fromAddress: ' + email.fromAddress);
            System.debug(LOGGINGLEVEL.ERROR, 'email.toAddresses: ' + email.toAddresses);
            // System.debug(LOGGINGLEVEL.ERROR, 'email.headers: ' + email.headers);
            // for(Messaging.InboundEmail.Header header : email.headers) {
            //     System.debug(LOGGINGLEVEL.ERROR, 'header.name: ' + header.name);
            //     System.debug(LOGGINGLEVEL.ERROR, 'header.value: ' + header.value);
            // }
            // System.debug(LOGGINGLEVEL.ERROR, 'email.binaryAttachments: ' + email.binaryAttachments);
            // System.debug(LOGGINGLEVEL.ERROR, 'email.textAttachments: ' + email.textAttachments);
            // System.debug(LOGGINGLEVEL.ERROR, 'email.references: ' + email.references);
            // for(String references : email.references) {
            //     System.debug(LOGGINGLEVEL.ERROR, 'references: ' + references);
            // }
            System.debug(LOGGINGLEVEL.ERROR, 'env.fromAddress: ' + env.fromAddress);
            System.debug(LOGGINGLEVEL.ERROR, 'env.toAddress: ' + env.toAddress);
            // System.debug(LOGGINGLEVEL.ERROR, 'email.plainTextBody: ' + email.plainTextBody);
            // System.debug(LOGGINGLEVEL.ERROR, 'email.plainTextBody.length: ' + email.plainTextBody.length());
            // System.debug(LOGGINGLEVEL.ERROR, 'email.htmlBody: ' + email.htmlBody);
            // System.debug(LOGGINGLEVEL.ERROR, 'email.htmlBody.length: ' + email.htmlBody.length());

            // String emailSubject = email.subject;
            // System.debug(LOGGINGLEVEL.ERROR, 'emailSubject / length: ' + emailSubject + ' / ' + emailSubject.length());
            // List<String> emailBodyLines = email.plainTextBody.split('\n');
            // for (String emailBodyLine : emailBodyLines){
            // System.debug(LOGGINGLEVEL.ERROR, 'emailBodyLine / length: ' + emailBodyLine + ' / ' + emailBodyLine.length());
            // }

            // TODO - how to idenify which VMS Parser to use 
            // this will come from either: 
            //      source email address - depends on direct email or forwarded 
            //      read in subject/body 

            String strVMS;
            if(Test.isRunningTest()){
                System.debug(LOGGINGLEVEL.ERROR, 'email.plainTextBody: ' + email.plainTextBody);
                System.debug(LOGGINGLEVEL.ERROR, 'email.plainTextBody.indexOf: ' + email.plainTextBody.indexOf('staffcentral'));
            }
            // Integer vmsStaffCentral = email.plainTextBody.indexOf('staffcentral');
            // Integer vmsEmprevo = email.plainTextBody.indexOf('emprevo');
            // System.debug(LOGGINGLEVEL.ERROR, 'vmsStaffCentral: ' + vmsStaffCentral);
            // System.debug(LOGGINGLEVEL.ERROR, 'vmsEmprevo: ' + vmsEmprevo);

            if(email.plainTextBody.indexOf('staffcentral') > -1) {
                strVMS = 'StaffCentral';
            }
            else if(email.plainTextBody.indexOf('emprevo') > -1) {
                strVMS = 'Emprevo';
            }

            // String strVMS = 'StaffCentral';
            // VMS_Email_Provider__mdt vmsProvider = [SELECT Label, Email_Parsing_Class__c, VMS_Website__c FROM VMS_Email_Provider__mdt WHERE Label = :strVMS];
            // VMS_Email_Provider__mdt vmsProvider = [SELECT Label, Email_Parsing_Class__c FROM VMS_Email_Provider__mdt WHERE Label = :strVMS];
            vmsProvider = [SELECT Label, Email_Parsing_Class__c FROM VMS_Email_Provider__mdt WHERE Label = :strVMS];

            // String strVMS_Website = vmsProvider.VMS_Website__c; // not required
            // String strVMS_Parsing_Class = vmsProvider.Email_Parsing_Class__c;
            // use Type to create the instance of Class 
            Type typeClass = Type.forName(vmsProvider.Email_Parsing_Class__c);

            // VMSShiftParser vmsParser = new VMSParserStaffCentral();
            VMSShiftParser vmsParser = (VMSShiftParser)typeClass.newInstance();
            // ShiftService.CreateShiftRequest parsedEmail = vmsParser.parseEmail(email);
            parsedEmail = vmsParser.parseEmail(email);
            System.debug(LOGGINGLEVEL.ERROR, 'parsedEmail: ' + parsedEmail);

            // VMSShiftParser vmsParserBase = new VMSShiftParserBase();
            Database.SaveResult[] srList = new List<Database.SaveResult>();

            // vmsParserBase.createShift(parsedEmail);
            if (parsedEmail.action == 'Create'){
                // vmsParserBase.createShift(parsedEmail);
                parsedEmail.recordTypeId = Schema.SObjectType.sirenum__Shift__c.getRecordTypeInfosByName().get('Shift Demand').getRecordTypeId();
                srList = vmsParserBase.createShiftFromEmail(parsedEmail);
            }
            if (parsedEmail.action == 'Cancel' && parsedEmail.extShiftId != null){
                // TODO - update method to return Database.SaveResult[]
                // vmsParserBase.cancelShift(parsedEmail);
                srList = vmsParserBase.cancelShiftFromEmail(parsedEmail);
            }
            if (parsedEmail.action == null){
                // throw an error
                System.debug(LOGGINGLEVEL.ERROR, 'Throw general Excpetion');
                // ShiftService.ServiceException generalException = new ShiftService.ServiceException();
                throw new ShiftService.ServiceException('Email Error - Action not found');
                
            }

            // TODO - Notifications Groups/Users
            Set<String> sUsers = new Set<String>();
            // Users to be definded for Notification - use my ID for now
            List<User> testUser = [SELECT Id from User WHERE Name = '1218 Admin'];
            sUsers.add(testUser[0].Id);


            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully inserted shift. Shift ID: ' + sr.getId());
                    AttachEmailToObject.attachEmail(email, sr.getId());

                    // TODO - need to incorporate errors related to failing to parse Account/Site/Job Role

                    If (parsedEmail.action == 'Create' && (parsedEmail.jobRole == null || parsedEmail.contract == null || parsedEmail.site == null)){
                        // create error record 
                        parsedEmail.sfShiftId = sr.getId();
                        parsedEmail.shiftErrorInfo = '';
                        If (parsedEmail.site == null){
                            parsedEmail.shiftErrorInfo += 'Unable to map Facility. ';
                        }
                        If (parsedEmail.contract == null){
                            parsedEmail.shiftErrorInfo += 'Unable to map Contract. ';
                        }
                        If (parsedEmail.jobRole == null){
                            parsedEmail.shiftErrorInfo += 'Unable to map Job Role. ';
                        }
                    
                        parsedEmail.shiftErrorInfo +=  ' Please review email attached to Shift. ';
                        
                        Database.SaveResult[] srErrorList = vmsParserBase.createShiftError(parsedEmail);
                        for (Database.SaveResult srError : srErrorList) {
                            if (srError.isSuccess()) {
                                // Operation was successful, so get the ID of the record that was processed
                                System.debug('Successfully inserted shift error Shift ID: ' + srError.getId());
                                AttachEmailToObject.attachEmail(email, srError.getId());
                                String notTitle = 'Shift Partially Created'; // 250 chars
                                String notBody = 'Shift Partially Created: ' + parsedEmail.source + ' Shift Id ' + parsedEmail.extShiftId + ' Message '+ parsedEmail.shiftErrorInfo; // 750
                                SendCustomNotification.notifyUsers (sUsers, srError.getId(), notTitle, notBody, 'VMS_Shift_Partially_Created');
                            } else {
                                for(Database.Error err : srError.getErrors()) {
                                    System.debug('VMS Shift Error Record error: ' + err.getStatusCode() + ': ' + err.getMessage() + ': ' + err.getFields());
                                }
                            }
                        }
                    } else {
                        String notTitle = parsedEmail.action == 'Create' ? 'Shift Created': 'Shift Cancelled'; // 250 chars
                        String notBody = parsedEmail.action == 'Create' ? 'Shift Created: ' + parsedEmail.source + ' Shift Id ' + parsedEmail.extShiftId : 'Shift Cancelled: ' + parsedEmail.source + ' Shift Id ' + parsedEmail.extShiftId; // 750
                        String notType = parsedEmail.action == 'Create' ? 'VMS_Shift_Created' : 'VMS_Shift_Cancelled';
                        SendCustomNotification.notifyUsers (sUsers, sr.getId(), notTitle, notBody, notType);
                    }
                } else {
                    // Create a VMS Shift Error Record - attach email and send notification
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {              
                        System.debug('Shift Error: ' + err.getStatusCode() + ': ' + err.getMessage() + ': ' + err.getFields());
                        parsedEmail.errorType = err.getStatusCode().toString();
                        parsedEmail.errorMessage = err.getMessage();
                    }

                    // TODO - create a VMS Shift Error Object
                    Database.SaveResult[] srErrorList = vmsParserBase.createShiftError(parsedEmail);
                    for (Database.SaveResult srError : srErrorList) {
                        if (srError.isSuccess()) {
                            // Operation was successful, so get the ID of the record that was processed
                            System.debug('Successfully inserted shift error Shift ID: ' + srError.getId());
                            AttachEmailToObject.attachEmail(email, srError.getId());
                            String notTitle = 'Shift Error'; // 250 chars
                            String notBody = 'Shift Error: ' + parsedEmail.source + ' Shift Id ' + parsedEmail.extShiftId; // 750
                            SendCustomNotification.notifyUsers (sUsers, srError.getId(), notTitle, notBody, 'VMS_Shift_Error');
                        }
                        else {
                            for(Database.Error err : srError.getErrors()) {
                                System.debug('VMS Shift Error Record error: ' + err.getStatusCode() + ': ' + err.getMessage() + ': ' + err.getFields());
                            }
                        }
                    }
                }
            }                  
        } catch (Exception error) {
            System.debug(LOGGINGLEVEL.ERROR, 'error: ' + error.getMessage());
            // Database.rollback(sp);
            ShiftService.CreateShiftRequest errorEmail = new ShiftService.CreateShiftRequest();

            if(parsedEmail != null){
                errorEmail = parsedEmail;
            }

            errorEmail.errorType = error.getTypeName();
            // errorEmail.errorType = 'Unexpected Error';
            errorEmail.errorMessage = error.getMessage();
            
            Database.SaveResult[] srErrorList = vmsParserBase.createShiftError(errorEmail);
            for (Database.SaveResult srError : srErrorList) {
                if (srError.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully inserted shift error Shift ID: ' + srError.getId());
                    AttachEmailToObject.attachEmail(email, srError.getId());
                    // String notTitle = 'Shift Error'; // 250 chars
                    // String notBody = 'Shift Error: ' + parsedEmail.source + ' Shift Id ' + parsedEmail.extShiftId; // 750
                    // SendCustomNotification.notifyUsers (sUsers, srError.getId(), notTitle, notBody, 'VMS_Shift_Error');
                }
                else {
                    for(Database.Error err : srError.getErrors()) {
                        System.debug('VMS Shift Error Record error: ' + err.getStatusCode() + ': ' + err.getMessage() + ': ' + err.getFields());
                    }
                }
            }
        }

        result.success = true;
        return result;
    }
        
}