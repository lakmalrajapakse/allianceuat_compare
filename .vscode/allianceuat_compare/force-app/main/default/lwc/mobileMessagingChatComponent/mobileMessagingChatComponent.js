import { LightningElement, api, track, wire } from 'lwc';
import { fetchPastMessages, sendNewMessage } from './mobileMessagingChatComponentService';
import { subscribeToPushTopic, unsubscribeFromPushTopic, registerErrorListener } from './mobileMessagingChatComponentSubscription';
import { processPastMessagesData } from './mobileMessagingChatComponentMessageProcessor';
import { formatDate, showToast } from './mobileMessagingChatComponentUtils';
import { labels } from './mobileMessagingChatComponentConstants';
import CONTACT_FIRST_NAME_FIELD from '@salesforce/schema/Contact.FirstName';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
// import getSettings from '@salesforce/apex/SettingsProvider.getSettings';
import getInstance from '@salesforce/apex/SMSSettings.getInstance';
import USER_ID from '@salesforce/user/Id';
import USER_FIRSTNAME from '@salesforce/schema/User.FirstName';
import USER_LASTNAME from '@salesforce/schema/User.LastName';
import SMS_COST_CENTER from '@salesforce/schema/User.SMS_Cost_Center__c'; 
import CAN_SEND_SMS from '@salesforce/schema/User.Can_Send_SMS__c'; 

export default class MobileMessagingChatComponent extends LightningElement {
    fetchPastMessages
    @api recordId
    @track newMessageType = 'outbound'
    @track newMessageContent = '';
    @track pastMessagesContent = [];
    @track isLoading = false;
    @track showLoadMoreButton = true;
    @track messageMap = new Map();
    @track pageNumber = 1;
    @track pageSize = 10;
    @track contactInitials = '';
    @track selectedField = '';
    @track greetingValue = 'Regards';
    @track isSMSEnabled = false; // Initialize send button state
    userId = '';
    @track smsSettings;
    @track error;
    @track costCenter = '';
    @track smsModuleBehavior = {};
    @track canSendSMS = false;
    

    label = labels;
    subscription = null;
    contact;

    @wire(getRecord, { recordId: '$recordId', fields: [CONTACT_FIRST_NAME_FIELD] })
    // contact;
    wiredContact(result) {
        this.contact = result;
        if (result.data) {
            this.firstName = getFieldValue(result.data, CONTACT_FIRST_NAME_FIELD);
        }
    }

    // Getter to extract the first name from the Contact record
    // get firstName() {
    //     return getFieldValue(this.contact.data, CONTACT_FIRST_NAME_FIELD);
    // }

    @wire(getRecord, { recordId: USER_ID, fields: [CAN_SEND_SMS, SMS_COST_CENTER, USER_FIRSTNAME, USER_LASTNAME] })
    userProfile({ error, data }) {
        if (data) {
            // console.log('User profile:', JSON.stringify(data));
            this.canSendSMS = getFieldValue(data, CAN_SEND_SMS);
            this.costCenter = getFieldValue(data, SMS_COST_CENTER);
            this.userName = getFieldValue(data, USER_FIRSTNAME) + ' ' + getFieldValue(data, USER_LASTNAME);
            // console.log('canSendSMS:', this.canSendSMS);
            // console.log('costCenter:', this.costCenter);
            // Check if both canSendSMS and costCenter are true to enable SMS functionality
            if (this.canSendSMS && this.costCenter) {
                this.isSMSEnabled = true;
                console.log('SMS is enabled');
            } else {
                console.log('SMS is not enabled');
                this.isSMSEnabled = false; // Ensure isSMSEnabled is set correctly when conditions are not met
            }
            console.log('isSMSEnabled:', this.isSMSEnabled);
            console.log('canSendSMS:', this.canSendSMS);
            console.log('costCenter:', this.costCenter);
            // Fetch instance when costCenter is obtained, regardless of the canSendSMS value
            if (this.costCenter) {
                console.log('before fetching SMS settings...' + this.costCenter);
                getInstance({ costCenter: this.costCenter })
                    .then(result => {
                        // console.log('getInstance then(result: ', result);
                        this.smsSettings = result;
                        // console.log('getInstance SMS settings result:', JSON.stringify(result));
                        // console.log('getInstance SMS this.smsSettings:', JSON.stringify(this.smsSettings));
                        this.greetingValue = this.smsSettings.defaultGreeting;
                        // Fetch SMS module behavior after settings are ensured
                        // Note: You can decide whether to call this based on other conditions
                        // return this.fetchSMSModuleBehavior(); 
                    })
                    .catch(error => {
                        console.error('Error fetching SMS settings from LWC:', error);
                        this.smsSettings = undefined; // Handle error appropriately
                    });
            } else  {
                // return this.fetchSMSModuleBehavior();
            }
        } else if (error) {
            this.error = error;
            this.canSendSMS = false;
            this.costCenter = undefined;
            this.isSMSEnabled = false; // Also ensure isSMSEnabled is false when there is an error
        }
    }

    renderedCallback() {
        this.adjustToTabHeight();
    }

    adjustToTabHeight() {
        // Check if the elements are defined
        if (this.template.host.parentElement && this.template.host.parentElement.clientHeight) {
            const tabHeight = this.template.host.parentElement.clientHeight;
            this.template.host.style.height = `${tabHeight}px`;
        }
    }


    // @wire(getSettings)
    // wiredSettings({ error, data }) {
    //     if (data) {
    //         this.greetingValue = data.defaultGreeting;
    //     } else if (error) {
    //         this.greetingValue = 'Regards';
    //     }
    // }

    connectedCallback() {
        Promise.all([
            this.loadMessages()
        ])
            .then(() => {
                this.subscription = subscribeToPushTopic.call(this);
                registerErrorListener.call(this);
            })
            .catch(error => {
                console.log(error)
            });
    }

    disconnectedCallback() {
        unsubscribeFromPushTopic.call(this, this.subscription);
    }

    loadMessages() {
        this.isLoading = true;
        this.newMessageContent = '';
        fetchPastMessages({ contactId: this.recordId, pageNumber: this.pageNumber, pageSize: this.pageSize })

            .then(data => {
                console.log("mobileMessagingChatComponent loadMessages");
                processPastMessagesData.call(this, data);
                this.showLoadMoreButton = data.length === this.pageSize;
            })
            .catch(error => {
                showToast.call(this, 'Error retrieving messages: ' + error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleLoadMore() {
        this.pageNumber++;
        this.loadMessages();
    }

    handleInputChange(event) {
        this.newMessageContent = event.target.value;
        this.isSendDisabled = !this.newMessageContent.trim();
    }

    insertFirstName(event) {
        if (this.firstName !== null) {
            this.newMessageContent = this.newMessageContent + this.firstName;
            this.template.querySelector('.slds-text-longform').value = this.newMessageContent;
        }
    }

    insertGreetings(event) {
        this.newMessageContent = this.newMessageContent + this.greetingValue;
        this.template.querySelector('.slds-text-longform').value = this.newMessageContent;
    }
    handleSendMessage() {
        if (this.newMessageContent.trim()) {
            this.isLoading = true;
            sendNewMessage(this.recordId, this.newMessageContent, this.newMessageType)
                .then(() => {
                    showToast.call(this, 'Message sent successfully', 'success');
                    // this.loadMessages();
                })
                .catch(error => {
                    showToast.call(this, 'Error sending message: ' + error);
                })
                .finally(() => {
                    // PE-525 - add new message to start of array
                    // this.pastMessagesContent.push({direction: "outbound", formattedTimestamp: formatDate(new Date()), senderName: this.userName, messageContent: this.newMessageContent});
                    this.pastMessagesContent.unshift({direction: "outbound", formattedTimestamp: formatDate(new Date()), senderName: this.userName, messageContent: this.newMessageContent});
                    this.newMessageContent = '';
                    this.template.querySelector('.slds-text-longform').value = '';
                    this.isLoading = false;
                });
        } else {
            showToast.call(this, 'Cannot send an empty message', 'warning');
        }
    }


}