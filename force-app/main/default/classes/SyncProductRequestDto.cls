public with sharing class SyncProductRequestDto {
    public List<Map<String, Object>> updatedProducts { get; set; }
    public List<Id> deletedProductIds { get; set; }

    public SyncProductRequestDto() {
        updatedProducts = new List<Map<String, Object>>();
        deletedProductIds = new List<Id>();
    }
}