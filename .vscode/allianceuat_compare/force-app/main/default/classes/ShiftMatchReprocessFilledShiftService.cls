public with sharing class ShiftMatchReprocessFilledShiftService {
    @InvocableMethod(label='Reprocess ShiftMatch Filled Shifts' category='Shiftmatch')
    public static void reprocessShiftmatchShortfalls(List<List<ID>> ids) {
        if (ids == null || ids.isEmpty() || ids[0] == null || ids[0].isEmpty()) {
            return;   
        }
                
        ShiftMatchManager sm = new ShiftMatchManager();
        sm.reprocessFilledShifts(ids[0]);
    }
}