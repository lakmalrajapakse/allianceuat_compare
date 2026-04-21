trigger EmployeeRequestTrigger on sirenum__Employee_Request__c (before insert, before update) {
    EmployeeRequestTriggerHandler.handleChange();
}