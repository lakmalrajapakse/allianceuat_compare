/*
 * Add formatting options to this file
 */

if (window.ObjectRendering) {
    ObjectRendering.addRenderer(
        ObjectRendering.contextTypes.TABLE_CELL_SHIFT,
        function (renderingContext) {            
            try{                
                let shift = renderingContext.object;
                let shiftDiv = renderingContext.element;
                let scheduleStatus = shift.params?.Schedule_Status__c;
                let scheduleDispStatus = shift.params?.Schedule_Display_Status__c;
                let id = shift.params?.Id;
                let createdDate = shift.params?.CreatedDate;
                let employeeChanged = shift.params?.Employee_Changed__c;
                let dateNow = Date.now();
                let employeeConfirmed = shift.params?.Employee_Changed__c;
                let facilityConfirmed = shift.params?.Confirmed_With_Facility__c;
                // Pe-445 - Add Notes (Internal Only) to Shift Tile
                let internalNotes = shift.params?.Notes_Internal_Only__c;
                let shiftTimeDiv = shiftDiv.getElementsByClassName("shiftTime");
                // console.log('options addRenderer shiftTimeDiv: ' + shiftTimeDiv.length);
                // console.log('options addRenderer shiftTimeDiv[0]: ' + shiftTimeDiv[0]);
                // console.log('options addRenderer shiftTimeDiv[0]: ' + shiftTimeDiv[0].parentNode);
                // PE-501 - Cancellation Fees
                let cancelFeeAppl = shift.params?.Cancel_Fee_Applicable__c;
                // PE-498 - Shift Demand Date Check
                let scheduledDate = shift.params?.sirenum__Scheduled_Start_Time__c;
                let contact = shift.params?.sirenum__Contact__c;
                // console.log('options addRenderer contact: ' + contact);
                // PE-501 - Hide Cancellation Menu
                let cancelCompleted = shift.params?.Cancellation_Completed__c;
                let multiJobRole = shift.params?.sirenum__Team__r?.Name == "Multi";

                // console.log('options addRenderer shift: ' + shift);
                // console.log('options addRenderer shiftDiv: ' + shiftDiv);
                // console.log('options addRenderer scheduleStatus: ' + scheduleStatus);
                // console.log('options addRenderer id: ' + id);
                // console.log('options addRenderer createdDate: ' + createdDate + ' / dateNow: ' + dateNow);
                // console.log('options addRenderer dateNow: ' + dateNow);

                // Add Icons for Schedule Status to class="status"
                // let statusDivs = shiftDiv.getElementsByClassName("status");
                // let shiftStatusDivs = shiftDiv.getElementsByClassName("shiftStatus");
                console.log('options addRenderer contact: ' + contact);
                let shiftStatusDivs = null;
                if (contact != undefined){
                    shiftStatusDivs = shiftDiv.getElementsByClassName("shiftStatus");
                    // console.log('options addRenderer contact != undefined: ' + contact);
                    // console.log('options addRenderer shiftStatusDivs: ' + shiftStatusDivs.length);
                } else {
                    shiftStatusDivs = shiftDiv.getElementsByClassName("shiftDemandBadge");
                    // console.log('options addRenderer contact == undefined: ' + contact);
                    // console.log('options addRenderer shiftStatusDivs: ' + shiftStatusDivs.length);
                }

                // console.log('options addRenderer shiftStatusDivs: ' + shiftStatusDivs.length);
                // console.log('options addRenderer shiftStatusDivs[0]: ' + shiftStatusDivs[0]);

            
                // if (scheduleStatus == "Reconfirm with Facility" || (scheduleStatus == "Reconfirm" && facilityConfirmed == false)){
                if (scheduleDispStatus == "Reconfirm with Facility" || (scheduleDispStatus == "Reconfirm" && facilityConfirmed == false)){
                    let reconfirmFacilityIconDiv = document.createElement("div");
                    reconfirmFacilityIconDiv.className = 'shiftRecFac fas fa-warehouse'; 
                    reconfirmFacilityIconDiv.id = 'scheduleRecFacIcon_' + id;
                    reconfirmFacilityIconDiv.title = "Reconfirm with Facility";
                    // console.log('options addRenderer reconfirmFacilityIconDiv: ' + reconfirmFacilityIconDiv.id);
                    // statusDivs[0].appendChild(reconfirmFacilityIconDiv);
                    shiftStatusDivs[0].parentNode.insertBefore(reconfirmFacilityIconDiv, shiftStatusDivs[0]);
                }
                // if (scheduleStatus == "Reconfirm with Employee" || (scheduleStatus == "Reconfirm" && employeeConfirmed == 0)){
                if (scheduleDispStatus == "Reconfirm with Employee" || (scheduleDispStatus == "Reconfirm" && employeeConfirmed == 0)){
                    let reconfirmEmployeeIconDiv = document.createElement("div");
                    reconfirmEmployeeIconDiv.className = 'shiftRecEmp fas fa-user'; 
                    reconfirmEmployeeIconDiv.id = 'scheduleRecEmpIcon_' + id;
                    reconfirmEmployeeIconDiv.title = "Reconfirm with Employee";
                    // console.log('options addRenderer reconfirmEmployeeIconDiv: ' + reconfirmEmployeeIconDiv.id);
                    // statusDivs[0].appendChild(reconfirmEmployeeIconDiv);
                    shiftStatusDivs[0].parentNode.insertBefore(reconfirmEmployeeIconDiv, shiftStatusDivs[0]);
                }
                //If NOT a demand and Job Role is "Multi" then display Multi decoration
                if (multiJobRole && shift?.contact != "*"){
                    let multiRoleDiv = document.createElement("div");
                    multiRoleDiv.id = 'multiRoleDiv_' + id;
                    multiRoleDiv.className = "shiftDemandBadge";
                    multiRoleDiv.style.backgroundColor = '#C23934';
                    multiRoleDiv.innerText = "! MULTI !";
                    multiRoleDiv.title = "Please resolve Job Role by selecting a valid role for the contract. Do this via right clicking on the Shift tile and selecting 'Resolve Job Role'";
                    shiftStatusDivs[0].parentNode.insertBefore(multiRoleDiv, shiftStatusDivs[0]);
                }

                if (multiJobRole && shift?.contact == "*"){
                    let multiRoleDiv = document.createElement("div");
                    multiRoleDiv.id = 'multiRoleDiv_' + id;
                    multiRoleDiv.className = "shiftDemandBadge";                    
                    multiRoleDiv.innerText = " MULTI ";
                    multiRoleDiv.style='font-size: smaller; font-weight: bold; background-color: #ccebfa';
                    const title=shift.params?.Competency_JSON__c;
                    let formatedTitle = '';
                    if (title && title.length > 0) {
                        try {                            
                            const titleObj = JSON.parse(title);                            
                            Object.keys(titleObj).forEach(key => {
                                if (Array.isArray(titleObj[key]) && titleObj[key].length > 0) {
                                    formatedTitle += `\n${key}:`;
                                    titleObj[key].forEach((e) => {
                                        formatedTitle += `\n  ${e}`;
                                    });                                
                                }    
                            });                                                        
                        } catch (err) {
                            
                        }
                    }
                    multiRoleDiv.title = formatedTitle;
                    shiftStatusDivs[0].parentNode.insertBefore(multiRoleDiv, shiftStatusDivs[0]);
                }
                // let scheduleStatusDiv = document.createElement("div");
                // // innerText will be hidden when this is working
                // scheduleStatusDiv.innerText = scheduleStatus;
                // scheduleStatusDiv.dataset.scheduleStatus = scheduleStatus;
                // scheduleStatusDiv.className = 'scheduleStatus';
                // scheduleStatusDiv.id = 'scheduleStatus_' + id;
                // shiftDiv.appendChild(scheduleStatusDiv);

                let scheduleDispStatusDiv = document.createElement("div");
                // innerText will be hidden when this is working
                // scheduleDispStatusDiv.innerText = 'Disp Status: ' + scheduleDispStatus;
                scheduleDispStatusDiv.innerText = scheduleDispStatus;
                scheduleDispStatusDiv.dataset.scheduleDispStatus = scheduleDispStatus;
                scheduleDispStatusDiv.className = 'scheduleDispStatus';
                scheduleDispStatusDiv.id = 'scheduleDispStatus_' + id;
                shiftDiv.appendChild(scheduleDispStatusDiv);

                let createdDateDiv = document.createElement("div");
                createdDateDiv.className = 'createdDate';
                createdDateDiv.id = 'createdDate_' + id;
                createdDateDiv.dataset.lastHour = dateNow - createdDate <= 3600000 ? true : false;
                // console.log('options addRenderer createdDateDiv.dataset.lastHour: ' + createdDateDiv.dataset.lastHour);
                // scheduleStatusDiv.appendChild(createdDateDiv);
                scheduleDispStatusDiv.appendChild(createdDateDiv);

                // if (employeeChanged == true){
                    let employeeChangedDiv = document.createElement("div");
                    employeeChangedDiv.className = 'employeeChanged'; 
                    employeeChangedDiv.id = 'employeeChangedDiv_' + id;
                    employeeChangedDiv.dataset.empChanged = employeeChanged;
                    // console.log('options addRenderer employeeChangedDiv: ' + employeeChangedDiv.id);
                    // scheduleStatusDiv.appendChild(employeeChangedDiv);
                    scheduleDispStatusDiv.appendChild(employeeChangedDiv);
                // }

                // PE-498 - Shift Demand Date Check
                let scheduledDateDiv = document.createElement("div");
                scheduledDateDiv.className = 'scheduledDate';
                scheduledDateDiv.id = 'scheduledDate_' + id;
                // console.log('options addRenderer scheduledDateDiv dateNow: ' + dateNow + ' / scheduledDate:' + scheduledDate);
                // let testValue = dateNow - scheduledDate;
                // console.log('options addRenderer dateNow - scheduledDate: ' + testValue);
                if (contact != "*"){
                    // console.log('options addRenderer shift.contact != * dataset.oldShift: ' + shift.contact + ' / ' + contact);
                    scheduledDateDiv.dataset.oldShift = dateNow - scheduledDate >= 0 ? true : false;
                } else {
                    // console.log('options addRenderer shift.contact = * dataset.oldShiftDemand: ' + shift.contact + ' / ' + contact);
                    scheduledDateDiv.dataset.oldShiftDemand = dateNow - scheduledDate >= 0 ? true : false;
                }
                // console.log('options addRenderer scheduledDateDiv.dataset.oldShiftDemand: ' + scheduledDateDiv.dataset.oldShiftDemand);
                // scheduleStatusDiv.appendChild(scheduledDateDiv);
                scheduleDispStatusDiv.appendChild(scheduledDateDiv);

                // PE-501 - Hide Cancellation Menu
                let cancelCompletedDiv = document.createElement("div");
                cancelCompletedDiv.className = 'cancelCompleted';
                cancelCompletedDiv.id = 'cancelCompleted_' + id;
                cancelCompletedDiv.dataset.cancelCompleted = cancelCompleted;
                shiftDiv.appendChild(cancelCompletedDiv);

                // if (shiftDiv && scheduleStatus) {
                //     console.log('options addRenderer if (staffShift && scheduleStatus): ' );
                // }

                // PE-445 - Add Notes (Internal Only) to Shift Tile
                if (internalNotes){
                    let internalNoteDiv = document.createElement("div");
                    internalNoteDiv.id = 'internalNote_' + id;
                    internalNoteDiv.className = 'internalNotes';
                    internalNoteDiv.innerText = internalNotes;
                    // shiftDiv.appendChild(internalNoteDiv);
                    shiftTimeDiv[0].parentNode.insertBefore(internalNoteDiv, shiftTimeDiv[0]);
                }

                // PE-501 - Cancellation Fees
                if(cancelFeeAppl) {
                    let cancelFeeApplDiv = document.createElement("div");
                    cancelFeeApplDiv.className = 'cancelFeeAppl fas fa-money-check';
                    cancelFeeApplDiv.id = 'cancelFeeAppl_' + id;
                    cancelFeeApplDiv.title = "Cancellation Fee Applied";
                    shiftStatusDivs[0].parentNode.insertBefore(cancelFeeApplDiv, shiftStatusDivs[0])
                }

                if (!shiftStatusDivs || shiftStatusDivs.length === 0) {
                    shiftStatusDivs = shiftDiv.getElementsByClassName("shiftDemandBadge"); 
                }

                if (shiftStatusDivs && shiftStatusDivs.length > 0) {
                    let vmsIcon = getVMSIcon(shift);
                    if (vmsIcon) {                
                        shiftStatusDivs[0].parentNode.insertBefore(vmsIcon, shiftStatusDivs[0]);
                    }
                }
                                

            }catch(err){
                console.log('Error in Renderer TABLE_CELL_SHIFT', err);
            }
        }
    );
    // PE-1404 - Display Candidate Qualification 
    ObjectRendering.addRenderer(
        ObjectRendering.contextTypes.TABLE_ROW_HEADER_CONTACT,
        function(objectRenderingContext) {
            try{
                var object = objectRenderingContext.object;
                // console.log('TABLE_ROW_HEADER_CONTACT object: ', object);
                if (object.sObject.Id == '*') {
                    return;
                }
                if (object.sObject.Id != '*'){
                    var element = objectRenderingContext.element;
                    // console.log('TABLE_ROW_HEADER_CONTACT element: ', element);
                    // let phoneNumberDiv = element.getElementsByClassName("phoneNumber");
                    // console.log('TABLE_ROW_HEADER_CONTACT phoneNumberDiv: ', phoneNumberDiv);
                    // console.log('TABLE_ROW_HEADER_CONTACT phoneNumberDiv.parentElement: ', phoneNumberDiv.parentElement);

                    var outer = document.createElement('div');
                    outer.className = 'additional-content';                    

                    if (object.sObject.Classification__c != null) {
                        var classificationDiv = document.createElement('div');
                        classificationDiv.className = 'classification';
                        classificationDiv.innerText = object.sObject.Classification__c;
                        outer.appendChild(classificationDiv);
                    }
                    if (object.sObject.Flag_Text__c != null) {
                        var flagTextDiv = document.createElement('div');                    
                        flagTextDiv.style='color: darkred; font-weight: bold; font-size: small;';
                        flagTextDiv.innerText = object.sObject.Flag_Text__c;
                        outer.appendChild(flagTextDiv);
                    }
                    

                    // Add the generated root element to the row header.
                    element.appendChild(outer);
                    // element.append(outer);
                    // phoneNumberDiv[0].parentNode.insertBefore(phoneNumberDiv, outer);
                    // phoneNumberDiv.insertBefore(outer, insertBefore);
                }
            }catch(err){
                console.log('Error in Renderer TABLE_ROW_HEADER_CONTACT', err);
            }
    });
    ObjectRendering.addRenderer(
        ObjectRendering.contextTypes.SEARCH_RESULT_DETAIL_CONTACT,
        function(objectRenderingContext) {
            try{
                var object = objectRenderingContext.object;                
                var element = objectRenderingContext.element;
                if (object.sObject.Flag_Text__c != null) {
                    var flagTextDiv = document.createElement('div');
                    flagTextDiv.style='color: darkred; font-weight: bold; font-size: small;';
                    flagTextDiv.innerText = object.sObject.Flag_Text__c;
                    element.appendChild(flagTextDiv);
                }
                
            }catch(err){
                console.log('Error in Renderer SEARCH_RESULT_DETAIL_CONTACT', err);
            }
        }
    );
}

function getVMSIcon(shift){

    // PE-1173 Approved by Client check first
    if (shift.params?.sirenum__Approved_By_Client__c) {
        let approvedIcon = document.createElement('span');
        approvedIcon.className = 'fas fa-check-circle';
        approvedIcon.setAttribute('title', 'Approved by Client');
        approvedIcon.style.marginLeft = '3px';
        return approvedIcon; // directly return the approved icon
    }
    
    if (!shift.params.VMS_Source__c) {
        return null;
    }

    let icon = document.createElement('span');
    let title = `VMS: ${shift.params.VMS_Source__c} ${(shift.params.VMS_Send_Status__c) ? '(' + shift.params.VMS_Send_Status__c + ')' : ''}`;
    
    if (shift.params.VMS_Source__c == 'ShiftMatch') {
        icon.innerHTML = 'SM';
        icon.style='font-size: smaller; font-weight: bold;';
    } else {
        icon.innerHTML = 'V';
    }

    let className = 'c-info';
    if(shift.params.VMS_Send_Status__c ==  'Ready To Send'){
        className = 'c-warning';
    } else if(shift.params.VMS_Send_Status__c == 'Sent'){
        className = 'c-success';
    }

    icon.classList.add('c-status-icon');
    icon.classList.add(className);
    icon.setAttribute('title', title);
    return icon;

}