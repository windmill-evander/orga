trigger ProductTrigger on Product2 (before delete, after undelete, before update) { // Product.trigger
    new ProductTriggerHandler().run();
}