console.log('Campaign SMS')

/*
Shift Exceptions Override
*/
// var SHIFT_APPROVAL_PAGE = 'Shift_Approval';
// window.addEventListener('DOMContentLoaded', (event) => {
//     let shiftExceptionCards = document.getElementsByClassName('subCardShiftException');
//     if(shiftExceptionCards && shiftExceptionCards.length > 0){
//         shiftExceptionCards[0].href = '/lightning/n/' + SHIFT_APPROVAL_PAGE;
//     }
// });


// Load labels
 var SMSConsoleLabel = {
     "SelectNotificationCheckbox": "Select to send notification",
     "Select": "Select Visible",
     "Clear": "Clear",
     "SMSToSend": "SMS to send",
     "ClearSelectedTitle": "Click to clear selected",
     "SelectDeselectTitle": "Click to select/deselect visible",
     "AlertNoOneSelected": "You haven\'t selected anyone to send SMS to."
   };

// Since the origin URL will be the Scheduler page, it will have the sirenum namespace in the URL
// Like "https://sirenum."
// The SchedulingSMS page is not part of the sirenum namespace so it will fail to load if the
// URL has the sirenum namespace, we need to replace it by c
window.global_environment_URL = window.location.origin.replace("sirenum", "c");

if(typeof createTableRow !== 'undefined'){
    //Render rows and add options
    let old_createTableRow = createTableRow;

    createTableRow = function (c) {
        const table_row = old_createTableRow(c);
        const contact_header = table_row.getElementsByClassName('rowHeader')[0];
        // noinspection JSUnresolvedVariable
        const isContact = (c instanceof contact) && c.id !== "*";

        if (isContact) {
            const hr_el = document.createElement('hr');
            const rowSMS_el = document.createElement('div');
            rowSMS_el.classList.add('rowSMS');
            rowSMS_el.innerText = SMSConsoleLabel.SelectNotificationCheckbox;

            const rowSMS_input_el = document.createElement('input');
            rowSMS_input_el.classList.add('smsCheckbox');
            rowSMS_input_el.setAttribute('type', 'checkbox');
            rowSMS_input_el.id = c.id;
            rowSMS_input_el.onclick = function () {
                setNumberSelected();
            };

            rowSMS_el.appendChild(rowSMS_input_el);
            contact_header.appendChild(hr_el);
            contact_header.appendChild(rowSMS_el);
        }

        return table_row;
    };

    
    //Call the initialiser function after
    const old_createTableRows = createTableRows;

    createTableRows = function (tbl) {
        const return_val = old_createTableRows(tbl);
        addSMSMenu();
        return return_val;
    };

}

/**
Add cost center to shift tile:
*/
// if (window.ObjectRendering) {
//     ObjectRendering.addRenderer(
//         ObjectRendering.contextTypes.TABLE_CELL_SHIFT,
//         function (renderingContext) {            
//             try{                
//                 let shift = renderingContext.object;
//                 let costc = shift.params.Cost_Centre__c;
//                 let accepted = shift.params.sirenum__Accepted__c;
//                 let published = shift.params.sirenum__Published__c;
//                 let unallocated = shift.params.sirenum__Contact__c;
//                 let account = shift.params.Account__r;

//                 let teamDiv = renderingContext.element.querySelector('.shiftDetailTeam');

//                 if (teamDiv && costc) {
//                    let teamText = teamDiv.innerHTML;
//                    teamDiv.innerHTML="";

//                    let teamSpan = document.createElement("span");
//                    teamSpan.innerText = teamText;
//                    teamSpan.className = "shiftDetailTeam_1";
//                    teamDiv.appendChild(teamSpan);

//                    let costcSpan = document.createElement("span");
//                    costcSpan.innerText = costc;
//                    costcSpan.className = "shiftDetailTeam_2";
//                    teamDiv.appendChild(costcSpan);
//                 }
                
//                 let staffShift = renderingContext.element.querySelector('.shiftDetailSite');
                
//                 if(account!==undefined){
                    
//                     let shiftTopDiv = staffShift.closest('.shiftTop');
//                     let nameDiv = document.createElement("div");
//                     nameDiv.innerText = shift.params.Account__r.Name;
//                     shiftTopDiv.prepend(nameDiv);
//                 }
               
//                 if(published==false &&  unallocated!==undefined){

//                     staffShift.closest('.staffShift').style.backgroundColor ='#EDEB69'; //yellow

//                 }
//                 else
//                 if(published==true && unallocated!==undefined){
                    
//                     if(accepted==true || accepted===1){
//                         staffShift.closest('.staffShift').style.backgroundColor = '#46A249'; //Dark green
//                     }
//                     else if(accepted===-1){

//                         staffShift.closest('.staffShift').style.backgroundColor ='#EA323A'; //Red

//                     }
//                     else if(accepted===0) {
//                         staffShift.closest('.staffShift').style.backgroundColor ='#ED942E'; //Orange
//                     }
//                 }
//                 else
//                 if(unallocated===undefined){
//                     staffShift.closest('.staffShift').style.backgroundColor ='#FF369B'; //pink
//                 }       

//             }catch(err){
//                 console.log('Error in Renderer TABLE_CELL_SHIFT', err);
//             }
//         }
//     );
// }

/* SMS HELPER METHODS*/
function addSMSMenu() {
    let hrefSplit = window.location.href.split("sfdcIFrameOrigin=");

    if (hrefSplit.length > 1) {
        window.global_environment_URL = hrefSplit[1].replace("%3A%2F%2F", "://").split("&")[0] || window.location.origin;
    }

    const alertsIcon = document.getElementById('alertsGeneral');

    if (!alertsIcon)
        return;

    let smsGeneral = document.getElementById("smsGeneral");

    if (!smsGeneral) {
        //switching views, or creating for the first time. Need to reset
        smsGeneral = document.createElement("A");
        const selectedForSMS = getNumberSelected();
        const linkText = document.createTextNode("" + selectedForSMS);
        smsGeneral.appendChild(linkText);
        smsGeneral.classList.add('headerButton');
        smsGeneral.classList.add('headerButtonRight');
        smsGeneral.classList.add('smsIcon');
        smsGeneral.id = 'smsGeneral';
        smsGeneral.title = SMSConsoleLabel.SMSToSend;
        smsGeneral.addEventListener("click", loadSMSPage);
        insertAfter(smsGeneral, alertsIcon);

        //Now Create Controls - Clear
        const smsGeneralControl = document.createElement("A");
        let linkTextControl = document.createTextNode(SMSConsoleLabel.Clear);
        smsGeneralControl.appendChild(linkTextControl);
        smsGeneralControl.classList.add('headerButton');
        smsGeneralControl.classList.add('headerButtonRight');
        smsGeneralControl.classList.add('smsIcon');
        smsGeneralControl.classList.add('smsClear');
        smsGeneralControl.id = 'smsGeneralClear';
        smsGeneralControl.title = SMSConsoleLabel.ClearSelectedTitle;
        smsGeneralControl.addEventListener("click", clearSelected);
        insertAfter(smsGeneralControl, smsGeneral);

        //Select/deselect
        const smsSelectControl = document.createElement("A");
        linkTextControl = document.createTextNode(SMSConsoleLabel.Select);
        smsSelectControl.appendChild(linkTextControl);
        smsSelectControl.classList.add('headerButton');
        smsSelectControl.classList.add('headerButtonRight');
        smsSelectControl.classList.add('smsIcon');
        smsSelectControl.classList.add('smsClear');
        smsSelectControl.id = 'smsSelectVisible';
        smsSelectControl.title = SMSConsoleLabel.SelectDeselectTitle;
        smsSelectControl.addEventListener("click", selectVisible);
        insertAfter(smsSelectControl, smsGeneralControl);
    }

    setNumberSelected();
}

function loadSMSPage() {
    let numberSelected = 0;
    let idsSelected = "";
    const smsCheckboxes = document.getElementsByClassName('smsCheckbox');

    for (let i = 0; i < smsCheckboxes.length; ++i) {
        if (smsCheckboxes[i].checked) {
            numberSelected++;
            idsSelected += smsCheckboxes[i].id + ',';
        }
    }

    if (numberSelected === 0) {
        idsSelected = [];
    }else{
        idsSelected = idsSelected.substring(0, idsSelected.length - 1);
    }

    createSMSForm(idsSelected);
    // noinspection JSUnresolvedFunction
    stopBubble(event);
}

function getNumberSelected() {
    let numberSelected = 0;
    const smsCheckboxes = document.getElementsByClassName('smsCheckbox');

    for (let i = 0; i < smsCheckboxes.length; ++i) {
        if (smsCheckboxes[i].checked) {
            numberSelected++;
        }
    }

    return numberSelected;
}

function setNumberSelected() {
    const smsIndicator = document.getElementById('smsGeneral');

    if (!smsIndicator)
        return;

    let numberSelected = 0;
    const smsCheckboxes = document.getElementsByClassName('smsCheckbox');

    for (let i = 0; i < smsCheckboxes.length; ++i) {
        if (smsCheckboxes[i].checked) {
            numberSelected++;
        }
    }

    smsIndicator.innerHTML = numberSelected.toString();
}

function clearSelected() {
    const smsIndicator = document.getElementById('smsGeneral');

    if (!smsIndicator)
        return;

    const smsCheckboxes = document.getElementsByClassName('smsCheckbox');

    for (let i = 0; i < smsCheckboxes.length; ++i) {
        if (smsCheckboxes[i].checked) {
            smsCheckboxes[i].checked = false;
        }
    }

    smsIndicator.innerHTML = '0';
}

/* Shows notifications frame */
function createSMSForm(idsSelected) {
    // noinspection JSUnresolvedFunction
    const frmDiv = createCenteredForm("notificationsForm", "Communication Manager");
    const listFrame = document.createElement("iframe");
    listFrame.setAttribute("id", "notificationsIFrame");
    listFrame.setAttribute("src", global_environment_URL + "/apex/MassMessageManagerPage?selectedContactIds=" + idsSelected);
    listFrame.setAttribute("frameBorder", "0");
    frmDiv.appendChild(listFrame);
    const rect = frmDiv.getBoundingClientRect();
    const frameRect = listFrame.getBoundingClientRect();
    listFrame.style.height = (rect.bottom - frameRect.top - 40) + "px";

    frmDiv.onclick = function (e) {
        e.stopPropagation();
    }
}

function insertAfter(newElement, targetElement) {
    // target is what you want it to go after. Look for this elements parent.
    const parent = targetElement.parentNode;

    // if the parents lastchild is the targetElement...
    if (parent.lastChild === targetElement) {
        // add the newElement after the target element.
        parent.appendChild(newElement);
    } else {
        // else the target has siblings, insert the new element between the target and it's next sibling.
        parent.insertBefore(newElement, targetElement.nextSibling);
    }
}

function selectVisible() {
    const visibleRows = document.getElementsByTagName('TR');

    for (let i = 0; i < visibleRows.length; ++i) {
        if (visibleRows[i].getAttribute('contact') !== null && visibleRows[i].getAttribute('contact') !== '*') {
            if (visibleRows[i].style.display !== "none") {
                const smsCheckbox = visibleRows[i].getElementsByClassName("smsCheckbox");

                for (let j = 0; j < smsCheckbox.length; ++j) {
                    smsCheckbox[j].checked = smsCheckbox[j].checked !== true;
                }
            }
        }
    }
    setNumberSelected();
}
  
// if (window.ObjectRendering) {
//     ObjectRendering.addRenderer(
//         ObjectRendering.contextTypes.TABLE_CELL_REQUEST,
//         function (renderingContext) {            
//             try{                
//                 let div2 = renderingContext.element.querySelector('.requestTypeDetail');
//                 if(div2.innerText==='Training'){
//                     div2.closest('.staffRequest').style.backgroundColor ='#9A7F9F';
//                     div2.closest('.staffRequest').style.color='black';

//                  } 
//             }catch(err){
//                 console.log('Error in Renderer TABLE_CELL_SHIFT', err);
//             }
//         }
//     );
// }