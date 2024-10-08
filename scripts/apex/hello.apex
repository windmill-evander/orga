String cronExpression = '0 12 * * * ?'; // Every minute at 0 seconds
String jobName = 'ProductSyncJob';

ScheduledProductSync job = new ScheduledProductSync();
System.schedule(jobName, cronExpression, job);

// Apex code to update all Product2 records' Stock__c field to 2
// List<Product2> productsToUpdate = [SELECT Id, Stock__c FROM Product2];

// for (Product2 product : productsToUpdate) {
//     product.Stock__c = 2; // Set Stock__c to 2
// }

// try {
//     update productsToUpdate; // Perform the update
//     System.debug('Successfully updated Stock__c for all Product2 records to 2.');
// } catch (DmlException e) {
//     System.debug('Error occurred while updating Product2 records: ' + e.getMessage());
// }
