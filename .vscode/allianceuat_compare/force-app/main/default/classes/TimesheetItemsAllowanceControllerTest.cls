@isTest(SeeAllData=true)
private class TimesheetItemsAllowanceControllerTest {

    private static TimesheetItemsAllowanceController buildController(Id timesheetId) {
        ApexPages.StandardController sc = new ApexPages.StandardController(
            new tc9_et__Timesheet__c(Id = timesheetId)
        );
        return new TimesheetItemsAllowanceController(sc);
    }

    private static tc9_et__Timesheet__c getNewTimesheet() {
        return [
            SELECT Id, tc9_et__Transaction_Creation_Stage__c
            FROM   tc9_et__Timesheet__c
            WHERE  tc9_et__Transaction_Creation_Stage__c = '1'
            LIMIT  1
        ];
    }

    private static tc9_et__Timesheet__c getNonNewTimesheet() {
        return [
            SELECT Id, tc9_et__Transaction_Creation_Stage__c
            FROM   tc9_et__Timesheet__c
            WHERE  tc9_et__Transaction_Creation_Stage__c != '1'
            LIMIT  1
        ];
    }

    @isTest
    static void testConstructor_NewStage_IsNotProcessed() {
        tc9_et__Timesheet__c ts = getNewTimesheet();
        Test.startTest();
        TimesheetItemsAllowanceController ctrl = buildController(ts.Id);
        Test.stopTest();
        System.assertEquals(false, ctrl.isProcessed, 'Stage 1 should not be processed');
        System.assertEquals(false, ctrl.hasEdits, 'hasEdits should be false on load');
        System.assertNotEquals(null, ctrl.itemWrappers, 'itemWrappers should be initialised');
    }

    @isTest
    static void testConstructor_NonNewStage_IsProcessed() {
        tc9_et__Timesheet__c ts = getNonNewTimesheet();
        Test.startTest();
        TimesheetItemsAllowanceController ctrl = buildController(ts.Id);
        Test.stopTest();
        System.assertEquals(true, ctrl.isProcessed, 'Non-New stage should be locked');
    }

    @isTest
    static void testConstructor_NullRecordId_SetsErrorMessage() {
        ApexPages.StandardController sc = new ApexPages.StandardController(
            new tc9_et__Timesheet__c()
        );
        Test.startTest();
        TimesheetItemsAllowanceController ctrl = new TimesheetItemsAllowanceController(sc);
        Test.stopTest();
        System.assertNotEquals(null, ctrl.errorMessage, 'Error message should be set for null Id');
    }

    @isTest
    static void testItemWrappers_LoadedCorrectly() {
        tc9_et__Timesheet__c ts = getNewTimesheet();
        Test.startTest();
        TimesheetItemsAllowanceController ctrl = buildController(ts.Id);
        Test.stopTest();
        System.assertNotEquals(null, ctrl.itemWrappers, 'itemWrappers should not be null');
    }

    @isTest
    static void testMarkEdited_SetsHasEditsTrue() {
        tc9_et__Timesheet__c ts = getNewTimesheet();
        TimesheetItemsAllowanceController ctrl = buildController(ts.Id);
        Test.startTest();
        PageReference result = ctrl.markEdited();
        Test.stopTest();
        System.assertEquals(true, ctrl.hasEdits, 'hasEdits should be true after markEdited');
        System.assertEquals(null, result, 'markEdited should return null');
    }

    @isTest
    static void testSaveItems_NewStage_SavesSuccessfully() {
        tc9_et__Timesheet__c ts = getNewTimesheet();
        TimesheetItemsAllowanceController ctrl = buildController(ts.Id);
        if (ctrl.itemWrappers.size() > 0) {
            ctrl.itemWrappers[0].startTimeStr = '9:00 am';
            ctrl.itemWrappers[0].endTimeStr   = '5:00 pm';
        }
        Test.startTest();
        PageReference result = ctrl.saveItems();
        Test.stopTest();
        System.assertEquals('Timesheet items updated successfully.', ctrl.successMessage);
        System.assertEquals(null, ctrl.errorMessage);
        System.assertEquals(false, ctrl.hasEdits);
    }

    @isTest
    static void testSaveItems_NonNewStage_BlocksSave() {
        tc9_et__Timesheet__c ts = getNonNewTimesheet();
        TimesheetItemsAllowanceController ctrl = buildController(ts.Id);
        Test.startTest();
        ctrl.saveItems();
        Test.stopTest();
        System.assertEquals('Editing is not allowed in the current state. To make changes, click Revert To New above.', ctrl.errorMessage);
        System.assertEquals(null, ctrl.successMessage);
    }

    @isTest
    static void testSaveItems_BlankTimeStr_DoesNotOverwrite() {
        tc9_et__Timesheet__c ts = getNewTimesheet();
        TimesheetItemsAllowanceController ctrl = buildController(ts.Id);
        if (ctrl.itemWrappers.size() > 0) {
            Time originalStart = ctrl.itemWrappers[0].item.tc9_util__Start_Time__c;
            Time originalEnd   = ctrl.itemWrappers[0].item.tc9_util__End_Time__c;
            ctrl.itemWrappers[0].startTimeStr = '';
            ctrl.itemWrappers[0].endTimeStr   = '';
            Test.startTest();
            ctrl.saveItems();
            Test.stopTest();
            tc9_et__Timesheet_Item__c saved = [
                SELECT tc9_util__Start_Time__c, tc9_util__End_Time__c
                FROM   tc9_et__Timesheet_Item__c
                WHERE  Id = :ctrl.itemWrappers[0].item.Id
                LIMIT  1
            ];
            System.assertEquals(originalStart, saved.tc9_util__Start_Time__c, 'Blank string should not overwrite start time');
            System.assertEquals(originalEnd,   saved.tc9_util__End_Time__c,   'Blank string should not overwrite end time');
        }
    }

    @isTest
    static void testCancel_ResetsHasEditsAndReloads() {
        tc9_et__Timesheet__c ts = getNewTimesheet();
        TimesheetItemsAllowanceController ctrl = buildController(ts.Id);
        ctrl.hasEdits = true;
        Test.startTest();
        PageReference result = ctrl.cancel();
        Test.stopTest();
        System.assertEquals(false, ctrl.hasEdits, 'hasEdits should be false after cancel');
        System.assertEquals(null, result, 'cancel should return null');
        System.assertNotEquals(null, ctrl.itemWrappers, 'itemWrappers should be reloaded');
    }

    @isTest
    static void testRefreshIfStageChanged_NoChange_NoReload() {
        tc9_et__Timesheet__c ts = getNewTimesheet();
        TimesheetItemsAllowanceController ctrl = buildController(ts.Id);
        Boolean beforeProcessed = ctrl.isProcessed;
        Test.startTest();
        PageReference result = ctrl.refreshIfStageChanged();
        Test.stopTest();
        System.assertEquals(beforeProcessed, ctrl.isProcessed, 'isProcessed should not change');
        System.assertEquals(null, result);
    }

    @isTest
    static void testRefreshIfStageChanged_NullRecordId_ReturnsNull() {
        ApexPages.StandardController sc = new ApexPages.StandardController(new tc9_et__Timesheet__c());
        TimesheetItemsAllowanceController ctrl = new TimesheetItemsAllowanceController(sc);
        Test.startTest();
        PageReference result = ctrl.refreshIfStageChanged();
        Test.stopTest();
        System.assertEquals(null, result);
    }

    @isTest
    static void testSaveItems_ParseTime_TwelvePm_StaysTwelve() {
        tc9_et__Timesheet__c ts = getNewTimesheet();
        TimesheetItemsAllowanceController ctrl = buildController(ts.Id);
        if (ctrl.itemWrappers.size() > 0) {
            ctrl.itemWrappers[0].startTimeStr = '12:00 pm';
            ctrl.itemWrappers[0].endTimeStr   = '12:30 pm';
            Test.startTest();
            ctrl.saveItems();
            Test.stopTest();
            tc9_et__Timesheet_Item__c saved = [
                SELECT tc9_util__Start_Time__c, tc9_util__End_Time__c
                FROM   tc9_et__Timesheet_Item__c
                WHERE  Id = :ctrl.itemWrappers[0].item.Id LIMIT 1
            ];
            System.assertEquals(Time.newInstance(12, 0, 0, 0), saved.tc9_util__Start_Time__c, '12:00 pm should be hour 12');
            System.assertEquals(Time.newInstance(12, 30, 0, 0), saved.tc9_util__End_Time__c, '12:30 pm should be hour 12');
        }
    }

    @isTest
    static void testSaveItems_ParseTime_TwelveAm_BecomesZero() {
        tc9_et__Timesheet__c ts = getNewTimesheet();
        TimesheetItemsAllowanceController ctrl = buildController(ts.Id);
        if (ctrl.itemWrappers.size() > 0) {
            ctrl.itemWrappers[0].startTimeStr = '12:00 am';
            ctrl.itemWrappers[0].endTimeStr   = '12:15 am';
            Test.startTest();
            ctrl.saveItems();
            Test.stopTest();
            tc9_et__Timesheet_Item__c saved = [
                SELECT tc9_util__Start_Time__c, tc9_util__End_Time__c
                FROM   tc9_et__Timesheet_Item__c
                WHERE  Id = :ctrl.itemWrappers[0].item.Id LIMIT 1
            ];
            System.assertEquals(Time.newInstance(0, 0, 0, 0), saved.tc9_util__Start_Time__c, '12:00 am should be hour 0');
            System.assertEquals(Time.newInstance(0, 15, 0, 0), saved.tc9_util__End_Time__c, '12:15 am should be hour 0');
        }
    }

    @isTest
    static void testSaveItems_ParseTime_AfternoonHours() {
        tc9_et__Timesheet__c ts = getNewTimesheet();
        TimesheetItemsAllowanceController ctrl = buildController(ts.Id);
        if (ctrl.itemWrappers.size() > 0) {
            ctrl.itemWrappers[0].startTimeStr = '1:00 pm';
            ctrl.itemWrappers[0].endTimeStr   = '11:45 pm';
            Test.startTest();
            ctrl.saveItems();
            Test.stopTest();
            tc9_et__Timesheet_Item__c saved = [
                SELECT tc9_util__Start_Time__c, tc9_util__End_Time__c
                FROM   tc9_et__Timesheet_Item__c
                WHERE  Id = :ctrl.itemWrappers[0].item.Id LIMIT 1
            ];
            System.assertEquals(Time.newInstance(13, 0, 0, 0), saved.tc9_util__Start_Time__c, '1:00 pm should be hour 13');
            System.assertEquals(Time.newInstance(23, 45, 0, 0), saved.tc9_util__End_Time__c, '11:45 pm should be hour 23');
        }
    }

    @isTest
    static void testSaveItems_ParseTime_NoColon_DoesNotSave() {
        tc9_et__Timesheet__c ts = getNewTimesheet();
        TimesheetItemsAllowanceController ctrl = buildController(ts.Id);
        if (ctrl.itemWrappers.size() > 0) {
            Time originalStart = ctrl.itemWrappers[0].item.tc9_util__Start_Time__c;
            ctrl.itemWrappers[0].startTimeStr = 'invalid';
            ctrl.itemWrappers[0].endTimeStr   = '';
            Test.startTest();
            ctrl.saveItems();
            Test.stopTest();
            tc9_et__Timesheet_Item__c saved = [
                SELECT tc9_util__Start_Time__c
                FROM   tc9_et__Timesheet_Item__c
                WHERE  Id = :ctrl.itemWrappers[0].item.Id LIMIT 1
            ];
            System.assertEquals(null, saved.tc9_util__Start_Time__c, 'Invalid time string should result in null');
        }
    }

    @isTest
    static void testRefreshIfStageChanged_StageChangesToNonNew_UpdatesIsProcessed() {
        tc9_et__Timesheet__c ts = getNewTimesheet();
        TimesheetItemsAllowanceController ctrl = buildController(ts.Id);
        System.assertEquals(false, ctrl.isProcessed, 'Should start as not processed');
        ts.tc9_et__Transaction_Creation_Stage__c = '3';
        update ts;
        Test.startTest();
        ctrl.refreshIfStageChanged();
        Test.stopTest();
        System.assertEquals(true, ctrl.isProcessed, 'isProcessed should update to true after stage change');
    }

    @isTest
    static void testItemWrappers_TimeFormatting_MinutePadding() {
        tc9_et__Timesheet__c ts = getNewTimesheet();
        TimesheetItemsAllowanceController ctrl = buildController(ts.Id);
        TimesheetItemsAllowanceController.TimesheetItemWrapper w =
            new TimesheetItemsAllowanceController.TimesheetItemWrapper(
                new tc9_et__Timesheet_Item__c(
                    tc9_util__Start_Time__c = Time.newInstance(9, 5, 0, 0),
                    tc9_util__End_Time__c   = Time.newInstance(0, 0, 0, 0)
                )
            );
        System.assertEquals('9:05 am', w.startTimeStr, 'Single digit minute should be zero-padded');
        System.assertEquals('12:00 am', w.endTimeStr, 'Midnight should be 12:00 am');
    }

    @isTest
    static void testSaveItems_WithPopulatedTimeStrings_UpdatesRecord() {
        tc9_et__Timesheet__c ts = getNewTimesheet();
        TimesheetItemsAllowanceController ctrl = buildController(ts.Id);
        if (ctrl.itemWrappers.size() > 0) {
            ctrl.itemWrappers[0].startTimeStr = '8:00 am';
            ctrl.itemWrappers[0].endTimeStr   = '4:00 pm';
            Test.startTest();
            ctrl.saveItems();
            Test.stopTest();
            System.assertEquals('Timesheet items updated successfully.', ctrl.successMessage);
            tc9_et__Timesheet_Item__c saved = [
                SELECT tc9_util__Start_Time__c, tc9_util__End_Time__c
                FROM   tc9_et__Timesheet_Item__c
                WHERE  Id = :ctrl.itemWrappers[0].item.Id LIMIT 1
            ];
            System.assertEquals(Time.newInstance(8, 0, 0, 0), saved.tc9_util__Start_Time__c);
            System.assertEquals(Time.newInstance(16, 0, 0, 0), saved.tc9_util__End_Time__c);
        }
    }

    @isTest
    static void testSaveItems_ParseTime_BlankString_ReturnsNull() {
        tc9_et__Timesheet__c ts = getNewTimesheet();
        TimesheetItemsAllowanceController ctrl = buildController(ts.Id);
        if (ctrl.itemWrappers.size() > 0) {
            ctrl.itemWrappers[0].startTimeStr = '   ';
            ctrl.itemWrappers[0].endTimeStr   = '';
            Test.startTest();
            ctrl.saveItems();
            Test.stopTest();
            System.assertEquals('Timesheet items updated successfully.', ctrl.successMessage);
        }
    }

    @isTest
    static void testSaveItems_MultipleItems_AllUpdated() {
        tc9_et__Timesheet__c ts = getNewTimesheet();
        TimesheetItemsAllowanceController ctrl = buildController(ts.Id);
        if (ctrl.itemWrappers.size() > 1) {
            for (TimesheetItemsAllowanceController.TimesheetItemWrapper w : ctrl.itemWrappers) {
                w.startTimeStr = '7:00 am';
                w.endTimeStr   = '3:00 pm';
            }
            Test.startTest();
            ctrl.saveItems();
            Test.stopTest();
            System.assertEquals('Timesheet items updated successfully.', ctrl.successMessage);
        }
    }

    @isTest
    static void testCancel_AfterEdits_ReloadsCleanState() {
        tc9_et__Timesheet__c ts = getNewTimesheet();
        TimesheetItemsAllowanceController ctrl = buildController(ts.Id);
        ctrl.hasEdits = true;
        ctrl.successMessage = 'some message';
        ctrl.errorMessage   = 'some error';
        Test.startTest();
        ctrl.cancel();
        Test.stopTest();
        System.assertEquals(false, ctrl.hasEdits);
        System.assertNotEquals(null, ctrl.itemWrappers);
    }

    @isTest
    static void testMarkEdited_CalledMultipleTimes_RemainsTrue() {
        tc9_et__Timesheet__c ts = getNewTimesheet();
        TimesheetItemsAllowanceController ctrl = buildController(ts.Id);
        Test.startTest();
        ctrl.markEdited();
        ctrl.markEdited();
        ctrl.markEdited();
        Test.stopTest();
        System.assertEquals(true, ctrl.hasEdits);
    }

    @isTest
    static void testItemWrappers_WrapperProperties_SetCorrectly() {
        tc9_et__Timesheet__c ts = getNewTimesheet();
        TimesheetItemsAllowanceController ctrl = buildController(ts.Id);
        if (ctrl.itemWrappers.size() > 0) {
            TimesheetItemsAllowanceController.TimesheetItemWrapper w = ctrl.itemWrappers[0];
            System.assertNotEquals(null, w.item, 'item should not be null');
            System.assertEquals(false, w.isEdited, 'isEdited should default to false');
            System.assertNotEquals(null, w.startTimeStr, 'startTimeStr should not be null');
            System.assertNotEquals(null, w.endTimeStr, 'endTimeStr should not be null');
        }
    }

    @isTest
    static void testItemWrappers_AllHoursFormatCorrectly() {
        List<Time> testTimes = new List<Time>{
            Time.newInstance(0, 0, 0, 0),
            Time.newInstance(1, 15, 0, 0),
            Time.newInstance(11, 59, 0, 0),
            Time.newInstance(12, 0, 0, 0),
            Time.newInstance(13, 30, 0, 0),
            Time.newInstance(23, 45, 0, 0)
        };
        List<String> expected = new List<String>{
            '12:00 am', '1:15 am', '11:59 am', '12:00 pm', '1:30 pm', '11:45 pm'
        };
        for (Integer i = 0; i < testTimes.size(); i++) {
            TimesheetItemsAllowanceController.TimesheetItemWrapper w =
                new TimesheetItemsAllowanceController.TimesheetItemWrapper(
                    new tc9_et__Timesheet_Item__c(
                        tc9_util__Start_Time__c = testTimes[i],
                        tc9_util__End_Time__c   = testTimes[i]
                    )
                );
            System.assertEquals(expected[i], w.startTimeStr, 'Time ' + testTimes[i] + ' should format as ' + expected[i]);
        }
    }

    @isTest
    static void testSaveItems_SaveAndSaveAgain_BothSucceed() {
        tc9_et__Timesheet__c ts = getNewTimesheet();
        TimesheetItemsAllowanceController ctrl = buildController(ts.Id);
        if (ctrl.itemWrappers.size() > 0) {
            ctrl.itemWrappers[0].startTimeStr = '6:00 am';
            ctrl.itemWrappers[0].endTimeStr   = '2:00 pm';
            Test.startTest();
            ctrl.saveItems();
            System.assertEquals('Timesheet items updated successfully.', ctrl.successMessage);
            ctrl.itemWrappers[0].startTimeStr = '7:00 am';
            ctrl.itemWrappers[0].endTimeStr   = '3:00 pm';
            ctrl.saveItems();
            Test.stopTest();
            System.assertEquals('Timesheet items updated successfully.', ctrl.successMessage);
        }
    }

    @isTest
    static void testRefreshIfStageChanged_RevertsToNew_UnlocksEditing() {
        tc9_et__Timesheet__c ts = getNonNewTimesheet();
        TimesheetItemsAllowanceController ctrl = buildController(ts.Id);
        System.assertEquals(true, ctrl.isProcessed, 'Should start locked');
        ts.tc9_et__Transaction_Creation_Stage__c = '1';
        update ts;
        Test.startTest();
        ctrl.refreshIfStageChanged();
        Test.stopTest();
        System.assertEquals(false, ctrl.isProcessed, 'Should unlock after reverting to stage 1');
    }

}