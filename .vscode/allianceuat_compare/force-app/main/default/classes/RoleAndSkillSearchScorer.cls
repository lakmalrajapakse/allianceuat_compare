/**
 * Custom Scorer class to handle visibility of Skills and Roles required for a Shift (via custom Skill Bundle and
 * Role Bundle lookups) in Logic Services Results display. A flat score of 0.01 is applied if there are ANY required
 * skills detected - and the same goes for Roles. This is to guarantee that the Score (if created) is never hidden.
 */
global class RoleAndSkillSearchScorer implements sirenum.WorkerSearchScorer {

    global Set<String> getRequiredShiftFields() {
        return new Set<String> {'Skill_Attribute_OR_Bundle__c','Role_OR_Bundle__c'};
    }

    global Set<String> getRequiredWorkerFields() {
        return new Set<String> {};
    }

    global List<sirenum.WorkerSearchScore> scoreWorkers(sirenum.WorkerSearchScorerContext context) {
        List<sirenum.WorkerSearchScore> scores = new List<sirenum.WorkerSearchScore>();
        List<sirenum__Shift__c> shifts = context.getShiftTemplates();

        // Build lists of bundle items
        Id skillBundleId = shifts[0].Skill_Attribute_OR_Bundle__c;
        Id roleBundleId = shifts[0].Role_OR_Bundle__c;

        // If either a Role or Skill bundle is specified, continue
        if (skillBundleId != null || roleBundleId != null) {
            // Create a list of competency Ids which are in either the role or skill bundle
            List<sirenum__CompetencyBundleItem__c> bundleItems = [
                    SELECT sirenum__Competency__c
                    FROM sirenum__CompetencyBundleItem__c
                    WHERE sirenum__CompetencyBundle__c = :skillBundleId
                    OR sirenum__CompetencyBundle__c = :roleBundleId
            ];
            List<Id> competencyIds = new List<Id>();
            for (sirenum__CompetencyBundleItem__c bundleItem : bundleItems) {
                competencyIds.add(bundleItem.sirenum__Competency__c);
            }

            // Retrieve all Tickets for all workers being scored, for competencies in the Skill or Role bundle
            List<sirenum__Ticket__c> tickets = [
                    SELECT sirenum__Owner__c, sirenum__TicketType__c, sirenum__TicketType__r.Name, Competency_Master_Category__c
                    FROM sirenum__Ticket__c
                    WHERE sirenum__Owner__c IN :context.getWorkersById().keySet()
                    AND sirenum__Valid__c = true
                    AND sirenum__TicketType__c IN :competencyIds
            ];

            // Map tickets found by contactId; separate maps for Skill tickets and Role tickets
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

            // Loop workers being scored, creating up to two Score entries to summarise:
            // (a) Role tickets present which are required by Role bundle
            // (b) Skill tickets present which are required by Skill bundle
            // Recording Roles and Skills separately provides more characters to display ticket names
            for (Id workerId : context.getWorkersById().keySet()) {
                List<sirenum__Ticket__c> workerRoleTickets = roleTicketsByContactId.get(workerId);
                if (workerRoleTickets != null) {
                    List<String> competencies = new List<String>();
                    for (sirenum__Ticket__c workerTicket : workerRoleTickets) {
                        competencies.add(workerTicket.sirenum__TicketType__r.Name);
                    }
                    scores.add(new sirenum.WorkerSearchScore()
                            .withWorkerId(workerId)
                            .withScore(0.01)
                            .withDescription(String.format('For having Role competencies: {0}', new List<String>{String.join(competencies, ', ')}))
                    );
                }
                List<sirenum__Ticket__c> workerSkillTickets = skillTicketsByContactId.get(workerId);
                if (workerSkillTickets != null) {
                    List<String> competencies = new List<String>();
                    for (sirenum__Ticket__c workerTicket : workerSkillTickets) {
                        competencies.add(workerTicket.sirenum__TicketType__r.Name);
                    }
                    scores.add(new sirenum.WorkerSearchScore()
                            .withWorkerId(workerId)
                            .withScore(0.01)
                            .withDescription(String.format('For having Skill competencies: {0}', new List<String>{String.join(competencies, ', ')}))
                    );
                }
            }
        }

        return scores;
    }
}