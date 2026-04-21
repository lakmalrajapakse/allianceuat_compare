global without sharing class SendEmailReminderToConsultant {

    // ===== Invocable Request =====
    global class Request {
        @InvocableVariable(required=true)
        global Id templateId;

        @InvocableVariable(required=true)
        global String emailAddress;

        @InvocableVariable(required=true)
        global Id whatId;
    }

    // ===== Invocable Response =====
    global class Response {
        @InvocableVariable
        global String status;
    }

    // ===== Invocable Method =====
    @InvocableMethod(label='Send Email Reminder To Consultant')
    global static List<Response> sendEmail(List<Request> requests) {

        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            Response res = new Response();

            try {
                //Fetch Email Template (validation purpose)
                EmailTemplate et = [
                    SELECT Id, Name
                    FROM EmailTemplate
                    WHERE Id = :req.templateId
                    LIMIT 1
                ];

                //Render Stored Email Template
                // whoId = null (as requested)
                Messaging.SingleEmailMessage email =
                    Messaging.renderStoredEmailTemplate(
                        req.templateId,
                        null,
                        req.whatId
                    );

                //Set To Address
                email.setToAddresses(new String[] { req.emailAddress});

                //Fetch Org-Wide Email Address for From Address
                 OrgWideEmailAddress owea = [
                    SELECT Id
                    FROM OrgWideEmailAddress
                    where purpose in ('UserSelectionAndDefaultNoReply', 'DefaultNoReply')
                    LIMIT 1
                 ];

                email.setOrgWideEmailAddressId(owea.Id);

                // Optional but recommended
                //email.setReplyTo(req.emailAddress);
                email.setUseSignature(false);
                email.setSaveAsActivity(false);

                //Send Email
                Messaging.sendEmail(
                    new Messaging.SingleEmailMessage[] { email }
                );

                res.status = 'SUCCESS';

            } catch (Exception e) {
                res.status = 'ERROR: ' + e.getMessage();
            }

            responses.add(res);
        }

        return responses;
    }
}