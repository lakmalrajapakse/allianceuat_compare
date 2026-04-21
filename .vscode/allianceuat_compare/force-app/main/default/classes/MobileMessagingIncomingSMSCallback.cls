@RestResource(urlMapping='/MobileMessagingIncomingSMS/*')
global class MobileMessagingIncomingSMSCallback {

    @HttpPost
    global static String handleMessage() {
        system.debug('MobileMessagingIncomingSMSCallback handleMessage');
        RestRequest req = RestContext.request;
        try {         
            SMSSettings settings = SMSSettings.getInstance(); // how do we link the integrated SMS User to an SMS Cost Center
            // SMSSettings settings = SettingsProvider.getSettings();
            if (settings == null) {  
                System.debug('Settings not found');
                return 'Settings not found';
            }   

            // Below required for authentication 
            // String converFromHex;
            // for (String headerName : req.headers.keySet()) {
            //     system.debug('headerName: ' + headerName);
            //     system.debug('req.headers.get(headerName): ' + headerName + ' / ' + req.headers.get(headerName));
                
            //         if(headerName=='X-Request-Id') // is this the correct header
            //         {
            //             converFromHex = req.headers.get(headerName);
            //         }
            // }

            // Boolean verified = Crypto.verifyHmac(
            //     'hmacSHA256',
            //     blob.valueOf(req.requestBody.toString()),
            //     blob.valueOf(settings.authenticationToken), // is this authenticationToken or accountSID
            //     encodingutil.convertFromHex(converFromHex)
            // );

            String strMMToken; 
            for (String headerName : req.headers.keySet()) {
                // system.debug('MobileMessagingServiceStatusCallback headerName: ' + headerName);
                system.debug('MobileMessagingServiceStatusCallback req.headers.get(headerName): ' + headerName + ' / ' + req.headers.get(headerName));
                
                    if(headerName==settings.inboundHeader) 
                    {
                        strMMToken = req.headers.get(headerName);   
                        continue;                  
                    }
            }

            system.debug('MobileMessagingServiceStatusCallback strMMToken: ' + strMMToken);

            system.debug('MobileMessagingServiceStatusCallback req.requestBody: ' + req.requestBody.toString());

            if (strMMToken == settings.inboundToken && !String.isBlank(settings.inboundToken)){
             
                Map<String, Object> jsonPayload = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString().replaceAll('\n', '\\\\n'));
                // system.debug('MobileMessagingIncomingSMSCallback req.requestBody.toString(): ' + req.requestBody.toString());
                system.debug('MobileMessagingIncomingSMSCallback jsonPayload: ' + jsonPayload);

                String messageId = jsonPayload.get('metadata_sf_id').ToString().trim();
                String messageIdMM = jsonPayload.get('message_id').ToString();
                String replyId = jsonPayload.get('reply_id').ToString();
                String sourceAddress = jsonPayload.get('source_address').ToString();
                String destinationAddress = jsonPayload.get('destination_address').ToString();
                String messageContent = jsonPayload.get('message_content').ToString();
                String replyContent = jsonPayload.get('reply_content').ToString();

                system.debug('MobileMessagingServiceStatusCallback messageId / sourceAddress/ destinationAddress / reply_content: ' + messageId + ' / ' + sourceAddress + ' / ' + destinationAddress + ' / ' + replyContent );

                // String converFromHex;
                // for (String headerName : req.headers.keySet()) {
                //     system.debug('headerName: ' + headerName);
                //     // if(headerName=='X-TextUs-Signature')
                //     if(headerName=='X-TextUs-Signature')
                //     {
                //         converFromHex = req.headers.get(headerName);
                //     }
                // }

                // Boolean verified = Crypto.verifyHmac(
                // 'hmacSHA256',
                // blob.valueOf(req.requestBody.toString()),
                // // blob.valueOf(settings.textUsPrivateKey),
                // blob.valueOf(settings.authenticationToken),
                // //blob.valueOf('textus-pYXYCsmd78OSwtshFcnZ0w'),
                // encodingutil.convertFromHex(converFromHex)
                // );

            
                // if(verified && !String.isBlank(settings.textUsPrivateKey)){
                // if(verified && !String.isBlank(settings.authenticationToken)){
                //     Map<String, Object> messageObject = (Map<String, Object>) jsonPayload.get('message');
                //     Map<String, Object> conversationObject = (Map<String, Object>) jsonPayload.get('conversation');
                //     if (jsonPayload.get('action') != 'message.received') {
                //         return 'Action is not incoming';
                //     }
                    
                    
                //     String body = (String) messageObject.get('body');
                //     System.debug(body);
                //     String formattedNumber = (String) conversationObject.get('formattedPhoneNumber');
                //     String fromNumber = (String) conversationObject.get('phoneNumber');
                
                        // Standardize the phone number format to +XXXXXXXXXX
                        List<Contact> relatedContacts = new List<Contact>();
                
                        // Integer countryCodeLength = destinationAddress.indexOf(' ');

                        // Extract the country code and the remaining digits
                        // String countryCode = destinationAddress.substring(0, countryCodeLength);
                        // String remainingDigits = destinationAddress.substring(countryCodeLength);
                        
                        // Construct the list of values
                        List<String> phoneNumberValues = new List<String>{
                            sourceAddress//,                              // Original international format
                            // '0' + remainingDigits,                  // With leading zero
                            // remainingDigits                          // Without country code and leading zero
                        };
                        // Query 'Contact' using potentially matching 'MobilePhone' values
                            relatedContacts = [
                                SELECT Id
                                FROM Contact
                                WHERE MobilePhone IN :phoneNumberValues
                                ORDER BY CreatedDate DESC
                                LIMIT 1
                            ];
            
                if (!relatedContacts.isEmpty()) {
                   
                    // Attempt to find the last SMS message for default sender info
                    //List<MobileMessaging_SMS_Message__c> lastSMS = [SELECT Sender__c, Sender_Name__c FROM MobileMessaging_SMS_Message__c WHERE Contact__c = :relatedContacts[0].Id ORDER BY CreatedDate DESC LIMIT 1];
            
                    // Use Message Id from metadata supplied to original message to map Sender for inbound messages
                    List<MobileMessaging_SMS_Message__c> lastSMS = [SELECT Sender__c, Sender_Name__c FROM MobileMessaging_SMS_Message__c WHERE Id = :messageId];

                    //         // Default sender details (could be replaced with actual admin details)
                    //         String defaultSenderId;
                    //         String defaultSenderName;
                    //         if(Test.isRunningTest()){
                    //             defaultSenderId = UserInfo.getUserId();
                    //             defaultSenderName = 'SMS Admin';
                    //         } else {
                    //             // defaultSenderId = settings.adminId; // Replace with actual Admin Id
                    //             // defaultSenderName = settings.adminName; // Replace with actual Admin Name    
                    //             defaultSenderId = settings.defaultAdminId; // Replace with actual Admin Id
                    //             defaultSenderName = settings.defaultAdminName; // Replace with actual Admin Name      
                    //         }                

                    MobileMessaging_SMS_Message__c newSMS = new MobileMessaging_SMS_Message__c(
                    
                        Contact__c = relatedContacts[0].Id,
                        Message_Content__c = replyContent,
                        Short_Message__c = replyContent.left(255).trim(),
                        Status__c = 'Received',
                        Direction__c = 'inbound',
                        Source__c = 'incoming',
                        Destination_Number__c = destinationAddress,
                        // Set Sender__c and Sender__Name__c based on last message or default admin details
                        // Sender__c = lastSMS.isEmpty() ? defaultSenderId : lastSMS[0].Sender__c,
                        // Sender_Name__c = lastSMS.isEmpty() ? defaultSenderName : lastSMS[0].Sender_Name__c
                        Sender__c = lastSMS.isEmpty() ? null : lastSMS[0].Sender__c,
                        Sender_Name__c = lastSMS.isEmpty() ? 'No Sender' : lastSMS[0].Sender_Name__c
                    );

                        insert newSMS;
                        SMSEventLogger.logSMSEvent('inbound', sourceAddress, replyContent, newSMS.Contact__c, newSMS.Sender__c);
                        return 'Message Received';
                //     }
                }    
            }
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            sirenum__LogEntry__c logEntry = new sirenum__LogEntry__c(
                sirenum__Category__c = 'SMS Incoming',
                sirenum__Severity__c = 'Fatal',
                sirenum__Details__c = 'Error in MobileMessagingIncomingSMSCallback: ' + e.getMessage() + '\n' + req
            );
            insert logEntry;
            return(e.getMessage());
        }
        return('It seems nothing has ignited the process');
    }
    // Method to standardize phone number format to +XXXXXXXXXX
    private static String standardizePhoneNumber(String phoneNumber) {
        // Add leading '+' if not present
        if (!phoneNumber.startsWith('+')) {
            phoneNumber = '+' + phoneNumber;
        }
        return phoneNumber;
    } 

    // // Map of top 30 most important countries and their country codes
    // private static final Map<String, String> COUNTRY_CODES = new Map<String, String>{
    //     'US' => '1',
    //     'CA' => '1',
    //     'MX' => '52',
    //     'BR' => '55',
    //     'AR' => '54',
    //     'GB' => '44',
    //     'DE' => '49',
    //     'FR' => '33',
    //     'ES' => '34',
    //     'IT' => '39',
    //     'NL' => '31',
    //     'BE' => '32',
    //     'PL' => '48',
    //     'SE' => '46',
    //     'CH' => '41',
    //     'AT' => '43',
    //     'DK' => '45',
    //     'NO' => '47',
    //     'FI' => '358',
    //     'IE' => '353',
    //     'PT' => '351',
    //     'GR' => '30',
    //     'RU' => '7',
    //     'UA' => '380',
    //     'TR' => '90',
    //     'IN' => '91',
    //     'CN' => '86',
    //     'JP' => '81',
    //     'KR' => '82',
    //     'AU' => '61',
    //     'NZ' => '64'
    // };

    // @HttpPost
    // global static void handleMessage() {
    //     RestRequest req = RestContext.request;
    //     RestResponse res = RestContext.response;
    //     String fromNumber = req.params.get('From');
    //     String body = req.params.get('Body');
    //     String sid = req.params.get('SmsMessageSid');

    //     // Create an array of possible phone number variations
    //     List<String> phoneVariations = generatePhoneVariations(fromNumber);

    //     // Find all contacts with any of the phone number variations and a non-empty mobile number
    //     // List<Contact> relatedContacts = [
    //     //     SELECT Id
    //     //     FROM Contact
    //     //     WHERE MobilePhone IN :phoneVariations AND MobilePhone != null
    //     // ];
    //     List<List<SObject>> result = [
    //         FIND :String.join(phoneVariations, ' OR ')
    //         IN PHONE FIELDS
    //         RETURNING
    //             Contact(Id)
    //         LIMIT 1
    //     ];
    //     List<Contact> relatedContacts = result[0];

    //     // Create a new message record for each related contact with a non-empty mobile number
    //     List<MobileMessaging_SMS_Message__c> newSMSList = new List<MobileMessaging_SMS_Message__c>();
    //     for (Contact relatedContact : relatedContacts) {
    //         MobileMessaging_SMS_Message__c newSMS = new MobileMessaging_SMS_Message__c(
    //             Contact__c = relatedContact.Id,
    //             Message_Content__c = body,
    //             Short_Message__c = body.left(255).trim(),
    //             Status__c = 'Received',
    //             Direction__c = 'Inbound',
    //             Source__c = 'incoming'// Review data,
    //             //Incoming_Phone_Number__c = fromNumber,
    //             //UniqueId__c = sid
    //         );
    //         newSMSList.add(newSMS);
    //     }

    //     // Insert all the new message records
    //     if (!newSMSList.isEmpty()) {
    //         insert newSMSList;
    //     }

    //     String twiml = '<?xml version="1.0" encoding="UTF-8"?><Response/>';
    //     res.statusCode = 200;
    //     res.responseBody = Blob.valueOf(twiml);
    //     res.addHeader('Content-Type', 'application/xml');
    // }

    // // Helper method to generate phone number variations
    // private static List<String> generatePhoneVariations(String phoneNumber) {
    //     List<String> variations = new List<String>();
    //     variations.add(phoneNumber);

    //     // Determine the country code based on the phone number
    //     String countryCode = '';
    //     for (String code : COUNTRY_CODES.values()) {
    //         if (phoneNumber.startsWith('+' + code)) {
    //             countryCode = code;
    //             break;
    //         }
    //     }

    //     // Remove the country code from the phone number
    //     String withoutCountryCode = phoneNumber.replaceFirst('^\\+' + countryCode, '');
    //     variations.add(withoutCountryCode);

    //     // Add a leading '0' if it doesn't exist
    //     if (!withoutCountryCode.startsWith('0')) {
    //         variations.add('0' + withoutCountryCode);
    //     }

    //     return variations;
    // }

    
}