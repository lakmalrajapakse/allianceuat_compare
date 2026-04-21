global class HouseKeeperScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        HouseKeeperHelper.runNextHouseKeepingJob(-1);
    }
}