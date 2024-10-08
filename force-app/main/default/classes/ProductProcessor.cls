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
public with sharing class ProductProcessor {
    // 여기서 changed products 사이즈를 보고 진행
    public static void postChangedProducts() {
        List<Product2> products = extractChangedProducts();
        if (!products.isEmpty()) {
            callout(products);
        }
    }

    // trigger? 변경된 것만 모을 수 있게 뭔가 잘 해보자
    private static List<Product2> extractChangedProducts() {
        List<Product2> products = [
            SELECT Id, Stock__c, ExternalId, Name, Description, IsActive, ProductCode, Family
            FROM Product2
            WITH SECURITY_ENFORCED
        ];
        return products;
    }

    private static void callout(List<Product2> products) {
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

}