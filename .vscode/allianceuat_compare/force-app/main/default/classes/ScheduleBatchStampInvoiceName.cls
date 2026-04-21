global class ScheduleBatchStampInvoiceName implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchStampInvoiceNameOnAssignment(), 200);
    }
}