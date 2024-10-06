public class CalloutJob implements Queueable, Database.AllowsCallouts {
    public void execute(QueueableContext context) { // impl
        postChangedProducts();
    }

    // 여기서 changed products 사이즈를 보고 뭘 한다
    public static void postChangedProducts() {
        List<Product2> products = getChangedProducts();
        if (!products.isEmpty()) {
            callout(products);
        }
    }

    // 뭔가 잘... 해보자
    private static List<Product2> getChangedProducts() {
        List<Product2> products = [
            SELECT Id, Stock__c, ExternalId, Name
            FROM Product2
            WITH SECURITY_ENFORCED
        ];
        return products;
    }

    private static void callout(List<Product2> products) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:For_Org_B_Named/services/apexrest/product2/sync');
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

    @future(callout=true)
    public static void postChangedProductsForSchedule() {
        postChangedProducts();
    }
}
