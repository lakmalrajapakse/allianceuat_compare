public without sharing class Async_Utils {
    public static final String STATUS_SUCCESS = 'Success';
    public static final String STATUS_ERROR = 'Error';
    public static final List<String> ACTIVE_ASYNC_EXECUTION_STATUSES = new List<String> {
        'New', 'Queued', 'Executing'
    };
    public static final List<String> BAD_ASYNC_EXECUTION_STATUSES = new List<String> {
        'Error'
    };

    public static final List<String> ACTIVE_BATCH_STATUSES = new List<String> {
        'Holding', 'Queued', 'Preparing', 'Processing'
    };
    public static final List<String> EXECUTING_BATCH_STATUSES = new List<String> {
        'Preparing', 'Processing'
    };
    
    public static Boolean isContextAsync() {
        return (System.isBatch() || System.isFuture() || System.isQueueable() || System.isScheduled());
    }
    
    public static Boolean isAnotherBatchActive(String batchClassName, Id currentJobId) {
        // Validate there is a class name
        if (String.isBlank(batchClassName)) {
            return false;
        }

        // Get the namespace and the class name
        String namespace = '';
        String className = batchClassName;
        // Batch implementations are always top-level classes, so any dot must delineate the separation
        // between namespace and class name
        if (batchClassName.contains('.')) {
            namespace = batchClassName.substringBefore('.');
            className = batchClassName.substringAfter('.');
        }

        // When the current job id is specified (the check is called form the start of a batch), we only need
        // to check for another 'Preparing' or 'Processing' batch to allow the first batch in the queue to start
        // executing even if there are more items waiting in the queue
        List<String> statuses = currentJobId != null ? EXECUTING_BATCH_STATUSES : ACTIVE_BATCH_STATUSES;

        // Count the number of active batch items that are not the current batch
        return 0 < [
                SELECT COUNT()
                FROM AsyncApexJob
                WHERE Id != :currentJobId
                AND ApexClass.NamespacePrefix = :namespace
                AND ApexClass.Name = :className
                AND (JobType = 'BatchApex' OR JobType = 'Queueable')
                AND Status IN :statuses
        ];
    }
}