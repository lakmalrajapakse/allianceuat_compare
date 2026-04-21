public with sharing class ShiftMatchGradingService {
    
    @InvocableMethod(label='Refresh ShiftMatch Pay Grading' category='Shiftmatch')
    public static void refreshShiftmatchPayGrading(List<ID> ids) {
        if (ids == null || ids.isEmpty()) {
            return;   
        }
        
        ShiftMatchManager sm = new ShiftMatchManager();
        sm.refreshShiftmatchGradingMapData(ids[0]);
    }
}