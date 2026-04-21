/**
 * MobileMessagingServiceStatusCallback
 * This class defines a REST endpoint that acts as a callback service for handling status updates of SMS messages.
 * It is exposed as a REST resource and listens for HTTP POST requests with status updates from the SMS service provider.
 *
 * Usage:
 * - The service provider should send an HTTP POST request to this endpoint with the message ID and status as parameters.
 * - The endpoint captures the status and updates the corresponding Salesforce record.
 *
 * Created by: Issam Alameh
 * Role: Technical Consultant
 * Company: 1218 Global
 * Email: issam.alameh@1218global.com
 * LinkedIn: https://www.linkedin.com/in/issam
 * Creation Date: [Specify Creation Date Here]
 * Last Modified: 14 Jan 2024
 */
@RestResource(urlMapping='/MobileMessagingServiceStatusCallback/*')
global class MobileMessagingServiceStatusCallback {

    /**
     * Captures the status of an SMS message from an HTTP POST request and updates the Salesforce record.
     * The method retrieves the message ID and status from the request parameters, queries the corresponding record,
     * and updates it with the status received from the SMS service provider.
     *
     * @return A string indicating the result of the operation.
     */
    @HttpPost
    global static String captureStatus() {
        system.debug('MobileMessagingServiceStatusCallback captureStatus');
        RestRequest req = RestContext.request;

        // TO DO - include authentication code
        SMSSettings settings = SMSSettings.getInstance();  
        System.debug('MobileMessagingServiceStatusCallback settings.inboundHeader: ' + settings.inboundHeader);
        // SMSSettings settings = SettingsProvider.getSettings();

        // Below required for authentication 
        if (settings == null) {  
            System.debug('Settings not found');
            return 'Settings not found';
        }   

        // String strMMSignature;
        // String strMMDigest;
        // String strMMDate;
        String strMMToken; 
        for (String headerName : req.headers.keySet()) {
            // system.debug('MobileMessagingServiceStatusCallback headerName: ' + headerName);
            system.debug('MobileMessagingServiceStatusCallback req.headers.get(headerName): ' + headerName + ' / ' + req.headers.get(headerName));
            
                if(headerName==settings.inboundHeader) 
                {
                    strMMToken = req.headers.get(headerName);                     
                }
        }

        if (strMMToken == settings.inboundToken && !String.isBlank(settings.inboundToken)){
            Map<String, Object> reqBody = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
            system.debug('MobileMessagingServiceStatusCallback reqBody: ' + reqBody);
            RestResponse res = RestContext.response;
            // Map<String, Object> resBody = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
            // system.debug('MobileMessagingServiceStatusCallback resBody: ' + resBody);
    
            // Extract message ID and SMS status from request parameters
            // String messageId = req.params.get('messageId');
            // String smsStatus = req.params.get('SmsStatus');
            String messageId = reqBody.get('metadata_sf_id').ToString();
            String smsStatus = reqBody.get('status').ToString();
            //String errorCode = reqBody.get('error_code').ToString();
            system.debug('MobileMessagingServiceStatusCallback reqBody.get metadata_sf_id / status: ' + messageId + ' / ' + smsStatus );
    
            // Query Salesforce to find the message record by ID
            List<MobileMessaging_SMS_Message__c> messageList 
                  = [SELECT Id, Message_Response__c 
                     FROM MobileMessaging_SMS_Message__c 
                     WHERE Id =: messageId];
    
            // Check if a record with the given ID exists
            if(!messageList.isEmpty()) {
                // If found, update the message record with the new status
                MobileMessaging_SMS_Message__c message = messageList[0];
                message.Message_Response__c = smsStatus;
                update message;
            } 

        }

            // system.debug('MobileMessagingServiceStatusCallback req.requestBody.toString(): ' + req.requestBody.toString());

            // Boolean verified = Crypto.generateMac(
            //     'hmacSHA256', // 'hmac' + strMMDigest
            //     blob.valueOf(req.requestBody.toString()),
            //     blob.valueOf(settings.authenticationToken), // is this authenticationToken or accountSID
            //     encodingutil.convertFromHex(converFromHex)
            // );

            // Boolean verified = Crypto.verifyHmac(
            //     'hmacSHA256', // 'hmac' + strMMDigest
            //     blob.valueOf(req.requestBody.toString()),
            //     blob.valueOf(settings.authenticationToken), // is this authenticationToken or accountSID
            //     encodingutil.convertFromHex(converFromHex)
            // );
            // system.debug('MobileMessagingServiceStatusCallback verified: ' + verified);
            // returning false, so need to check which header

        // Return a success response
        return 'Success';
    }
}