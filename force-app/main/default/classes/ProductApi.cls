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
    @HttpGet
    global static void doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        if (req.requestURI.endsWith('/sync')) {
            res.responseBody = Blob.valueOf(enqueueSyncProductCalloutJob());
            res.statusCode = 200;
        } else if (req.requestURI.endsWith('/synchronization')) {
            SyncProductRequestDto syncProductRequestDto = new SyncProductRequestDto();
            
            syncProductRequestDto.changedProducts = ProductProcessor.extractChangedProducts();
            syncProductRequestDto.deletedProductIds = ProductProcessor.extractDeletedProductIds();
    
            String jsonResponse = JSON.serialize(syncProductRequestDto);
    
            res.responseBody = Blob.valueOf(jsonResponse);
            res.statusCode = 200;

            // no problem? --> delete all deletedProduct // 이걸 또 B에서 던지자



        } else {
            res.responseBody = Blob.valueOf('Invalid endpoint');
            res.statusCode = 404;
        }
    }
    
    // Example method for syncing products
    private static String enqueueSyncProductCalloutJob() {
        System.enqueueJob(new SyncProductCalloutJob());
        return 'Sync started';
    }
}
