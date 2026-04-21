public with sharing class SIM_AhpraIntegrationHandler {

    @InvocableMethod(label='Get Ahpra Details' description='Fetches AHPRA data and creates candidate records')
    public static List<ahpraResponse> sendRequest (List<List<String>> ahpraNumberListBulk) {

        // System.debug('AHPRA Numbers: ' + ahpraNumberListBulk[0]);
        List<ahpraResponse> ahpraResponseList = new List<ahpraResponse>();

        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();

        Ahpra_Integration_Settings__c aSettings = Ahpra_Integration_Settings__c.getInstance();
        String endpoint = aSettings.Ahpra_Endpoint__c;
        String userId = aSettings.Ahpra_Username__c;
        String password = aSettings.Ahpra_Password__c;

        req.setEndpoint(endpoint);
        req.setHeader('Content-Type', 'application/soap+xml');
        req.setMethod('POST');
        req.setCompressed(false);

        String reqBodyStart = 
            '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:ns="http://ns.ahpra.gov.au/pie/xsd/common/CommonCoreElements/2.0.0" xmlns:ns1="http://ns.ahpra.gov.au/pie/svc/frs/FindRegistration/2.0.0" xmlns:ns2="http://ns.ahpra.gov.au/pie/xsd/frs/FindRegistrationMessages/2.0.0">' +
            '<soap:Header xmlns:wsa="http://www.w3.org/2005/08/addressing">' +
            '<To soap:mustUnderstand="1" xmlns="http://www.w3.org/2005/08/addressing">' + endpoint + '</To>' +
            '<wsa:Action>http://ns.ahpra.gov.au/pie/svc/frs/FindRegistration/2.0.0/FindRegistrationPortType/FindRegistrationsRequest</wsa:Action>' +
            '<ns:LoginDetails><ns:UserId>' + userId + '</ns:UserId><ns:Password>' + password + '</ns:Password></ns:LoginDetails>' +
            '</soap:Header><soap:Body><ns1:FindRegistrations>';

        List<String> ahpraNumberList = new List<String>();

        for (String num : ahpraNumberListBulk[0]) {
            if (!String.isBlank(num)) {
                ahpraNumberList.add(num);
            }
        }
        // system.debug('SPC Ahpra Numbers: ' + ahpraNumberList);



        String numbersXml = '';
        for (String a : ahpraNumberList) {
            if (String.isNotBlank(a)) {
                numbersXml += '<ns2:ProfessionNumber>' + a.trim().toUpperCase() + '</ns2:ProfessionNumber>';
            }
        }
        // system.debug('SPC Ahpra Numbers XML: ' + numbersXml);

        String reqBodyEnd = '</ns1:FindRegistrations></soap:Body></soap:Envelope>';
        req.setBody(reqBodyStart + numbersXml + reqBodyEnd);
        
        try {
            res = http.send(req);
            System.debug('AHPRA Response: ' + res.getBody());

            if (res.getStatusCode() == 500) {
                insertLog('AHPRA Fetch error: ' + res.getBody());
                ahpraResponseList.add(new ahpraResponse(500, res.getStatus(), null, null));
                return ahpraResponseList;
            }

            String xmlResponse = '<?xml version="1.0" encoding="utf-8"?>' + res.getBody();
            SIM_AhpraIntegreation_FindRegHandler.FindRegistrationsResponse parser = new SIM_AhpraIntegreation_FindRegHandler.FindRegistrationsResponse();
            SIM_AhpraIntegreation_FindRegHandler.FindRegistrationsResponse parsed = parser.parse(xmlResponse);

            // Map Contacts
            Map<String, Id> conMap = new Map<String, Id>();
            List<Contact> conList = [
                SELECT Id, aa_AHPRA_Number__c, aa_AHPRA_Number_2__c, aa_AHPRA_Number_3__c
                FROM Contact 
                WHERE aa_AHPRA_Number__c IN :ahpraNumberList 
                OR aa_AHPRA_Number_2__c IN :ahpraNumberList 
                OR aa_AHPRA_Number_3__c IN :ahpraNumberList
            ];
            for (Contact c : conList) {
                if (c.aa_AHPRA_Number__c != null) conMap.put(c.aa_AHPRA_Number__c, c.Id);
                if (c.aa_AHPRA_Number_2__c != null) conMap.put(c.aa_AHPRA_Number_2__c, c.Id);
                if (c.aa_AHPRA_Number_3__c != null) conMap.put(c.aa_AHPRA_Number_3__c, c.Id);
            }

            List<Ahpra_Candidate_Check__c> toInsert = new List<Ahpra_Candidate_Check__c>();
            for (SIM_AhpraIntegreation_FindRegHandler.ProfessionNumberReplay r : parsed.professionNumberReplays) {
                String profNum = r.professionNumber;
                SIM_AhpraIntegreation_FindRegHandler.Practitioner p = r.practitioner;
                SIM_AhpraIntegreation_FindRegHandler.Profession prof = (p != null) ? p.profession : null;
                SIM_AhpraIntegreation_FindRegHandler.Registration reg = (prof != null) ? prof.registration : null;

                Ahpra_Candidate_Check__c rec = new Ahpra_Candidate_Check__c();
                rec.AHPRA_Candidate_Number__c = profNum;
                rec.Profession__c = (prof != null) ? prof.profession : null;
                rec.Profession_Start_Date__c = (prof != null) ? prof.professionStartDate : null;
                rec.Registration_Type__c = (reg != null) ? reg.registrationType : null;
                rec.Registration_Status__c = (reg != null) ? reg.registrationStatus : null;
                rec.Registration_To_Date__c = (reg != null) ? reg.registrationToDate : null;
                rec.Sub_Status__c = (reg != null) ? reg.registrationSubStatus : null;

                rec.Number_of_Cautions__c = (reg != null) ? reg.cautions : 0;
                rec.Number_of_Conditions__c = (reg != null) ? reg.conditions : 0;
                rec.Number_of_Endorsements__c = (reg != null) ? reg.endorsements : 0;
                rec.Number_of_Notations__c = (reg != null) ? reg.notations : 0;
                rec.Number_of_Reprimands__c = (reg != null) ? reg.reprimands : 0;
                rec.Number_of_Undertakings__c = (reg != null) ? reg.undertakings : 0;

                rec.Candidate__c = conMap.get(profNum);
                rec.AHPRA_First_Name__c = (p != null && p.practitionerName != null) ? p.practitionerName.givenName : null;
                rec.AHPRA_Last_Name__c = (p != null && p.practitionerName != null) ? p.practitionerName.familyName : null;

                toInsert.add(rec);
            }

            if (!toInsert.isEmpty()) {
                insert toInsert;
            } else {
                insertLog('AHPRA found but no data.');
                ahpraResponseList.add(new ahpraResponse(501, 'AHPRA found but no data', null, null));
            }

        } catch (Exception e) {
            insertLog('AHPRA error: ' + e.getMessage());
            ahpraResponseList.add(new ahpraResponse(501, 'AHPRA error: ' + e.getMessage(), null, null));
        }

        return ahpraResponseList;
    }

    private static void insertLog(String message) {
        insert new sirenum__LogEntry__c(
            sirenum__Details__c = message,
            sirenum__Category__c = 'AHPRA Check Batch Job',
            sirenum__Severity__c = 'Error'
        );
    }

    public class ahpraResponse {
        @InvocableVariable public Integer resStatus;
        @InvocableVariable public String resMessage;
        @InvocableVariable public String CandidateName;
        @InvocableVariable public String AhpraId;
        public ahpraResponse(Integer resStatus, String resMessage, String CandidateName, String AhpraId) {
            this.resStatus = resStatus;
            this.resMessage = resMessage;
            this.CandidateName = CandidateName;
            this.AhpraId = AhpraId;
        }
    }
}