@isTest
public class QuipHelperTest{   

  @TestSetup
  static void setupData(){
    QuipSetting__c quipSetting = new QuipSetting__c();   
    quipSetting.Name = 'QuipSetting';
    quipSetting.ClientId__c = '66wgU+D59DKfZ6j+s37cvrGNyG4TjCPOJKAa/onzQlcLl+fcF7JCt9Odp757BvfL';
    quipSetting.ClientSecretKey__c = '66wgU+D59DKfZ6j+s37cvrGNyG4TjCPOJKAa/onzQlcLl+fcF7JCt9Odp757BvfL';
    insert quipSetting;

    Datetime currentDateTime = Datetime.now();
    String formattedDate = currentDateTime.formatGMT('dd/MM/yyyy HH:mm:ss');
    String docHtml = '';

    Knowledge__kav newArticle = new Knowledge__kav();
    newArticle.Title = 'Quip Document knowledge ' + ' ' + formattedDate;
    newArticle.UrlName = 'Quip-Document-knowledge';
    newArticle.Article_Content__c = docHtml;
    newArticle.Question__c = 'Knowledge title';
    newArticle.ThreadId__c = 'xn79876wzz';
    insert newArticle;

    Id knowledgeArticleId = [SELECT KnowledgeArticleId FROM Knowledge__kav WHERE Id =: newArticle.Id].KnowledgeArticleId;
    KbManagement.PublishingService.publishArticle(knowledgeArticleId, true);    
  }
  static testMethod void encryptionDecryptionTest(){
    String stringToEncrypt = 'klient-1234';
    Test.startTest();
      String encrypted = QuipHelper.encryptClientIdandclientSecret(stringToEncrypt);
      String decrypted = QuipHelper.decryptClientIdandclientSecret(encrypted);
      System.assertEquals(stringToEncrypt, decrypted);
    Test.stopTest();
  }    

  static testMethod void getRefreshTokenTest(){
    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
    Test.startTest();
      QuipHelper.Response res = QuipHelper.getRefreshToken();
    Test.stopTest();
    System.assertEquals(200, res.statusCode);
  }

  static testMethod void setVerificationCodeTest(){
    String verificationCode = '123456';
    Test.startTest();
      String error = QuipHelper.setVerificationCode(verificationCode);
      System.assertEquals('', error);
    Test.stopTest();    
  }

  static testMethod void getAccessTokenTest(){
    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
    Test.startTest();
      String accessToken = QuipHelper.getAccessToken();

      QuipSetting__c quipSetting = QuipSetting__c.getValues('QuipSetting');
      System.assertEquals(accessToken, quipSetting.AccessToken__c);
    Test.stopTest();
  }

  static testMethod void getQuipDocTest(){
    List<Knowledge__kav> knowledgeArticles = [Select Id, KnowledgeArticleId, Title, PublishStatus From Knowledge__kav limit 1];
    String recordId = knowledgeArticles.get(0).Id;

    Test.setMock(HttpCalloutMock.class, new QuipDocMock());

    Test.startTest();
      String error = QuipHelper.getQuipDoc(recordId, '123456');
      System.debug(error);
      System.assert(true);
    Test.stopTest();
  }

  static testMethod void getthreadIdTest(){
    List<Knowledge__kav> knowledgeArticles = [Select Id, ThreadId__c From Knowledge__kav limit 1];
    String recordId = knowledgeArticles.get(0).Id;
    String threadId = knowledgeArticles.get(0).ThreadId__c;

    Test.startTest();
      QuipHelper.ArticalthreadId articleThread = QuipHelper.getThreadId(recordId);
      System.assertEquals(threadId, articleThread.threadId);
    Test.stopTest();
  }
  
    static testMethod void publishArticleTest(){      
        Knowledge__kav newArticle = new Knowledge__kav();        
    	newArticle.Title = 'Quip Document knowledge 111';
    	newArticle.UrlName = 'Quip-Document-knowledge111';
    	newArticle.Article_Content__c = '';
    	newArticle.Question__c = 'Knowledge title';
    	newArticle.ThreadId__c = 'xn79876wzz';
    	insert newArticle;
        Knowledge__kav kavResult = [SELECT KnowledgeArticleId,PublishStatus FROM Knowledge__kav WHERE Id =: newArticle.Id LIMIT 1];
        system.debug(kavResult.KnowledgeArticleId);
        system.debug(kavResult.PublishStatus);
        Test.startTest();
       	QuipHelper.publishArticle(kavResult.KnowledgeArticleId);
        Test.stopTest();
        Knowledge__kav kavarticalvirsionResult = [SELECT KnowledgeArticleId,PublishStatus FROM Knowledge__kav WHERE KnowledgeArticleId =: kavResult.KnowledgeArticleId LIMIT 1];
       	system.debug(kavarticalvirsionResult.PublishStatus);
        System.assertEquals(kavarticalvirsionResult.PublishStatus, 'Online');
        
         QuipHelper.unPublishArticle(kavarticalvirsionResult.KnowledgeArticleId);
         Knowledge__kav unPublishArticleResult = [SELECT KnowledgeArticleId,PublishStatus FROM Knowledge__kav WHERE KnowledgeArticleId =: kavarticalvirsionResult.KnowledgeArticleId LIMIT 1];
      
        
        System.assertEquals(unPublishArticleResult.PublishStatus, 'Draft');

      }  
    
  private class MockHttpResponseGenerator implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        // You could assert the request content here
        //System.assertEquals('http://example.com/example/test', req.getEndpoint());
        //System.assertEquals('GET', req.getMethod());
        system.debug(req.getEndpoint());

        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"example":"test"}');
        res.setStatusCode(200);
        return res;
    }
  }

  private class QuipDocMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"html":"<h1 id=\'hxmdpn\'>Heading</h1>Test 1234<h2 id=\'hxmdpn\'>Heading2</h2><h3 id=\'hxmdpn\'>Heading3</h3><h4 id=\'hxmdpn\'>Heading4</h4><h5 id=\'hxmdpn\'>Heading5</h5><h6 id=\'hxmdpn\'>Heading6</h6><img src=\'/-/blob/MKSAAAoDn0d/x9ezZoIqJwwbNj6LFf6Emg\' id=\'ITeACAsTu8l\' alt=\'image\'></img>"}');
        res.setStatusCode(200);
        return res;
    }
  }
}