/* import { LightningElement, track, api } from 'lwc';
import { showToast } from 'c/toasts';
import { debug } from 'c/debug';

import { deleteRecord } from 'lightning/uiRecordApi';

export default class ShiftBreakEditor extends LightningElement {
    @track shiftId;
    @track breakId;
    @track _startTime;
    @track _endTime;

    @track isUpdate = false;
    

    @track showModal = false;
    @api openModal(shiftId, breakId, startTime, endTime){
        debug('ShiftBreakCreator shiftId', shiftId);
        debug('ShiftBreakCreator breakId', breakId);
        this.shiftId = shiftId;
        this.breakId = breakId;
        this.start = startTime;
        this.end = endTime;
        this.showModal = true;      
        this.isUpdate = this.breakId ? true : false;
    }

    @api closeModal(){
        this.showModal = false;
    }

    handleOnDelete(){
        this.isLoading = true;
        deleteRecord(this.breakId)
            .then(() => {
                this.reportToParent();
            })
            .catch(error => {
                showToast(this, ('Error deleting break - ' + error.body.message), 'error');
            });
    }

    @track isLoading = true;
    handleOnLoad(event){
        debug('handleOnLoad', event.detail);
        this.isLoading = false;
    }
    handleOnSubmit(){
        this.isLoading = true;
    }

    handleSuccess(event) {
        showToast(this, 'Updates made succesfully', 'success');
        this.breakId = event.detail.id;
        this.reportToParent();
    }

    handleError(event){
        debug('err', event.detail);
        this.isLoading = false;
        showToast(this, (event.detail.message + ' - ' + event.detail.detail), 'error');
    }

    reportToParent() {
        this.isLoading = false;
        this.showModal = false;

        const changeEvent = new CustomEvent('update',
            {
                detail: {
                    shiftId: this.shiftId,
                    breakId: this.breakId
                }
            });
        this.dispatchEvent(changeEvent);
    }    

    get start() {
        return this._startTime;
    }

    set start(value) {
        this._startTime = value;
    }

    get end() {
        return this._endTime;
    }

    set end(value) {
        this._endTime = value;
    }
} */
import { LightningElement, track, api } from 'lwc';
import { showToast } from 'c/toasts';
import { debug } from 'c/debug';

export default class ShiftBreakEditor extends LightningElement {
    @track shiftId;
    @track breakType;        // first | second
    @track startTime;
    @track breakLength;

    @track isUpdate = false;
    @track showModal = false;
    @track isLoading = true;

    /**
     * Open modal for Shift record (First / Second break)
     */
    @api
    openModal({ shiftId, breakType, startTime, breakLength }) {
        debug('ShiftBreakEditor shiftId', shiftId);
        debug('ShiftBreakEditor breakType', breakType);

        this.shiftId = shiftId;
        this.breakType = breakType;
        this.startTime = startTime;
        this.breakLength = breakLength;

        this.showModal = true;
        this.isUpdate = true;
    }

    @api
    closeModal() {
        this.showModal = false;
    }

    handleOnLoad(event) {
        debug('handleOnLoad', event.detail);
        this.isLoading = false;
    }

    handleOnSubmit() {
        this.isLoading = true;
    }

    /**
     * Shift update success
     */
    handleSuccess(event) {
        showToast(this, 'Shift updated successfully', 'success');
        this.shiftId = event.detail.id;
        this.reportToParent();
    }

    handleError(event) {
        debug('err', event.detail);
        this.isLoading = false;
        showToast(
            this,
            event.detail.message + ' - ' + event.detail.detail,
            'error'
        );
    }

    /**
     * Notify parent component
     */
    reportToParent() {
        this.isLoading = false;
        this.showModal = false;

        const changeEvent = new CustomEvent('update', {
            detail: {
                shiftId: this.shiftId
            }
        });

        this.dispatchEvent(changeEvent);
    }

    /* =========================
       TEMPLATE HELPERS
       ========================= */

    get isFirstBreak() {
        return this.breakType === 'first';
    }

    get isSecondBreak() {
        return this.breakType === 'second';
    }
}