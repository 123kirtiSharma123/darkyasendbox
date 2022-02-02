@isTest
public class TEST_FeedCommentTriggerHandler {
    @isTest static void testFeedCommentTriggerHandler(){
        Case caseObj = new Case(Status='Open', Priority='Medium');
        insert caseObj;
        
        //Create Related Feed Item Record
        FeedItem feeditm = new FeedItem(ParentId = caseObj.Id, Body = 'Test Body');
        insert feeditm;
        
        Profile profileObj = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User usr = new User(Alias = 'standt', Email='standarduser@testorg.com',
                            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', ProfileId = profileObj.Id,
                            TimeZoneSidKey='America/Los_Angeles',
                            UserName='userTestname@test.com');
        
        System.runAs(usr) {
            //Create Feed Comment Record
            FeedComment fcomment = new FeedComment(FeedItemId = feeditm.Id, CommentBody = 'Test Comment');
            insert fcomment;
        }
        
    }
}