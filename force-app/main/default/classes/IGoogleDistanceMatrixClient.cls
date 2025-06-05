public interface IGoogleDistanceMatrixClient {
    String callDistanceMatrixApi(String origin, String destination, String apiKey);
}