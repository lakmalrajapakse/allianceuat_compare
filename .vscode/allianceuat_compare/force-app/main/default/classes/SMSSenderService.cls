public class SMSSenderService {
    public void sendSMS(String to, String body, Id messageId) {
        SMSSettings settings = SMSSettings.getInstance();
        // String apiToken = settings.apiToken;
        String apiToken = settings.accountSID;
        String phoneNumber = settings.senderPhoneNumber;
        // String apiUrl = settings.apiUrl;
        String apiUrl = settings.apiEndpoint;
        String apiSecret = settings.authenticationToken;

        SMSRequestBuilder requestBuilder = new SMSRequestBuilder();
        SMSRequest request = requestBuilder.buildRequest(apiToken, apiSecret, phoneNumber, apiUrl, to, body, messageId);

        SMSRequestSender sender = new SMSRequestSender();
        HttpResponse httpResponse = sender.sendRequest(request);
        System.debug(LOGGINGLEVEL.ERROR, 'SMSSenderService httpResponse: ' + httpResponse);
        System.debug(LOGGINGLEVEL.ERROR, 'SMSSenderService httpResponse.getStatus(): ' + httpResponse.getStatus());
        System.debug(LOGGINGLEVEL.ERROR, 'SMSSenderService httpResponse.getStatusCode(): ' + httpResponse.getStatusCode());
        System.debug(LOGGINGLEVEL.ERROR, 'SMSSenderService httpResponse.getBody(): ' + httpResponse.getBody());
        System.debug(LOGGINGLEVEL.ERROR, 'SMSSenderService httpResponse.getHeaderKeys(): ' + httpResponse.getHeaderKeys());
        System.debug(LOGGINGLEVEL.ERROR, 'SMSSenderService httpResponse.toString(): ' + httpResponse.toString());

        // Convert HttpResponse to SMSResponse
        SMSResponse smsResponse = new SMSResponse(httpResponse);
        System.debug(LOGGINGLEVEL.ERROR, 'SMSSenderService smsResponse: ' + smsResponse);

        // String messageMMId = smsResponse.getMMSMSMessage();
        // System.debug(LOGGINGLEVEL.ERROR, 'SMSSenderService messageMMId: ' + messageMMId);


        // Success from MM is defined as receiving a Response with a message 
        if (smsResponse.isSuccess()) {
            System.debug('SMS sent successfully!');
        } else {
            String errorTitle = smsResponse.getErrorTitle();
            String errorDetail = smsResponse.getErrorDetail();
            throw new SMSSendException('Failed to send SMS. Error Title: ' + errorTitle + ', Error Detail: ' + errorDetail);
        }
    }

    // public void sendSMS(String to, String body) {
    //     SMSSettings settings = SMSSettings.getInstance();

    //     if (settings.providerType.equals('TextUs')) {
    //         sendSMSViaTextUs(to, body, settings);
    //     } else if (settings.providerType.equals('Twilio')) {
    //         sendSMSViaTwilio(to, body, settings);
    //     } else if (settings.providerType.equals('MessageMedia')) {
    //         sendSMSViaMessageMedia(to, body, settings);
    //     } else {
    //         System.debug('Unsupported SMS provider type.');
    //     }
    // }

}