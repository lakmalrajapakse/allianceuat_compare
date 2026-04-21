public class SMSRequestSender {
    public HttpResponse sendRequest(SMSRequest request) {
        Http http = new Http();
        HttpRequest httpRequest = createHttpRequest(request);

    System.debug(LOGGINGLEVEL.ERROR, 'SMSRequestSender httpRequest Method: ' + httpRequest.getMethod());
    System.debug(LOGGINGLEVEL.ERROR, 'SMSRequestSender httpRequest Endpoint: ' + httpRequest.getEndpoint());
    System.debug(LOGGINGLEVEL.ERROR, 'SMSRequestSender httpRequest Date: ' + httpRequest.getHeader('Date'));
    //System.debug(LOGGINGLEVEL.ERROR, 'req Content-Type: ' + req.getHeader(Content-Type));
    System.debug(LOGGINGLEVEL.ERROR, 'SMSRequestSender httpRequest Authorization: ' + httpRequest.getHeader('Authorization'));

        return http.send(httpRequest);
    }

    private HttpRequest createHttpRequest(SMSRequest request) {
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint(request.apiUrl);
        httpRequest.setMethod('POST');

        // Set individual headers
        for (String headerName : request.headers.keySet()) {
            httpRequest.setHeader(headerName, request.headers.get(headerName));
        }

        httpRequest.setBody(request.payloadJSON);
        // System.assert(false, request.payloadJSON);
        return httpRequest;
    }
}