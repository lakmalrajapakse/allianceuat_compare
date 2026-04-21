public with sharing class AvailabilitySelectorController {
    private static final Set<String> AM_TYPES = new Set<String>{
        Constants.EMPLOYEE_REQUEST_AM_AVAILABLE,
        Constants.EMPLOYEE_REQUEST_AM_UNAVAILABLE
    };

    private static final Set<String> PM_TYPES = new Set<String>{
        Constants.EMPLOYEE_REQUEST_PM_AVAILABLE,
        Constants.EMPLOYEE_REQUEST_PM_UNAVAILABLE
    };

    private static final Set<String> NIGHT_TYPES = new Set<String>{
        Constants.EMPLOYEE_REQUEST_ND_AVAILABLE,
        Constants.EMPLOYEE_REQUEST_ND_UNAVAILABLE
    };

    @AuraEnabled
    public static void saveAvailability(Id contactId, List<EmployeeRequest> requests) {
        try {
            List<sirenum__Employee_Request__c> ers = new List<sirenum__Employee_Request__c>();
            List<sirenum__Employee_Request__c> deleteErs = new List<sirenum__Employee_Request__c>();

            for (EmployeeRequest request : requests) {
                String type = '';

                if (request.Available == null) {
                    if (request.Id != null) {
                        deleteErs.add(new sirenum__Employee_Request__c(Id = request.Id));
                    }

                    continue;
                }

                if (request.Type == 0) {
                    type = request.Available
                        ? Constants.EMPLOYEE_REQUEST_AM_AVAILABLE
                        : Constants.EMPLOYEE_REQUEST_AM_UNAVAILABLE;
                } else if (request.Type == 1) {
                    type = request.Available
                        ? Constants.EMPLOYEE_REQUEST_PM_AVAILABLE
                        : Constants.EMPLOYEE_REQUEST_PM_UNAVAILABLE;
                } else if (request.Type == 2) {
                    type = request.Available
                        ? Constants.EMPLOYEE_REQUEST_ND_AVAILABLE
                        : Constants.EMPLOYEE_REQUEST_ND_UNAVAILABLE;
                }

                sirenum__Employee_Request__c er = new sirenum__Employee_Request__c(
                    Id = request.Id,
                    sirenum__Type__c = type,
                    sirenum__Local_Start_Date__c = request.Day,
                    sirenum__Contact__c = contactId
                );

                ers.add(er);
            }

            Database.upsert(ers, AccessLevel.USER_MODE);
            Database.delete(deleteErs, AccessLevel.USER_MODE);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static List<EmployeeRequest> getAvailabilityFrom(Date startDate, Id contactId, Integer days) {
        try {
            List<EmployeeRequest> results = new List<EmployeeRequest>();

            List<sirenum__Employee_Request__c> ers = [
                SELECT Id, sirenum__Type__c, sirenum__Local_Start_Date__c
                FROM sirenum__Employee_Request__c
                WHERE
                    sirenum__Contact__c = :contactId
                    AND sirenum__Local_Start_Date__c >= :startDate                    
                    AND sirenum__Local_Start_Date__c <= :startDate.addDays(days)
                WITH USER_MODE
            ];

            for (sirenum__Employee_Request__c er : ers) {
                EmployeeRequest erd = new EmployeeRequest();
                erd.Id = er.Id;
                erd.Day = er.sirenum__Local_Start_Date__c;
                erd.Available = false;

                if (Constants.EMPLOYEE_REQUEST_AVAILABLE_TYPES.contains(er.sirenum__Type__c)) {
                    erd.Available = true;
                } else if (Constants.EMPLOYEE_REQUEST_UNAVAILABLE_TYPES.contains(er.sirenum__Type__c)) {
                    erd.Available = false;
                }

                if (AM_TYPES.contains(er.sirenum__Type__c)) {
                    erd.Type = 0;
                } else if (PM_TYPES.contains(er.sirenum__Type__c)) {
                    erd.Type = 1;
                } else if (NIGHT_TYPES.contains(er.sirenum__Type__c)) {
                    erd.Type = 2;
                }

                results.add(erd);
            }

            return results;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    public class EmployeeRequest {
        @AuraEnabled
        public String Id { get; set; }
        @AuraEnabled
        public Date Day { get; set; }
        @AuraEnabled
        public Integer Type { get; set; }
        @AuraEnabled
        public Boolean Available { get; set; }

        public EmployeeRequest() {
            Type = -1;
        }
    }
}