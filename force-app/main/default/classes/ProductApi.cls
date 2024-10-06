@RestResource(urlMapping='/product2/*')
global with sharing class ProductApi {
    @HttpGet
    global static String doGet() {
        RestRequest req = RestContext.request;
        if (req.requestURI.endsWith('/sync')) {
            // 다시 callout 하려면 Queueable
            System.enqueueJob(new CalloutJob()); // 여기서 changed products 사이즈를 보고 뭘 한다
            return 'sync started';
        } else {
            return 'Invalid endpoint';
        }
    }
}