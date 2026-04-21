/**
* Created by: Rishikesh Kumar Suman
* Date: 12-Sep-2025
* Description: Test class to Reset the community password for a given Contact's associated user.
*/
@IsTest
private class CommunityPasswordResetControllerTest {
    
    // -------------------------
    // Test: Success
    // -------------------------
    @IsTest(SeeAllData=true)
    static void testResetPassword_Success() {
        // Query an existing community user with 'Alliance Connect User' profile
        User communityUser = [SELECT Id, ContactId, IsActive, Profile.Name 
                              FROM User 
                              WHERE Profile.Name='Alliance Connect User' 
                              AND IsActive = true
                              LIMIT 1];
    // Assign permission set to running user
    PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'X1218_Reset_Password_for_Alliance_Connect' LIMIT 1];
    insert new PermissionSetAssignment(
        AssigneeId = UserInfo.getUserId(),
        PermissionSetId = ps.Id
    );
        
        System.assertNotEquals(null, communityUser.ContactId, 'Community user must be linked to a contact');
        
        Test.startTest();
        Map<String,String> result = CommunityPasswordResetController.resetPassword(communityUser.ContactId);
        Test.stopTest();
        
        System.assertEquals('SUCCESS', result.get('status'));
        System.assert(result.get('message').contains('Password reset email sent'));
    }
    
    // ------------------------
    // Test: Inactive user
    // ------------------------
    @IsTest(SeeAllData=true)
    static void testResetPassword_InactiveUser() {
        // Query an existing inactive community user
        User inactiveUser = [SELECT Id, ContactId, IsActive, Profile.Name 
                             FROM User 
                             WHERE Profile.Name='Alliance Connect User' 
                             AND IsActive = false
                             LIMIT 1];
        
        Test.startTest();
        Map<String,String> result = CommunityPasswordResetController.resetPassword(inactiveUser.ContactId);
        Test.stopTest();
        
        System.assertEquals('ERROR', result.get('status'));
        System.assert(result.get('message').contains('inactive'));
    }
    
    // -------------------------
    // Test: No user linked
    // -------------------------
    @IsTest
    static void testResetPassword_NoUser() {
        // Create account & contact locally, no user linked
        Account acc = new Account(Name='Test NoUser Account', tc9_pr__Available_Payment_Methods__c='Payee Cash', tc9_pr__Maximum_Payment_Distributions__c='1');
        insert acc;
        
        Contact c = new Contact(FirstName='NoUser', LastName='Contact', AccountId=acc.Id);
        insert c;
        
        Test.startTest();
        Map<String,String> result = CommunityPasswordResetController.resetPassword(c.Id);
        Test.stopTest();
        
        System.assertEquals('ERROR', result.get('status'));
        System.assert(result.get('message').contains('No Community User'));
    }
    
    // -------------------------
    // Test: Exception (null Id)
    // -------------------------
    @IsTest
    static void testResetPassword_Exception() {
        Test.startTest();
        Map<String,String> result = CommunityPasswordResetController.resetPassword(null);
        Test.stopTest();
        
        System.assertEquals('ERROR', result.get('status'));
        //System.assert(result.get('message').contains('Error while resetting password'));
    }

 @IsTest
static void testAssignCurrentUserToPSG() {
    // 1. Query the Permission Set you want to link
    PermissionSet ps = [
        SELECT Id, Name 
        FROM PermissionSet 
        WHERE Name = 'X1218_Reset_Password_for_Alliance_Connect'
        LIMIT 1
    ];

    // 2. Fetch all users assigned to this PSG via PermissionSetAssignment
    List<PermissionSetAssignment> psaList = [
        SELECT AssigneeId, PermissionSetGroupId
        FROM PermissionSetAssignment
        WHERE PermissionSetId = :ps.Id OR PermissionSetGroupId != null
    ];

    Boolean isAssigned = false;
    for (PermissionSetAssignment psa : psaList) {
        if (psa.AssigneeId == UserInfo.getUserId()) {
            isAssigned = true;
            break;
        }
    }

    // Assert that the current user is assigned
    System.assert(isAssigned, 'Current user should be assigned to the Permission Set or Permission Set Group');
    System.debug('User assigned to PSG successfully.');

    // 3. Execute the helper method to cover it
    Boolean hasPerm = CommunityPasswordResetController.hasPermission(UserInfo.getUserId());
    System.assert(hasPerm, 'Helper method should return true for current user');
}

}