public class QuipHelper{
   
     private static final Blob KEY_BLOB = Blob.valueOf('klient_quip_doc_setting_00000007');
     private static final Blob IV_BLOB = Blob.valueOf('klient_quip__doc');
     private static final String AES_256 = 'AES256';
     public static String verificationCode {get; set;}
     public static String publishStatus {get; set;}
 
     public QuipHelper(){
         verificationCode = ApexPages.currentPage().getParameters().get('code');
     }
 
    
     public static String encryptClientIdandclientSecret(String appId){
         Blob data = Blob.valueOf(appId);
         Blob encryptedData = Crypto.encrypt(AES_256, KEY_BLOB, IV_BLOB, data);
         return EncodingUtil.base64Encode(encryptedData);
     }
 
     public static String decryptClientIdandclientSecret(String appId){
         Blob data = EncodingUtil.base64Decode(appId);
         Blob decryptedData = Crypto.decrypt(AES_256, KEY_BLOB, IV_BLOB, data);
         return decryptedData.toString();
     }
 
    
 
     @RemoteAction
     public static String setVerificationCode(String verificationCode){
         String error = '';
         try{
             QuipSetting__c quipSetting = QuipSetting__c.getValues('QuipSetting');
     
             if(quipSetting == null){
                 quipSetting = new QuipSetting__c();
                 quipSetting.Name = 'QuipSetting';
             }
             
             quipSetting.Quip_Verification_Code__c = verificationCode;
             upsert quipSetting;
         }
         catch(Exception ex){
             error = 'Error - ' + ex.getMessage() + ' Line Number - ' + ex.getLineNumber();
         }
         return error;
     }
     
     @AuraEnabled
     public static String getAccessToken(){
         String redirectUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/apex/QuipPage';
         QuipSetting__c quipSetting = QuipSetting__c.getValues('QuipSetting');
        
         String appClientId = decryptClientIdandclientSecret(quipSetting.ClientId__c);
         String clientSecret = decryptClientIdandclientSecret(quipSetting.ClientSecretKey__c);
 
         String endPoint = 'https://platform.quip.com/1/oauth/access_token';
         String endPointUrl = endPoint + '?grant_type=authorization_code&client_id=' + appClientId + '&client_secret=' + clientSecret + '&code='+quipSetting.Quip_Verification_Code__c + '&redirect_uri='+redirectUrl;        
 
         HttpRequest req = new HttpRequest();
         req.setEndpoint(endPointUrl);
         req.setMethod('POST');
 
         Http http = new Http();
         HttpResponse response = http.send(req);
         system.debug('--Auth token response code -->' + response.getStatusCode());
         system.debug('--Auth token response body -->' + response.getBody());   
 
         if(response.getStatusCode() == 200){
             AccessTokenResponse tokenResponse = (AccessTokenResponse)JSON.deserialize(response.getBody(), AccessTokenResponse.class);
             quipSetting.AccessToken__c = tokenResponse.access_token;
             update quipSetting;      
             return tokenResponse.access_token;  
         }
         
         return '';
     }
     
 
     @AuraEnabled
     public static String getQuipDoc(String recordId, String threadId){   
         
         String errorMessage = '';   
         try{
             List<Knowledge__kav> knowledgeArticles = [Select Id, KnowledgeArticleId, Title, PublishStatus From Knowledge__kav Where Id =: recordId];
             //String knowledgeArticleTitle = knowledgeArticles.get(0).title;
             publishStatus = knowledgeArticles.get(0).PublishStatus.toLowerCase();
             DocumentResponse dockResponse = new DocumentResponse();
 
             if(!String.isBlank(threadId)){
                 QuipSetting__c quipSetting = QuipSetting__c.getValues('QuipSetting');
                 String accessToken = quipSetting.AccessToken__c;
 
                 String endPoint = 'https://platform.quip.com/1/threads/copy-document?thread_id=' + threadId;
                 HttpRequest req = new HttpRequest();
                 req.setEndpoint(endPoint);
                 req.setMethod('POST');
                 req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
 
                 String authorizationHeader = 'OAuth ' + accessToken;
                 req.setHeader('Authorization', authorizationHeader);
 
                 req.setTimeout(120000);
 
                 Http httpCallout = new Http();
                 HttpResponse res = httpCallout.send(req);
                     
 
                 if(res.getStatusCode() == 200){
                     dockResponse = (DocumentResponse)JSON.deserialize(res.getBody(), DocumentResponse.class);
                 }
                 else{
                     dockResponse.error = res.getBody();
                 }          
                 dockResponse.statusCode = res.getStatusCode(); 
                 //dockResponse.parentObjectFieldValue = knowledgeArticleTitle;     
             }
 
             Id newArticleId = recordId;
             Id newKnowledgeArticleId = knowledgeArticles.get(0).KnowledgeArticleId;
             if(publishStatus.toLowerCase() == 'online'){
                 Id newVersionId = unPublishArticle(newKnowledgeArticleId);
                 List<Knowledge__kav> newArticles = [SELECT Id, KnowledgeArticleId FROM Knowledge__kav WHERE Id =: newVersionId];
                 newArticleId = newArticles.get(0).Id;
                 newKnowledgeArticleId = newArticles.get(0).KnowledgeArticleId;
             }
             Pattern regexforknowledgeArticleTitle = Pattern.compile('<h[1][^>]*?>(?<TagText>.*?)</h[1]>');  
             Matcher regexMatcherforTitle = regexforknowledgeArticleTitle.matcher(dockResponse.html);
             List<String> tagHtmlforTitleList = new List<String>();
             while (regexMatcherforTitle.find()) {
                 String tagHtmlforTitle = regexMatcherforTitle.group();
                 tagHtmlforTitle=tagHtmlforTitle.stripHtmlTags();
                 tagHtmlforTitleList.add(tagHtmlforTitle);
             } 
 
             system.debug('tagHtml1tagHtml1==>'+ tagHtmlforTitleList[0] );
             String knowledgeArticleTitle = tagHtmlforTitleList[0];
 
             Pattern regex = Pattern.compile('<h[1-6][^>]*?>(?<TagText>.*?)</h[1-6]>');  
             Matcher regexMatcher = regex.matcher(dockResponse.html);
 
             String tableContentString = '';
             Integer parentIndex = 0;        
             Integer elementIndex = 0;
             tableContentString += '<h5 style="color:black;font-size:20px;font-weight: bold;">Table Of Contents</h5><ul style="list-style-type: none;">';
             
             while (regexMatcher.find()) {
                 String tagHtml = regexMatcher.group();
                 system.debug('tagHtml==>'+ tagHtml);
                 List<String> tagSubStrings = tagHtml.split('\'');
 
                 String tagId = tagSubStrings.get(1);
 
                 String content1 = tagSubStrings.get(2).replaceAll('<\\/?[biu]>', ' ');
                 List<String> con = content1.split('<');
                 string content = con.get(0).replace('>', '');
                 system.debug('content'+content);
 
                 //String content = getTextValue(tagSubStrings.get(2));
 
                 if(knowledgeArticleTitle.trim() == content.trim()){
                     continue;
                 }
                 
                 Integer headerIndex = findIndex(tagHtml);
                 string extrastyleforh1=' ';
                 if(headerIndex == 1){
                     extrastyleforh1 = ' style="font-size:20px;" ';
                 }
                                
                 if(parentIndex == 0){                                 
                     tableContentString += '<li style="list-style-type: none;"> <a href="#'+ tagId +'" '+extrastyleforh1+'>'+ content + '</a>';
                     system.debug('<li> <a href="'+ tagId +'">' + content + '</a>');
                 }
                 else if(headerIndex == parentIndex){
                     tableContentString += '</li><li style="list-style-type: none;"> <a href="#'+ tagId +'" '+extrastyleforh1+'>' + content + '</a>';
                     system.debug('</li><li> <a href="'+ tagId +'">' + content + '</a>');
                 }
                 else if(headerIndex > parentIndex){
                     tableContentString += '<ul style="list-style-type: none;">';
                     tableContentString += '<li style="list-style-type: none;"> <a href="#'+ tagId +'" '+extrastyleforh1+'>' + content + '</a>';
                     system.debug('<ul>');
                     system.debug('<li> <a href="#'+ tagId +'">' + content + '</a>');
                 }
                 else if(headerIndex < parentIndex){
                     tableContentString += '</ul></li>';
                     tableContentString += '<li style="list-style-type: none;"> <a href="#'+ tagId +'" '+extrastyleforh1+'>' + content +'</a>';
                     system.debug('</ul></li>');
                     system.debug('<li> <a href="#'+ tagId +'">' + content + '</a>');
                 }
                 parentIndex = headerIndex;
                 
             }
 
             tableContentString += '</ul><hr style="display: block;  margin-top: 3%; margin-bottom: 2%; margin-start: auto; margin-end: auto; overflow: hidden; border-style: inset; border-width: 1px;background-color:#D3D3D3;opcaity: 0.5;"/>';
             dockResponse.html = tableContentString + dockResponse.html;
             System.debug('tableContentString-->'+tableContentString);
             //system.debug(dockResponse.html);
             correctHtml(dockResponse.html, newArticleId, knowledgeArticleTitle, newKnowledgeArticleId,threadId); 
         }
         catch(Exception ex){
             errorMessage = ex.getMessage();
         }      
         return errorMessage;  
     }
 
    /*  private static String getTextValue(String substring){
         String textValue = substring.substringBetween('>', '<');
         if(String.isBlank(textValue)){
             textValue = substring.substringBetween('<b>', '</b>');
         }
 
         return textValue;
     } */
 
     private static Integer findIndex(String tagHtml){
         Integer elementIndex = 0;
         if(tagHtml.startsWithIgnoreCase('<h1')){
             elementIndex = 1; 
         }
         else if(tagHtml.startsWithIgnoreCase('<h2')){
             elementIndex = 2; 
         }
         else if(tagHtml.startsWithIgnoreCase('<h3')){
             elementIndex = 3; 
         }
         else if(tagHtml.startsWithIgnoreCase('<h4')){
             elementIndex = 4; 
         }
         else if(tagHtml.startsWithIgnoreCase('<h5')){
             elementIndex = 5; 
         }
         else if(tagHtml.startsWithIgnoreCase('<h6')){
             elementIndex = 6; 
         }
         return elementIndex;
     }
 
     private static void correctHtml(String htmlString, Id recordId, String parentObjectTitle, Id knowledgeArticleId,String threadId){
         List<QuipImageIterator.QuipImageWrapper> quipImageWrappers = new List<QuipImageIterator.QuipImageWrapper>();
 
         Pattern regex = Pattern.compile('<img(.+?)>');
         Matcher regexMatcher = regex.matcher(htmlString);
         String imageURL='';
 
         while (regexMatcher.find()) {
             System.debug(regexMatcher.group());
             String imageTag = regexMatcher.group();
             imageURL= imageTag.substringBetween(' src=\'', '\'' );
             String getalttag= imageTag.substringBetween(' alt="', '"');
             QuipImageIterator.QuipImageWrapper wrapper = new QuipImageIterator.QuipImageWrapper();
             wrapper.fileTitle = getalttag;
             wrapper.quipImageUrl = imageURL;
             wrapper.parentId = recordId;
             quipImageWrappers.add(wrapper);
         }
 
         ConvertQuipImagesToFilesBatch batchContext = new ConvertQuipImagesToFilesBatch(quipImageWrappers, htmlString, parentObjectTitle, recordId, knowledgeArticleId,threadId);
        Database.executeBatch(batchContext, 1);
     }
 
 
     @AuraEnabled
     public static Response getRefreshToken(){
         QuipSetting__c quipSetting = QuipSetting__c.getValues('QuipSetting');
      String appClientId = decryptClientIdandclientSecret(quipSetting.ClientId__c);
       String clientSecret = decryptClientIdandclientSecret(quipSetting.ClientSecretKey__c);
         String endPoint = 'https://platform.quip.com/1/oauth/login';
         String redirectUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/apex/QuipPage';        
         String endPointUrl = endPoint + '?client_id=' + appClientId + '&client_secret=' + clientSecret + '&redirect_uri='+redirectUrl;
 
         HttpRequest req = new HttpRequest();
         req.setEndpoint(endPointUrl);
         req.setMethod('GET');
         Http http = new Http();
         HTTPResponse response = http.send(req);
         Response resultResponse = new Response(response.getStatusCode(), redirectUrl);
         return resultResponse;
     }
 
  
     @AuraEnabled(cacheable=true)
     public static ArticalthreadId getthreadId(Id recordId){        
         Knowledge__kav threadId = [SELECT ThreadId__c FROM Knowledge__kav WHERE Id =: recordId LIMIT 1];
         ArticalthreadId Response = new ArticalthreadId();
         Response.threadId = threadId.ThreadId__c;        
         return Response;
     }
 
 
     @AuraEnabled
     public static QuipSettingResponse getQuipSetting(){       
             QuipSetting__c quipSetting = QuipSetting__c.getValues('QuipSetting');
             QuipSettingResponse settingResponse = new QuipSettingResponse();
 
             if(quipSetting != null){
                 settingResponse.verificationCode = quipSetting.Quip_Verification_Code__c;
                 settingResponse.accessTocken = quipSetting.AccessToken__c;
             }
             
         return settingResponse;
     }
 
     @AuraEnabled
     public static String unPublishArticle(Id articleId){ //It need to be KnowledgeArticleId
         // Create a new version of knowledge article and do not unpublish.
         String newArticleId = KbManagement.PublishingService.editOnlineArticle(articleId, true);        
         return newArticleId;    
     }
 
     @AuraEnabled
     public static void publishArticle(String recordId) { //It need to be KnowledgeArticleId
         KbManagement.PublishingService.publishArticle(recordId, true);
     }
 
     //public static PageReference createNewArticle(String docHtml, String parentObjTitle, Id recordId) {     
        
     public static void updateArticle(String docHtml,string parentObjectTitle,Id recordId, Id knowledgeArticleId,String threadId) {     
         List<Knowledge__kav> knowledgeArticles = [Select Id, Article_Content__c,Title,QuipArticleSource__c,ThreadId__c From Knowledge__kav Where Id =: recordId];  
         knowledgeArticles.get(0).Article_Content__c = docHtml;
         knowledgeArticles.get(0).QuipArticleSource__c = 'https://klient-quipdevenvironment.quip.com/'+threadId;
         knowledgeArticles.get(0).ThreadId__c = threadId;
         knowledgeArticles.get(0).Title = parentObjectTitle;
         update knowledgeArticles;
         publishArticle(knowledgeArticleId);
     }
 
     public class Response{
         @AuraEnabled
         public Integer statusCode {get; set;}
 
         @AuraEnabled
         public String redirectUrl {get; set;}
 
         @AuraEnabled
         public String clientId {get; set;}
 
         @AuraEnabled
         public String secretKey {get; set;}
 
         public Response(Integer stCode, String rdUrl){
             QuipSetting__c quipSetting = QuipSetting__c.getValues('QuipSetting');
             String appClientId = decryptClientIdandclientSecret(quipSetting.ClientId__c);
             String clientSecret = decryptClientIdandclientSecret(quipSetting.ClientSecretKey__c);
 
             this.statusCode = stCode;
             this.redirectUrl = rdUrl;
             this.clientId = appClientId;
             this.secretKey = clientSecret;
         }
     }
 
     public class AccessTokenResponse{
         public String access_token {get; set;}
         public String expires_in {get; set;}
         public String refresh_token {get; set;}
         public String scope {get; set;}
         public String token_type {get; set;}
     }
 
     public class DocumentResponse{
         @AuraEnabled
         public String html {get; set;}
 
         public List<String> markdown {get; set;}
 
         @AuraEnabled
         public Integer statusCode {get; set;}
 
         @AuraEnabled
         public String error {get; set;}
 
         @AuraEnabled
         public String parentObjectFieldValue {get; set;}
     }
     public class ArticalthreadId{
         @AuraEnabled
         public string threadId {get; set;}
 
     }
     public class QuipSettingResponse{
         @AuraEnabled
         public string verificationCode {get; set;}
 
         @AuraEnabled
         public string accessTocken {get; set;}
     }
 }