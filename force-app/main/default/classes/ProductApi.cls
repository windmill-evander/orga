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
    global static String doGet() {
        RestRequest req = RestContext.request;

        if (req.requestURI.endsWith('/sync')) {
            return enqueueSyncProductCalloutJob(); // 다시 callout 하려면 Queueable
        } else {
            return 'Invalid endpoint';
        }
    }

    private static String enqueueSyncProductCalloutJob() {
        System.enqueueJob(new SyncProductCalloutJob());
        return 'sync started'; // 상태같은거 리턴
    }
}