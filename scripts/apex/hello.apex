// String cronExpression = '0 12 * * * ?'; // Every minute at 0 seconds
// String jobName = 'ProductSyncJob';

// ScheduledProductSync job = new ScheduledProductSync();
// System.schedule(jobName, cronExpression, job);

        try {
            // Query for the deleted product using ALL ROWS to include deleted records
            List<Product2> deletedProducts = [SELECT Id, Name FROM Product2 WHERE IsDeleted = true ALL ROWS];
            System.debug(deletedProducts.size());
            // Perform the undelete operation
            undelete deletedProducts;

        } catch (Exception e) {
            System.debug('Error undeleting product: ' + e.getMessage());
        }