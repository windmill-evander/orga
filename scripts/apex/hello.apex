String cronExpression = '0 58 * * * ?'; // 2 AM every day
ScheduledProductSync job = new ScheduledProductSync();
System.schedule('Product Sync', cronExpression, job);
