public interface VMSShiftParser {
    ShiftService.CreateShiftRequest parseEmail(Messaging.InboundEmail email);
    // boolean createShift(ShiftService.CreateShiftRequest shiftRequest);
    // void createShift(ShiftService.CreateShiftRequest shiftRequest);
    // void cancelShift(ShiftService.CreateShiftRequest shiftRequest);
    Database.SaveResult[] createShiftFromEmail(ShiftService.CreateShiftRequest shiftRequest);
    Database.SaveResult[] createShiftError(ShiftService.CreateShiftRequest shiftRequest);
    Database.SaveResult[] cancelShiftFromEmail(ShiftService.CreateShiftRequest shiftRequest);
}