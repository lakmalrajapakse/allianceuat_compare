/*
 * Add Custom Filters in this file
 */

ObjectFiltering.registerFilter({
    
        name: "schedule-status",
        label: "Schedule Status",
        items: function () {
            let items = [];

            // // items.push({name: 'Accepted', label: 'Accepted'});
            // items.push({name: 'Allocated', label: 'Allocated'});    
            // // items.push({name: 'Awaiting Allocation', label: 'Awaiting Allocation'});
            // // items.push({name: 'Cancelled', label: 'Cancelled'});
            // items.push({name: 'Completed', label: 'Completed'});
            // // items.push({name: 'Reconfirmed', label: 'Reconfirmed'});
            // // items.push({name: 'Rejected', label: 'Rejected'});
            // items.push({name: 'Confirmed', label: 'Confirmed'});
            // items.push({name: 'In a Cancelled Shift', label: 'In a Cancelled Shift'});
            // items.push({name: 'Name Given', label: 'Name Given'});
            // items.push({name: 'Reconfirm', label: 'Reconfirm'});
            // items.push({name: 'Reconfirm with Employee', label: 'Reconfirm with Employee'});
            // items.push({name: 'Reconfirm with Facility', label: 'Reconfirm with Facility'});
            // items.push({name: 'Shift Cancelled', label: 'Shift Cancelled'});
            // items.push({name: 'Shift Cancelled Filled', label: 'Shift Cancelled Filled'});
            // // items.push({name: 'Unable to Fill', label: 'Unable to Fill'});
            // items.push({name: 'Waiting', label: 'Waiting'});

            let scheduleStatuses = {};

        shifts.forEach(shift => {
            if (shift.params &&
                shift.params.Schedule_Display_Status__c &&
                !scheduleStatuses[shift.Schedule_Display_Status__c]) {
                    scheduleStatuses[shift.params.Schedule_Display_Status__c] =
                    shift.params.Schedule_Display_Status__c;
            }
            // console.log('filters.js shift.params?.VMS_Source__c: ' + shift.params?.VMS_Source__c);
        });

        items = Object.keys(scheduleStatuses).map(id => {
            return {
                name: id,
                label: scheduleStatuses[id]
            }
        }).sort(function(a, b){return a-b;});

            // console.log('registerFilter items: ' + items);
            
            // Add to the list of items
            return items;
        },
        matchesObjectType: function (objectType) {
            // console.log('matchesObjectType objectType: ' + objectType);
            return objectType === ObjectFiltering.ObjectType.SHIFT;
        },
        matchesItems: function (scheduleObject, filterItems) {
            // console.log('matchesItems scheduleObject: ' + scheduleObject + ' / filterItems: ' + filterItems);
            return filterItems.some(filterItem => {
                // console.log('matchesItems scheduleObject.params.Schedule_Status__c: ' + scheduleObject.params.Schedule_Status__c);
                // console.log('matchesItems filterItem.name: ' + filterItem.name);
                // return '' + scheduleObject.params.Schedule_Status__c === filterItem.name;
                return '' + scheduleObject.params.Schedule_Display_Status__c === filterItem.name;
            });
        }

});

// ObjectFiltering.registerFilter({
    
//     name: "branch",
//     label: "Branch",
//     items: function () {
//         let items = [];
//         let branches = {};

// 		shifts.forEach(shift => {
// 			if (shift.params &&
// 				shift.params.Branch__c &&
// 				!branches[shift.Branch__c]) {
//                     branches[shift.params.Branch__c] =
// 					shift.params.Branch_Name__c;
// 			}
//             // console.log('filters.js shift.params?.Branch__c: ' + shift.params?.Branch__c);
//             // console.log('shift.params?.Branch__r.Name: ' + shift.params?.Branch__r.Name);
//             // console.log('filters.js shift.params?.Branch_Name__c: ' + shift.params?.Branch_Name__c);
// 		});

// 		items = Object.keys(branches).map(id => {
// 			return {
// 				name: id,
// 				label: branches[id]
// 			}
// 		}).sort(function(a, b){return a-b;});

//         // console.log('registerFilter items: ' + items);
        
//         // Add to the list of items
//         return items;
//     },
//     matchesObjectType: function (objectType) {
//         // console.log('matchesObjectType objectType: ' + objectType);
//         return objectType === ObjectFiltering.ObjectType.SHIFT;
//     },
//     matchesItems: function (scheduleObject, filterItems) {
//         // console.log('matchesItems scheduleObject: ' + scheduleObject + ' / filterItems: ' + filterItems);
//         return filterItems.some(filterItem => {
//             // console.log('matchesItems scheduleObject.params.Schedule_Status__c: ' + scheduleObject.params.Schedule_Status__c);
//             // console.log('matchesItems filterItem.name: ' + filterItem.name);
//             return '' + scheduleObject.params.Branch__c === filterItem.name;
//         });
//     }
// });

ObjectFiltering.registerFilter({

    name: "vms_source",
    label: "VMS Source",
    items: function () {
        let items = [];

        // items.push({name: 'Accepted', label: 'Accepted'});

        let vmsSources = {};

        shifts.forEach(shift => {
            if (shift.params &&
                shift.params.VMS_Source__c &&
                !vmsSources[shift.VMS_Source__c]) {
                    vmsSources[shift.params.VMS_Source__c] =
                    shift.params.VMS_Source__c;
            }
            // console.log('filters.js shift.params?.VMS_Source__c: ' + shift.params?.VMS_Source__c);
        });

        items = Object.keys(vmsSources).map(id => {
            return {
                name: id,
                label: vmsSources[id]
            }
        }).sort(function(a, b){return a-b;});

        // console.log('registerFilter items: ' + items);
        
        // Add to the list of items
        return items;
    },
    matchesObjectType: function (objectType) {
        // console.log('matchesObjectType objectType: ' + objectType);
        return objectType === ObjectFiltering.ObjectType.SHIFT;
    },
    matchesItems: function (scheduleObject, filterItems) {
        // console.log('matchesItems scheduleObject: ' + scheduleObject + ' / filterItems: ' + filterItems);
        return filterItems.some(filterItem => {
            // console.log('matchesItems scheduleObject.params.Schedule_Status__c: ' + scheduleObject.params.Schedule_Status__c);
            // console.log('matchesItems filterItem.name: ' + filterItem.name);
            return '' + scheduleObject.params.VMS_Source__c === filterItem.name;
        });
    }
});

ObjectFiltering.registerFilter({

    name: "shift_type",
    label: "Shift Type",
    items: function () {
        let items = [];

        let shiftTypes = {};

        shifts.forEach(shift => {
            if (shift.params &&
                shift.params.Shift_Type__c &&
                !shiftTypes[shift.Shift_Type__c]) {
                    shiftTypes[shift.params.Shift_Type__c] =
                    shift.params.Shift_Type__c;
            }
            // console.log('filters.js shift.params?.VMS_Source__c: ' + shift.params?.VMS_Source__c);
        });

        items = Object.keys(shiftTypes).map(id => {
            return {
                name: id,
                label: shiftTypes[id]
            }
        }).sort(function(a, b){return a-b;});

        // console.log('registerFilter items: ' + items);
        
        // Add to the list of items
        return items;
    },
    matchesObjectType: function (objectType) {
        // console.log('matchesObjectType objectType: ' + objectType);
        return objectType === ObjectFiltering.ObjectType.SHIFT;
    },
    matchesItems: function (scheduleObject, filterItems) {
        // console.log('matchesItems scheduleObject: ' + scheduleObject + ' / filterItems: ' + filterItems);
        return filterItems.some(filterItem => {
            // console.log('matchesItems scheduleObject.params.Schedule_Status__c: ' + scheduleObject.params.Schedule_Status__c);
            // console.log('matchesItems filterItem.name: ' + filterItem.name);
            return '' + scheduleObject.params.Shift_Type__c === filterItem.name;
        });
    }
});

ObjectFiltering.registerFilter({
  name: "approval_status",
  label: "Approval Status",
  items: function () {
    return [
      { name: "Approved", label: "Approved" },
      { name: "Unapproved", label: "Unapproved" }
    ];
  },
  matchesObjectType: function (objectType) {
    return objectType === ObjectFiltering.ObjectType.SHIFT;
  },
  matchesItems: function (scheduleObject, filterItems) {
    const approvedAt = scheduleObject?.params?.sirenum__Approved_By_Client__c;
    return filterItems.some(f => {
      if (f.name === "Approved") return !!approvedAt;      // has a value
      if (f.name === "Unapproved") return !approvedAt;     // null/undefined/empty
      return false;
    });
  }
});

// PE-1379 Job Type
ObjectFiltering.registerFilter({
    name: "job_type",
    label: "Job Type",
    items: function () {
        // console.log('filters.js Job Type Start ');
        let items = [];

        let jobTypes = {};
        // console.log('filters.js shift.params: ' + shift.params);

        shifts.forEach(shift => {
            // console.log('filters.js shift.params: ' + JSON.stringify(shift.params));
            if (shift.params &&
                shift.params.Job_Type_Name__c &&
                !jobTypes[shift.Job_Type_Name__c]) {
                    jobTypes[shift.params.Job_Type_Name__c] =
                    shift.params.Job_Type_Name__c;
            }            
        });

        // console.log('filters.js jobTypes: ' + JSON.stringify(jobTypes));

        items = Object.keys(jobTypes).map(id => {
            return {
                name: id,
                label: jobTypes[id]
            }
        }).sort(function(a, b){return a-b;});
        
        // Add to the list of items
        return items;
    },
    matchesObjectType: function (objectType) {
        // console.log('matchesObjectType objectType: ' + objectType);
        return objectType === ObjectFiltering.ObjectType.SHIFT;
    },
    matchesItems: function (scheduleObject, filterItems) {
        return filterItems.some(filterItem => {
            // console.log('matchesItems filterItem.name: ' + filterItem.name);
            return '' + scheduleObject.params.Job_Type_Name__c === filterItem.name;
        });
    }
});


// PE-1379 Employee Request Type
ObjectFiltering.registerFilter({
    name: "emp_request",
    label: "Employee Request (Alliance)",
    items: function () {
        // console.log('filters.js Employee Request Start ');
        let items = [];

        let empRequests = {};
        // console.log('filters.js shift.params: ' + shift.params);

        requests.forEach(request => {
            // console.log('filters.js requests.params: ' + JSON.stringify(request.params));
            if (request.params &&
                request.params.sirenum__Type__c &&
                !empRequests[request.sirenum__Type__c]) {
                    empRequests[request.params.sirenum__Type__c] =
                    request.params.sirenum__Type__c;
            }
            // console.log('filters.js request.params?.Job_Type__c: ' + request.params?.sirenum__Type__c);
        });

        // console.log('filters.js empRequests: ' + JSON.stringify(empRequests));

        items = Object.keys(empRequests).map(id => {
            return {
                name: id,
                label: empRequests[id]
            }
        }).sort(function(a, b){return a-b;});
        
        // Add to the list of items
        return items;
    },
    matchesObjectType: function (objectType) {
        // console.log('matchesObjectType objectType: ' + objectType);
        return objectType === ObjectFiltering.ObjectType.REQUEST;
    },
    matchesItems: function (scheduleObject, filterItems) {
        return filterItems.some(filterItem => {
            // console.log('matchesItems filterItem.name: ' + filterItem.name);
            return '' + scheduleObject.params.sirenum__Type__c === filterItem.name;
        });
    }
});
// ObjectFiltering.registerFilter('vms_source');

// EXAMPLE AND/OR FILTER

// Add an AND filter for tickets
// Custom filter to only select contacts that have all selected tickets
ObjectFiltering.registerFilter({
    name: 'ticketAll',
    label: () => Label.Tickets + ' (AND)',
    items: function () {
        return tickets.map(option => {
            return {
                name: option.id,
                label: option.name
            };
        }).sort((a, b) =>
            // Put the 'null' item at the end (the code leverage implicit casting of boolean to number,
            // true -> 1 and false -> 0)
            ((a.name === '*') - (b.name === '*')) || a.label.localeCompare(b.label)
        );
    },
    matchesObjectType: function (objectType) {
        return objectType === ObjectFiltering.ObjectType.CONTACT;
    },
    matchesItems: function (scheduleObject, filterItems) {
        // The requirements row (id of *) and any contact with the one or more selected tickets match
        return filterItems.every(filterItem => {
            return scheduleObject.id === "*" || (scheduleObject.tickets && scheduleObject.tickets.includes(filterItem.name));
        });
    }
});

// // Can be removed once fix is deployed in patch and installed.
if (window.ObjectFiltering) {
    ObjectFiltering.registerFilter({
        name: 'ticket',
        label: () => Label.Tickets + ' (OR)',
        items: function () {
            return tickets.map(option => {
                return {
                    name: option.id,
                    label: option.name
                };
            }).sort((a, b) =>
                // Put the 'null' item at the end (the code leverage implicit casting of boolean to number,
                // true -> 1 and false -> 0)
                ((a.name === '*') - (b.name === '*')) || a.label.localeCompare(b.label)
            );
        },
        matchesObjectType: function (objectType) {
            return objectType === ObjectFiltering.ObjectType.CONTACT;
        },
        matchesItems: function (scheduleObject, filterItems) {
            // The requirements row (id of *) and any contact with the one or more selected tickets match
            return filterItems.some(filterItem => {
                return scheduleObject.id === "*" || (scheduleObject.tickets && scheduleObject.tickets.includes(filterItem.name));
            });
        }
    });
}

// PE-1379 - Filter for Contacts with zero shifts 
ObjectFiltering.registerFilter({
    
        name: "candidate-zeroshifts",
        label: "Candidates with Zero Shifts",
        items: function () {
            let items = [];

            let candidatesWithShifts = {};
            let candidatesNoShifts = [];

        shifts.forEach(shift => {
            // console.log('filters.js shift.params: ' + JSON.stringify(shift.params));
            // console.log('filters.js candidate with no Shifts shift.contact: ' + shift.contact);
            if (shift.contact &&
                shift.contact !== "*" &&
                shift.params?.sirenum__Cancelled__c === false &&
                !candidatesWithShifts[shift.contact]) {
                    candidatesWithShifts[shift.contact] =
                    shift.contact;
            }
            // console.log('filters.js shift.params?.sirenum__Contact__c: ' + shift.params?.sirenum__Contact__c);
            // console.log('filters.js filters.js candidate with no Shifts candidatesWithShifts: ' + JSON.stringify(candidatesWithShifts));
            // console.log('filters.js shift.contact: ' + shift.contact);
        });

        console.log('filters.js candidate with no Shifts candidatesWithShifts complete: ' + JSON.stringify(candidatesWithShifts));

        contacts.forEach(contact => {
            // console.log('filters.js contact: ' + JSON.stringify(contact));
            console.log('filters.js contact.id: ' + contact.id + ' / contact.name: ' + contact.name);
            // console.log('filters.js contact.id: ' + contact.id);
            // console.log('filters.js contact.name: ' + contact.name);
            if (contact.id &&
                contact.id !== "*" &&
                !candidatesWithShifts[contact.id]) {
                    // console.log('filters.js test without candidatesNoShifts in contacts if clause : ' + contact.id);
                    // console.log('filters.js test without candidatesNoShifts in contacts if clause : ' + contact.name);
                    candidatesNoShifts.push(contact.id);
                    // candidatesNoShifts[contact.id] = contact.name;
                }
            console.log('filters.js candidate with no Shifts candidatesNoShifts: ' + JSON.stringify(candidatesNoShifts));
        });

        items = // Object.keys(candidatesNoShifts).map(id => {
            [{
                // name: id,
                // label: candidatesNoShifts[id]
                name: 'Candidates with no Shifts',
                label: 'Candidates with no Shifts',
                candidateList: candidatesNoShifts
            }];
        // }).sort(function(a, b){return a-b;});

            // console.log('filters.js candidate with no Shifts items: ' + JSON.stringify(items));
            
            // Add to the list of items
            return items;
        },
        matchesObjectType: function (objectType) {
            // console.log('matchesObjectType objectType: ' + objectType);
            return objectType === ObjectFiltering.ObjectType.CONTACT;
        },
        matchesItems: function (scheduleObject, filterItems) {
            // console.log('matchesItems scheduleObject: ' + JSON.stringify(scheduleObject) + ' / filterItems: ' + JSON.stringify(filterItems));
           

            if (!filterItems || filterItems.length === 0) {
                return false;
            }

            return filterItems[0].candidateList.some(filterItem => {
                
                return '' + scheduleObject.id === filterItem;
                
            });
        }

});