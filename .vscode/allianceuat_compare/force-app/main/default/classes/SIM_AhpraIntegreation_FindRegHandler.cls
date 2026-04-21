public with sharing class SIM_AhpraIntegreation_FindRegHandler {
    
    public class FindRegistrationsResponse {
        public AuditDetails auditDetails;
        public List<ProfessionNumberReplay> professionNumberReplays;
        
        public FindRegistrationsResponse parse(String xmlString) {

            Dom.Document doc = new Dom.Document();
            doc.load(xmlString);
            Dom.XmlNode root = doc.getRootElement();
            String nms = root.getNameSpace();
    
            FindRegistrationsResponse response = new FindRegistrationsResponse();
            response.auditDetails = new AuditDetails();
            response.professionNumberReplays = new List<ProfessionNumberReplay>();            

            Dom.XmlNode body = root.getChildElement('Body', nms);
            if (body != null) {
                for (Dom.XmlNode getRegResponse : body.getChildElements()) {
                    response.auditDetails = parseAuditDetails(getRegResponse);
                    response.professionNumberReplays = parseProfessionNumberReplays(getRegResponse);
                }
            }
            return response;
        }
        
        private AuditDetails parseAuditDetails(Dom.XmlNode rootNode) {
            String nsAudit = 'http://ns.ahpra.gov.au/pie/xsd/frs/FindRegistrationMessages/2.0.0';
            String nsCommon = 'http://ns.ahpra.gov.au/pie/xsd/common/CommonCoreElements/2.0.0';

            Dom.XmlNode auditNode = rootNode.getChildElement('AuditDetails', nsAudit);
            AuditDetails auditDetails = new AuditDetails();
            if (auditNode != null) {
                auditDetails.queryIdentifier = getSafeText(auditNode, 'QueryIdentifier', nsCommon);
                auditDetails.practitionerCount = getSafeInt(auditNode, 'PractitionerCount', nsCommon);
                auditDetails.serviceMessagesCount = getSafeInt(auditNode, 'ServiceMessagesCount', nsCommon);
                auditDetails.totalRecordsSearched = getSafeInt(auditNode, 'TotalRecordsSearched', nsCommon);
                auditDetails.totalNumberOfRegistration = getSafeInt(auditNode, 'TotalNumberOfRegistration', nsCommon);
                auditDetails.snapshotDate = getSafeDate(auditNode, 'SnapshotDate', nsCommon);
            }
            return auditDetails;
        }
        
        private List<ProfessionNumberReplay> parseProfessionNumberReplays(Dom.XmlNode rootNode) {
            String ns = 'http://ns.ahpra.gov.au/pie/xsd/frs/PractitionerRegistrationElements/2.0.0';
            List<ProfessionNumberReplay> replays = new List<ProfessionNumberReplay>();

            for (Dom.XmlNode replayNode : rootNode.getChildElements()) {
                if (replayNode.getName() == 'ProfessionNumberReplay') {
                    ProfessionNumberReplay replay = new ProfessionNumberReplay();
                    replay.professionNumber = replayNode.getAttribute('ProfessionNumber', null);

                    for (Dom.XmlNode pn : replayNode.getChildElements()) {
                        if (pn.getName() == 'Practitioner') {
                            replay.practitioner = parsePractitioner(pn);
                            replays.add(replay);
                        }
                    }
                }
            }
            return replays;
        }
        
        private Practitioner parsePractitioner(Dom.XmlNode practitionerNode) {
            String ns = 'http://ns.ahpra.gov.au/pie/xsd/frs/PractitionerRegistrationElements/2.0.0';
            Practitioner practitioner = new Practitioner();

            practitioner.practitionerIdentifier = getSafeText(practitionerNode, 'PractitionerIdentifier', ns);
            practitioner.practitionerName = parsePractitionerName(practitionerNode.getChildElement('PractitionerName', ns));
            practitioner.profession = parseProfession(practitionerNode.getChildElement('Profession', ns));

            return practitioner;
        }

        private Profession parseProfession(Dom.XmlNode profNode) {
            if (profNode == null) return null;
            String ns = 'http://ns.ahpra.gov.au/pie/xsd/frs/PractitionerRegistrationElements/2.0.0';
            
            Profession prof = new Profession();
            prof.professionNumber = getSafeText(profNode, 'ProfessionNumber', ns);
            prof.profession = getSafeText(profNode, 'Profession', ns);
            prof.professionStartDate = getSafeDate(profNode, 'ProfessionStartDate', ns);

            // Parse Registration (which may contain nested Notations)
            Dom.XmlNode regNode = profNode.getChildElement('Registration', ns);
            prof.registration = parseRegistration(regNode);

            Integer cautions = 0, conditions = 0, endorsements = 0, notations = 0, reprimands = 0, undertakings = 0;

            // Count issues at both Profession level and inside Registration
            for (Dom.XmlNode rn : profNode.getChildElements()) {
                String name = rn.getName();
                if (name == 'Caution') cautions++;
                if (name == 'Condition') conditions++;
                if (name == 'Endorsement') endorsements++;
                if (name == 'Reprimand') reprimands++;
                if (name == 'Undertaking') undertakings++;
            }

            // 👇 Add nested check for Notations inside Registration
            if (regNode != null) {
                for (Dom.XmlNode regChild : regNode.getChildElements()) {
                    if (regChild.getName() == 'Notation') {
                        notations++;
                    }
                }
            }

            if (prof.registration != null) {
                prof.registration.cautions = cautions;
                prof.registration.conditions = conditions;
                prof.registration.endorsements = endorsements;
                prof.registration.notations = notations;
                prof.registration.reprimands = reprimands;
                prof.registration.undertakings = undertakings;
            }

            return prof;
        }

        
        private Registration parseRegistration(Dom.XmlNode regNode) {
            if (regNode == null) return null;
            String ns = 'http://ns.ahpra.gov.au/pie/xsd/frs/PractitionerRegistrationElements/2.0.0';
            
            Registration reg = new Registration();
            reg.recordNumber = getSafeText(regNode, 'RecordNumber', ns);
            reg.registrationType = getSafeText(regNode, 'RegistrationType', ns);
            reg.registrationStatus = getSafeText(regNode, 'RegistrationStatus', ns);
            reg.registrationSubStatus = getSafeText(regNode, 'RegistrationSubStatus', ns);
            reg.initialRegistrationDate = getSafeDate(regNode, 'InitialRegistrationDate', ns);
            reg.registrationToDate = getSafeDate(regNode, 'RegistrationToDate', ns);
            return reg;
        }            

        private PractitionerName parsePractitionerName(Dom.XmlNode node) {   
            if (node == null) return null;
            String ns = 'http://ns.ahpra.gov.au/pie/xsd/frs/PractitionerRegistrationElements/2.0.0';        
            PractitionerName name = new PractitionerName();
            name.nameTitle  = getSafeText(node, 'NameTitle', ns);
            name.familyName = getSafeText(node, 'FamilyName', ns);
            name.givenName  = getSafeText(node, 'GivenName', ns);
            name.middleName = getSafeText(node, 'MiddleName', ns);
            return name;
        }    

        // Utility helpers
        private String getSafeText(Dom.XmlNode parent, String childName, String ns) {
            Dom.XmlNode child = (parent != null) ? parent.getChildElement(childName, ns) : null;
            return (child != null && String.isNotBlank(child.getText())) ? child.getText() : null;
        }            

        private Integer getSafeInt(Dom.XmlNode parent, String childName, String ns) {
            String txt = getSafeText(parent, childName, ns);
            return (String.isNotBlank(txt)) ? Integer.valueOf(txt) : null;
        }

        private Date getSafeDate(Dom.XmlNode parent, String childName, String ns) {
            String txt = getSafeText(parent, childName, ns);
            try { return (String.isNotBlank(txt)) ? Date.valueOf(txt) : null; }
            catch (Exception e) { return null; }
        }        
        
    }
    
    // Data structures
    public class AuditDetails {
        public String queryIdentifier;
        public Integer practitionerCount;
        public Integer serviceMessagesCount;
        public Integer totalRecordsSearched;
        public Integer totalNumberOfRegistration;
        public Date snapshotDate;
    }

    public class ProfessionNumberReplay {
        public String professionNumber;
        public Practitioner practitioner;
    }

    public class Practitioner {
        public String practitionerIdentifier;
        public PractitionerName practitionerName;
        public Profession profession;
    }

    public class PractitionerName {
        public String nameTitle;
        public String familyName;
        public String givenName;
        public String middleName;
        public Datetime nameEditDate;
    }

    public class Profession {
        public String professionNumber;
        public String profession;
        public Date professionStartDate;
        public Registration registration;
    }

    public class Registration {
        public String recordNumber;
        public String registrationType;
        public String registrationStatus;
        public String registrationSubStatus;
        public Date registrationToDate;
        public Date initialRegistrationDate;
        public Integer cautions;
        public Integer conditions;
        public Integer endorsements;
        public Integer notations;
        public Integer reprimands;
        public Integer undertakings;
    }
}