import { LightningElement, api, track } from 'lwc';
import resetCommunityPassword from '@salesforce/apex/CommunityPasswordResetController.resetPassword';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class CommunityPasswordReset extends LightningElement {
    @api recordId; // Contact Id from Quick Action
    @track isLoading = false; // Optional spinner

    // Cancel button closes the modal
    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    // Reset Password button calls Apex
    handleReset() {
        this.isLoading = true;

        resetCommunityPassword({ contactId: this.recordId })
            .then(result => {
                const status = result.status || 'ERROR';
                const message = result.message || 'Unknown error';

                // Show toast
                this.showToast(
                    status === 'SUCCESS' ? 'Success' : 'Error',
                    message,
                    status === 'SUCCESS' ? 'success' : 'error'
                );

                // Close the modal automatically if success
                if (status === 'SUCCESS') {
                    this.dispatchEvent(new CloseActionScreenEvent());
                }
            })
            .catch(error => {
                // Safe error handling
                let message = 'Unknown error';
                if (error?.body?.message) {
                    message = error.body.message;
                } else if (error?.body) {
                    message = JSON.stringify(error.body);
                } else if (error?.message) {
                    message = error.message;
                }

                this.showToast('Error', message, 'error');
                // Close the modal automatically if Error                
                    this.dispatchEvent(new CloseActionScreenEvent());

            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // Show toast
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}