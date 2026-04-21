import { LightningElement, track, wire } from 'lwc';
import { debug } from 'c/debug';
import { handleException } from 'c/exceptions';
import Utils from './utils.js';
import moment from '@salesforce/resourceUrl/moment';
import momentTimezone from '@salesforce/resourceUrl/momentTimezone';
import { loadScript } from 'lightning/platformResourceLoader';
import getSetup from '@salesforce/apex/SIM_TimeApproval.getSetup';
import getData from '@salesforce/apex/SIM_TimeApproval.getData';
import updateShifts from '@salesforce/apex/SIM_TimeApproval.updateShifts';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from 'lightning/navigation';
import SHIFT_OBJECT from '@salesforce/schema/sirenum__Shift__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import USER_ID from '@salesforce/user/Id';
import { showToast } from 'c/toasts';
// import TIME_TYPE_FIELD from '@salesforce/schema/sirenum__Shift__c.Time_Type__c';

export default class ShiftApprovalManager extends NavigationMixin(LightningElement) {
    // for data set the payroll cycle id on contract 
    _DEFAULT_CURRENCY = null;
    _EVENT_FILTER_BUILT = 'event_filter_built';

    @track SHIFT_DESC;

    //All loaded records
    @track fullRecords = [];
    //Paginated Records
    @track records = [];

    //Attachment popup variables
    @track showAttachmentModal = false;
    @track currentFiles = [];

    @track showSaveResults = false;
    @track isLoading = true;
    @track isSaving = false;
    @track startDate;
    @track endDate;

    periods = {};
    formattedString;
    hasSignature = true;
    shiftSignatures;
    signatureLinks;
    jsonSignatures;
    timeTypeOptions = [];
    siteTimezones;

    BOOL_TRUE = true;

    exportFile = '';
    exportFileHeaders = 'Shift Id,Shift Name,Worker Name,Shift Date,Site Id,Site Name,Job Role Name,Scheduled Start Date,Scheduled End Date,Scheduled Start Time,Scheduled End Time,Actual Start Date,Actual End Date,Actual Start Time,Actual End Time,Approved Start Date,Approved End Date,Approved Start Time,Approved End Time,Total Approved Hours,Is Approved,Is Cancelled,Cancellation Reason,Query,WFM External Id,PO Number';

    _CAN_SEE_PAY = false;
    _CAN_SEE_CHARGE = false;
    _CAN_ENTER_EXPENSES = false;
    _CAN_ENTER_ACTUAL = false;
    _CAN_ENTER_ABSOLUTE = false;
    _CAN_ENTER_BILLABLE = false;
    _CAN_ENTER_REPORTED = false;
    _CAN_REJECT_SHIFT = false;
    _CAN_SUBMIT = false;
    _CAN_APPROVE_PAY = false;
    _CAN_APPROVE_CHARGE = false;
    _CAN_SEE_APPROVE_PAY = false;
    _CAN_SEE_APPROVE_CHARGE = false;
    _LOCAL_STARTDATE = 'startDateId';
    _LOCAL_ENDDATE = 'endDateId';
    _LOCAL_FILTER = 'soqlFilter';
    _LOCAL_FILTER_BREADCRUMBS = 'filterBreadcrumbs';

    constructor() {
        super();
        this.addEventListener(this._EVENT_FILTER_BUILT, this.handleFilterChangeEvent.bind(this));
    }

    get _CAN_SEE_APPROVE_PAY_AND_CHARGE() {
        return this._CAN_SEE_APPROVE_CHARGE && this._CAN_SEE_APPROVE_PAY && this.hasRecords;
    }

    get _CAN_APPROVE_PAY_AND_CHARGE() {
        return this._CAN_APPROVE_CHARGE && this._CAN_APPROVE_PAY && this.hasRecords;
    }

    get _CAN_SUBMIT_ALL() {
        return this._CAN_SUBMIT && this.hasRecords;
    }

    @track selectedCycle = null;
    @track selectedPeriod = null;

    // @track updatedRecords = new Map();
    // @track updatedRecords = [];
    get hasChanges() {
        // return this.updatedRecords.length > 0
        return this.records.filter(record => record.isChanged).length > 0;
    }

    /**
     * First phase of initialization
     * 
     **/
    connectedCallback() {
        this.initComponent();
    }

    /**
 * Load Additional Resources
 * 
 * - Moment JS - library to help formatting times
 * - Luxon JS - modern library to help formatting times and determining week length aka intervals
 */
    @track isRendered = false;
    async renderedCallback() {
        if (this.isRendered)
            return;
        await Promise.all([
            loadScript(this, moment + '/moment.js'),
            loadScript(this, momentTimezone + '/moment-timezone-with-data.js')
        ]).then(() => {
            debug('Loaded Moment and Moment-timezone Libraries Successfully');
            this.isRendered = true;
        })
            .catch(err => {
                handleException(this, err, true);
            });
    }

    disconnectedCallback() {
        //this.remove(this._EVENT_FILTER_BUILT);
    }

    initComponent() {
        this.loadSetup();
    }

    /**
     * Cycle period selection handler
     */
    handleCyclePeriodChange(event) {
        this.selectedCycle = event.detail.selectedCycle;
        this.selectedPeriod = event.detail.selectedPeriod;
    }

    handleStartDateChange(event) {
        // console.log(`start date selected ${event.currentTarget.value}`);
        this.weekStart = this.convertFormat(event.currentTarget.value);
    }

    handleEndDateChange(event) {
        // console.log(`end date selected ${event.currentTarget.value}`);
        this.weekEnd = this.convertFormat(event.currentTarget.value);
    }

    handleExport(event) {
        let data = this.fullRecords ?? [];
        let lines = data.map(record => {
            return [
                record.Id,
                record.ShiftName,
                record.workerName,
                record.date,
                record.siteId,
                record.siteName,
                record.JobRoleName,
                Utils.getLocalDate(record.schedStart, record.timezone),
                Utils.getLocalDate(record.schedEnd, record.timezone),
                Utils.getLocalTime(record.schedStart, record.timezone),
                Utils.getLocalTime(record.schedEnd, record.timezone),
                Utils.getLocalDate(record.actStart, record.timezone),
                Utils.getLocalDate(record.actEnd, record.timezone),
                Utils.getLocalTime(record.actStart, record.timzone),
                Utils.getLocalTime(record.actEnd, record.timezone),
                Utils.getLocalDate(record.appStart, record.timezone),
                Utils.getLocalDate(record.appEnd, record.timezone),
                Utils.getLocalTime(record.appStart, record.timezone),
                Utils.getLocalTime(record.appEnd, record.timezone),
                record.totalApprovedTime,
                record.isApproved,
                record.isCancelled,
                record.cancellationReason,
                record.query,
                record.wfmId
            ];
        });

        if (lines && lines.length) {
            for (let line of lines) {
                // console.log('' + JSON.parse(JSON.stringify(line)));
                this.exportFile += line.join(',') + '\n';
                // this.exportFile += `${line.join(',')}
                // `;
            }
        }

        if (this.exportFile.length > 0) {
            this.export(this.exportFileHeaders += '\n' + this.exportFile, new Date().toLocaleDateString() + '-shifts');
        }

    }

    handleImport(event) {
        var url = 'https://allianceaustralia--uat.sandbox.lightning.force.com/lightning/n/Shift_Import'; // get from processing apex response
        window.open(url, "_blank");
    }

    export(file, fileName) {
        let downloadElement = document.createElement('a');
        downloadElement.href = `data:text/dat;charset=utf-8,${encodeURI(file)}`;
        downloadElement.target = '_self';
        downloadElement.download = `${fileName}.csv`;
        document.body.appendChild(downloadElement);
        downloadElement.click();
        showToast(this, 'You shifts have been exported in CSV format.', 'success');
    }

    handleOpenQuery(event) {
        // console.log(`query:: ${event.currentTarget.dataset.query}`);
        this.template.querySelector('c-query-modal').openModal(event.currentTarget.dataset.query);
    }
    /**
     * Workers selection handler
     */
    @track filterContacts = [];
    handleContactsSelect(event) {
        this.filterContacts = event.detail;
        debug('handleContactsSelect', this.filterContacts);
    }
    /**
     * Account selection handler
     */
    @track filterAccounts = [];
    handleAccountsSelect(event) {
        this.filterAccounts = event.detail;
        debug('handleAccountsSelect', this.filterAccounts);
    }

    /**
     * File Type selection handler
     */
selectedFileType = 'all';
handleFileTypeChange(event) {
    this.selectedFileType = event.detail.value;
    this.applyFileTypeFilter();
}
applyFileTypeFilter() {

    let data = [...this.fullRecords]; // use existing data

    if (this.selectedFileType === 'with_file') {
        data = data.filter(r => r.hasAttachment);
    } 
    else if (this.selectedFileType === 'without_file') {
        data = data.filter(r => !r.hasAttachment);
    }
    // 'all' = no filter

    this.updatePagination(1, this.itemsPerPage, data)
        .then(res => {
            this.records = res;
        });
}

    /**
     * Site selection handler
     */
    @track filterSites = [];
    handleSitesSelect(event) {
        this.filterSites = event.detail;
        debug('handleSiteSelect', this.filterSites);
    }

    /**
     * Job Role selection handler
     */
    @track filterJobRoles = [];
    handleJobRoleSelect(event) {
        this.filterJobRoles = event.detail;
        debug('handleJobRoleSelect', this.filterJobRoles);
    }

    /**
     * Branch selection handler
     */
    @track filterBranches = [];
    handleBranchSelect(event) {
        this.filterBranches = event.detail;
        debug('handleBranchSelect', this.filterBranches);
    }
    fileTypeOptions = [
    { label: 'All', value: 'all' },
    { label: 'Shift with file', value: 'with_file' },
    { label: 'Shift without file', value: 'without_file' }
];

    /**
     * handles obtaining results from filtering records
     * 
     * @param {*} event
     */
    @track shiftsSOQLfilter = null;
    @track filterBreadcrumbs = null;
    handleFilterChangeEvent(event) {
        debug('handleFilterChangeEvent', event.detail);
        this.shiftsSOQLfilter = event.detail.soqlFilter;
        this.filterBreadcrumbs = {
            crossGroupOperator: event.detail.crossGroupOperator,
            groups: event.detail.groups
        };

        this.setFiltersCache();
        this.filterToggle(false);
        this.refresh();
    }

    get totalResultsCount() {
        return this.fullRecords ? this.fullRecords.length : 0;
    }

    /**
     * save filters to local storage
     */
    setFiltersCache() {
        localStorage.setItem(this._LOCAL_STARTDATE, (this.startDate !== undefined && this.startDate !== null && this.startDate !== '' ? this.startDate : null));
        localStorage.setItem(this._LOCAL_ENDDATE, (this.endDate !== undefined && this.endDate !== null && this.endDate !== '' ? this.endDate : null));
        localStorage.setItem(this._LOCAL_FILTER, (this.shiftsSOQLfilter && this.shiftsSOQLfilter.length > 0 ? this.shiftsSOQLfilter : null));
        localStorage.setItem(this._LOCAL_FILTER_BREADCRUMBS, (this.filterBreadcrumbs ? JSON.stringify(this.filterBreadcrumbs) : null));
    }

    // @track showFiltersModal = false;
    filterToggle(state) {
        if (state !== undefined && (typeof variable === 'boolean')) {
            this.showFiltersModal = state;
        } else {
            this.showFiltersModal = !this.showFiltersModal;
        }

        this.populateFiltersModal();
    }

    @track filterComponentValue = null;
    populateFiltersModal() {
        let compValue = null;
        if (this.filterBreadcrumbs && this.filterBreadcrumbs != null) {
            compValue = {
                crossGroupOperator: JSON.parse(JSON.stringify(this.filterBreadcrumbs.crossGroupOperator)),
                groups: JSON.parse(JSON.stringify(this.filterBreadcrumbs.groups))
            }
        }
        this.filterComponentValue = compValue;
        debug('this.filterComponentValue', this.filterComponentValue);
    }

    /** Get SOQL Filter **/
    applyFilter() {
        this.template.querySelector('c-filter-component').getFilter();
    }

    @track showingFilters = false;
    toggleFiltersPanel(forceAction) {
        if (forceAction === undefined || forceAction === null || typeof forceAction !== "boolean") {
            //Toggle previous state
            this.showingFilters = !this.showingFilters;
        } else {
            //Requested specific state
            this.showingFilters = !!forceAction;
        }

        let panel = this.template.querySelector('.slds-panel');
        if (this.showingFilters == true) {
            panel.classList.add('slds-is-open');
        } else {
            panel.classList.remove('slds-is-open');
        }
    }

    /** 
     * When invoked, we will open the fieters editor
     */
    @track showFiltersModal = false;
    openFiltersModal() {
        this.showFiltersModal = true;
    }
    closeFiltersModal() {
        this.showFiltersModal = false;
    }


    @track filterComponentValue = null;
    populateFiltersModal() {
        let compValue = null;
        if (this.filterBreadcrumbs && this.filterBreadcrumbs != null) {
            compValue = {
                crossGroupOperator: JSON.parse(JSON.stringify(this.filterBreadcrumbs.crossGroupOperator)),
                groups: JSON.parse(JSON.stringify(this.filterBreadcrumbs.groups))
            }
        }
        this.filterComponentValue = compValue;
    }

    currentPage = 1;
    itemsPerPage = 25;
    handlePaginationChange(event) {
        this.resetState();

        this.currentPage = event.detail.currentPage;
        this.itemsPerPage = event.detail.itemsPerPage;
        this.isLoading = true;
        this.records = [];

        this.updatePagination(event.detail.currentPage, event.detail.itemsPerPage, this.fullRecords).then((subsetRecords) => {
            this.records = [...subsetRecords];
        }).catch(err => {
            handleException(this, err, true);
        }).finally(() => {
            this.isLoading = false;
        })
    }

    updatePagination(currentPage = 1, itemsPerPage = 25, records = []) {
        this.isLoading = true;
        return new Promise((resolve, reject) => {
            try {
                if (records && records.length > 0) {
                    for (let record of records) {
                        if (record.hasOwnProperty('isChanged')) {
                            delete record.isChanged;
                        }
                    }
                    let maxIndex = (currentPage * itemsPerPage);
                    let minIndex = (maxIndex - itemsPerPage);
                    let subsetRecords = records.slice(minIndex, maxIndex);
                    // resolve(subsetRecords);
                    setTimeout(() => { resolve(JSON.parse(JSON.stringify(subsetRecords))) }, 10);
                }

                // resolve([]);
                setTimeout(() => { resolve([]) }, 10);
            } catch (err) {
                reject(err.message);
            } finally {
                this.isLoading = false;
            }
        });
    }

    /**
     * Wire shift object Describe
     * 
     * - Used to get field labels
     * @param {*} param0 
     */
    @wire(getObjectInfo, { objectApiName: SHIFT_OBJECT })
    shiftInfo({ data, error }) {
        if (error) {
            console.error(error);
        }

        if (data) {
            this.SHIFT_DESC = data;
        }
    }

    // @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: TIME_TYPE_FIELD })
    // timeTypeOptionsWire({ data, error }) {
    //     if (error){
    //         debug(error);
    //     }

    //     if (data) {
    //         this.timeTypeOptions = data.values.map(x => {return {label: x.label, value: x.value}});
    //     }
    // } 


    /**
     * Refresh function - when called, 
     * this will cause a full shift data load with any
     * cached filters
     */
    refresh() {
        if (!this.checkValidity()) {
            return;
        }
        //Remove Genral Error Popover
        this.hasGeneralError = false;
        this.showGeneralError = false;
        this.updatePagination();
        this.resetState();

        this.loadData();
    }

    resetState() {
        // this.updatedRecords = new Map();
        // this.updatedRecords = [];
        // this.hasChanges = false;
        this.lastLoadedRecordId = null;
        this.currentPage = 1;
    }

    loadSetup() {
        getSetup({ usrID: USER_ID }).then(results => {
            let response = JSON.parse(results);
            // console.log('***getSetup Response', response);

            this._DEFAULT_CURRENCY = response.responseObject.currency;
            this._CAN_SEE_PAY = response.responseObject.canSeePay;
            this._CAN_SEE_CHARGE = response.responseObject.canSeeCharge;
            this._USE_TIME_TYPE_ON_SHIFT = true;
            this._CAN_ENTER_EXPENSES = response.responseObject.canEnterExpenses;
            this._CAN_ENTER_ACTUAL = response.responseObject.canEnterActual;
            this._CAN_ENTER_BILLABLE = response.responseObject.canEnterBillable;
            this._CAN_ENTER_ABSOLUTE = response.responseObject.canEnterAbsolute;
            this._CAN_ENTER_REPORTED = response.responseObject.canEnterReported;
            this._CAN_REJECT_SHIFT = response.responseObject.canRejectShift;
            this._CAN_APPROVE_PAY = response.responseObject.canApprovePay;
            this._CAN_SUBMIT = response.responseObject.canSubmit;
            this._CAN_SEE_SUBMIT = response.responseObject.canSeeSubmit;
            this._CAN_APPROVE_CHARGE = response.responseObject.canApproveCharge;
            this._CAN_PROCESS_PREVIOUS = response.responseObject.canProcessPrevious;
            this._CAN_SEE_APPROVE_PAY = response.responseObject.canSeeApprovePay;
            this._CAN_SEE_APPROVE_CHARGE = response.responseObject.canSeeApproveCharge;
            this.userContactId = response.responseObject.userContactId;

        }).catch(err => {
            handleException(this, err, true);
        }).finally(fin => {
            this.loadData();
        });

    }

    // get sigs() {
    //     this.signatureLinks = JSON.stringify(this.signatureLinks);
    //     return Object.values(this.signatureLinks).map(signature => ({
    //         Id: signature.Id,
    //         url: signature.Body ? URL.createObjectURL(signature.Body.inputStream) : ''
    //     }));
    // }


    loadData() {
        this.isLoading = true;
        this.fullRecords = [];
        this.records = [];

        this.fetchRecords().then(() => {
            this.hasGeneralError = false;
            this.showGeneralError = false;
            //Re-set any previous changes
            // this.updatedRecords = new Map();
            // this.updatedRecords = [];
            // this.hasChanges = false;
            this.showSaveResults = false;
        }).catch(err => {
            handleException(this, err, true);
        }).finally(() => {
            this.isLoading = false;
        });
    }

    lastLoadedRecordId = null;

    fetchRecords() {
        if (!this.weekStart && !this.weekEnd) {
            let { startOfWeek, endOfWeek } = this.getWeekStartAndEnd(new Date());
            this.weekStart = startOfWeek;
            this.weekEnd = endOfWeek;
            this.startDate = this.convertToDatePickerFormat(startOfWeek);
            this.endDate = this.convertToDatePickerFormat(endOfWeek);
        }
        return new Promise((resolve, reject) => {
            getData({
                soqlFilter: this.shiftsSOQLfilter,
                // periodId: this.selectedPeriod,
                weekStart: this.weekStart,
                weekEnd: this.weekEnd,
                filterSites: this.filterSites,
                filterContacts: this.filterContacts,
                filterAccounts: this.filterAccounts,
                resumeFromId: this.lastLoadedRecordId,
                filterBranches: this.filterBranches,
                filterJobRoles: this.filterJobRoles
            }).then(results => {
                let response = JSON.parse(results);
                // console.log('***loadData Response', response);

                if (response.success) {
                    this.siteTimezones = response.responseObject.siteTimezones;
                    console.log('RESPONSE > ', JSON.stringify(response.responseObject));
                    // this.signatureLinks = response.responseObject.signatureLinks;
                    // console.log(`signature links: ${this.signatureLinks}`);

                    let newRecords = Utils.convertShifts(response.responseObject.records, this.siteTimezones, this.signatureLinks);
                    // console.log('Loaded Batch Records: ', newRecords);

                    //added by Rishikesh Date 17/2/26
                    newRecords = newRecords.map(rec => {

    let files = [];
    let hasAttachment = false;

    // ILES (ContentDocument)
    let docLinks = rec.shift?.ContentDocumentLinks?.records;

    if (docLinks && Array.isArray(docLinks)) {
        let fileDocs = docLinks
            .filter(f => {
                let title = (f.ContentDocument?.Title || '').toLowerCase();
                return !title.includes('esign') && !title.includes('signature');
            })
            .map(f => {
                return {
                    Id: f.ContentDocumentId,
                    title: f.ContentDocument?.Title,
                    ext: f.ContentDocument?.FileExtension,
                    versionId: f.ContentDocument?.LatestPublishedVersionId,
                    isAttachment: false   //important
                };
            });

        files = [...files, ...fileDocs];
    }

    // ATTACHMENTS (OLD)
    let attachments = rec.shift?.Attachments?.records;

    if (attachments && Array.isArray(attachments)) {
        let attachDocs = attachments.map(att => {
            return {
                Id: att.Id,
                title: att.Name,
                ext: att.Name?.split('.').pop(),
                versionId: att.Id,
                isAttachment: true   //important
            };
        });

        files = [...files, ...attachDocs];
    }

    // final flag
    if (files.length > 0) {
        hasAttachment = true;
    }

    rec.hasAttachment = hasAttachment;
    rec.attachments = files;

    return rec;
});



                    Array.prototype.push.apply(this.fullRecords, newRecords);

                    if (this.fullRecords && this.fullRecords.length > 0) {
                        this.lastLoadedRecordId = this.fullRecords[this.fullRecords.length - 1].Id;
                    }

                    if (newRecords.length > 0) {
                        //Recursively load more records
                        setTimeout(() => { return resolve(this.fetchRecords()) }, 0);
                    }
                    else {
                        //No more records to load in operation

                        //Sort records by conditions
                        Utils.sortRecords(this.fullRecords);
                        //Apply pagination
                        this.updatePagination(1, this.itemsPerPage, this.fullRecords).then((subsetRecords) => {
                            this.records = [...subsetRecords];
                            return resolve();
                        }).catch(err => {
                            reject(err)
                        }).finally(() => {
                        });
                    }
                } else {
                    //Well Managed Error
                    reject(response.message);
                }
            }).catch(err => {
                //Un-Managed Error
                reject(err);
            });
        });
    }

    get showCosts() {
        if (!this._CAN_SEE_CHARGE && !this._CAN_SEE_PAY)
            return false;

        return true;
    }

    // @track hasChanges = false;
    @track showGeneralError = false;
    @track hasGeneralError = false;
    @track generalErrorMessage;
    saveChanges() {
        this.isSaving = true;
        this.hasGeneralError = false;
        this.showGeneralError = false;

        const fieldsToDelete = ['Name', 'attributes'];
        let copyOfRecords = JSON.parse(JSON.stringify(this.records));
        let updatedRecords = copyOfRecords.filter(record => record.isChanged).map(record => {
            for (let field of fieldsToDelete) {
                delete record.shift[field];
            }
            for (const fieldName in record.shift) {
                if (fieldName.indexOf('__r') > 0) {
                    delete record.shift[fieldName];
                }
            }
            return record.shift;
        });


        debug('Saving...', updatedRecords);
        updateShifts({
            jsonData: JSON.stringify(updatedRecords)
        }).then(results => {
            let response = JSON.parse(results);
            console.log('***updateShifts Response', response);

            if (response.success) {
                //All shifts saved successfully
                this.refresh();
            } else {
                this.processSaveErrors(response.responseObject);
            }
        }).catch(err => {
            handleException(this, err, true);
            this.hasGeneralError = true;
            this.showGeneralError = true;
            this.generalErrorMessage = unmngErr;
        }).finally(fin => {
            this.isSaving = false;
        });
    }

    processSaveErrors(saveResultItems) {
        debug('saveResultItems', saveResultItems);
        let shiftSaveResults = new Map();

        for (let i = 0; i < saveResultItems.length; i++) {
            shiftSaveResults.set(saveResultItems[i].recId, saveResultItems[i]);
        }

        for (let i = 0; i < this.records.length; i++) {
            if (!shiftSaveResults.has(this.records[i].Id)) {
                continue;
            }
            let shiftSaveResult = shiftSaveResults.get(this.records[i].Id)

            this.records[i]['saveSuccess'] = shiftSaveResult.success;
            this.records[i]['saveError'] = !shiftSaveResult.success;
            //Hide popover with results by defualt
            this.records[i]['showPopover'] = false;
            //Populate error messages for the record
            this.records[i]['errorMessages'] = shiftSaveResult.errors;

        }
        //Show Save Results
        this.showSaveResults = true;

        this.hasGeneralError = true;
        this.showGeneralError = true;
        this.generalErrorMessage = 'Some shifts failed to save. Please review the errors.';
    }

    handleOpenSignature(event) {
        console.log('handleOpenSignature', event.currentTarget.dataset.hassignature);
        if (event.currentTarget.dataset.hassignature) {
            let signatureLink = event.currentTarget.dataset.signatureLink;
            this.template.querySelector('c-signature-modal').openSignature(signatureLink);
        }
    }

    updateRecords(shiftId, props) {
        // debug('updateRecords before:', this.updatedRecords);
        debug('updateRecords shiftId:', shiftId);
        debug('updateRecords props:', props);
        let hasMatch = false;

        this.records.map(record => {
            if (record.Id == shiftId) {
                for (let prop of props) {
                    record.shift[prop.name] = prop.value;
                }
                record.isChanged = true;
            }
        })

        // for(let updatedRecord of this.updatedRecords){
        //     if(updatedRecord.Id == shiftId){
        //         for(let prop of props){
        //             updatedRecord[prop.name] = prop.value;
        //         }
        //         hasMatch = true;
        //         break;
        //     }
        // }

        // if(!hasMatch){
        //     let updateRecord = {
        //         Id: shiftId
        //     };
        //     for(let prop of props){
        //         updateRecord[prop.name] = prop.value;
        //     }
        //     this.updatedRecords.push(updateRecord);
        // }

        // //Update records table
        // for(let record of this.records){
        //     if(record.Id == shiftId){
        //         for(let prop of props){
        //             record.shift[prop.name] = prop.value;
        //         }
        //         break;
        //     }
        // }

        // debug('updateRecords AFTER:', this.updatedRecords);
    }

    recalculateTotalLength(shiftId, start, end) {
        // debug('updateRecords before:', this.updatedRecords);
        debug('updateRecords shiftId:', shiftId);
        debug('updateRecords new start:', start);
        debug('updateRecords new end:', end);
        let hasMatch = false;

        this.records.map(record => {
            if (record.Id == shiftId) {
                const { hoursDecimal, hours, minutes, formattedString } = Utils.calculateLength(start, end, record);
                this.formattedString = formattedString;
                record.shiftTotalColumn = formattedString;
                record.decimalLength = hoursDecimal;
                record.Hours = hours;
                record.Minutes = minutes;
            }
        });

        // const totalColumn = this.template.querySelector(`div[data-total="${shiftId}"]`);
        // totalColumn.textContent = this.formattedString;
    }

    /**
     * This function handles the change in state
     * for non-checkbox fields (time fields) and updates
     * the respective shift record with the new value
     * of the change regiestered
     * 
     * @param {*} event 
     */
    handleTimesChange(event) {
        // let shiftId = event.currentTarget.dataset.id;
        let writeToStartFieldName = event.currentTarget.dataset.writeToStart;
        let writeToEndFieldName = event.currentTarget.dataset.writeToEnd;

        let shiftId = event.detail.uId;
        let apiStartValue = event.detail.value.startDT;
        let apiEndValue = event.detail.value.endDT;

        this.updateRecords(shiftId, [
            { name: writeToStartFieldName, value: apiStartValue },
            { name: writeToEndFieldName, value: apiEndValue }
        ]);

        if (writeToStartFieldName === 'sirenum__Billable_Start_Time__c' && writeToEndFieldName === 'sirenum__Billable_End_Time__c') {
            this.recalculateTotalLength(shiftId, apiStartValue, apiEndValue);
        }
    }

    handleTimeTypeChange(event) {
        let writeToFieldName = event.currentTarget.dataset.writeTo;

        let shiftId = event.currentTarget.dataset.recordId;
        let newValue = event.detail.value;

        this.updateRecords(shiftId, [
            { name: writeToFieldName, value: newValue }
        ]);


        for (let record of this.records) {
            if (record.Id == shiftId) {
                debug(`Found Record ${record.Id}`, newValue);
                record.portalHoursEntry = (newValue == 'Hours');
                break;
            }
        }
    }

    handleTextInputChange(event) {
        let writeToFieldName = event.currentTarget.dataset.writeTo;

        let shiftId = event.currentTarget.dataset.recordId;
        let newValue = event.detail.value;

        this.updateRecords(shiftId, [
            { name: writeToFieldName, value: newValue }
        ]);
    }

    getWeekStartAndEnd(currentDate) {
        // australia counts monday as first day of week js uses sunday so add one to each day
        const startDate = new Date(currentDate);
        if (startDate.getDay() !== 1) {
            startDate.setDate(currentDate.getDate() - currentDate.getDay());
            startDate.setDate(startDate.getDate() + 1);
        }
        const endDate = new Date(startDate);
        endDate.setDate(startDate.getDate() + (7 - startDate.getDay()));

        // get in dd/mm/yyyy format
        let startOfWeek = this.formatDate(startDate);
        let endOfWeek = this.formatDate(endDate);

        return {
            startOfWeek,
            endOfWeek
        };
    }

    convertToDatePickerFormat(dateString) {
        let date = dateString.split('/');
        // yyyy-mm-dd
        return `${date[2]}-${date[0]}-${date[1]}`;
    }

    formatDate(date) {
        let day = date.getDate();
        let month = date.getMonth() + 1;
        let year = date.getFullYear();

        day = day < 10 ? '0' + day : day;
        month = month < 10 ? '0' + month : month;
        return `${month}/${day}/${year}`;
    }

    convertFormat(dateString) {
        let date = dateString.split('-');
        // mm/dd/yyyy
        return `${date[1]}/${date[2]}/${date[0]}`;
    }


    /**
     * Invoked by an onclick event on an element with the
     * attributes "shift" and "break"
     * 
     * - Shift attribute is the shift's ID that we are editing
     * - Break attribute is the break's ID that we are editing
     * 
     * @param {*} event 
     */
/*     handleBreakEdit(event) {
        let shiftId = event.currentTarget.dataset.shift;
        let breakId = event.currentTarget.dataset.break;
        let isEdit = event.currentTarget.dataset.isEdit;
        let editEndTime = event.currentTarget.dataset.endTime;
        let editStartTime = event.currentTarget.dataset.startTime;
        let date;
        let breakTime;

        if (!isEdit) {
            date = event.currentTarget.dataset.date;
            breakTime = this.convertToLWCDateTimeFormat(date, 14);
        }
        let startTime = editStartTime !== undefined ? editStartTime : breakTime;
        let endTime = editEndTime !== undefined ? editEndTime : breakTime;
        this.template.querySelector('c-shift-break-editor').openModal(shiftId, breakId, startTime, endTime);
    } */

    handleBreakEdit(event) {
    const shiftId = event.currentTarget.dataset.shift;
    let breakType = event.currentTarget.dataset.break; 
    // breakType = first | second | add

    let startTime;
    let breakLength;

    const record = this.records.find(r => r.Id === shiftId);
    if (!record) return;

    const shift = record.shift;

    if (breakType === 'first') {
        startTime = shift.sirenum__BreakStartTime__c;
        breakLength = shift.sirenum__Break_Length__c;
    }
    else if (breakType === 'second') {
        startTime = shift.tc9_ext_sirint__Second_Break_Start_Time__c;
        breakLength = shift.tc9_ext_sirint__Second_Break_Length__c;
    }
    else {
        // SINGLE Add logic
        if (!shift.sirenum__Break_Length__c) {
            breakType = 'first';
        } else {
            breakType = 'second';
        }

        startTime = null;
        breakLength = null;
    }

    this.template
        .querySelector('c-shift-break-editor')
        .openModal({
            shiftId,
            breakType,
            startTime,
            breakLength
        });
}
handleSaveBreak(event) {
    const { shiftId, breakType, startTime, breakLength } = event.detail;

    let updates = [];

    if (breakType === 'first') {
        updates = [
            { name: 'sirenum__BreakStartTime__c', value: startTime },
            { name: 'sirenum__Break_Length__c', value: breakLength }
        ];
    } else {
        updates = [
            { name: 'tc9_ext_sirint__Second_Break_Start_Time__c', value: startTime },
            { name: 'tc9_ext_sirint__Second_Break_Length__c', value: breakLength }
        ];
    }

    this.updateRecords(shiftId, updates);
}



    convertToLWCDateTimeFormat(breakDate, hour) {
        let date = breakDate.split('/');
        let day = date[1].length === 2 ? date[1] : `0${date[1]}`;
        let month = date[0].length === 2 ? date[0] : `0${date[0]}`;
        return `${date[2]}-${month}-${day}T${hour}:00:00Z`;
    }

    handleExpenseEdit(event) {
        let shiftId = event.currentTarget.dataset.shift;
        let contactId = event.currentTarget.dataset.contact;
        let contractId = event.currentTarget.dataset.contract;
        let shiftDate = event.currentTarget.dataset.shiftDate;
        let expenseId = event.currentTarget.dataset.expense;
        this.template.querySelector('c-expense-editor').openModal(shiftId, contactId, contractId, shiftDate, expenseId);
    }

    handleRejection(event) {
        if (event.detail.checked) {
            let shiftId = event.currentTarget.dataset.recordId;
            let rejectionReason = event.currentTarget.dataset.rejectionReason;
            let rejectionReasonOther = event.currentTarget.dataset.rejectionReasonOther;
            this.template.querySelector('c-rejection-editor').openModal(shiftId, rejectionReason, rejectionReasonOther);
        } else {
            this.handleCheckboxChange(event);
        }
    }

    updateRejection(event) {
        let shiftId = event.detail.shiftId;
        let rejectionReason = event.detail.rejectionReason;
        let rejectionReasonOther = event.detail.rejectionReasonOther;

        this.updateRecords(shiftId, [
            { name: 'Rejected__c', value: true },
            { name: 'Rejection_Reason__c', value: rejectionReason },
            { name: 'Rejection_Reason_Other__c', value: rejectionReasonOther },
        ]);
    }

    get getExpressionBuilderWrapperClass() {
        return this.showFiltersModal ? '' : 'slds-hide';
    }

    /**
     * This function shows/hides the general error
     * pop-up
     */
    toggleGeneralError() {
        this.showGeneralError = !this.showGeneralError;
    }

    /**
     * This shows the errors popover 
     * 
     * - This is invoked from an onclick event where
     * the element that called this function must have attribute "shift"
     * - Shift attribute is the shift id for which we want to render the erros
     * popover
     * 
     * @param {*} event 
     */
    showErrorPopover(event) {
        let shiftId = event.currentTarget.dataset.shift;
        // for(let i = 0; i < this.fullRecords.length; i++){
        //     if(this.fullRecords[i].Id == shiftId){
        //         this.fullRecords[i]['showPopover'] = true;
        //     }else{
        //         //close any open popovers
        //         this.fullRecords[i]['showPopover'] = false;
        //     }
        // }

        this.closeErrorPopover();

        this.records.filter(record => {
            return record.Id == shiftId
        }).map(record => {
            record['showPopover'] = true;
        });
    }

    /**
     * This closes the errors popover
     */
    closeErrorPopover() {
        this.records.map(record => {
            record['showPopover'] = false;
        });
    }

    handleShowImage(event) {
        let link = event?.currentTarget?.dataset?.link;
        this.template.querySelector('c-signature-modal').openModal(link);
    }

    /** 
     * Navigate to Record
     */
    handleNavigateClick(event) {
        let recID = event.currentTarget.dataset.record;
        let objType = event.currentTarget.dataset.object;
        this.navigateToRecordViewPage(recID, objType);
    }
    /** 
     * Navigate to Record
     */
    navigateToRecordViewPage(recID, objType) {
        // View a custom object record.
        this[NavigationMixin.GenerateUrl]({
            type: "standard__recordPage",
            attributes: {
                recordId: recID,
                objectApiName: objType,
                actionName: 'view'
            }
        }).then(url => {
            window.open(url, "_blank");
        });
    }

    /**
     * Approve all visible shifts
     */
    async approveAll() {
        console.log('Approve all triggered');
        new Promise((resolve) => {
            //Update the record UI
            for (let record of this.records) {
                if (!record.shift.Lock_Approve_Charge__c) {
                    debug(`Marking Record: `, record);
                    this.updateRecords(record.Id, [
                        { name: 'sirenum__Allow_charge__c', value: true },
                        { name: 'sirenum__Allow_pay__c', value: true },
                        { name: 'sirenum__Client_Approval_By__c', value: this.userContactId },
                        { name: 'sirenum__Approved_By_Client__c', value: new Date().toISOString() }
                    ]);
                    debug('Updated Record: ', record);
                }
            }
            setTimeout(() => resolve(), 10);
        }).then(() => {

        }).finally(() => {
        })
    }

    /**
     * When filters are loading, this function is called
     * by the filters component to help us show the user
     * an indication that the system is loading.
     * 
     * @param {*} event 
     */
    handleFilterLoadingState(event) {
        if (event.detail.isLoading != this.isLoading) {
            this.isLoading = event.detail.isLoading;
        }
    }

    /**
     * This function handles the change in state 
     * for checkbox fields (Pay and Charge) and 
     * updates the respective shift record with the 
     * new value of the change registered
     * 
     * @param {*} event 
     */
    handleCheckboxChange(event) {
        let shiftId = event.currentTarget.dataset.recordId;
        let apiName = event.currentTarget.dataset.name;
        let apiNameSecond = event.currentTarget.dataset.nameSecond;
        let apiNameThird = event.currentTarget.dataset.approver;
        let apiValue = event.detail.checked;

        let fieldUpdates = [{ name: apiName, value: apiValue }];
        if (apiNameSecond) {
            fieldUpdates.push({ name: apiNameSecond, value: apiValue });
        }
        if (apiNameThird) {
            fieldUpdates.push({ name: apiNameThird, value: this.userContactId });
        }
        if (apiValue === true) {
            fieldUpdates.push({ name: 'sirenum__Approved_By_Client__c', value: new Date().toISOString() });
        } else {
            fieldUpdates.push({ name: 'sirenum__Approved_By_Client__c', value: null });
        }
        this.updateRecords(shiftId, fieldUpdates);
    }
    //added by Rishikesh Date 17/2/26
    // ================= ATTACHMENT POPUP =================

    openAttachmentPopup(event){
        let shiftId = event.currentTarget.dataset.id;

        let rec = this.records.find(r => r.Id === shiftId);
        if(rec){
            this.currentFiles = rec.attachments;
            this.showAttachmentModal = true;
        }
    }

    closeAttachmentPopup(){
        this.showAttachmentModal = false;
    }

previewFile(event) {
    const selectedDocId = event.currentTarget.dataset.id;
    const isAttachment = event.currentTarget.dataset.isattachment === 'true';

    //If Attachment → open separately
    if (isAttachment) {
        window.open(`/servlet/servlet.FileDownload?file=${selectedDocId}`, '_blank');
        return;
    }

    //Only take FILES (exclude attachments)
    const fileDocIds = this.currentFiles
        .filter(file => !file.isAttachment) //important
        .map(file => file.Id);

    this[NavigationMixin.Navigate]({
        type: 'standard__namedPage',
        attributes: {
            pageName: 'filePreview'
        },
        state: {
            recordIds: fileDocIds.join(','),   //nables arrows
            selectedRecordId: selectedDocId    //open clicked file
        }
    });
}

        get hasRecords() {
            return this.records?.length > 0;
        }

        checkValidity() {
            return this.reportValidity();
        }

        reportValidity() {
            const allInputsAreValid = [...this.template.querySelectorAll('[data-validated-component=true]')]
                .reduce((validSoFar, inputCmp) => {
                    //Get Validity
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
                }, true);

            return allInputsAreValid;
        }
    //***END***/

}