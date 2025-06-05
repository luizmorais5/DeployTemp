public with sharing class GoogleDistanceMatrixService {
    private final IGoogleDistanceMatrixClient client;
    private final IGoogleApiKeyProvider keyProvider;

    public GoogleDistanceMatrixService() {
        this.client = new GoogleDistanceMatrixClient();
        this.keyProvider = new GoogleApiKeyProvider();
    }

    public DistanceMatrixResult getDistanceAndTime(String origin, String destination) {
        String apiKey = keyProvider.getApiKey();
        String jsonResponse = client.callDistanceMatrixApi(origin, destination, apiKey);
        return GoogleDistanceMatrixParser.parse(jsonResponse);
    }
}