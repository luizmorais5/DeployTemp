@isTest
private class GoogleDistanceMatrixServiceTest {
    @isTest static void testGetDistanceAndTime() {
        // Mock
        Test.setMock(HttpCalloutMock.class, new GoogleDistanceMatrixMock());

        Test.startTest();
        GoogleDistanceMatrixService service = new GoogleDistanceMatrixService();
        DistanceMatrixResult result = service.getDistanceAndTime('Av Paulista 1400', 'Av Sumaré 1234');
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals('4.6 km', result.distanceText);
        System.assertEquals('11 mins', result.durationText);
        System.assertEquals(4553, result.distanceValue);
        System.assertEquals(664, result.durationValue);
    }
}