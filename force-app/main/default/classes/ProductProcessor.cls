/****************************************************************************************   
* File Name   : ProductProcessor.cls
* Description : Sync해야 할 Product 변경사항 처리
* Test Class  : ProductProcessor_Test.cls
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
public with sharing class ProductProcessor { // SyncProcessor?
    // 여기서 changed products 사이즈를 보고 진행
    public static void postChangedProducts() {
        List<Map<String, Object>> products = extractChangedProducts();
        if (!products.isEmpty()) {
            callout(products);
        }
    }

    // trigger? 변경된 것만 모을 수 있게 뭔가 잘 해보자
    public static List<Map<String, Object>> extractChangedProducts() {
        List<Product2> products = [
            SELECT Id, Stock__c, Name, Description, IsActive, ProductCode, Family
            FROM Product2
            WITH SECURITY_ENFORCED
        ];
        List<Map<String, Object>> productMaps = new List<Map<String, Object>>();
        List<Product2> productList = new List<Product2>();

        for (Product2 product : products) {
            Map<String, Object> productMap = new Map<String, Object>();
            productMap.put('Id', product.Id);
            productMap.put('Stock__c', product.Stock__c);
            productMap.put('Name', product.Name);
            productMap.put('Description', product.Description);
            productMap.put('IsActive', product.IsActive);
            productMap.put('ProductCode', product.ProductCode);
            productMap.put('Family', product.Family);
            
            productMaps.add(productMap);
        }
    
        return productMaps;
    }

    private static void callout(List<Map<String, Object>> products) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:For_Org_B_Named/services/apexrest/product2/sync'); // bulk API?
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(JSON.serialize(products));
        
        try {
            HttpResponse response = http.send(request);
            System.debug('Response: ' + response.getBody());
        } catch (Exception e) {
            System.debug('Error occurred while sending products: ' + e.getMessage());
        }
    }

    public static List<Id> extractDeletedProductIds() {
        List<DeletedProduct__c> deletedProducts = new List<DeletedProduct__c>();
        if (Schema.sObjectType.DeletedProduct__c.isAccessible()) {
            deletedProducts = [SELECT Id, ProductId__c FROM DeletedProduct__c];
        } else {
            System.debug('User does not have read access to DeletedProduct__c.'); // debug를 cust excep으로?
            throw new AuraHandledException('User does not have read access to DeletedProduct__c.');
        }
        List<Id> deletedProductIds = new List<Id>();
    
        for (DeletedProduct__c deletedProduct : deletedProducts) {
            deletedProductIds.add(deletedProduct.ProductId__c);
        }
    
        return deletedProductIds;
    }
}