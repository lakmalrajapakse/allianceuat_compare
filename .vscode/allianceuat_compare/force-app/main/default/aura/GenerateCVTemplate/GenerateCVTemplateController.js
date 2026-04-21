({  
    
    onInit : function( component, event, helper ) {    
        
        let action = component.get( 'c.createCVSingle' );  
        action.setParams({  
            recordId: component.get( 'v.recordId' )
        });  
        action.setCallback(this, function(response) {  
            let state = response.getState();  
            if ( state === 'SUCCESS' ) {  

                let showToast = $A.get( 'e.force:showToast' );
                showToast.setParams({
                    title : 'Documents created',
                    message : 'Documents created successfully',
                    type : 'success',
                    mode : 'sticky'
                });
                showToast.fire();
                
                $A.get('e.force:closeQuickAction').fire();  
                $A.get('e.force:refreshView').fire();   
                
            }  else {
                
                let showToast = $A.get( 'e.force:showToast' );
                showToast.setParams({
                    title : 'Error saving documents',
                    message : 'An error occured saving documents, please contact an administrator' ,
                    type : 'error',
                    mode : 'sticky'
                });
                showToast.fire();
                
            }
        });  
        $A.enqueueAction( action );         
        
    }
    
})