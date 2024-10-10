public class SyncProductResultRequestDto {
    public List<Id> successfullyDeletedIds { get; set; }
    public List<Id> successfullyUpdatedIds { get; set; }
    
    public SyncProductResultRequestDto() {
        successfullyDeletedIds = new List<Id>();
        successfullyUpdatedIds = new List<Id>();
    }
}