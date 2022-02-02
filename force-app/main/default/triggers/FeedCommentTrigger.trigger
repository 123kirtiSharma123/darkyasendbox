trigger FeedCommentTrigger on FeedComment (after insert) {

    if(Trigger.isAfter && Trigger.isInsert){
        FeedCommentTriggerHandler.afterInsert(trigger.new, trigger.newMap);
    }
}