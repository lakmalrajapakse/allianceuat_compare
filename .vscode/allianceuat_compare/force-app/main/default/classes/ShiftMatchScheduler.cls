global class ShiftMatchScheduler implements Schedulable {
    static final String jobName = 'ShiftMatchScheduler';
    static final SIM_General_Settings__c settings = SIM_General_Settings__c.getInstance();

    global void execute(SchedulableContext SC) {
        try {
            // Call the method to match shifts
            ShiftMatchManager sm = new ShiftMatchManager();
            sm.processShortfalls();
        } finally {
            rescheduleJob(settings.Shiftmatch_Scheduler_Name__c, Integer.valueOf(settings.Shiftmatch_Minimum_Interval_mins__c));
        }
    }

    private static void rescheduleJob(String jobName, Integer minutesFromNow) {
        List<CronTrigger> jobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :jobName];

        if (!jobs.isEmpty()) {
            System.abortJob(jobs[0].Id);
        }

        String cronExpression = generateCronExpression(minutesFromNow);
        System.schedule(jobName, cronExpression, new ShiftMatchScheduler());
    }

 
    @testVisible
    private static String generateCronExpression(Integer minutesFromNow) {       
        DateTime scheduledTime = DateTime.now().addMinutes(minutesFromNow);  
        Integer minute = scheduledTime.minute();  
        Integer hour = scheduledTime.hour();  
        Integer day = scheduledTime.day(); 
        Integer month = scheduledTime.month();  
        Integer year = scheduledTime.year();  

        return '0 ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ? ' + year; 
    } 
}