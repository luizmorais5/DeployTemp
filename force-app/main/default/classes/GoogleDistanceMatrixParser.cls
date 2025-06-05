public class GoogleDistanceMatrixParser {
    public static DistanceMatrixResult parse(String jsonResponse) {
        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
        List<Object> rows = (List<Object>) root.get('rows');
        if (rows.isEmpty()) return null;

        Map<String, Object> row = (Map<String, Object>) rows[0];
        List<Object> elements = (List<Object>) row.get('elements');
        if (elements.isEmpty()) return null;

        Map<String, Object> element = (Map<String, Object>) elements[0];

        Map<String, Object> distance = (Map<String, Object>) element.get('distance');
        Map<String, Object> duration = (Map<String, Object>) element.get('duration');

        DistanceMatrixResult result = new DistanceMatrixResult();
        result.distanceText = (String) distance.get('text');
        result.distanceValue = ((Decimal) distance.get('value')).intValue();
        result.durationText = (String) duration.get('text');
        result.durationValue = ((Decimal) duration.get('value')).intValue();

        return result;
    }
}