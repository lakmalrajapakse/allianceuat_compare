public with sharing class SIM_ShiftTimeEvaluator {

    public class Request {
        @InvocableVariable(required=true description='Scheduled shift datetime')
        public Datetime scheduledDateTime;

        @InvocableVariable(required=false description='Minutes after now threshold (default 15)')
        public Integer minutesAfterNow;
    }

    public class Response {
        @InvocableVariable(description='True if scheduled start is valid')
        public Boolean isValid;

        @InvocableVariable(description='Scheduled start in UTC')
        public Datetime scheduledStartUtc;

        @InvocableVariable(description='Current time in UTC')
        public Datetime nowUtc;

        @InvocableVariable(description='Minutes difference (scheduled - now)')
        public Long minutesDifference;

        @InvocableVariable(description='Debug info')
        public String debug;
    }

    @InvocableMethod(label='Check Scheduled Shift' description='Valid if scheduled start is now, in the past, or within X minutes in the future (default 15).')
    public static List<Response> checkShift(List<Request> requests) {
        List<Response> results = new List<Response>();
        Datetime nowUtc = Datetime.now();

        for (Request req : requests) {
            Response res = new Response();
            res.nowUtc = nowUtc;
            res.scheduledStartUtc = req.scheduledDateTime;

            if (req.scheduledDateTime == null) {
                res.isValid = false;
                res.debug = 'Missing scheduledDateTime';
                results.add(res);
                continue;
            }

            Integer windowMins = (req.minutesAfterNow == null) ? 15 : req.minutesAfterNow;

            Long diffMinutes = (req.scheduledDateTime.getTime() - nowUtc.getTime()) / 60000;
            res.minutesDifference = diffMinutes;

            // ✅ Valid if in the past or within X minutes in the future
            res.isValid = (diffMinutes <= windowMins);

            res.debug = 'Scheduled: ' + req.scheduledDateTime +
                        ', Now: ' + nowUtc +
                        ', DiffMinutes: ' + diffMinutes +
                        ', WindowMins: ' + windowMins +
                        ', IsValid: ' + res.isValid;

            System.debug(res.debug);
            results.add(res);
        }

        return results;
    }
}