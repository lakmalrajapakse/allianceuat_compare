public with sharing class ShiftMatchSkillService {
    @InvocableMethod(label='Refresh ShiftMatch Skills' category='Shiftmatch')
    public static void refreshShiftmatchSkills(List<ID> ids) {
        if (ids == null || ids.isEmpty()) {
            return;   
        }
        
        ShiftMatchManager sm = new ShiftMatchManager();
        sm.refreshShiftmatchSkillMapData(ids[0]);
    }
}