public with sharing class ShiftMatchLocationService {
    
    @InvocableMethod(label='Refresh Shiftmatch Locations' category='Shiftmatch')
    public static void refreshShiftmatchLocations(List<ID> ids) {
        if (ids == null || ids.isEmpty()) {
            return;   
        }
        
        ShiftMatchManager sm = new ShiftMatchManager();
        sm.refreshShiftmatchLocationMapData(ids[0]);
    }
}