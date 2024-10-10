/****************************************************************************************   
* File Name   : ProductApi.cls
* Description : Product 관련 API  
* Test Class  : ProductApi_Test.cls
* Author      : Evander  
* Modification Log  
* ===============================================================  
* Ver  Date        Author        Modification  
* ===============================================================  
* 1.0  2024.10.07  Evander        Create  
**************************************************************************************** 
* TODO  
* 테스트 작성  
****************************************************************************************/ 
@RestResource(urlMapping='/product2/*')
global with sharing class ProductApi {
    static final Integer MB_OF_2_AS_BYTE = 2000000;
    // static final Integer MB_OF_2_AS_BYTE = 6000;
    static final Integer MAX_SIZE_OF_PRODUCT_TO_SEND = 5000;

    @HttpGet
    global static void doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        if (req.requestURI.endsWith('/synchronization')) {
            String deleteParam = req.params.get('delete');
            System.debug(deleteParam);
            Integer receivedDeleteOffset = (deleteParam != null) ? Integer.valueOf(deleteParam) : 0;
            String updateParam = req.params.get('update');
            System.debug(updateParam);
            Integer receivedUpdateOffset = (updateParam != null) ? Integer.valueOf(updateParam) : 0;
            Integer heapCur = Limits.getHeapSize();
            
            SyncProductRequestDto syncProductResponseDto = new SyncProductRequestDto();
            
            // can lock?
            // batch를 안쓰는데 50000 리밋을 봐야하나? or timeout by serialize?
            // Limits.getQueryRows()
            while (receivedDeleteOffset >= 0 && heapCur < MB_OF_2_AS_BYTE
                    && syncProductResponseDto.deletedProductIds.size() + syncProductResponseDto.updatedProducts.size() < 50000) { // 겁나 비효율적
                Integer heapRemain = MB_OF_2_AS_BYTE - heapCur;
                Integer chunk = heapRemain / MAX_SIZE_OF_PRODUCT_TO_SEND;
                if (chunk < 20) { // dml 개수 낮춰서 효율 && dml 제한 방어\
                    System.debug('too low chunk. heapRemain: ' + heapRemain + 'MAX SIZE PRODUCT: ' + MAX_SIZE_OF_PRODUCT_TO_SEND);
                    break;
                }

                List<Id> deletedProductIdChunk = ProductProcessor.extractDeletedProductIds(chunk, receivedDeleteOffset);
                if (deletedProductIdChunk.isEmpty()) { // end query deleted product
                    receivedDeleteOffset = -1;
                    break;
                }
                syncProductResponseDto.deletedProductIds.addAll(deletedProductIdChunk);
                receivedDeleteOffset += chunk;
                heapCur = Limits.getHeapSize();
            }
            
            while (receivedUpdateOffset >= 0 && heapCur < MB_OF_2_AS_BYTE
                    && syncProductResponseDto.deletedProductIds.size() + syncProductResponseDto.updatedProducts.size() < 50000) {
                Integer heapRemain = MB_OF_2_AS_BYTE - heapCur;
                Integer chunk = heapRemain / MAX_SIZE_OF_PRODUCT_TO_SEND;
                if (chunk < 20) {
                    System.debug('too low chunk. heapRemain: ' + heapRemain + 'MAX SIZE PRODUCT: ' + MAX_SIZE_OF_PRODUCT_TO_SEND);
                    break;
                }

                List<Map<String, Object>> updatedProductChunk = ProductProcessor.extractUpdatedProducts(chunk, receivedUpdateOffset);
                if (updatedProductChunk.isEmpty()) {
                    receivedUpdateOffset = -1;
                    break;
                }
                syncProductResponseDto.updatedProducts.addAll(updatedProductChunk);
                receivedUpdateOffset += chunk;
                heapCur = Limits.getHeapSize();
            }

            String jsonResponse = JSON.serialize(syncProductResponseDto);
            
            res.responseBody = Blob.valueOf(jsonResponse);
            res.statusCode = 200;

            if (receivedDeleteOffset != -1) {
                res.addHeader('Next-Url', '/services/apexrest/product2/synchronization?delete=' + receivedDeleteOffset);
            } else if (receivedUpdateOffset != -1) {
                res.addHeader('Next-Url', '/services/apexrest/product2/synchronization?update=' + receivedUpdateOffset);
            } else {
                res.addHeader('Next-Url', '');
            }
            
        } else {
            res.responseBody = Blob.valueOf('Invalid endpoint');
            res.statusCode = 404;
        }
    }

    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        if (req.requestURI.endsWith('/synchronization/results')) {
            SyncProductResultRequestDto requestDto =
                    (SyncProductResultRequestDto) JSON.deserialize(req.requestBody.toString(), SyncProductResultRequestDto.class);
            System.debug(requestDto.successfullyDeletedIds.toString());
            System.debug(requestDto.successfullyUpdatedIds.toString());
            
            try {
                if (requestDto.successfullyDeletedIds != null && !requestDto.successfullyDeletedIds.isEmpty()) {
                    deleteDeletedProducts(requestDto.successfullyDeletedIds);
                }

                if (requestDto.successfullyUpdatedIds != null && !requestDto.successfullyUpdatedIds.isEmpty()) {
                    updateProducts(requestDto.successfullyUpdatedIds);
                }

                res.statusCode = 200;
            } catch (Exception e) {
                System.debug('Error occurred: ' + e.getMessage());
                res.statusCode = 500;
                res.responseBody = Blob.valueOf('Error processing request: ' + e.getMessage());
            }
        } else {
            res.statusCode = 404;
            res.responseBody = Blob.valueOf('Resource not found');
        }
    }

    private static void deleteDeletedProducts(List<Id> deletedIds) {
        if (!Schema.sObjectType.DeletedProduct__c.isDeletable()) {
            System.debug('DeletedProduct__c is not deletable.');
            return;
        }

        try {
            List<DeletedProduct__c> productsToDelete = [SELECT Id FROM DeletedProduct__c WHERE ProductId__c IN :deletedIds];
            if (!productsToDelete.isEmpty()) {
                delete productsToDelete;
            }
        } catch (DmlException e) {
            System.debug('Error deleting products: ' + e.getMessage());
        }
    }
    
    private static void updateProducts(List<Id> updatedIds) {
        if (!Schema.sObjectType.Product2.isUpdateable()) {
            System.debug('Product2 is not updatable.');
            return;
        }

        try {
            List<Product2> productsToUpdate = [SELECT Id, IsSynced__c FROM Product2 WHERE Id IN :updatedIds];
            for (Product2 product : productsToUpdate) {
                product.IsSynced__c = true;
            }
            if (!productsToUpdate.isEmpty()) {
                update productsToUpdate;
            }
        } catch (DmlException e) {
            System.debug('Error updating products: ' + e.getMessage());
        }
    }

    private static String enqueueSyncProductCalloutJob() {
        System.enqueueJob(new SyncProductCalloutJob());
        return 'Sync started';
    }
}