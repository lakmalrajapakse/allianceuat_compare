/**
* Created by: Rishikesh Kumar Suman
* Date: 12-Sep-2025
* Description: Reset the community password for a given Contact's associated user.
*/
public with sharing class CommunityPasswordResetController {
    
    // Constant for required Permission Set name
    private static final String REQUIRED_PERM_SET = 'X1218_Reset_Password_for_Alliance_Connect';
    
    /**
* Resets the password for the Community User linked to the given Contact Id.
* @param contactId The Id of the Contact whose Community User's password needs to be reset.
* @return A Map containing 'status' (SUCCESS / ERROR) and 'message' with details.
*/
    @AuraEnabled
    public static Map<String, String> resetPassword(Id contactId) {
        Map<String, String> result = new Map<String, String>();
        String status;
        String message;
        
        try {
            // Fetch the Community User linked to this Contact
            User communityUser = [
                SELECT Id, Email, IsActive, Profile.Name 
                FROM User 
                WHERE ContactId = :contactId
                LIMIT 1
            ];
            
            // Check if the Community User is active
            if (!communityUser.IsActive) {
                status = 'ERROR';
                message = 'The Community User is inactive. Cannot reset password.';
            } 
            // Check Permission Set (direct or via group)
            else if (!hasPermission(UserInfo.getUserId())) {
                status = 'ERROR';
                message = 'You do not have permission to reset passwords.';
            }
            // Check if the Community User's profile is Alliance Connect User
            else if (communityUser.Profile.Name != 'Alliance Connect User') {
                status = 'ERROR';
                message = 'Password reset is not allowed for this profile.';
            }
            // Reset password functionality
            else {
                System.resetPassword(communityUser.Id, true);
                status = 'SUCCESS';
                message = 'Password reset email sent to: ' + communityUser.Email;
            }
            
        } catch (QueryException qe) {
            status = 'ERROR';
            message = 'No Community User linked to this Contact.';
        } catch (Exception e) {
            status = 'ERROR';
            message = 'Error while resetting password: ' + e.getMessage();
        }
        
        result.put('status', status);
        result.put('message', message);
        return result;
    }
    
    // Helper method to check Permission Set or Permission Set Group
    Public static Boolean hasPermission(Id userId) {
        // Step 1: Direct Permission Set check
        Integer directCount = [
            SELECT COUNT()
            FROM PermissionSetAssignment
            WHERE AssigneeId = :userId
            AND PermissionSet.Name = :REQUIRED_PERM_SET
        ];
        if (directCount > 0) {
            return true;
        }
        
        // Step 2: Find all Permission Set Groups that include the required Permission Set
        Set<Id> groupIds = new Set<Id>();
        for (PermissionSetGroupComponent comp : [
            SELECT PermissionSetGroupId
            FROM PermissionSetGroupComponent
            WHERE PermissionSet.Name = :REQUIRED_PERM_SET
        ]) {
            groupIds.add(comp.PermissionSetGroupId);
        }
        
        if (groupIds.isEmpty()) {
            return false; // no groups contain this permission set
        }
        
        // Step 3: Check if the user has any of those groups assigned
        Integer groupCount = [
            SELECT COUNT()
            FROM PermissionSetAssignment
            WHERE AssigneeId = :userId
            AND PermissionSetGroupId IN :groupIds
        ];
        
        return groupCount > 0;
    }
    
}