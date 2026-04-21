public class SMSRequestBuilder {
    public SMSRequest buildRequest(String apiToken, String apiSecret, String phoneNumber, String apiUrl, String to, String body, Id messageId) {
        // Map<String, String> headers = createHeaders(apiToken);
        
        Map<String, Object> payload = createPayload(phoneNumber, to, body, messageId);
        String payloadJSON = serializePayload(payload);
        Map<String, String> headers = createHeaders(apiToken, apiSecret, payloadJSON);
        String strApiUrl = apiUrl + '/v1/messages';

        System.debug(LOGGINGLEVEL.ERROR, 'SMSRequestBuilder headers: ' + headers);
        System.debug(LOGGINGLEVEL.ERROR, 'SMSRequestBuilder payload: ' + payload);
        System.debug(LOGGINGLEVEL.ERROR, 'SMSRequestBuilder payloadJSON: ' + payloadJSON);
        System.debug(LOGGINGLEVEL.ERROR, 'SMSRequestBuilder strApiUrl: ' + strApiUrl);

        //return new SMSRequest(apiUrl, headers, payloadJSON);
        return new SMSRequest(strApiUrl, headers, payloadJSON);
    }

    // Set up the HTTP request for the MessageMedia messaging service API
    // Step 1 Add a Date header to the request using the current date time in RFC7231 Section 7.1.1.2 format
    // Step 2 If the request has a body, add a header called Content-MD5 where the value of this header is an MD5 hash of the request body, 
    // otherwise this header is not required
    // Step 3 Create a signing string by concatenating the Date header, the Content-MD5 header (if set) and the request line with line breaks: 
    // Date: Sat, 30 Jul 2016 05:13:23 GMT\nContent-MD5: 10fd4feab20d38432480c07301e49616\nPOST /v1/messages HTTP/1.1 or
    // Date: Sat, 30 Jul 2016 05:13:23 GMT\nGET /v1/messages/404b941b-2a29-469f-b114-9ea3e16bbe18 HTTP/1.1
    // Step 4 Create a SHA1 HMAC hash using the signing string and the secret key (both converted to bytes using UTF-8) HMAC-SHA1(signing string, secret)
    // Step 5 Base64 encode the HMAC hash and include it as the signature in the Authorization header

    private Map<String, String> createHeaders(String apiToken, String apiSecret, String body) {


        // const hash = CryptoJS.enc.Hex.stringify(CryptoJS.MD5(pm.request.body.raw));
        // pm.environment.set("Content-MD5", hash);
 
        // const date = new Date().toGMTString();
        // pm.environment.set("Date", date);
        
        // const signingString = [
        //     "Date: " + date,"Content-MD5: " + hash, "POST /v1/messages HTTP/1.1"
        // ].join("\n");
        
        // pm.environment.set("SigningString", signingString);
        
        // var signBytes = CryptoJS.HmacSHA1(signingString, 'mMXU6YgxJv85YSgt29YhgPxMQ0vpN6');
        // var signHex = CryptoJS.enc.Base64.stringify(signBytes);
        
        // pm.environment.set("Signature",signHex);

        // String strHeaderDate = Datetime.now().format('EEE, dd MMM yyyy HH:mm:ss z','Europe/London');
        String strHeaderDate = Datetime.now().formatGMT('EEE, dd MMM yyyy HH:mm:ss z');
        // String strContentMd5 = EncodingUtil.base64Encode(Crypto.generateDigest('MD5', Blob.valueOf(body)));
        String strContentMd5 = EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(body)));
        String strSigningString = 'Date: ' + strHeaderDate + '\n' + 'Content-MD5: ' + strContentMd5 + '\n' + 'POST /v1/messages HTTP/1.1';
        // Blob blobHeaderDate = Blob.valueOf(dtHeaderDate);
        System.debug(LOGGINGLEVEL.ERROR, 'strSigningString: ' + strSigningString);
        String strSHA1HMAC = EncodingUtil.base64Encode(Crypto.generateMac('hmacSHA1', Blob.valueOf(strSigningString), Blob.valueOf(apiSecret)));
        System.debug(LOGGINGLEVEL.ERROR, 'strSHA1HMAC: ' + strSHA1HMAC);

        Map<String, String> headers = new Map<String, String>{
            // 'Authorization' => 'Bearer ' + apiToken,
            // 'Content-Type' => 'application/vnd.textus+jsonld',
            // 'Accept' => 'application/vnd.textus+jsonld'

            // 'Host' => 'api.messagemedia.com',
            // 'Date' => Datetime.now().format('EEE, dd MMM yyyy HH:mm:ss z','Europe/London'),
            'Date' => strHeaderDate,
            'Content-Type' => 'application/json',
            'Accept' => 'application/json',
            // 'Content-MD5' => EncodingUtil.base64Encode(Crypto.generateDigest('MD5', Blob.valueOf(body))), 
            'Content-MD5' => strContentMd5,
            // Authorization: hmac username="<API KEY>", algorithm="hmac-sha1", headers="Date Content-MD5 request-line", signature="<SIGNATURE>"
            'Authorization' => 'hmac username="' + apiToken + '", algorithm="hmac-sha1", headers="Date Content-MD5 request-line", signature="' + strSHA1HMAC + '"'
            // + EncodingUtil.base64Encode(Crypto.generateMac('hmacSHA1', Blob.valueOf('test'), Blob.valueOf('test')))        
     
        };
        return headers;
    }

    private Map<String, Object> createPayload(String phoneNumber, String to, String body, Id messageId) {
        Map<String, Object> payload = new Map<String, Object>{
            'messages' => new List<Map<String, Object>> {
                new Map<String, Object> {
                    'content' => body,
                    'destination_number' => to,
                    'source_number' => phoneNumber,
                    // callback not required as set up as Webhook
                    // 'callback_url' => 'https://allianceaustralia--dev.sandbox.my.salesforce-sites.com/smsintegration/services/apexrest/MobileMessagingServiceStatusCallback/',
                    'delivery_report' => true,
                    'metadata' => new Map<String, Object> {
                        'salesforce_message_id' => messageId
                    }
                }
            }
            // // 'from' => phoneNumber,
            // // 'to' => to,
            // // 'body' => body
            // 'content' => body,
            // 'destination_number' => to,
            // //'format' => SMS // this is the default
            // // additonal message data 
            // 'source_number' => phoneNumber
            // // 'callback_url' => ''
        };
        return payload;
    }

    private String serializePayload(Map<String, Object> payload) {
        return JSON.serialize(payload);
    }
}