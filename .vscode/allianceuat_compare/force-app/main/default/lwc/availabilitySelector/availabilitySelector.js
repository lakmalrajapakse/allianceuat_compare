import { LightningElement, api, track } from "lwc";
import getAvailabilityFrom from "@salesforce/apex/AvailabilitySelectorController.getAvailabilityFrom";
import saveAvailability from "@salesforce/apex/AvailabilitySelectorController.saveAvailability";
import { handleTransactionError, showErrorToast, showSuccessToast, zeroPad } from "c/utils";

export default class AvailabilitySelector extends LightningElement {
    _recordId;
    _fromDate;
    _days = 7;

    @api
    set recordId(value) {
        this._recordId = value;
        this.reload();
    }
    get recordId() {
        return this._recordId;
    }

    set fromDate(value) {
        this._fromDate = value;
    }
    get fromDate() {
        return this._fromDate;
    }

    set days(value) {
        this._days = value;
    }
    get days() {
        return this._days;
    }

    @track
    _availabilityDays = [];

    _queryingEmployeeRequests = false;
    _savingRequests = false;
    _ready = false;

    allAmAvailable = null;
    allPmAvailable = null;
    allNightAvailable = null;

    async connectedCallback() {
        const initialDate = new Date();
        initialDate.setHours(0, 0, 0);
        this.fromDate = initialDate.getFullYear() + "-" + zeroPad((initialDate.getMonth() + 1), 2) + "-" + zeroPad(initialDate.getDate(), 2);

        this._ready = true;
        this.reload();
    }

    async reload() {
        try {
            if (!this._ready || !this.recordId) return;

            this._queryingEmployeeRequests = true;

            this.processEmployeeRequestsResponse(
                this.fromDate,
                this.days,
                await getAvailabilityFrom({
                    contactId: this.recordId,
                    startDate: this.fromDate,
                    days: this.days
                })
            );
        } catch (ex) {
            handleTransactionError("Load error", ex);
        } finally {
            this._queryingEmployeeRequests = false;
        }
    }

    processEmployeeRequestsResponse(startDate, days, response) {
        this._availabilityDays = [];

        for (let i = 0; i < response.length; i++) {
            response[i].Day = new Date(response[i].Day);
        }

        const addDays = function (from, days) {
            var date = new Date(from.valueOf());
            date.setDate(date.getDate() + days);
            return date;
        };

        const employeeRequestsByDate = response.reduce((acc, cur) => {
            const key = cur.Day.toLocaleDateString();

            if (!acc[key]) {
                acc[key] = [];
            }

            acc[key].push(cur);

            return acc;
        }, {});

        for (let i = 0; i < days; i++) {
            const targetDate = addDays(startDate, i);
            const key = targetDate.toLocaleDateString();
            const existingDates = employeeRequestsByDate[key];

            const day = {
                index: i,
                date: targetDate,
                am: {},
                pm: {},
                night: {},
            };

            if (existingDates) {
                const existingAm = existingDates.find((x) => x.Type == 0);
                const existingPm = existingDates.find((x) => x.Type == 1);
                const existingNight = existingDates.find((x) => x.Type == 2);

                if (existingAm) {
                    day.am.available = existingAm.Available;
                    day.am.id = existingAm.Id;
                }

                if (existingPm) {
                    day.pm.available = existingPm.Available;
                    day.pm.id = existingPm.Id;
                }

                if (existingNight) {
                    day.night.available = existingNight.Available;
                    day.night.id = existingNight.Id;
                }
            }

            day.am.original = day.am.available;
            day.pm.original = day.pm.available;
            day.night.original = day.night.available;

            day.dirty = function () {
                return day.original.am != day.am || day.original.pm != day.pm || day.original.night != day.night;
            };

            this._availabilityDays.push(day);
        }

        this.allAmAvailable = null;
        this.allPmAvailable = null;
        this.allNightAvailable = null;
    }

    get availabilityDays() {
        return this._availabilityDays;
    }

    get hasData() {
        return this._availabilityDays.length > 0;
    }

    get isLoading() {
        return this._queryingEmployeeRequests == true || this._savingRequests == true;
    }

    get periodRowHeight() {
        return 30;
    }

    handleAmAvailabilityChanged(event) {
        const day = this._availabilityDays.find((x) => x.date == event.target.dataset.day);
        day.am.available = event.detail.available;
    }

    handlePmAvailabilityChanged(event) {
        const day = this._availabilityDays.find((x) => x.date == event.target.dataset.day);
        day.pm.available = event.detail.available;
    }

    handleNightAvailabilityChanged(event) {
        const day = this._availabilityDays.find((x) => x.date == event.target.dataset.day);
        day.night.available = event.detail.available;
    }

    handleAllDayAvailabilityChanged(event) {
        const day = this._availabilityDays.find((x) => x.date == event.target.dataset.day);
        day.am.available = event.detail.available;
        day.pm.available = event.detail.available;
        day.night.available = event.detail.available;
        day.available = event.detail.available;
    }

    handleAllAmAvailabilityChanged(event) {
        this._availabilityDays.forEach(x => x.am.available = event.detail.available);
        this.allAmAvailable = event.detail.available;
    }
    
    handleAllPmAvailabilityChanged(event) {
        this._availabilityDays.forEach(x => x.pm.available = event.detail.available);
        this.allPmAvailable = event.detail.available;
    }

    handleAllNightAvailabilityChanged(event) {
        this._availabilityDays.forEach(x => x.night.available = event.detail.available);
        this.allNightAvailable = event.detail.available;
    }

    handleDateChange(event) {
        this.fromDate = event.detail.value;
    }

    handleDaysChange(event) {
        this.days = event.detail.value;
    }

    handleRefreshClick(event) {
        event.preventDefault();
        const dateField = this.template.querySelector('lightning-input[data-id="dateField"]');
        const daysField = this.template.querySelector('lightning-input[data-id="daysInput"]');

        dateField.reportValidity();
        daysField.reportValidity();

        if (!dateField.validity.valid || !daysField.validity.valid) {
            showErrorToast("Invalid input", "Ensure all fields are filled in correctly");
            return;
        }

        this.reload();
    }

    async handleSaveClick() {
        try {
            this._savingRequests = true;
            const updatedRecords = [];

            this._availabilityDays.forEach((x) => {
                if (x.am.available != x.am.original) {
                    updatedRecords.push({
                        Id: x.am.id,
                        Day: x.date,
                        Type: 0,
                        Available: x.am.available
                    });
                }

                if (x.pm.available != x.pm.original) {
                    updatedRecords.push({
                        Id: x.pm.id,
                        Day: x.date,
                        Type: 1,
                        Available: x.pm.available
                    });
                }

                if (x.night.available != x.night.original) {
                    updatedRecords.push({
                        Id: x.night.id,
                        Day: x.date,
                        Type: 2,
                        Available: x.night.available
                    });
                }
            });

            await saveAvailability({
                contactId: this.recordId,
                requests: updatedRecords
            });

            await this.reload();

            showSuccessToast("Success", "Saved successfully");
        } catch (ex) {
            handleTransactionError("Save error", ex);
        } finally {
            this._savingRequests = false;
        }
    }
}