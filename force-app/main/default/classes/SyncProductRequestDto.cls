public with sharing class SyncProductRequestDto {
    public List<Map<String, Object>> changedProducts { get; set; }
    public List<Id> deletedProductIds { get; set; }
}