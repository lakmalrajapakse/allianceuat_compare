public with sharing class PDF_IDBadgeExtension {
    public TR1__Fixed_Assets__c record {get;set;}
    // public List<TR1__EmploymentHistory__c> empHists {get;set;}
    public List<b3o__Document_Submission__c> docSubmissions {get;set;}
    public List<b3o__Certificate__c> certs {get;set;}
    public List<ContentDocumentLink> docLinks {get;set;}

    public PDF_IDBadgeExtension(ApexPages.StandardController stdController) {
        System.debug(LOGGINGLEVEL.ERROR, stdController.getId());

        // this.record = [SELECT Id, 
        //     Name, 
        //     FirstName, 
        //     LastName, 
        //     aa_AHPRA_Number__c,
        //     aa_AHPRA_Number_2__c,
        //     aa_AHPRA_Number_3__c,
        //     MailingStreet, 
        //     MailingCity
        //     // More Fields Here 
        //     FROM Contact 
        //     WHERE Id = :stdController.getId()];

        this.record = [SELECT Id, 
            Preferred_Name__c,       
            Position__c, 
            AHPRA_Number__c,
            Assigned__c,
            Assigned__r.Name,
            Assigned__r.sirenum__Photo_ID__c,
            Assigned__r.PhotoURL,
            Branch__r.Branch_Name__c,
            Branch_Email__c,
            // // Branch__r.Branch_Phone_Number__c,
            Branch_Phone_Number__c,
            // // Branch__r.Branch_Phone_Number__c,
            Brand__c
            // // More Fields Here 
            FROM TR1__Fixed_Assets__c 
            WHERE Id = :stdController.getId()];

        // List<b3o__Document_Submission__c> docSubmissions  = [SELECT Id, 
        //     b3o__Contact__c, 
        //     b3o__Document__r.Name, 
        //     b3o__Form_Response__c, 
        //     b3o__Status__c,
        //     CreatedDate
        //     FROM b3o__Document_Submission__c 
        //     WHERE b3o__Contact__c = :this.record.Assigned__c
        //     AND b3o__Document__r.Name = 'Photo ID Form' 
        //     AND b3o__Status__c in ('Pending Review', 'Approved')
        //     ORDER BY CreatedDate DESC
        //     LIMIT 1];

        // this.docSubmissions = docSubmissions;

        List<b3o__Certificate__c> certs = [SELECT Id, 
            b3o__Contact__c, 
            Certificate_Type_Name__c, 
            Certificate_Status__c,
            b3o__Status__c,
            CreatedDate
            FROM b3o__Certificate__c 
            WHERE b3o__Contact__c = :this.record.Assigned__c
            AND Certificate_Type_Name__c = 'Photo ID'
            AND Certificate_Status__c in ('Pending Review',  'Complete', 'Final Review') 
            ORDER BY CreatedDate DESC
            LIMIT 1];

        this.certs = certs;

        // if (docSubmissions.size() > 0) {
        if (certs.size() > 0) {
            List<ContentDocumentLink> docLinks = [SELECT Id, 
                ContentDocumentId, 
                LinkedEntityId, 
                ContentDocument.FileType,
                ContentDocument.LatestPublishedVersionId
                FROM ContentDocumentLink 
                WHERE LinkedEntityId= :this.certs[0].Id 
                AND ContentDocument.FileType in ('JPG','PNG')];

            this.docLinks = docLinks;
        } else {
            this.docLinks = null;
        }
 
    }

    public String photoIdLink {
        get {
            // System.debug(LOGGINGLEVEL.ERROR, 'this.record.Assigned__r?.sirenum__Photo_ID__c: ' + this.record.Assigned__r?.sirenum__Photo_ID__c);
            // System.debug(LOGGINGLEVEL.ERROR, 'this.record.Assigned__r?.sirenum__Photo_ID__c: ' + this.record.Assigned__r?.PhotoURL);    
            // return '/servlet/servlet.FileDownload?file=' + this.record.Assigned__r?.sirenum__Photo_ID__c;
             // return '/servlet/servlet.FileDownload?file=0699t0000059GYvAAM';
            // return '/sfc/servlet.shepherd/version/download/0699t0000059GYvAAM';
            // return '/sfc/servlet.shepherd/version/download/0689t000005pQC5AAM';
            // return '/servlet/servlet.FileDownload?file=0689t000005pQC5AAM';
            // if (this.docLinks.size() > 0){

            if (this.docLinks.size() > 0){
            // if (this.docLinks != null){
                System.debug(LOGGINGLEVEL.ERROR, 'this?.docLinks.size(): ' + this?.docLinks.size());
                System.debug(LOGGINGLEVEL.ERROR, 'this?.docLinks: ' + this?.docLinks);
                // return '/servlet/servlet.FileDownload?file=' + this?.docLinks[0].ContentDocumentId;
                System.debug(LOGGINGLEVEL.ERROR, 'this?.docLinks[0].ContentDocument.LatestPublishedVersionId: ' + this?.docLinks[0].ContentDocument.LatestPublishedVersionId);
                return '/sfc/servlet.shepherd/version/download/' + this?.docLinks[0].ContentDocument.LatestPublishedVersionId;
            
            } else {
                return '';
            }
                     
        }
    }

    // public String ahpraNumbers {
    //     get {
    //         List<String> listARPHANumbers = new List<String>();
    //         String result = '';
    //         if (this.record.aa_AHPRA_Number__c != null) {
    //             listARPHANumbers.add(this.record?.aa_AHPRA_Number__c);
    //         }
    //         if (this.record.aa_AHPRA_Number__c != null) {
    //             listARPHANumbers.add(this.record?.aa_AHPRA_Number_2__c);
    //         }
    //         if (this.record.aa_AHPRA_Number__c != null) {
    //             listARPHANumbers.add(this.record?.aa_AHPRA_Number_3__c);
    //         }

    //         return listARPHANumbers.toString();
    //     }
    // }
}