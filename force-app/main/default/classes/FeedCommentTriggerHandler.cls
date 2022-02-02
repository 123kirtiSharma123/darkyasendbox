public without sharing class FeedCommentTriggerHandler {
    
    public static void afterInsert(List<FeedComment> feedComments, Map<Id,FeedComment> feedCommentNewMap){
        Map<Id, FeedComment> feedCommentByCaseId = new Map<Id, FeedComment>();
        Set<Id> userIds = new Set<Id>();
        //List<Case> caseListToUpdate = new List<Case>();
        for (FeedComment feedComment : feedComments) {
            if(String.ValueOf(feedComment.ParentId.getSobjectType()) == 'Case'){
                feedCommentByCaseId.put(feedComment.ParentId, FeedComment);
                userIds.add(FeedComment.createdById);
            }
        }
        updateCaseStatus(feedCommentByCaseId, userIds);
    }

    private static void updateCaseStatus(Map<Id, FeedComment> feedCommentByCaseId, Set<Id> userIds){
        List<Case> cases = [SELECT Id, Status, OwnerId FROM Case WHERE Id IN : feedCommentByCaseId.keySet() 
                            	AND Status != 'New'];
        Map<Id, User> userByUserId = new Map<Id, User>([SELECT Id, Name, ProfileId, Community_user__c FROM User WHERE Id IN : userIds]);
        List<Case> casesToUpdate = new List<Case>();
        for(Case caseObj : cases){
            if(feedCommentByCaseId.containsKey(caseObj.Id) && feedCommentByCaseId.get(caseObj.Id).createdById != caseObj.OwnerId){
                system.debug(feedCommentByCaseId.get(caseObj.Id).createdById);
                if(userByUserId.get(feedCommentByCaseId.get(caseObj.Id).createdById).Community_user__c){
                    caseObj.Internal_Status__c = 'New Post (Customer)';
                }else{
                    caseObj.Internal_Status__c = 'New Post (Internal)';    
                }
            }else{
                caseObj.Internal_Status__c = 'All good!';
            }
            casesToUpdate.add(caseObj);
        }
        update casesToUpdate;
    }
}