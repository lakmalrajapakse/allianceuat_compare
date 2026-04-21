public class ShiftAutoBroadcastHandler {

    private static Boolean isRunning = false;

    public static void runAutoBroadcast(List<sirenum__Shift__c> shifts, Map<Id, sirenum__Shift__c> oldShiftMap ) {
        if (isRunning) return;
        isRunning = true;

        List<sirenum__Shift__c> autoBroadcastShifts = new List<sirenum__Shift__c>();

        for (sirenum__Shift__c shift : shifts) {

            if (oldShiftMap == null) {
                if (shift.Auto_Broadcast__c == true) {
                    autoBroadcastShifts.add(shift);
                }
            }
            else {
                sirenum__Shift__c oldShift = oldShiftMap.get(shift.Id);

                if (shift.Auto_Broadcast__c == true &&
                    oldShift.Auto_Broadcast__c == false) {

                    autoBroadcastShifts.add(shift);
                }
            }
        }

        if (!autoBroadcastShifts.isEmpty()) {
            ShiftBiddingService.autoBidShiftDemands(autoBroadcastShifts);
        }

        isRunning = false;
    }
}