public without sharing class SkieInvoiceTemplateQuery {

    public static List<tc9_et__Invoice__c> getInvoices(List<Id> ids, String token){
        String invQuery = ' SELECT Id, Name, tc9_et__Invoice_Entity__c, tc9_et__Invoice_Entity__r.Name, tc9_et__Invoice_Entity__r.Trading_Name__c, tc9_et__Invoice_Entity__r.Billingstreet, ';
        invQuery       += ' tc9_et__Invoice_Entity__r.Billingcity, tc9_et__Invoice_Entity__r.Billingstate, tc9_et__Invoice_Entity__r.BillingPostalcode, ';
        invQuery       += ' tc9_et__Invoice_Entity__r.tc9_pr__ABN__c, tc9_et__Invoice_Entity__r.Phone, tc9_et__Invoice_Message__c, RecordType.DeveloperName,';
        invQuery       += ' tc9_et__Invoice_Entity__r.tc9_et__Bank_Account_Name__c, tc9_et__Invoice_Entity__r.tc9_et__Bank_Account_Branch_Code__c, ';
        invQuery       += ' tc9_et__Invoice_Entity__r.tc9_et__Bank_Account_Number__c, tc9_et__Invoice_Entity__r.tc9_et__Remittance_Email__c, tc9_et__Invoice_Entity__r.tc9_et__Send_Invoice_Emails_From_Email__c, ';
        invQuery       += ' tc9_et__Invoice_Entity__r.Fax, tc9_et__Invoice_Date__c, tc9_et__Payment_Terms__r.Name, tc9_et__Due_Date__c, tc9_et__Invoice_To_Account__r.Name,';
        invQuery       += ' tc9_et__Invoice_To_Account__r.Billingstreet, tc9_et__Invoice_To_Account__r.Billingcity, tc9_et__Invoice_To_Account__r.Billingstate, tc9_et__Invoice_To_Account__r.BillingPostalcode, ';
        invQuery       += ' tc9_et__Invoice_To_Contact__c, tc9_et__Invoice_To_Contact__r.Name, tc9_et__Invoice_To_Contact__r.Firstname, tc9_et__Invoice_To_Contact__r.Lastname, tc9_et__Invoice_To_Contact__r.MailingStreet, ';
        invQuery       += ' tc9_et__Invoice_To_Contact__r.MailingCity, tc9_et__Invoice_To_Contact__r.MailingState,tc9_et__Invoice_To_Contact__r.MailingPostalCode, tc9_et__Invoice_To_Contact__r.MailingCountry, ';
        invQuery       += ' tc9_et__Invoice_Total_Ex_Tax__c, tc9_et__Invoice_Total_Tax__c, tc9_et__Invoice_No__c, tc9_et__Original_Invoice__r.Name, tc9_et__Invoice_To_Account__r.Customer_ID__c, Purchase_Order_Number__c, ';
        invQuery       += ' tc9_et__Invoice_Total_Inc_Tax__c, tc9_et__Invoice_Setting__r.tc9_et__Invoice_Entity__c, tc9_et__Invoice_Setting__r.tc9_et__Include_Backing_Sheet__c, tc9_et__Invoice_Setting__r.tc9_et__Exp_Claim_Attachments_with_Invoice__c,  ';
        invQuery       +=       ' (select id, tc9_et__Pay_Transaction__r.tc9_et__Purchase_Order_Number__c, tc9_et__Pay_Transaction__r.tc9_et__Invoice_Calendar_Period__r.tc9_pr__Start_Date__c, tc9_et__Pay_Transaction__r.tc9_et__Invoice_Calendar_Period__r.tc9_pr__End_Date__c ' +
            					' from tc9_et__InvoiceItems__r) ';
        invQuery       += ' FROM tc9_et__Invoice__c ';
        
        if(!ids.isEmpty()) {
            invQuery += ' WHERE id IN: ids ';
        } else {
            invQuery += ' WHERE tc9_et__Invoice_Link_Token__c =: token ';
        }
        
        return Database.query(invQuery);
    }

    public static List<tc9_et__Invoice_Item__c> getInvoiceItems(List<tc9_et__Invoice__c> invoices) {
        return getInvoiceItems(invoices, 'tc9_et__Entry_Date__c');
    }

    public static List<tc9_et__Invoice_Item__c> getInvoiceItems(List<tc9_et__Invoice__c> invoices, String orderBy) {
        orderBy = orderBy ?? ' tc9_et__Entry_Date__c ';

        String query = 'SELECT Id, Name, tc9_et__Invoice__c, tc9_et__Assignment__c, tc9_et__Assignment__r.tc9_pr__Employee__c, tc9_et__Invoice_Item_Description__c, tc9_et__Fee_Type__c, tc9_et__Invoiceable_Fee__c, tc9_et__Entry_Date__c, tc9_et__Invoice_Rate__c, ' +
                       ' tc9_et__Assignment__r.tc9_pr__Employee__r.FirstName, tc9_et__Assignment__r.tc9_pr__Employee__r.LastName, tc9_et__Assignment__r.tc9_pr__Employee__r.Name, tc9_et__Quantity__c, tc9_et__Invoice_Item__c.tc9_et__Employee__r.Name, ' + 
                       ' tc9_et__Pay_Code__r.RecordTypeId, tc9_et__Pay_Code__r.RecordType.Name, tc9_et__Pay_Code__r.RecordType.DeveloperName, tc9_et__Timesheet_Entry__r.tc9_et__Day__c, tc9_et__Assignment__r.Invoice_Name__c, tc9_et__Pay_Transaction__r.tc9_et__Invoice_Total_Ex_Tax__c, tc9_et__Pay_Transaction__r.tc9_et__Invoice_Total_Tax__c,' +
                       ' tc9_et__Timesheet_Entry__r.tc9_et__Total_Time_hours__c, tc9_et__Timesheet_Entry__r.tc9_ext_sirint__Site__r.Name, tc9_et__Pay_Transaction__r.Shift__r.tc9_ext_sirint__TSE_Start_Date__c, ' + 
                       ' tc9_et__Pay_Code__r.Shift_Invoice_Allowance_Column__c, tc9_et__Pay_Code__r.Laun_Invoice_Allowance_Column__c, tc9_et__Pay_Code__r.Unif_Invoice_Allowance_Column__c, tc9_et__Pay_Code__r.Qual_Invoice_Allowance_Column__c, ' +
                       ' tc9_et__Pay_Code__r.On_Call_Invoice_Allowance_Column__c, tc9_et__Pay_Code__r.Misc_Invoice_Allowance_Column__c, tc9_et__Pay_Code__r.BFee_Invoice_Allowance_Column__c, tc9_et__Pay_Code__r.PFee_Invoice_Allowance_Column__c, tc9_et__Pay_Code__r.IC_Invoice_Allowance_Column__c, ' +
                       ' tc9_et__Assignment__r.Name, tc9_et__Assignment__r.tc9_pr__Assignment_Name__c, tc9_et__Assignment__r.tc9_pr__Client__c, tc9_et__Assignment__r.tc9_pr__Client__r.Name, tc9_et__Client__r.Customer_ID__c, ' +
                       ' tc9_et__Assignment__r.tc9_et__Client_Hiring_Manager__r.Name , tc9_et__Client__r.Name, tc9_et__Client__r.Billingstreet, tc9_et__Client__r.Billingcity, tc9_et__Client__r.Billingstate, tc9_et__Client__r.BillingPostalcode, ' +
                       ' tc9_et__Assignment__r.tc9_et__Award_Level__c, tc9_et__Assignment__r.tc9_et__Award_Level__r.Name, tc9_et__Project_Code__c, tc9_et__Project_Code__r.Name,  tc9_et__Project_Code__r.tc9_et__Invoice_Name__c, tc9_et__Pay_Code__r.tc9_et__Invoice_Name__c,  ' +
                       ' tc9_et__Timesheet_Entry__r.tc9_et__Project_Code__c, tc9_et__Timesheet_Entry__r.tc9_et__Timesheet__c, tc9_et__Timesheet_Entry__r.tc9_et__Timesheet__r.tc9_et__End_Date__c,tc9_et__Timesheet_Entry__r.tc9_et__Timesheet__r.tc9_et__Start_Date__c, ' +
                       ' tc9_et__Timesheet_Entry__r.tc9_et__Project_Code__r.Name, tc9_et__Pay_Code__c, tc9_et__Timesheet_Entry__c, tc9_et__Pay_Code_Sort_Order__c, tc9_et__Invoice_Total_Ex_Tax__c, tc9_et__Pay_Transaction__r.Shift__r.sirenum__Site__r.Name, ' +
                       ' tc9_et__Timesheet_Entry__r.tc9_et__Start_Date__c, tc9_et__Timesheet_Entry__r.tc9_et__Start_Time__c,  tc9_et__Timesheet_Entry__r.tc9_et__End_Date__c, tc9_et__Timesheet_Entry__r.tc9_et__End_Time__c, tc9_et__Timesheet_Entry__r.tc9_et__Timesheet__r.tc9_et__Approved_Rejected_By_Name__c, ' +
                       ' tc9_et__Timesheet_Entry__r.tc9_et__Break_1_Total__c, tc9_et__Timesheet_Entry__r.tc9_et__Total_Hours__c, tc9_et__Timesheet_Entry__r.tc9_et__Timesheet__r.tc9_et__Submitted_Date__c, tc9_et__Timesheet_Entry__r.tc9_et__Timesheet__r.tc9_et__Approved_Rejected_Date__c, ' +
                       ' tc9_et__Timesheet_Entry__r.tc9_et__Timesheet__r.tc9_et__Approved_Rejected_on_Behalf_User_Name__c, tc9_et__Timesheet_Entry__r.tc9_et__Timesheet__r.tc9_et__Approved_Rejected_on_Behalf_Reason__c, tc9_et__Timesheet_Entry__r.tc9_et__Timesheet__r.tc9_et__Approved_Rejected_By__c, ' +
                       ' tc9_et__Timesheet_Entry__r.tc9_et__Employee_Notes__c, tc9_et__Timesheet_Item__r.tc9_et__Project_Code__c, tc9_et__Timesheet_Item__r.tc9_et__Timesheet__r.tc9_et__End_Date__c, tc9_et__Pay_Transaction__r.Shift__r.sirenum__Actual_Shift_Length_Decimal__c, ' +
                       ' tc9_et__Timesheet_Item__r.tc9_et__Project_Code__r.Name, tc9_et__Timesheet_Item__c, tc9_et__Invoice_Total_Tax__c, tc9_et__Invoice_Total_Inc_Tax__c, tc9_et__Pay_Transaction__r.Shift__r.tc9_ext_sirint__TSE_Start_Time__c, tc9_et__Pay_Transaction__r.Shift__r.tc9_ext_sirint__TSE_End_Time__c, ' +
                       ' tc9_et__Pay_Transaction__c, tc9_et__Pay_Transaction__r.tc9_et__Timesheet_Entry__c, tc9_et__Pay_Code__r.tc9_pr__Description__c, RecordType.DeveloperName, RecordType.Name, tc9_et__Pay_Transaction__r.Shift__r.sirenum__Approved_By_Client__c, ' +
                       ' tc9_et__Pay_Transaction__r.tc9_et__Timesheet_Entry__r.tc9_et__Timesheet__c, tc9_et__Pay_Transaction__r.tc9_et__Invoice_Calendar_Period__c,tc9_et__Pay_Transaction__r.tc9_pr__Assignment_Rate__c, tc9_et__Pay_Transaction__r.Shift__r.sirenum__Break_Length__c, ' +
                       ' tc9_et__Pay_Transaction__r.tc9_et__Timesheet_Entry__r.tc9_et__Timesheet__r.tc9_et__Start_Date__c, tc9_et__Pay_Transaction__r.tc9_et__Timesheet_Entry__r.tc9_et__Timesheet_Formula__c, tc9_et__Pay_Transaction__r.tc9_et__Timesheet_Entry__r.tc9_et__Start_Time__c, ' +
                       ' tc9_et__Pay_Transaction__r.tc9_et__Timesheet_Entry__r.tc9_et__Timesheet_Activity__r.Name, tc9_et__Pay_Transaction__r.tc9_et__Timesheet_Entry__r.tc9_et__Project_Code__r.Name, tc9_et__Pay_Transaction__r.tc9_pr__Entry_Date__c, ' + // ===== ADDED: Entry Date field for Expenses =====
                       ' tc9_et__Pay_Transaction__r.tc9_et__Timesheet_Entry__r.tc9_et__End_Time__c, tc9_et__Pay_Code__r.Name, tc9_et__Pay_Transaction__r.tc9_et__Purchase_Order_Number__c, tc9_et__Pay_Transaction__r.tc9_et__Timesheet_Entry__r.tc9_ext_sirint__Site__r.Name, ' +
                       ' tc9_et__Pay_Transaction__r.tc9_et__Invoice_Calendar_Period__r.tc9_pr__Start_Date__c, tc9_et__Pay_Transaction__r.tc9_et__Invoice_Calendar_Period__r.tc9_pr__End_Date__c, tc9_et__Pay_Transaction__r.Shift__r.Timesheet_Approver_Name__c, ' +
                       ' tc9_et__Expense__r.tc9_et__Expense_Claim__c, RecordTypeId, tc9_et__Timesheet_Entry__r.tc9_ext_sirint__Site__r.sirenum__Operating_Company__r.Name, tc9_et__Timesheet_Entry__r.tc9_ext_sirint__Shift__r.Authoriser__c, tc9_et__Timesheet_Entry__r.tc9_ext_sirint__Shift__r.Shift_Type__c, ' +
            		   ' tc9_et__Pay_Transaction__r.Shift__r.sirenum__Site__r.sirenum__Operating_Company__r.Name, tc9_et__Pay_Transaction__r.Shift__r.Shift_Type__c, tc9_et__Pay_Transaction__r.tc9_et__Timesheet_Entry__r.tc9_et__Timesheet_Activity__c,  ' +
                       ' tc9_et__Pay_Transaction__r.tc9_et__Timesheet_Entry__r.tc9_et__Project_Code__c, tc9_et__Assignment__r.tc9_pr__Client__r.Primary_Approval_Method__c' +
                       ' FROM tc9_et__Invoice_Item__c ' +
                       ' WHERE tc9_et__Invoice__c IN :invoices ';

        query += 'ORDER BY ' + orderBy;

        return Database.query(query);
    }

    public static List<tc9_et__Timesheet__c> getTimesheets(Set<Id> timesheetIdSet) {
    	return [SELECT Id, Name, tc9_et__Start_Date__c, tc9_et__End_Date__c, tc9_et__Employee__r.Name, tc9_et__Assignment__r.tc9_pr__Client__r.Name,
                tc9_et__Assignment__r.Name, tc9_et__Assignment__r.tc9_et__Client_Hiring_Manager__r.Name, tc9_et__Total_Hours__c, tc9_et__Approver_Notes__c,
                tc9_et__Assignment__r.tc9_et__Timesheet_Calendar__r.tc9_et__Timesheet_Entry_Format__c, tc9_et__Assignment__r.tc9_et__Timesheet_Calendar__r.tc9_et__Break_Entry_Format__c,
                tc9_et__Assignment__r.tc9_pr__Assignment_Name__c, tc9_et__Assignment__r.tc9_et__Client_Hiring_Manager__c,
                tc9_et__Submitted_Date__c, tc9_et__Approved_Rejected_on_Behalf_User__r.Name, tc9_et__Approved_Rejected_on_Behalf_Reason__c,tc9_et__Approved_Rejected_By__r.Name, tc9_et__Approved_Rejected_Date__c, tc9_et__Assignment__r.tc9_pr__Client__r.Primary_Approval_Method__c
                FROM tc9_et__Timesheet__c
                WHERE Id IN :timesheetIdSet
                ORDER BY tc9_et__Start_Date__c, tc9_et__Employee__r.Name];
	}   
    
    public static List<tc9_et__Timesheet_Entry__c> getTimesheetEntries(Set<Id> entryIdSet) {
        return [SELECT Id, tc9_et__Timesheet__c, tc9_et__End_Date__c , tc9_et__Start_Date__c, tc9_et__Day__c, tc9_et__Project_Code__c, tc9_et__Project_Code__r.Name, tc9_ext_sirint__Shift__r.sirenum__Team__r.Name,
                tc9_et__Start_Time__c, tc9_et__End_Time__c, tc9_et__Break_1_Total__c, tc9_et__Break_2_Total__c, tc9_et__Break_1_Start_Time__c, tc9_et__Break_2_Start_Time__c, tc9_et__Break_1_End_Time__c,
                tc9_et__Break_2_End_Time__c, tc9_et__Employee_Notes__c, tc9_et__Total_Hours__c, tc9_et__Payee_Leave_Rule__c, tc9_et__Total_Time_hours__c ,tc9_et__Total_Time_mins__c, tc9_ext_sirint__Shift__r.sirenum__Approved_By_Client__c,
                tc9_ext_sirint__Shift__r.Timesheet_Approver_Name__c,
                tc9_et__Submitted_Date__c, tc9_et__Approved_Rejected_on_Behalf_User__r.Name, tc9_et__Approved_Rejected_on_Behalf_Reason__c, tc9_et__Approved_Rejected_By__r.Name, tc9_et__Approved_Rejected_Date__c 
                FROM tc9_et__Timesheet_Entry__c
                WHERE Id IN :entryIdSet
                ORDER BY tc9_et__Start_Date__c];
    }
    
    public static List<ContentDocumentLink> getImageContentDocumentLink(Set<Id> linkEntityIdSet) {
        System.debug('getImageContentDocumentLink' + linkEntityIdSet);
        if(linkEntityIdSet.isEmpty()) {
            return new List<ContentDocumentLink>();
        }
        
        return [SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.Title, ContentDocument.ContentSize, ContentDocument.LatestPublishedVersionId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :linkEntityIdSet
                AND (ContentDocument.FileType = 'JPG' 
                    OR ContentDocument.FileType = 'JPEG'
                    OR ContentDocument.FileType = 'PNG'
                    OR ContentDocument.FileType = 'GIF'
                    OR ContentDocument.FileType = 'VISIO'
                    OR ContentDocument.FileType = 'TIFF'
                    OR ContentDocument.FileType = 'TIF'
                    OR ContentDocument.FileExtension = 'heic')];
    }

    public static List<ContentDocumentLink> getLogoContentDocumentLink(Set<Id> linkEntityIdSet) {
        if(linkEntityIdSet.isEmpty()) {
            return new List<ContentDocumentLink>();
        }
        
        return [SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.Title, 
                ContentDocument.ContentSize, ContentDocument.LatestPublishedVersionId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :linkEntityIdSet
                AND ContentDocument.Title LIKE '%logo%'];
    }
}