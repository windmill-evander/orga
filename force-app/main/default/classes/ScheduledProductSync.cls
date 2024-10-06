public with sharing class ScheduledProductSync implements Schedulable {
    public void execute(SchedulableContext sc) {
        CalloutJob.postChangedProductsForSchedule(); // future, static
    }
}