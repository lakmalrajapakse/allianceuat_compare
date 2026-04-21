import { LightningElement, api } from 'lwc';

export default class InputTimeAndHours extends LightningElement {
    @api record;
    showTimeInput = true;
    // This is just a wrapper for the other two components so that they share updates
    handleTimesChange(event){
        let writeToStartFieldName = event.currentTarget.dataset.writeToStart;
        let writeToEndFieldName = event.currentTarget.dataset.writeToEnd;

        let shiftId = event.detail.uId;
        let apiStartValue = event.detail.value.startDT;
        let apiEndValue = event.detail.value.endDT;

        let newValues = {};
        newValues[writeToStartFieldName] = apiStartValue;
        newValues[writeToEndFieldName] = apiEndValue;
        this.record = Object.assign({}, this.record, newValues);

        let newEvent = new CustomEvent('fieldchange', {detail:event.detail});
        this.dispatchEvent(newEvent);
    }
}