public with sharing class ProductTriggerHandler { // ProductSync_tr
    public void run() {
        if (Trigger.isDelete) { // 싱크와 싱크 사이에 만들었다가 지우면?
            handleBeforeDelete(Trigger.old);
        }
        
        if (Trigger.isUndelete) {
            handleUndelete(Trigger.new);
        }
        
        if (Trigger.isUpdate) {
            handleBeforeUpdate(Trigger.old, Trigger.new);
        }
    }

    private static void handleBeforeDelete(List<Product2> deletedProducts) {
        List<DeletedProduct__c> deletedProductsToInsert = new List<DeletedProduct__c>();
        
        for (Product2 deletedProduct : deletedProducts) {
            // if created && not-synced
            // return

            // deletedProduct.IsSynced__c = false; // trigger.old라서 readonly
            DeletedProduct__c deletedProductRecord = new DeletedProduct__c();
            deletedProductRecord.Name = deletedProduct.Name; 
            deletedProductRecord.ProductId__c = deletedProduct.Id; 
            deletedProductsToInsert.add(deletedProductRecord);
        }
        
        if (!deletedProductsToInsert.isEmpty() && Schema.sObjectType.DeletedProduct__c.isCreateable()) {
            insert deletedProductsToInsert; 
        } else {
            System.debug('User does not have create permission for DeletedProduct__c.');
        }
    }

    // similar to created --- orgB should delete and update
    private static void handleUndelete(List<Product2> undeletedProducts) {
        Set<Id> undeletedProductIds = new Set<Id>();
        for (Product2 undeletedProduct : undeletedProducts) {
            undeletedProductIds.add(undeletedProduct.Id);
            undeletedProduct.IsSynced__c = false; // undel -> new
        }
    
        List<DeletedProduct__c> deletedProductsToRemove = [
            SELECT Id FROM DeletedProduct__c 
            WHERE ProductId__c IN :undeletedProductIds
        ];
    
        if (!deletedProductsToRemove.isEmpty() && Schema.sObjectType.DeletedProduct__c.isDeletable()) {
            delete deletedProductsToRemove;
        }
    }

    // cannot cover update again before get result(between sync-req and get-result) 
    // so need to recieve failed-only
    private void handleBeforeUpdate(List<Product2> updatedProductsOld, List<Product2> updatedProductsNew) {
        for (Integer i = 0; i < updatedProductsOld.size(); i++) {
            if (updatedProductsOld[i].IsSynced__c) {
                updatedProductsNew[i].IsSynced__c = false;
            }
        }
    }
}