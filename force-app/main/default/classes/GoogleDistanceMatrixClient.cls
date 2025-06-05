public with sharing class GoogleDistanceMatrixClient implements IGoogleDistanceMatrixClient {
    private static final String NAMED_CREDENTIAL = 'callout:Google_DistanceMatrix';

    public String callDistanceMatrixApi(String origin, String destination, String apiKey) {
        String originEncoded = EncodingUtil.urlEncode(origin, 'UTF-8');
        String destinationEncoded = EncodingUtil.urlEncode(destination, 'UTF-8');

        String url = NAMED_CREDENTIAL + '/maps/api/distancematrix/json' +
                     '?origins=' + originEncoded +
                     '&destinations=' + destinationEncoded +
                     '&key=' + apiKey;

        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('GET');

        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('>>>>> API CALL: req ' + req);
        System.debug('>>>>> API CALL: res ' + res);

        if (res.getStatusCode() != 200) {
            throw new CalloutException('Erro na chamada HTTP: ' + res.getStatus() + ' - ' + res.getBody());
        }

        return res.getBody();
    }
}