public without sharing class ShiftMatchShortfallBatch implements Database.Batchable<Id>, Database.Stateful, Database.AllowsCallouts {
    private ShiftMatchManager manager;

    public ShiftMatchShortfallBatch(ShiftMatchManager manager) {
        this.manager = manager;
    }

    public Iterable<Id> start(Database.BatchableContext ctx) {   
        return this.manager.getAccountIdsToProcess();
    }

    public void execute(Database.BatchableContext ctx, List<Id> accountIds) {        
        this.manager.processShortfall(accountIds[0]);
    }

    public void finish(Database.BatchableContext ctx) {
        //this.manager.finalizeShortfallBatch();
    }
}