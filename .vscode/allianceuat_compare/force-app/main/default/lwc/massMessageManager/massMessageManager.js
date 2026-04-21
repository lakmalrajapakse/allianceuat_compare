import { LightningElement, api, track, wire} from 'lwc';

import { showToast } from 'c/toasts';
import { handleException } from 'c/exceptions';
import { debug } from 'c/debug';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import getRecepients from '@salesforce/apex/MassMessageManager.getRecepients';
import getTemplateOptions from '@salesforce/apex/MassMessageManager.getTemplateOptions';
import getTemplateBody from '@salesforce/apex/MassMessageManager.getTemplateBody';
import dispatchMessages from '@salesforce/apex/MassMessageManager.dispatchMessages';
// import getSettings from '@salesforce/apex/SettingsProvider.getSettings';
import getInstance from '@salesforce/apex/SMSSettings.getInstance';
import USER_ID from '@salesforce/user/Id';
import USER_FIRSTNAME from '@salesforce/schema/User.FirstName';
import USER_LASTNAME from '@salesforce/schema/User.LastName';
import SMS_COST_CENTER from '@salesforce/schema/User.SMS_Cost_Center__c'; 
import CAN_SEND_SMS from '@salesforce/schema/User.Can_Send_SMS__c'; 
// import getTemplates from '@salesforce/apex/SMSTemplatesController.getTemplates';
// import getSMSModuleBehavior from '@salesforce/apex/SMSModuleBehaviourController.getSMSModuleBehavior';

export default class MassMessageManager extends LightningElement {
    @api recordIds;    
    @track isLoading = true;
    @track messageContent = '';
    @track greetingValue = 'Regards';
    @track smsSettings;
    @track selectedTemplate;
    @track templateOptions = [];
    @track costCenter;
    @track canSendSMS;
    @track isSMSEnabled = false;

    // @wire(getSettings)
    // wiredSettings({ error, data }) {
    //     if (data) {
    //         this.greetingValue = data.Greetings__c;
    //     } else if (error) {
    //         this.greetingValue = 'Regards';
    //     }   
    // }

    connectedCallback(){
        console.log("LWC connectedCallback called");
        this.loadSettings();
        this.loadRecepients();
        this.loadTemplateOptions();
    }

    loadSettings() {

    }

    insertFirstName(event){ 
        this.messageContent = this.messageContent + "<FIRSTNAME>";
        this.template.querySelector('.slds-text-longform').value = this.messageContent;
    }

    insertGreetings(event){ 
        this.messageContent = this.messageContent + this.greetingValue;
        this.template.querySelector('.slds-text-longform').value = this.messageContent;
    }

    handleActive(event) {
        console.log('event.target.value', JSON.stringify(event.target.value));
        if (event.target.value == 'new'){
            
        }else{

        }
    }
    
    @track hasRecepients = false;
    @track recepients = [];
    loadRecepients() {
        debug('Getting Recepients', this.recordIds);
        getRecepients({
            recordIds: this.recordIds
        }).then(results => {
            let response = JSON.parse(results);
            console.log('loadRecepients', response);
            if (response.success) {
                this.hasRecepients = (response.responseObject && response.responseObject.length > 0);
                this.recepients = response.responseObject;
            }else {
                //error - well managed
                console.log('Err:', response.message);
                showToast(this, response.message, 'error');
            }
        }).catch(err => {
            console.log('Unmanaged Error ', JSON.stringify(err));
            handleException(this, err, true);
        }).finally(fin => {
            this.isLoading = false;
        });
    }

    @wire(getRecord, { recordId: USER_ID, fields: [CAN_SEND_SMS, SMS_COST_CENTER, USER_FIRSTNAME, USER_LASTNAME] })
        userProfile({ error, data }) {
            if (data) {
                // Get the cost center
                this.costCenter = getFieldValue(data, SMS_COST_CENTER);
                this.canSendSMS = getFieldValue(data, CAN_SEND_SMS);
                this.userName = getFieldValue(data, USER_FIRSTNAME) + ' ' + getFieldValue(data, USER_LASTNAME);
                // console.log('Cost Center:', this.costCenter);
                // console.log('Can Send SMS:', this.canSendSMS);
                this.error = undefined;
                if (this.canSendSMS && this.costCenter) {
                    this.isSMSEnabled = true;
                    console.log('SMS is enabled');
                } else {
                    console.log('SMS is not enabled');
                    this.isSMSEnabled = false; // Ensure isSMSEnabled is set correctly when conditions are not met
                    // return this.fetchSMSModuleBehavior(); 

                }
                if (this.costCenter) {
                    // Call getInstance to fetch smsSettings
                    getInstance({ costCenter: this.costCenter })
                        .then(result => {
                            // Store smsSettings
                            this.smsSettings = result;
                            console.log('SmsSettings:', JSON.stringify(result));
                            // Once smsSettings are fetched, call getTemplates to fetch templates
                            // return getTemplates({ costCenter: this.costCenter });
                            this.greetingValue = this.smsSettings.defaultGreeting;
                            // Fetch SMS module behavior after settings are ensured
                            // Note: You can decide whether to call this based on other conditions
                            // return this.fetchSMSModuleBehavior(); 
                        })
                        // .then(result => {
                        //     // Parse the JSON response from getTemplates
                        //     let templatesData = JSON.parse(result);
            
                        //     // Construct template options
                        //     let templateOptions = templatesData.map(template => ({
                        //         label: template.TemplateBody,
                        //         value: template.TemplateBody
                        //     }));
                        //     // Store template options
                        //     this.templateOptions = templateOptions;
                        // })
                        // .catch(error => {
                        //     // Handle errors appropriately
                        //     console.error('Error fetching templates:', error);
                        //     this.error = 'Error fetching templates';
                        //     this.smsSettings = undefined;
                        //     this.templateOptions = undefined;
                        // });
                        .catch(error => {
                            console.error('Error fetching SMS settings from LWC:', error);
                            this.smsSettings = undefined; // Handle error appropriately
                        });
                } else  {
                    // return this.fetchSMSModuleBehavior();
                }
            } else if (error) {
                // Handle error if getRecord fails
                // console.error('Error fetching record:', error);
                // this.error = 'Error fetching record';
                // this.costCenter = undefined;
                // this.smsSettings = undefined;
                // this.templateOptions = undefined;
                this.error = error;
                this.canSendSMS = false;
                this.costCenter = undefined;
                this.isSMSEnabled = false; // Also ensure isSMSEnabled is false when there is an error
            }
        }

    @track loadingTemplates = true;
    // @track templateOptions = [];
    loadTemplateOptions() {
        getTemplateOptions({
        }).then(results => {
            let response = JSON.parse(results);

            console.log('loadTemplateOptions', response);
            if (response.success) {
                this.templateOptions = response.responseObject;
            } 
        }).catch(err => {
            console.log('Unmanaged Error ', JSON.stringify(err));
            handleException(this, err, true);
        }).finally(fin => {
            this.loadingTemplates = false;
        });
    }

    @track loadingTemplateBody = false;
    loadTemplateBody(templateId) {
        this.loadingTemplateBody = true;
        getTemplateBody({
            templateId: templateId
        }).then(results => {
            this.loadingTemplateBody = false;
            let response = JSON.parse(results);
            console.log('loadTemplateBody', response);
            if (response.success) {
                this.messageContent = response.message;
            } 
        }).catch(err => {
            console.log('Unmanaged Error ', JSON.stringify(err));
            //error unmanaged - could be a controller exception or javascript exception
            handleException(this, err, true);
        }).finally(fin => {
            this.loadingTemplateBody = false;
        });
    }
    
    @track sendOperationComplete = false;
    sendMessages() {
        if (!this.reportMessageContentValidity()){
            return;
        }
        this.isLoading = true;
        console.log('Sending notification to recepients', JSON.parse(JSON.stringify(this.recepients)));
        dispatchMessages({
            recepientsJSON: JSON.stringify(this.recepients),
            messageContent: this.messageContent
        }).then(results => {
            let response = JSON.parse(results);
            console.log('dispatchMessages', response);
            if (response.success) {
                this.sendOperationComplete = true;
            } else {
                //error - well managed
                console.log('Err:', response.message);
                showToast(this, response.message, 'error');
            }
        }).catch(err => {
            console.log('Unmanaged Error ', JSON.stringify(err));
            //error unmanaged - could be a controller exception or javascript exception
            handleException(this, err, true);
        }).finally(fin => {
            this.isLoading = false;
        });
    }

    reportMessageContentValidity(){
        const messageInputValidity = [...this.template.querySelectorAll('lightning-textarea')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
        return messageInputValidity;
    }
    
    /*

    Utilities

    */
    // Method to fetch SMS module behavior based on cost center
    fetchSMSModuleBehavior() {
        getSMSModuleBehavior({ costCenter: this.costCenter })
            .then(result => {
                this.smsModuleBehavior = result;
                console.log('SMS module behavior:', JSON.stringify(result));
            })
            .catch(error => {
                this.smsModuleBehavior = {}; // Reset or set to default values as needed
                console.error('Error fetching SMS module behavior:', error);
            });
    }

   handleFieldChange(event) {
        let conId = event.target.dataset.conid;
        let isCheckbox = event.target.dataset.ischeckbox;
        let fieldName = event.target.dataset.fieldname;
        let fieldValue = event.detail.value;
        if (isCheckbox){
            fieldValue = event.detail.checked ? true : false;
        }
        console.log('fieldName', JSON.stringify(fieldName));
        console.log('fieldValue', JSON.stringify(fieldValue));

        if (fieldName == 'template'){
            this.loadTemplateBody(fieldValue);
        } else if (fieldName == 'content'){
            this.messageContent = fieldValue;
        }else{
            //Recepients Table Edits
            if (!conId || conId.length == 0)
                return;
            
            for (let i = 0; i < this.recepients.length; i++){
                let recepient = this.recepients[i];
                if (recepient.conId == conId){
                    recepient[fieldName] = fieldValue;
                }                
            }
        }
        console.log('Updated this.recepients', JSON.parse(JSON.stringify(this.recepients)));
    }
    markAll(event){
        let context = this;
        let markType = event.target.dataset.type;
        for (let i = 0; i < context.recepients.length; i++) {
            let recepient = context.recepients[i];
            
            if (markType == 'sms' && !recepient.sendSMSDisabled){
                recepient.sendSMS =  !recepient.sendSMS;
            } else if (markType == 'email' && !recepient.sendEmailDisabled){
                recepient.sendEmail = !recepient.sendEmail;
            } else if (markType == 'push' && !recepient.sendPushDisabled){
                recepient.sendPush = !recepient.sendPush;
            }
        }
    }

    close(){
		setTimeout(
			function() {
				window.history.back();
			},
			1000
		);
	}

}