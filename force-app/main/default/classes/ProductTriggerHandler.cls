public with sharing class ProductTriggerHandler {
    public void run() {
        if (Trigger.isDelete) { // 싱크와 싱크 사이에 만들었다가 지우면?
            handleBeforeDelete(Trigger.old);
        }
        
        if (Trigger.isUndelete) {
            handleUndelete(Trigger.new);
        }
    }

    public static void handleBeforeDelete(List<Product2> deletedProducts) {
        List<DeletedProduct__c> deletedProductsToInsert = new List<DeletedProduct__c>();
        DateTime now = System.now();
        
        for (Product2 deletedProduct : deletedProducts) {
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

    public static void handleUndelete(List<Product2> undeletedProducts) {
        Set<Id> undeletedProductIds = new Set<Id>();
        for (Product2 undeletedProduct : undeletedProducts) {
            undeletedProductIds.add(undeletedProduct.Id);
        }
    
        List<DeletedProduct__c> deletedProductsToRemove = [
            SELECT Id FROM DeletedProduct__c 
            WHERE ProductId__c IN :undeletedProductIds
        ];
    
        if (!deletedProductsToRemove.isEmpty() && Schema.sObjectType.DeletedProduct__c.isDeletable()) {
            delete deletedProductsToRemove;
        }
    }
}