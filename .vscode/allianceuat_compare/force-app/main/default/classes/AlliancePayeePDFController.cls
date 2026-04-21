public without sharing class AlliancePayeePDFController {

    public tc9_pr__Payee__c  payeeRecord { get; set; }
    public String logoUrl { get; set; }
    public Date mostRecentPayPeriodDate { get; set; }
    public List<Payee_Service__c  > payeeServices { get; set; } 

    public AlliancePayeePDFController(ApexPages.StandardSetController controller) {

        String token = ApexPages.currentPage()?.getParameters()?.get('token');
        if(token != null){
            token  = EncodingUtil.urlEncode(token, 'UTF-8');
        }
        
        List<Id> validatingPayees = new List<Id>();

        String printId = ApexPages.currentPage()?.getParameters()?.get('printId');
        if(printId!= null){
            token ='1';
            validatingPayees = printId.split('-');
        }
        
        if(token == null && printId == null){
            token = '1';
            List<tc9_pr__Payee__c> selectedIds = (List<tc9_pr__Payee__c>) Controller.getSelected();
            for(tc9_pr__Payee__c iteratingInvoice : selectedIds) {
                validatingPayees.add(iteratingInvoice.Id);
            }
        }

        String payeeId = ApexPages.currentPage()?.getParameters()?.get('PayeeId');
        if(String.isNotBlank(payeeId) && validatingPayees.isEmpty()) {
            validatingPayees.add(payeeId);
        }

        // Get the Id from the URL
        System.debug(payeeId);
        if (payeeId != null) {
            // Query Payee with related Payment Entity and its Billing Address
            payeeRecord = [
                SELECT Id, 
                       tc9_pr__Payment_Entity__r.Name,
                       tc9_pr__Payment_Entity__r.BillingStreet,
                       tc9_pr__Payment_Entity__r.BillingCity, 
                       tc9_pr__Payment_Entity__r.BillingState, 
                       tc9_pr__Payment_Entity__r.BillingPostalCode,
                       tc9_pr__Payment_Entity__r.Phone,
                       tc9_pr__Payment_Entity__r.Payment_Entity_Email__c,
                       tc9_pr__Payment_Entity__r.tc9_pr__ABN__c,
                       tc9_pr__Payment_Entity__r.Trading_Name__c,
                       tc9_pr__Employee__r.Name,
                       tc9_pr__Employee__r.MailingStreet,
                       tc9_pr__Employee__r.MailingCity,
                       tc9_pr__Employee__r.MailingState,
                       tc9_pr__Employee__r.MailingPostalCode,
                       tc9_pr__Payroll_Start_Date__c
                FROM tc9_pr__Payee__c
                WHERE Id = :payeeId
                LIMIT 1
            ];
            System.debug(payeeRecord);

            // 🔍 Fetch PayeeService records
            payeeServices = [
                SELECT Id,
                       Total_Hours__c,
                       Commencement_Date__c ,
                       Award_Classifications__r.Name,
                       Award_Level__r.Name
                FROM Payee_Service__c
                WHERE Payee__c = :payeeId
                ORDER BY Commencement_Date__c 
            ];

            // 🔍 Fetch logo for related Payment Entity
            Id paymentEntityId = payeeRecord.tc9_pr__Payment_Entity__r.Id;

            List<ContentDocumentLink> links = [
                SELECT ContentDocumentId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :paymentEntityId 
                LIMIT 1
            ];

            if (!links.isEmpty()) {
                List<ContentVersion> versions = [
                    SELECT Id 
                    FROM ContentVersion 
                    WHERE ContentDocumentId = :links[0].ContentDocumentId 
                    ORDER BY CreatedDate DESC 
                    LIMIT 1
                ];

                if (!versions.isEmpty()) {
                    logoUrl = '/sfc/servlet.shepherd/version/download/' + versions[0].Id;
                }
            }

            if (payeeRecord != null) {
                List<tc9_pr__Pay_Advice__c> recentAdviceList = [
                    SELECT Name, tc9_pr__Period_End_Date__c 
                    FROM tc9_pr__Pay_Advice__c
                    WHERE tc9_pr__Payee__c = :payeeRecord.Id
                    ORDER BY tc9_pr__Period_End_Date__c DESC
                    LIMIT 1
                ];
            
                if (!recentAdviceList.isEmpty()) {
                    mostRecentPayPeriodDate = recentAdviceList[0].tc9_pr__Period_End_Date__c;
                }
            }

            Date today = Date.today();

            String day = (today.day() < 10 ? '0' + today.day() : String.valueOf(today.day()));
            String month = (today.month() < 10 ? '0' + today.month() : String.valueOf(today.month()));
            String year = String.valueOf(today.year());

            String formattedDate = day + '-' + month + '-' + year;
            
            String fileName = payeeRecord.tc9_pr__Employee__r.Name + '.StatementofService.' + formattedDate + '.pdf';
            Apexpages.currentPage().getHeaders().put('content-disposition', 'inline; filename=' + fileName);

        }
        
    }    
    
}