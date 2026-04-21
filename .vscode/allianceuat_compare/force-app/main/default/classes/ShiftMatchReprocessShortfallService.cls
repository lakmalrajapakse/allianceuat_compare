public with sharing class ShiftMatchReprocessShortfallService {
    
    @InvocableMethod(label='Reprocess ShiftMatch Shortfalls' category='Shiftmatch')
    public static void reprocessShiftmatchShortfalls(List<List<ID>> ids) {
        if (ids == null || ids.isEmpty() || ids[0] == null || ids[0].isEmpty()) {
            return;   
        }
        
        ShiftMatchManager sm = new ShiftMatchManager();
        sm.reprocessShortfalls(ids[0]);
    }
}