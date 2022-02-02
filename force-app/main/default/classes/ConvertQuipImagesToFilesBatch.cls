public class ConvertQuipImagesToFilesBatch implements Database.batchable<QuipImageIterator.QuipImageWrapper>, Database.AllowsCallouts, Database.Stateful{
    public Map<String, String> filesByQuipImages = new Map<String, String>();
    List<QuipImageIterator.QuipImageWrapper> wrappers;
    String quipDocHtml;
    String parentObjectTitle;
    Id knowledgeId;
    String threadId;
    Id knowledgeArticleId;

    public ConvertQuipImagesToFilesBatch(List<QuipImageIterator.QuipImageWrapper> urlWrappers, String docHtml, String title,Id recordId, Id articleId,string thId) {
        this.wrappers = urlWrappers;
        this.quipDocHtml = docHtml;
        this.parentObjectTitle = title;
        this.knowledgeId = recordId;
        this.threadId = thId;
        this.knowledgeArticleId = articleId;
    }

    public Iterable<QuipImageIterator.QuipImageWrapper> start(Database.batchableContext info){ 
        return new QuipImageIterator(wrappers); 
    }

    public void execute(Database.batchableContext info, List<QuipImageIterator.QuipImageWrapper> quipImageWrappers){
        for(QuipImageIterator.QuipImageWrapper quipImageWrapper: quipImageWrappers){
            String apiUrl = 'https://platform.quip.com/1' + quipImageWrapper.quipImageUrl.unescapeHtml4();

            QuipSetting__c quipSetting = QuipSetting__c.getValues('QuipSetting');
            String accessToken = quipSetting.AccessToken__c;
        
            HttpRequest requestObj = new HttpRequest();
            requestObj.setMethod('GET');
            requestObj.setEndpoint(apiUrl);
            requestObj.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            String authorizationHeader = 'OAuth ' + accessToken;
            requestObj.setHeader('Authorization', authorizationHeader);
            requestObj.setTimeout(120000);

            Http httpObj = new Http();
            HttpResponse responseObj = httpObj.send(requestObj);        
            Blob blobContent = responseObj.getbodyasblob(); 
        

            /* code update for content version 03-11-21 */
            ContentVersion v = new ContentVersion();
            v.versionData = blobContent;
            v.title = quipImageWrapper.parentId + '-' +  quipImageWrapper.fileTitle;
            v.pathOnClient = v.title;
            insert v;            
            System.debug('vvvvvvvvv'+v.id);
            List<ContentDocumentLink> toDelete = [select Id from ContentDocumentLink where Id=:v.id];

            delete toDelete;

            v = [Select id, title, ContentDocumentID from ContentVersion where id=:v.id];            
            ContentDocumentLink cl = new ContentDocumentLink();
            cl.ContentDocumentId = v.ContentDocumentId;
            cl.LinkedEntityId = quipImageWrapper.parentId; 
            cl.ShareType = 'V';
            cl.Visibility = 'AllUsers';
            insert cl;
            
            System.debug('clllll'+cl.id);
            string NewImageurl = Url.getSalesforceBaseUrl().toExternalForm()+'/sfc/servlet.shepherd/document/download/'+cl.ContentDocumentId+'?operationContext=S1';
            system.debug('urlurlurl'+NewImageurl);
            filesByQuipImages.put(quipImageWrapper.quipImageUrl, NewImageurl);
        }        
    }

    public void finish(Database.BatchableContext bc){
        system.debug('----filesByQuipImages---->'+filesByQuipImages);
        for(String quipImageUrl : filesByQuipImages.keySet()){
            system.debug('----quipImageUrl---->'+quipImageUrl);
            String fileUrl = filesByQuipImages.get(quipImageUrl);
            system.debug('----fileUrl---->'+fileUrl);
            quipDocHtml = quipDocHtml.replace(quipImageUrl, fileUrl);
        }

        QuipHelper.updateArticle(quipDocHtml, parentObjectTitle,knowledgeId, knowledgeArticleId,threadId);        
    }
}