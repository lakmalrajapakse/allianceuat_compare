// Context Menu Customisations
if(window.showContextMenu){
    let showContextMenu_orig = showContextMenu;
    showContextMenu = (div, e) =>{
        // console.log('div: ' + div + ' | e: ' + e);
        console.log('div.Name: ' + div.Name + ' div.className: ' + div.className);
        showContextMenu_orig(div, e);
        //Hide context menu options
        if (div.className == "staffShift") {
            var cMenu = document.getElementById('sirenumContextMenu');
            var opsMenu = cMenu.getElementsByClassName('sirenumContextMenuItem');
            // For demands, display Multi Detail context menu flow action
            if (div.item.contact === "*"){
                // Create Multi Detail and Find Workers element just prior to Auto Assign
                for (i = 0; i < opsMenu.length; i++) {
                    var menuItem = opsMenu[i].textContent || opsMenu[i].innerText;
                    if(menuItem === Label.AutoAssign){
                        cMenu.insertBefore(createContextItem("Multi Detail", function(){openMultiDetail()}), opsMenu[i]);
                        cMenu.insertBefore(createContextItem("Invite Workers", function(){openInviteWorkers()}), opsMenu[i]);
                        break;
                    }
                }
            } else {
                // For shifts, display Multi Resolve context menu flow action
                // Create Multi Resolve element just prior to Advanced
                for (i = 0; i < opsMenu.length; i++) {
                    var menuItem = opsMenu[i].outerText;
                    if(menuItem === "Advanced"){
                        cMenu.insertBefore(createContextItem("Resolve Job Role", function(){openMultiResolve()}), opsMenu[i]);
                        break;
                    }
                }
            }

            // console.log('In if (div.className == staffShift)');
            var cancelCompletedDiv = div.getElementsByClassName("cancelCompleted")[0];
            // console.log('cancelCompletedDiv.id: ' + cancelCompletedDiv.id);
            // console.log('cancelCompletedDiv.dataset.cancelCompleted: ' + cancelCompletedDiv.dataset.cancelCompleted);
            if (cancelCompletedDiv?.dataset?.cancelCompleted === "false"){
                // console.log('In cancelCompletedDiv.dataCancelCompleted == false');
                hideContextOptions('Cancel');
            }

        } else {
            //PE-1137- Hide options from First Column of the Classic Schedule UI [Edit,New Contact,New Site]
            hideContextOptions('NonStaffShift');
        }

        hideContextOptions('Shift/Job Order');

        // PE-928 - Hide options from Employee Request
        hideContextOptions('Employee Request');

        // Rename Find Resource to Find Replacement in Site View
        let selectedShifts = getSelectedShifts();
		let onlyDemandsSelected = true;
        selectedShifts.forEach(selectedShift => {
            // console.log('selectedShift.contact: ' + selectedShift.contact);
			if (selectedShift.contact != '*') { //One of the selected Shifts was not a "requirement"
				onlyDemandsSelected = false;
                // console.log('onlyDemandsSelected: ' + onlyDemandsSelected);
			}
		});
        let selectedShiftDemands = getSelectedShiftDemands();
        selectedShiftDemands.forEach(selectedShiftDemand => {
            // console.log('selectedShiftDemand.contact: ' + selectedShiftDemand.contact);
			onlyDemandsSelected = true;
            // console.log('onlyDemandsSelected: ' + onlyDemandsSelected);
		});

        if (view.type == 2 && !onlyDemandsSelected){
            // console.log('Call renameMenuItems');
			renameMenuItems('Find Resource')
		}
        if (view.type == 2 && onlyDemandsSelected){
            // console.log('Call renameMenuItems');
			renameMenuItems('Find Replacement')
		}

        // PE-1030 - Hide Copy / Open Shift / Auto Assign for Shifts
        if (!onlyDemandsSelected){
            // console.log('Hide Copy / Open Shift / Auto Assign');
			hideContextOptions('Shift Options');
		}
    }
}

function openMultiDetail(){
	let params = {'shiftId':selectedItems[0].getAttribute("id")};
	embedFlowDynamically('mainTable', 'Configure_Shift_Bundles', params);
}

function openMultiResolve(){
    let params = {'shiftId':selectedItems[0].getAttribute("id")};
    embedFlowDynamically('mainTable', 'Resolve_Job_Role', params);
}

function openInviteWorkers(){
	let demandIds = [];
	for (var i = 0; i < selectedItems.length; i++) {
		demandIds.push(selectedItems[i].getAttribute("id"));
	}
	let params = {'demandIds':demandIds};
	embedFlowDynamically('mainTable', 'Invite_Workers_Custom', params);
}

/**
 * Creates an iframe dynamically and appends it to a target container.
 * @param {string} containerId - The ID of the div to hold the iframe.
 * @param {string} flowApiName - The API name of the Flow.
 * @param {object} inputParams - Object containing input variables.
 */
function embedFlowDynamically(containerId, flowApiName, inputParams) {
    const container = document.getElementById(containerId);
    if (!container) {
        console.error('Target container not found: ' + containerId);
        return;
    }

    // 1. Construct the Flow URL
    let flowUrl = '/flow/' + flowApiName;
    const queryParams = [];
    for (const key in inputParams) {
        if (inputParams.hasOwnProperty(key)) {
			if (Array.isArray(inputParams[key])) {
				// Need to encapsulate each value in quotes
                inputParams[key].forEach(value => {
                    queryParams.push(encodeURIComponent(key) + '=' + encodeURIComponent(value));
                });			    
			} else {
                queryParams.push(encodeURIComponent(key) + '=' + encodeURIComponent(inputParams[key]));
			}
        }
    }
	//const returnUrl = window.location.protocol + '//' + window.location.host + window.location.pathname + '?flowDone=1';
    const returnUrl = flowUrl + '?flowDone=1';
    if (queryParams.length > 0) {
        flowUrl += '?' + queryParams.join('&') + '&retURL=' + encodeURIComponent(returnUrl);
    } else {
	    flowUrl += '?retURL=' + encodeURIComponent(returnUrl);
	}

    // 2. Create the Iframe Element
    const iframe = document.createElement('iframe');
    iframe.src = flowUrl;
    
    // 3. Apply Overlay Styles
    Object.assign(iframe.style, {
        position: 'fixed',
        top: '50%',
        left: '50%',
        transform: 'translate(-50%, -50%)', // Perfectly centers the element
        width: '80%',
        height: '80vh',
        zIndex: '9999', // Ensure it sits on top of everything
        border: 'none',
        borderRadius: '8px',
        boxShadow: '0 4px 20px rgba(0,0,0,0.3)',
        backgroundColor: 'white'
    });

    // 4. (Optional) Add a Backdrop 
    // This dims the background while the flow is active
    const backdrop = document.createElement('div');
    Object.assign(backdrop.style, {
        position: 'fixed',
        top: '0',
        left: '0',
        width: '100vw',
        height: '100vh',
        backgroundColor: 'rgba(0, 0, 0, 0.5)',
        zIndex: '9998'
    });

			
	// 5. Monitor iframe for end of flow
	let lastPage = false;
    const checkInterval = setInterval(function() {
        try {
            const currentHTML = iframe.contentWindow.document.body.innerHTML;
			// Check if the last page has been recahed whicg contains the Finish button
			if (!lastPage && currentHTML.includes('flow-button__FINISH')) {
				lastPage = true;
		    // Check if the Finish button has been pressed i.e. there are no navgation buttons 
			} else if (lastPage && !currentHTML.includes('flow-button__FINISH')
				&& !currentHTML.includes('flow-button__NEXT')
			    && !currentHTML.includes('flow-button__PREVIOUS')) {
                // A. Stop the timer so we don't keep checking
                clearInterval(checkInterval);

                // B. Remove the iframe
                container.removeChild(iframe);
                container.removeChild(backdrop);
			}
        } catch (e) {
                    // This block handles Cross-Origin errors.
                    // If the flow redirects to a different domain, the browser blocks access
                    // to location.href. We ignore this and keep polling, assuming
                    // the flow is still running or loading.
        }
    }, 1000);

    // Close the flow when clicking the backdrop
    backdrop.onclick = () => {
		// A. Stop the timer so we don't keep checking
		clearInterval(checkInterval);
        container.removeChild(iframe);
        container.removeChild(backdrop);
    };
	
    // 6. Append elements
    container.appendChild(backdrop);
    container.appendChild(iframe);
}

function hideContextOptions(menuType){
    // note that Cancel / Employee Request / Advanced are Groups so have a different syntax to check
    // example - contextItems[i].innerHTML.startsWith('Advanced')
    var itemsToRemove;
    var menusToRemove;
    if (menuType == 'Cancel'){
        itemsToRemove = [];
        menusToRemove =['Cancel'];
    } 
    if (menuType == 'Shift/Job Order'){
        itemsToRemove = ['New Job Order','New Shift','Open Shift'];
        menusToRemove =[];
    }
    if (menuType == 'Employee Request'){
        itemsToRemove = ['Available','Request Shift','Unavailable','Other'];
        menusToRemove =[];
    }
    if (menuType == 'Shift Options'){
        itemsToRemove = [];
        menusToRemove =['Open Shift','Auto Assign','Copy'];
    }
    if (menuType == 'NonStaffShift'){
        itemsToRemove = ['Edit', 'New Contact', 'New Site'];
        menusToRemove = [];
    }

    let contextItems = document.querySelectorAll('.sirenumContextMenuItem');

    for(let i = 0; i < contextItems.length; i++){
         if(itemsToRemove.includes(contextItems[i].innerHTML)) {
            contextItems[i].style.display = "none";
        }
        for(let j = 0; j < menusToRemove.length; j++){
            if(contextItems[i].innerHTML.startsWith(menusToRemove[j])){
                contextItems[i].style.display = "none";
            }
        }
    }
}

function renameMenuItems(menuType){
    // console.log('In renameMenuItems');
    var itemsToRename;
    var renameItems = ['Find Resource'];
    var renameBack = ['Find Replacement'];
    let contextItems = document.querySelectorAll('.sirenumContextMenuItem');
    if (menuType == 'Find Resource'){
        itemsToRename = renameItems;
        for(let i = 0; i < contextItems.length; i++){
            // console.log('i:' + i);
            if(itemsToRename.includes(contextItems[i].innerHTML)) {
                // console.log('Find Resource found');
                contextItems[i].innerHTML = "Find Replacement";
            }
        }
    }
    if (menuType == 'Find Replacement'){
        itemsToRename = renameBack;
        for(let i = 0; i < contextItems.length; i++){
            // console.log('i:' + i);
            if(itemsToRename.includes(contextItems[i].innerHTML)) {
                // console.log('Find Resource found');
                contextItems[i].innerHTML = "Find Resource";
            }
        }
    }

    // for(let i = 0; i < contextItems.length; i++){
    //     // console.log('i:' + i);
    //     if(itemsToRename.includes(contextItems[i].innerHTML)) {
    //         // console.log('Find Resource found');
    //         contextItems[i].innerHTML = "Find Replacement";
    //     }
    // }
}