public with sharing class ShiftMatchCandidateService {
    
    @InvocableMethod(label='Refresh ShiftMatch Candidates' category='Shiftmatch')
    public static void refreshShiftmatchCandidates(List<ID> ids) {
        if (ids == null || ids.isEmpty()) {
            return;   
        }
        
        ShiftMatchManager sm = new ShiftMatchManager();
        sm.refreshShiftmatchCandidates(ids[0]);
    }
}