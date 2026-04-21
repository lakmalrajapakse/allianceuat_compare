public with sharing class Constants {
    public static final String EMPLOYEE_REQUEST_AM_AVAILABLE = 'AM - Available';
    public static final String EMPLOYEE_REQUEST_PM_AVAILABLE = 'PM - Available';
    public static final String EMPLOYEE_REQUEST_ND_AVAILABLE = 'ND - Available';

    public static final String EMPLOYEE_REQUEST_AM_UNAVAILABLE = 'AM - Unavailable';
    public static final String EMPLOYEE_REQUEST_PM_UNAVAILABLE = 'PM - Unavailable';
    public static final String EMPLOYEE_REQUEST_ND_UNAVAILABLE = 'ND - Unavailable';

    public static final String EMPLOYEE_REQUEST_SCHEDULED_ON_CONTRACT = 'Scheduled on Contract';

    public static final String CANDIDATE_AVAILABILITY_AVAILABLE_TYPE = 'Available';
    public static final String CANDIDATE_AVAILABILITY_UNAVAILABLE_TYPE = 'Unavailable';
    public static final String CANDIDATE_AVAILABILITY_SCHEDULED_TYPE = 'Scheduled';

    public static final Set<String> EMPLOYEE_REQUEST_AVAILABLE_TYPES = new Set<String>{
        EMPLOYEE_REQUEST_AM_AVAILABLE,
        EMPLOYEE_REQUEST_PM_AVAILABLE,
        EMPLOYEE_REQUEST_ND_AVAILABLE
    };

    public static final Set<String> EMPLOYEE_REQUEST_UNAVAILABLE_TYPES = new Set<String>{
        EMPLOYEE_REQUEST_AM_UNAVAILABLE,
        EMPLOYEE_REQUEST_PM_UNAVAILABLE,
        EMPLOYEE_REQUEST_ND_UNAVAILABLE
    };

    public static final Map<String, Map<String, String>> ER_TYPE_BY_PREFIX_AND_CA_TYPE = new Map<String, Map<String, String>>{
        CANDIDATE_AVAILABILITY_AVAILABLE_TYPE => new Map<String, String>{
            'AM' => EMPLOYEE_REQUEST_AM_AVAILABLE,
            'PM' => EMPLOYEE_REQUEST_PM_AVAILABLE,
            'ND' => EMPLOYEE_REQUEST_ND_AVAILABLE
        },
        CANDIDATE_AVAILABILITY_UNAVAILABLE_TYPE => new Map<String, String>{
            'AM' => EMPLOYEE_REQUEST_AM_UNAVAILABLE,
            'PM' => EMPLOYEE_REQUEST_PM_UNAVAILABLE,
            'ND' => EMPLOYEE_REQUEST_ND_UNAVAILABLE
        },
        CANDIDATE_AVAILABILITY_SCHEDULED_TYPE => new Map<String, String>{ '' => EMPLOYEE_REQUEST_SCHEDULED_ON_CONTRACT }
    };
}