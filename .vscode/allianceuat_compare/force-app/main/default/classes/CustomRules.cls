/**
 * Custom Rules class to handle H&S Rules which cannot be implemented via standard configuration
 *
 * Rules:
 * (1) Raise an alert if a given Shift's worker has ZERO of the Tickets in the Shift's Skill/Attribute bundle
 * (2) Raise an alert if a given Shift's worker has ZERO of the Tickets defined int he Shift's Role bundle
 */
global without sharing class CustomRules implements sirenum.SirenumEngineExtension {
    global List<sirenum__LogEntry__c> execute(List<sirenum.SirenumEngine.Shift> shifts) {
        List<sirenum__LogEntry__c> alerts = new List<sirenum__LogEntry__c>(); //List of alerts to return
        List<Id> contactIds = new List<Id>(); //Ids of contacts whom there are shifts for in the context
        List<Id> ticketTypeIds = new List<Id>(); //List of TicketTypes (Competencies) which are required for context shift(s). Assumed to be the same for ALL context Shift(s).

        //Build list of applicable Worker Ids
        List<sirenum.SirenumEngine.Shift> shiftsToCheck = new List<sirenum.SirenumEngine.Shift>();
        for (sirenum.SirenumEngine.Shift shift : shifts) {
            if (shift.isChecked) {
                shiftsToCheck.add(shift);
                contactIds.add(shift.shift.sirenum__Contact__c);
            }
        }

        //If no shifts to check, return empty list
        if (shiftsToCheck.isEmpty()){
            return new List<sirenum__LogEntry__c>();
        }

        //Build lists of bundle items
        Id skillBundleId = shifts[0].shift.Skill_Attribute_OR_Bundle__c;
        Id roleBundleId = shifts[0].shift.Role_OR_Bundle__c;

        List<sirenum__CompetencyBundleItem__c> bundleItems = [
                SELECT sirenum__Competency__c, sirenum__CompetencyBundle__c
                FROM sirenum__CompetencyBundleItem__c
                WHERE sirenum__CompetencyBundle__c = :skillBundleId
                OR sirenum__CompetencyBundle__c = :roleBundleId
        ];

        Integer skillBundleTicketCount = 0;
        Integer roleBundleTicketCount = 0;

        //Convert list of comp bundle items to required TicketType (Competency) Ids
        for (sirenum__CompetencyBundleItem__c bundleItem : bundleItems) {
            ticketTypeIds.add(bundleItem.sirenum__Competency__c);
            if (bundleItem.sirenum__CompetencyBundle__c == skillBundleId) {
                skillBundleTicketCount++;
            } else {
                roleBundleTicketCount++;
            }
        }

        //Get all instances of required tickets being assigned to relevant contacts
        List<sirenum__Ticket__c> tickets = [
                SELECT sirenum__Owner__c, sirenum__TicketType__c, sirenum__TicketType__r.Name, Competency_Master_Category__c
                FROM sirenum__Ticket__c
                WHERE sirenum__Owner__c IN :contactIds
                AND sirenum__Valid__c = true
                AND sirenum__TicketType__c IN :ticketTypeIds
        ];

        //Map tickets found by contactId; separate maps for Skill tickets and Role tickets
        Map<Id, List<sirenum__Ticket__c>> skillTicketsByContactId = new Map<Id, List<sirenum__Ticket__c>>();
        Map<Id, List<sirenum__Ticket__c>> roleTicketsByContactId = new Map<Id, List<sirenum__Ticket__c>>();

        for (sirenum__Ticket__c ticket : tickets){
            if (ticket.Competency_Master_Category__c == 'Role'){
                List<sirenum__Ticket__c> ticketsForContact = roleTicketsByContactId.get(ticket.sirenum__Owner__c);
                if (ticketsForContact == null){
                    roleTicketsByContactId.put(ticket.sirenum__Owner__c, new List<sirenum__Ticket__c>{ticket});
                } else {
                    ticketsForContact.add(ticket);
                }
            } else if (ticket.Competency_Master_Category__c == 'Skill'){
                List<sirenum__Ticket__c> ticketsForContact = skillTicketsByContactId.get(ticket.sirenum__Owner__c);
                if (ticketsForContact == null){
                    skillTicketsByContactId.put(ticket.sirenum__Owner__c, new List<sirenum__Ticket__c>{ticket});
                } else {
                    ticketsForContact.add(ticket);
                }
            }

        }

        //Loop shifts to be checked, creating Alert(s) if the assigned Contact has NONE of the required Skills and/or Roles
        for (sirenum.SirenumEngine.Shift shift : shiftsToCheck){
            //List of tickets found for contact; will either be Role or Skill
            List<sirenum__Ticket__c> ticketsForContact;            

            //If the number of Skill tickets found for the Contact is not >= 1, raise an alert
            if (skillBundleId != null) {
                ticketsForContact = skillTicketsByContactId.get(shift.shift.sirenum__Contact__c);
                if (ticketsForContact == null || ticketsForContact.isEmpty()) {
                    
                    alerts.add(new sirenum__LogEntry__c(
                            sirenum__Shift__c = shift.shift.Id,
                            sirenum__Shift__r = shift.shift,
                            sirenum__Contact__c = shift.shift.sirenum__Contact__c,
                            sirenum__Category__c = 'Bundle Competencies',
                            sirenum__Severity__c = 'Fatal',
                            sirenum__Details__c = String.format(Label.skill_bundle_alert, new List<Object>{
                                    String.valueOf(skillBundleTicketCount)
                            })
                    ));
                }
            }
            if (roleBundleId != null) {
                //If the number of Role tickets found for the Contact is not >= 1, raise an alert
                ticketsForContact = roleTicketsByContactId.get(shift.shift.sirenum__Contact__c);
                if (ticketsForContact == null || ticketsForContact.isEmpty()) {
                    alerts.add(new sirenum__LogEntry__c(
                            sirenum__Shift__c = shift.shift.Id,
                            sirenum__Shift__r = shift.shift,
                            sirenum__Contact__c = shift.shift.sirenum__Contact__c,
                            sirenum__Category__c = 'Bundle Competencies',
                            sirenum__Severity__c = 'Fatal',
                            sirenum__Details__c = String.format(Label.role_bundle_alert, new List<Object>{
                                    String.valueOf(roleBundleTicketCount)
                            })
                    ));
                }
            }
        }

        //Pass back list of alerts to engine
        return alerts;
    }
}