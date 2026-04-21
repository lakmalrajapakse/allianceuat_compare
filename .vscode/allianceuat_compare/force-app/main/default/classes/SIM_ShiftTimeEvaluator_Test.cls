@IsTest
public with sharing class SIM_ShiftTimeEvaluator_Test {
    
    @IsTest
    static void testShiftEvaluator_allScenarios() {
        Datetime now = Datetime.now();

        List<SIM_ShiftTimeEvaluator.Request> reqs = new List<SIM_ShiftTimeEvaluator.Request>();

        // Case 1: Past shift (always valid)
        SIM_ShiftTimeEvaluator.Request past = new SIM_ShiftTimeEvaluator.Request();
        past.scheduledDateTime = now.addMinutes(-30);
        reqs.add(past);

        // Case 2: Within default window (default 15 minutes)
        SIM_ShiftTimeEvaluator.Request within = new SIM_ShiftTimeEvaluator.Request();
        within.scheduledDateTime = now.addMinutes(10);
        reqs.add(within);

        // Case 3: Beyond default window (invalid)
        SIM_ShiftTimeEvaluator.Request beyond = new SIM_ShiftTimeEvaluator.Request();
        beyond.scheduledDateTime = now.addMinutes(60);
        reqs.add(beyond);

        // Case 4: Null scheduledDateTime (invalid)
        SIM_ShiftTimeEvaluator.Request missing = new SIM_ShiftTimeEvaluator.Request();
        missing.scheduledDateTime = null;
        reqs.add(missing);

        // Case 5: Custom window (30 mins) → still valid at +20
        SIM_ShiftTimeEvaluator.Request custom = new SIM_ShiftTimeEvaluator.Request();
        custom.scheduledDateTime = now.addMinutes(20);
        custom.minutesAfterNow = 30;
        reqs.add(custom);

        Test.startTest();
        List<SIM_ShiftTimeEvaluator.Response> results = SIM_ShiftTimeEvaluator.checkShift(reqs);
        Test.stopTest();

        System.assertEquals(5, results.size(), 'Should return one response per request');

        // Assertions
        System.assertEquals(true,  results[0].isValid, 'Past shift should be valid');
        System.assertEquals(true,  results[1].isValid, 'Within 15 minutes should be valid');
        System.assertEquals(false, results[2].isValid, 'Beyond 15 minutes should be invalid');
        System.assertEquals(false, results[3].isValid, 'Missing scheduledDateTime should be invalid');
        System.assertEquals(true,  results[4].isValid, 'Within custom 30 minutes should be valid');

        // Sanity check that debug info got populated
        for (SIM_ShiftTimeEvaluator.Response res : results) {
            System.assertNotEquals(null, res.debug, 'Debug string should not be null');
        }
    }
}