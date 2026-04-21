//Create an event when a a new scheduling miniform is opened
if(window.newSchedulingMiniForm){
    let newSchedulingMiniForm_old = newSchedulingMiniForm;
    newSchedulingMiniForm = (objectsBeingEdited, sObjectName, anchor, saveRecordFunction, layout, readonly) => {
        newSchedulingMiniForm_old(objectsBeingEdited, sObjectName, anchor, saveRecordFunction, layout, readonly);

        if(objectsBeingEdited){
            let documentBody = document.querySelector('body');

            //Used to notify other components that the miniform has been opened
            const miniformOpenEvent = new CustomEvent('newSchedulingMiniForm', { detail: {
                objectsBeingEdited: objectsBeingEdited,
                sObjectName: sObjectName,
                anchor: anchor,
                saveRecordFunction: saveRecordFunction,
                layout: layout,
                readonly: readonly
            }});

            documentBody.dispatchEvent(miniformOpenEvent);
        }
    }
}