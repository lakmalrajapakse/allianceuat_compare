public class SMSResponse {
    private Map<String, Object> responseMap;
    private SMSResponseMM messageMediaResponse;
    private Integer responseStatus;

    // SMSResponseMM:[messages=
    // (Messages:[callback_url=https://allianceaustralia--dev.sandbox.my.salesforce-sites.com/smsintegration/services/apexrest/MobileMessagingServiceStatusCallback, 
    // delivery_report=true, destination_number=+447881825126, format=SMS, message_expiry_timestamp=null, message_flags=()
    // , message_id=5043771f-500d-45be-bd41-191de803b577])]

    public SMSResponse(System.HttpResponse httpResponse) {
        System.debug(LOGGINGLEVEL.ERROR, 'SMSResponse httpResponse: ' + httpResponse);
        responseMap = parseResponse(httpResponse.getBody());
        responseStatus = httpResponse.getStatusCode();

        System.debug(LOGGINGLEVEL.ERROR, 'SMSResponse responseMap: ' + responseMap);
        System.debug(LOGGINGLEVEL.ERROR, 'SMSResponse responseMap.keySet(): ' + responseMap.keySet());
        System.debug(LOGGINGLEVEL.ERROR, 'SMSResponse responseMap.values(): ' + responseMap.values());
        // System.debug(LOGGINGLEVEL.ERROR, 'SMSResponse responseMap.get(status): ' + responseMap.get('status'));
        // System.debug(LOGGINGLEVEL.ERROR, 'SMSResponse responseMap.get(message_id): ' + responseMap.get('message_id'));
        System.debug(LOGGINGLEVEL.ERROR, 'SMSResponse responseMap.get(messages): ' + responseMap.get('messages'));

        // Map<String, Object> responseMessageMap = (Map<String, Object>) JSON.deserializeUntyped(responseMap.get('messages'));
        // System.debug(LOGGINGLEVEL.ERROR, 'SMSResponse responseMessageMap: ' + responseMessageMap;
        // System.debug(LOGGINGLEVEL.ERROR, 'SMSResponse httpResponse.getBody(): ' + httpResponse.getBody());
        // messages messageResponse = (messages) JSON.deserialize(httpResponse.getBody(), messages.class);
        // System.debug(LOGGINGLEVEL.ERROR, 'messageResponse: ' + messageResponse);

        messageMediaResponse = (SMSResponseMM)JSON.deserialize(httpResponse.getBody(), SMSResponseMM.class);
        // System.debug(LOGGINGLEVEL.ERROR, 'messageMediaResponse: ' + messageMediaResponse);
        // System.debug(LOGGINGLEVEL.ERROR, 'messageMediaResponse.messages[0].message_id): ' + messageMediaResponse.messages[0].message_id);
        // System.debug(LOGGINGLEVEL.ERROR, 'messageMediaResponse.messages[0].status: ' + messageMediaResponse.messages[0].status);
        // System.debug(LOGGINGLEVEL.ERROR, 'messageMediaResponse.messages[0].metadata.salesforce_message_id: ' + messageMediaResponse.messages[0].metadata.salesforce_message_id);
    }

    public String getMMSMSMessage() {
        return messageMediaResponse.messages[0].message_id;
    }

    public Boolean isSuccess() {
        // Check for success response structure
        // return responseMap.containsKey('@type') && responseMap.get('@type').equals('Message');
        return responseStatus == 202 ? true : false;
    }

    public Map<String, Object> getMessages() {
        return (Map<String, Object>) responseMap.get('messages');
    }

    public String getErrorTitle() {
        return (String) responseMap.get('title');
    }

    public String getErrorDetail() {
        return (String) responseMap.get('detail');
    }

    private Map<String, Object> parseResponse(String responseBody) {
        try {
            return (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        } catch (Exception e) {
            throw new SMSSendException('Failed to parse JSON response: ' + e.getMessage());
        }
    }
}