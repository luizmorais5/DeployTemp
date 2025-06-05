@isTest
global class GoogleDistanceMatrixMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        res.setBody(
            '{' +
                '"destination_addresses":["Av. Sumaré, 1000 - Perdizes, São Paulo - SP, 05016-110, Brazil"],' +
                '"origin_addresses":["Av. Paulista, 1000 - Bela Vista, São Paulo - SP, 01311-200, Brazil"],' +
                '"rows":[{' +
                    '"elements":[{' +
                        '"distance":{"text":"4.6 km","value":4553},' +
                        '"duration":{"text":"11 mins","value":664},' +
                        '"status":"OK"' +
                    '}]' +
                '}],' +
                '"status":"OK"' +
            '}'
        );
        return res;
    }
}