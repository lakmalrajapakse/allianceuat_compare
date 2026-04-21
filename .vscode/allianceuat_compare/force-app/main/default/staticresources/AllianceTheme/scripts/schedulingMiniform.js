if (window.newSchedulingMiniForm) {
    let HIDDEN_FIELDS = ['VMS_Source__c', 'VMS_External_Id__c', 'Lock_Timestamp__c', 'Minform_UUID__c', 'Competency_JSON__c', 'Role_OR_Bundle__c', 'Skill_Attribute_OR_Bundle__c'];
    // let CANCEL_FIELDS = ['Cancellation_Fee__c','Cancellation_Outcome__c','Cancelled_By__c','Cancelled_Date_Time__c','Cancellation_Completed__c','Cancellation_Note__c'];
    let CANCEL_FIELDS = ['Cancellation_Fee__c','Cancellation_Outcome__c'];
    let CANCEL_CMPL_FIELDS = ['Cancelled_By__c','Cancellation_Note__c'];
    let CONF_BY_FAC_FIELDS = ['Confirmed_By__c'];
    
    let documentBody = document.querySelector('body');
    let shifts;
    documentBody.addEventListener('newSchedulingMiniForm', function (e) {        
        let {objectsBeingEdited,sObjectName} = e.detail;
        
        if (objectsBeingEdited) {
            shifts=objectsBeingEdited;
            console.log(objectsBeingEdited);

            let canSendToVMS = objectsBeingEdited.reduce((validSoFar, objectEdited) => {
                return validSoFar && objectEdited?.params.VMS_Source__c == 'ShiftMatch'
                                  //&& objectEdited?.baseline?.params.sirenum__Accepted__c
                                  && (!objectEdited?.baseline?.params.VMS_Send_Status__c);
            }, true); 

            const uuid = crypto.randomUUID();
            objectsBeingEdited.forEach(objectEdited => {
                if (objectEdited?.params.Lock_Timestamp__c) {
                    objectEdited.baseline.params.Lock_Timestamp__c = null;
                } else {
                    objectEdited.baseline.params.Lock_Timestamp__c = 1000;
                    objectEdited.params.Lock_Timestamp__c = null;
                }

                objectEdited.params.Minform_UUID__c = uuid;
            });
            

            disableFields(['VMS_Send_Status__c'], true);
            if (canSendToVMS) {
                showSendToVMS();   
            } 
            
            let hiddenFields = HIDDEN_FIELDS;
            hideUnusedFields(hiddenFields);

            let cancellationFeeApplField = document.querySelector('[id^="sirenum__Shift__c-Cancel_Fee_Applicable__c"]');
            if (cancellationFeeApplField) {
                cancellationFeeApplField.addEventListener('click', handleCancellationFeeClick, false);

                // let customRequireValidationField= ['sirenum__Shift__c-Cancellation_Fee__c', 'sirenum__Shift__c-Cancellation_Outcome__c', 'sirenum__Shift__c-Cancelled_By__c', 'sirenum__Shift__c-Cancellation_Note__c'];
                let customRequireValidationField= ['sirenum__Shift__c-Cancellation_Fee__c', 'sirenum__Shift__c-Cancellation_Outcome__c'];
                customRequireValidationField.forEach(field => {
                    let selectFld = document.querySelector('[id^="' + field + '"]');
                    selectFld.addEventListener('change', validateCustomRequired, false);
                });                

                let cancelFeeAppl = objectsBeingEdited.reduce((validSoFarCanc, objectEdited) => {
                    return validSoFarCanc && objectEdited?.params.Cancel_Fee_Applicable__c == true;
                }, true); 
                
                if (cancelFeeAppl) {
                    disableFields(CANCEL_FIELDS, false);
                } else {
                    disableFields(CANCEL_FIELDS, true);
                }
            }            

            let cancellationCmplField = document.querySelector('[id^="sirenum__Shift__c-Cancellation_Completed__c"]');
            if (cancellationCmplField) {
                cancellationCmplField.addEventListener('click', handleCancellationCmplClick, false);

                let customCancelCompReqValidationField= ['sirenum__Shift__c-Cancelled_By__c', 'sirenum__Shift__c-Cancellation_Note__c'];
                customCancelCompReqValidationField.forEach(field => {
                    let selectFld = document.querySelector('[id^="' + field + '"]');
                    selectFld.addEventListener('change', validateCustomRequired, false);
                });  
                // let cancelCompleted = objectsBeingEdited.reduce((validSoFarCanc, objectEdited) => {
                //     return validSoFarCanc && objectEdited?.params.Cancellation_Completed__c == true;
                // }, true); 
                
                // if (cancelCompleted) {
                //     disableFields(CANCEL_CMPL_FIELDS, false);
                // } else {
                //     disableFields(CANCEL_CMPL_FIELDS, true);
                // }
            }

            let confirmedByFacField = document.querySelector('[id^="sirenum__Shift__c-Confirmed_With_Facility__c"]');
            if (confirmedByFacField) {
                // console.log('confirmedByFacField: ' + confirmedByFacField);
                confirmedByFacField.addEventListener('click', handleConfirmedByFacChange, false);

                let customConfByFacValidationField= ['sirenum__Shift__c-Confirmed_By__c'];
                // console.log('customConfByFacValidationField: ' + customConfByFacValidationField);
                customConfByFacValidationField.forEach(field => {
                    let selectFld = document.querySelector('[id^="' + field + '"]');
                    // console.log('selectFld: ' + selectFld);
                    selectFld.addEventListener('change', validateCustomRequired, false);
                });
            } 
        }       
    });
    
    function showHideSaveButton(show) {
        let saveButton = document.querySelector('[id^="miniFormSave"]');
        if (show) {
            saveButton.style.display = 'block';
        } else {
            saveButton.style.display = 'none';
        }
    }
    
    function validateCustomRequired(event){
        customValidation();        
    }

    function customValidation(){
        let valid = true;

        let cancellationFeeApplField = document.querySelector('[id^="sirenum__Shift__c-Cancel_Fee_Applicable__c"]');
        if (cancellationFeeApplField) {
            let cancelFeeAppl = cancellationFeeApplField.getAttribute('selected');
            if (cancelFeeAppl === "true") {
                CANCEL_FIELDS.forEach(field => {                    
                    let selectFld = document.querySelector('[id^="sirenum__Shift__c-' + field + '"]');
                    selectFld.removeAttribute('valid');
                    let selectFldValue = selectFld.options[selectFld.selectedIndex].value;
                    if (!selectFldValue || selectFldValue.length === 0) {
                        selectFld.setAttribute('valid', 'false');
                        valid = false;
                    }
                });
            }
        }

        let cancellationCompletedField = document.querySelector('[id^="sirenum__Shift__c-Cancellation_Completed__c"]');
        if (cancellationCompletedField) {
            let cancellationCompleted = cancellationCompletedField.getAttribute('selected');
            if (cancellationCompleted === "true") {                
                CANCEL_CMPL_FIELDS.forEach(field => {                    
                    let selectFld = document.querySelector('[id^="sirenum__Shift__c-' + field + '"]');
                    selectFld.removeAttribute('valid');
                    let selectFldValue = selectFld.value;
                    if (!selectFldValue || selectFldValue.length === 0) {
                        selectFld.setAttribute('valid', 'false');
                        valid = false;
                    }
                });
            }
        }

        let confirmedByFacilityField = document.querySelector('[id^="sirenum__Shift__c-Confirmed_With_Facility__c"]');
        if (confirmedByFacilityField) {
            let confirmedByFacility = confirmedByFacilityField.getAttribute('selected');
            if (confirmedByFacility === "true") {                
                CONF_BY_FAC_FIELDS.forEach(field => {                    
                    let selectFld = document.querySelector('[id^="sirenum__Shift__c-' + field + '"]');
                    selectFld.removeAttribute('valid');
                    let selectFldValue = selectFld.value;
                    if (!selectFldValue || selectFldValue.length === 0) {
                        selectFld.setAttribute('valid', 'false');
                        valid = false;
                    }
                });
            }
        }

        if (!valid) {
            showHideSaveButton(false);
        } else {
            showHideSaveButton(true);
        }
    }
    
    function showSendToVMS(){
        disableFields(['VMS_Send_Status__c'], false);
        let sendToVMSPick = document.querySelector('[id^="sirenum__Shift__c-VMS_Send_Status__c"]');
        if (!sendToVMSPick) {
            return;
        }

        for(let i = 0; i < sendToVMSPick.options.length; i++){
            let option = sendToVMSPick.options[i];

            //Check if context menu it
            if(!option.value || option.value.length == 0){
                //do not manage -- None -- option
                continue;
            }else if('Ready To Send' !== option.value){
                console.log(option);
                sendToVMSPick.remove(i);  i--;
            }
        }
    }

    function disableFields(fields, disable){
        // console.log('disableFields disable: ' + disable); 
        let miniformInputs = document.querySelectorAll('.sirenumInput');
        let miniformCheckboxes = document.querySelectorAll('.checkbox');

        for(let miniformInput of miniformInputs){           
            for(let j = 0; j < fields.length; j++){
                if(miniformInput.id.includes(fields[j])){               
                    if (disable) {
                        // console.log('miniformInput.id setAttribute: ' + miniformInput.id + ' / ' + disable);          
                       miniformInput.setAttribute('disabled', disable);  
                    } else {       
                    // console.log('miniformInput.id removeAttribute: ' + miniformInput.id + ' / ' + disable);                    
                       miniformInput.removeAttribute('disabled');
                    } 
                }
            }
        }

        // Checkboxes don't appear to be able to set disabled... 
        for(let miniformCheckbox of miniformCheckboxes){           
            for(let k = 0; k < fields.length; k++){
                if(miniformCheckbox.id.includes(fields[k])){                        
                    if (disable) {
                        // console.log('miniformCheckbox.id setAttribute: ' + miniformCheckbox.id + ' / ' + disable);      
                        miniformCheckbox.setAttribute('class', 'checkbox inputDisabled'); 
                        // miniformCheckbox.setAttribute('readonly', 'true');        
                    } else {       
                    // console.log('miniformCheckbox.id removeAttribute: ' + miniformCheckbox.id + ' / ' + disable);                    
                    miniformCheckbox.setAttribute('class', 'checkbox');  
                    miniformCheckbox.removeAttribute('readonly');
                   
                    } 
                }
            }
        }
    }

    function hideUnusedFields(hiddenFields){
        let miniformInputs = document.querySelectorAll('.sirenumInput');
        
        for(let miniformInput of miniformInputs){
            for(let j = 0; j < hiddenFields.length; j++){
                if(miniformInput.id.includes(hiddenFields[j])){
                    miniformInput.parentElement.style.display='none';
                }
            }
        }
    }    

    function handleCancellationFeeClick(event) {
        //put your logic here
        // console.log('handleCancellationFeeClick: ');
        let cancellationFeeValue = document.querySelector('[id^="sirenum__Shift__c-Cancel_Fee_Applicable__c"]').getAttribute('selected');
        // console.log('handleCancellationFeeClick cancellationFeeValue: ' + cancellationFeeValue);

        if (cancellationFeeValue === "true") {
            disableFields(CANCEL_FIELDS, false);
        } else {
            CANCEL_FIELDS.forEach(field => {                    
                let selectFld = document.querySelector('[id^="sirenum__Shift__c-' + field + '"]');
                selectFld.removeAttribute('valid');
                selectFld.selectedIndex= 0;
            });

            
            shifts.forEach(shift => {
                shift.params.Cancellation_Fee__c = null;
                shift.params.Cancellation_Outcome__c = null;
            });                   
            
            disableFields(CANCEL_FIELDS, true);
        }   
        customValidation();        
    }

    function handleCancellationCmplClick(event) {
        //put your logic here
        // console.log('handleCancellationCmplClick: ');
        let cancellationCmplValue = document.querySelector('[id^="sirenum__Shift__c-Cancellation_Completed__c"]').getAttribute('selected');
        // console.log('handleCancellationCmplClick cancellationCmplValue: ' + cancellationCmplValue);

        if (cancellationCmplValue === "true") {            
            // disableFields(CANCEL_CMPL_FIELDS, false);
        } else {
            CANCEL_CMPL_FIELDS.forEach(field => {                    
                let selectFld = document.querySelector('[id^="sirenum__Shift__c-' + field + '"]');
                selectFld.removeAttribute('valid');
                selectFld.value='';
            });

            
            shifts.forEach(shift => {
                shift.params.Cancelled_By__c = null;
                shift.params.Cancellation_Note__c = null;
            });                

            // disableFields(CANCEL_CMPL_FIELDS, true);
        }

        customValidation();
    }

    function handleConfirmedByFacChange(event) {
        // console.log('handleConfirmedByFacChange: ');
        let confByFacValue = document.querySelector('[id^="sirenum__Shift__c-Confirmed_With_Facility__c"]').getAttribute('selected');
        // console.log('confByFacValue: ' + confByFacValue);
        if (confByFacValue === "true") {            
            // console.log('confByFacValue === true: ');
            // disableFields(CONF_BY_FAC_FIELDS, false);
        } else {
            // console.log('confByFacValue === false: ');
            CONF_BY_FAC_FIELDS.forEach(field => {                    
                let selectFld = document.querySelector('[id^="sirenum__Shift__c-' + field + '"]');
                selectFld.removeAttribute('valid');
                selectFld.value='';
            });

            
            shifts.forEach(shift => {
                shift.params.Confirmed_By__c = null;
            });                

        }

        customValidation();
    }
        
}