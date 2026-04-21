public with sharing class AttachEmailToObject {
    public static void attachEmail(Messaging.InboundEmail email, String objectId) {
        
        System.debug(LOGGINGLEVEL.ERROR, 'String.join(email.toAddresses, ;): ' + String.join(email.toAddresses, ';'));
        EmailMessage newEmail = new EmailMessage(
            HtmlBody = email.htmlBody,
            TextBody = email.plainTextBody,
            Subject = email.subject,
            FromName = email.fromName,
            FromAddress = email.fromAddress,
            ToAddress = email.toAddresses[0],
            Incoming = true,
            Status = '3',
            RelatedToID = objectId
        );

        insert newEmail;

    }
}