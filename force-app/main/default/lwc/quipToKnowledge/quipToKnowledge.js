import { LightningElement, track, api, wire} from 'lwc';
import getQuipHtml from '@salesforce/apex/QuipHelper.getQuipDoc';
import getVerificationCode from '@salesforce/apex/QuipHelper.getRefreshToken';
import getQuipSetting from '@salesforce/apex/QuipHelper.getQuipSetting';
import getAccessToken from '@salesforce/apex/QuipHelper.getAccessToken';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import getThreadId from '@salesforce/apex/QuipHelper.getthreadId';
//import createNewArticle from '@salesforce/apex/QuipHelper.createNewArticle';

export default class QuipToKnowledge extends NavigationMixin(LightningElement) {
    @api recordId;
    @track editMode = false;
    @track verificationcodefound = true;
    @track accesstockenfound = false;
    @track findAccessTocken = false;
    @track updateArticle = true;
    @track accessTocken = '';
    @track isFieldSelected = false;
    @track quipDocHtml;
    @track error;
    @track quipDocFound = false;
    @track parentObjectFieldValue;
    @track threadId = '';
   
    value = ['fieldUrl'];

    // get options() {
    //     return [
    //         { label: 'Lead Field Url', value: 'fieldUrl' }
    //     ];
    // }

    /*get selectedValues() {
        return this.value.join(',');
    }*/

    connectedCallback() {

        getQuipSetting()
        .then(result => {   
               
            this.verificationcodefound = !!result.verificationCode;
            this.accesstockenfound = !!result.accessTocken;

            /*if(!this.verificationcodefound){                
                this.accesstockenfound = true;
            }*/

            this.findAccessTocken = !this.accesstockenfound && this.verificationcodefound;

            this.updateArticle = !(this.accesstockenfound && this.verificationcodefound);
            this.error = undefined;
            this.accesstockenfound = false;
        })
        .catch(error => {
            this.error = error;
            this.contacts = undefined;
        });
       
        getThreadId({recordId : this.recordId})
        .then(result=>{                
                this.threadId = result.threadId;  
        });  

    }

    getVerification(){
        getVerificationCode()
        .then(result=>{
            if(result.statusCode == 302){
                this.verificationcodefound = true;
                this.findAccessTocken = true;

                var endPoint = 'https://platform.quip.com/1/oauth/login';
                var endPointUrl = endPoint + '?client_id=' + result.clientId + '&client_secret=' + result.secretKey + '&redirect_uri='+ result.redirectUrl;                                
                window.open(endPointUrl);
            }
        })
        .catch(error=>{
            console.log(error);           
        });
    }    

    getAccessKey(){
        getAccessToken()
        .then(result=>{
            console.log(result);
            if(result != ''){
                this.accesstockenfound = true;   
                this.findAccessTocken = false;             
                this.accessTocken = result;
                this.updateArticle = false;
            }
        })
        .catch(error=>{
            console.log(error);           
        });
    }

    getQuipDocument(){ 
    
        getQuipHtml({recordId : this.recordId, threadId : this.threadId})
        .then(result=>{
            if(result == ''){
                this.showMessage('Success Message', 'Your knowledge article will be updated with quip document under ARTICLE CONTENT.');
            }
            else{
                this.showMessage('Error Message', result);
            }
            this.closeQuickAction();
        });        
    }

    showMessage(titleMessage, responseMessage){
        const event = new ShowToastEvent({
            title: titleMessage,
            message: responseMessage,
        });
        this.dispatchEvent(event);
    }
        
    closeQuickAction() {
        const closeQuickActionEvent = new CustomEvent('closequickaction', {
            detail: { },
        });
        // Fire the custom event
        this.dispatchEvent(closeQuickActionEvent);
        //this.dispatchEvent(new CloseActionScreenEvent());      
    }
    
    handleInputChange(e){
        this.threadId = e.detail.value;
        console.log(this.threadId);
    }
}