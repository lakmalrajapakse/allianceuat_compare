public with sharing class VMSShiftParserBase implements VMSShiftParser{
    
    public ShiftService.CreateShiftRequest parseEmail(Messaging.InboundEmail email){
        ShiftService.CreateShiftRequest shiftRequest = new ShiftService.CreateShiftRequest();
        return shiftRequest;
    }
    // 
    // public void createShift(ShiftService.CreateShiftRequest shiftRequest){
    //     List<ShiftService.CreateShiftRequest> shiftRequests = new List<ShiftService.CreateShiftRequest>();
    //     shiftRequests.add(shiftRequest);
    //     ShiftService.createShifts(shiftRequests);
    // }
    public Database.SaveResult[] createShiftFromEmail(ShiftService.CreateShiftRequest shiftRequest){
        List<ShiftService.CreateShiftRequest> shiftRequests = new List<ShiftService.CreateShiftRequest>();
        shiftRequests.add(shiftRequest);
        // ShiftService.createShifts(shiftRequests);
        Database.SaveResult[] srList = ShiftService.createShiftsFromEmail(shiftRequests);
        return srList;
    }

    // public void cancelShift(ShiftService.CreateShiftRequest shiftRequest){
    //     List<ShiftService.CreateShiftRequest> shiftRequests = new List<ShiftService.CreateShiftRequest>();
    //     shiftRequests.add(shiftRequest);
    //     ShiftService.cancelShifts(shiftRequests);
    // }
    public Database.SaveResult[] cancelShiftFromEmail(ShiftService.CreateShiftRequest shiftRequest){
        List<ShiftService.CreateShiftRequest> shiftRequests = new List<ShiftService.CreateShiftRequest>();
        shiftRequests.add(shiftRequest);
        // ShiftService.createShifts(shiftRequests);
        Database.SaveResult[] srList = ShiftService.cancelShiftsFromEmail(shiftRequests);
        return srList;
    }

    public Database.SaveResult[] createShiftError(ShiftService.CreateShiftRequest shiftRequest){
        List<ShiftService.CreateShiftRequest> shiftRequests = new List<ShiftService.CreateShiftRequest>();
        shiftRequests.add(shiftRequest);
        Database.SaveResult[] srList = ShiftService.createShiftErrors(shiftRequests);
        return srList;
    }
}