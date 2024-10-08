trigger ProductTrigger on Product2 (before delete, after undelete) {
    new ProductTriggerHandler().run();
}
