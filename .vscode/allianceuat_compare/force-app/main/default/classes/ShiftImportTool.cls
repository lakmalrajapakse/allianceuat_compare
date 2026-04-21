/**
 * @Description        : Used to import shifts and shift demands
 * @Author             : Simon Coles
 * @Group              : 
 * @Created By   : Simon Coles
 * @Last Modified On   : 2/9/2024
 * @Modification Log   : 
/**
 * Imports external Shifts and Shift Demands from CSV/XLS file
 */
public class ShiftImportTool {

    @TestVisible
    Public static Boolean throwTestException = false;


    public class globalSettings {
        public Boolean allowQuickCreate { get; set; }
        public Boolean allowDelete { get; set; }
        public Boolean allowShiftDemands { get; set; }
        public Boolean allowShift { get; set; }
        public String customHeaders;
        public List<String> parsedHeaders { get; set; }
        public ShiftImportSettings__c shiftImportSettings { get; set; }

        public globalSettings() {
            allowQuickCreate = false;
            allowDelete = false;
            allowShiftDemands = false;
            allowShift = false;

            this.shiftImportSettings = ShiftImportSettings__c.getInstance(UserInfo.getProfileId());

            if (shiftImportSettings.Header_Columns__c != null && shiftImportSettings.Header_Columns__c != '') {
                customHeaders = shiftImportSettings.Header_Columns__c;
            } else {
                customHeaders = 'REFERENCE, PO NUMBER, BOOKING DATE, SCHEDULED DATE, WORKER, SITE, ROTA, JOB ROLE, SHIFT TYPE, START, END, REQUIRED SHIFTS, COMMENTS, CANCELLED, BOOKED BY, Result';
            }

            parsedHeaders = customHeaders.split(', ');

            if (shiftImportSettings.Allow_Quick_Create__c == true) {
                allowQuickCreate = true;
            }

            if (shiftImportSettings.Allow_Delete_Results__c == true) {
                allowDelete = true;
            }

            if (shiftImportSettings.Import_Demand__c == true) {
                allowShiftDemands = true;
            }

            if (shiftImportSettings.Import_Shifts__c == true) {
                allowShift = true;
            }
        }
    }

    /**
    * Converts Map<String, Object> with Key (Header), Value = Values
    */
    private class Row {
        public String shiftComments;
        public String shiftReferenceN;
        public String shiftStation;
        public String shiftRota;
        public String shiftScheduledDate;
        public Date shiftScheduledDate_parsed;
        public String shiftBookingDate;
        public Date shiftBookingDate_parsed;
        public String shiftTeam;
        public String shiftAcStart;
        public String shiftAcEnd;
        public String shiftContact;
        public Integer shiftDemands;
        public String shiftCancelled;
        // public String shiftLocation;
        public String shiftPONumber;
        public String shiftType;
        public String shiftBookedBy;

        public Integer rowN = 0;
        public String status;

        public Row(Map<String, Object> rowValueByHeader, globalSettings settings) {
            rowN++;
            this.status = '';

            // Check that set up has defined 15 headers
            String[] headers = settings.parsedHeaders;

            if (headers.size() != 16) {
                throw new StringException('Custom Settings Headers not well defined: ' + settings.customHeaders);
            }

            // Check the value of the client reference
            if ((Boolean) rowValueByHeader.containsKey(headers[0])) {
                shiftReferenceN = (String) rowValueByHeader.get(headers[0]);
                shiftReferenceN = shiftReferenceN.trim();
            } else {
                shiftReferenceN = '';
            }

            // Check if any PO number is added
            if ((Boolean) rowValueByHeader.containsKey(headers[1])) {
                this.shiftPONumber = (String) rowValueByHeader.get(headers[1]);

                if (this.shiftPONumber == null) {
                    this.shiftPONumber = '';
                }
            } else {
                this.shiftPONumber = '';
            }
            
            // Check if Shift Booking Date is provided
            if ((Boolean) rowValueByHeader.containsKey(headers[2])) {
                this.shiftBookingDate = (String) rowValueByHeader.get(headers[2]);
                this.shiftBookingDate = this.shiftBookingDate.trim();

                // Date Format Check - Used to allow CSV format
                if (!Pattern.matches('[0-9]{4}-[0-9]{2}-[0-9]{2}', shiftBookingDate)) {
                    Date dateCheck = date.parse(shiftBookingDate);
                    shiftBookingDate = String.valueOf(dateCheck);
                }

                try {
                    // Dates must be in ISO format YYYY-MM-DD
                    if (!Pattern.matches('[0-9]{4}-[0-9]{2}-[0-9]{2}', shiftBookingDate)) {
                        this.status += '* Invalid Date: ' + this.shiftBookingDate + ' - expected ISO format YYYY-MM-DD; \r\n';
                    } else {
                        this.shiftBookingDate_parsed = parseDate(this.shiftBookingDate);
                    }
                } catch (Exception e) {
                    this.status += '* Exception Invalid Date: ' + this.shiftBookingDate + ' - ' + e.getMessage() + '; \r\n';
                }
            } else {
                this.status += '* Date Missing' + '; \r\n';
            }
            
            // Check if Shift Scheduled Date is provided
            if ((Boolean) rowValueByHeader.containsKey(headers[3])) {
                this.shiftScheduledDate = (String) rowValueByHeader.get(headers[3]);
                this.shiftScheduledDate = this.shiftScheduledDate.trim();

                // Date Format Check - Used to allow CSV format
                if (!Pattern.matches('[0-9]{4}-[0-9]{2}-[0-9]{2}', shiftScheduledDate)) {
                    Date dateCheck = date.parse(shiftScheduledDate);
                    shiftScheduledDate = String.valueOf(dateCheck);
                }

                try {
                    // Dates must be in ISO format YYYY-MM-DD
                    if (!Pattern.matches('[0-9]{4}-[0-9]{2}-[0-9]{2}', shiftScheduledDate)) {
                        this.status += '* Invalid Date: ' + this.shiftScheduledDate + ' - expected ISO format YYYY-MM-DD; \r\n';
                    } else {
                        this.shiftScheduledDate_parsed = parseDate(this.shiftScheduledDate);
                    }
                } catch (Exception e) {
                    this.status += '* Exception Invalid Date: ' + this.shiftScheduledDate + ' - ' + e.getMessage() + '; \r\n';
                }
            } else {
                this.status += '* Date Missing' + '; \r\n';
            }

            // Check if we are importing against a Worker. Also check if contact extra fields are added
            if ((Boolean) rowValueByHeader.containsKey(headers[4])) {
                shiftContact = (String) rowValueByHeader.get(headers[4]);
                shiftContact = shiftContact.trim();
            } else {
                shiftContact = null;
            }

            //Check if site is provided
            if ((Boolean) rowValueByHeader.containsKey(headers[5])) {
                shiftStation = (String) rowValueByHeader.get(headers[5]);
                shiftStation = shiftStation.trim();
            } else {
                shiftStation = '';
            }

            //Check if Rota is provided
            if ((Boolean) rowValueByHeader.containsKey(headers[6])) {
                shiftRota = (String) rowValueByHeader.get(headers[6]);
                shiftRota = shiftRota.trim();
            } else {
                shiftRota = '';
            }            

            //Check if Job Role is provided
            if ((Boolean) rowValueByHeader.containsKey(headers[7])) {
                shiftTeam = (String) rowValueByHeader.get(headers[7]);
                shiftTeam = shiftTeam.trim();
            } else {
                shiftTeam = '';
            }

            // Check if Shift Type is added
            if ((Boolean) rowValueByHeader.containsKey(headers[8])) {
                this.shiftType = (String) rowValueByHeader.get(headers[8]);
                if (this.shiftType == null) {
                    this.shiftType = '';
                }
            } else {
                this.shiftType = '';
            }


            //Check if Start Time is provided
            if ((Boolean) rowValueByHeader.containsKey(headers[9])) {
                this.shiftAcStart = (String) rowValueByHeader.get(headers[9]);
                this.shiftAcStart = this.shiftAcStart.trim();

                if (this.shiftAcStart == null || this.shiftAcStart == '') {
                    this.status += '* No start time' + '; \r\n';
                }
            } else {
                this.status += '* No start time' + '; \r\n';
            }

            // Check if End time is provided
            if ((Boolean) rowValueByHeader.containsKey(headers[10])) {
                this.shiftAcEnd = (String) rowValueByHeader.get(headers[10]);
                this.shiftAcEnd = this.shiftAcEnd.trim();

                if (this.shiftAcEnd == null || this.shiftAcEnd == '') {
                    this.status += '* No end time' + '; \r\n';
                }
            } else {
                this.status += '* No end time' + '; \r\n';
            } 
            
            // Check if Openings are provided
            if ((Boolean) rowValueByHeader.containsKey(headers[11])) {
                try {
                    this.shiftDemands = Integer.valueOf((String) rowValueByHeader.get(headers[11]));
                    if (this.shiftDemands == 0) {
                        this.shiftDemands = null;
                    }
                } catch (Exception e) {
                    this.shiftDemands = null;
                }
            } else {
                this.shiftDemands = null;
            }

            // Check if any comments are added
            if ((Boolean) rowValueByHeader.containsKey(headers[12])) {
                this.shiftComments = (String) rowValueByHeader.get(headers[12]);

                if (this.shiftComments == null) {
                    this.shiftComments = '';
                }
            } else {
                this.shiftComments = '';
            }

            // Check shift is cancelled
            if ((Boolean) rowValueByHeader.containsKey(headers[13])) {
                this.shiftCancelled = (String) rowValueByHeader.get(headers[13]);
                this.shiftCancelled = parseCancellation(this.shiftCancelled);

            } else {
                this.shiftCancelled = 'No';
            }            
            
            // Check if Booked By is added
            if ((Boolean) rowValueByHeader.containsKey(headers[14])) {
                this.shiftBookedBy = (String) rowValueByHeader.get(headers[14]);
                if (this.shiftBookedBy == null) {
                    this.shiftBookedBy = '';
                }
            } else {
                this.shiftBookedBy = '';
            }

            //Check if location is provided
            // if ((Boolean) rowValueByHeader.containsKey(headers[11])) {
            //     shiftLocation = (String) rowValueByHeader.get(headers[11]);
            //     shiftLocation = shiftLocation.trim();

            // } else {
            //     shiftLocation = '';
            // }           

        }
    }

    public class infoRow {
        public String infoId { get; set; }
        public String conId { get; set; }
        public String infoContact { get; set; }
        public String infoReference { get; set; }
        public String infoRota { get; set; }
        public String infoTeam { get; set; }
        public String infoSite { get; set; }
        public String infoStart { get; set; }
        public String infoEnd { get; set; }
        public String infoOpenings { get; set; }
        public String infoScheduledDate { get; set; }
        public String infoBookingDate { get; set; }
        public String infoComments { get; set; }
        public String infoMessage { get; set; }
        public String rawInfoMessage { get; set; }
        public String infoCancellation { get; set; }
        public Boolean infoAuto { get; set; }
        // public String infoLocation { get; set; }
        public String infoPONumber { get; set; }
        public String infoShiftType { get; set; }
        public String infoBookedBy { get; set; }
        public Boolean isSuccess { get; set; }
    }

    public class tempSettings {
        public String emailRecipient { get; set; }
        public String deleteLines { get; set; }

        public tempSettings() {
            String userName = UserInfo.getUserName();
            User activeUser = [SELECT Email FROM User WHERE Username = :userName LIMIT 1];
            emailRecipient = activeUser.Email;
            deleteLines = '';
        }
    }

    public static List<Row> rows;
    public static List<infoRow> infoRows;
    public globalSettings gSettings { get; set; }
    public tempSettings tSettings { get; set; }

    /**
    * Initializes the new instance using the standard page
    */
    //noinspection ApexUnusedDeclaration
    public ShiftImportTool(ApexPages.StandardController stdController) {

        try {
            //Load Server settings
            gSettings = new globalSettings();
            // Load temporary settings settings
            tSettings = new tempSettings();

        } catch (Exception e) {
            ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: ' +
                    e.getMessage() + ' - ' + e.getLineNumber());
            ApexPages.addMessage(errorMsg);
        }
    }

    /**
    This function is called by the client with a jsonString results from the parsing of the excel file
    */
    @RemoteAction
    public static List<infoRow> parse(String jsonString) {
        try {
            //INITIAL SETTINGS 
            globalSettings settings = new globalSettings();

            // Reversing List
            List<Id> successIds = new List<Id>();
            List<String> failedImports = new List<String>();

            String infoMessage = '';
            infoRows = new List<infoRow>();

            Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
            rows = new List<Row>();

            //No sheets
            if (jsonMap.values().size() == 0) {
                throw new StringException('The file selected is empty.');
            }
            //More than one sheet
            if (jsonMap.values().size() > 1) {
                throw new StringException('The file contains multiple sheets. Please only use a single sheet excel file.');
            }

            //For the first sheet in the List of rows, add the relative Map from JSON
            for (Object row : (List<Object>) jsonMap.values().get(0)) {
                rows.add(new Row((Map<String, Object>) row, settings));
            }
            if (rows.size() == 0) {
                throw new StringException('There are no valid rows in this file.');
            }

            /*//////////////////////////////////////////
            //                                        //
            //              LOADING                   //
            //                                        //                
            *///////////////////////////////////////////

            Set<String> shifts = new Set<String>();
            Set<String> sites = new Set<String>();
            Set<String> rotas = new Set<String>();
            Set<String> jobRoles = new Set<String>();
            Set<String> contacts = new Set<String>();
            // Set<String> locations = new Set<String>();

            //add all unique values to respective Lists
            for (Row r : rows) {
                //If this row has an error, skip it
                if (r.status != '') {
                    continue;
                }

                if (!shifts.contains(r.shiftReferenceN.toUpperCase())) {
                    shifts.add(r.shiftReferenceN.toUpperCase());
                }

                if (!sites.contains(r.shiftStation.toUpperCase())) {
                    if(settings.shiftImportSettings.Match_Sites__c != 'Id') {
                        sites.add(r.shiftStation.toUpperCase());
                    } else {
                        sites.add(r.shiftStation);
                    }           
                }

                // if (!locations.contains(r.shiftLocation.toUpperCase())) {
                //     if(settings.shiftImportSettings.Match_Locations__c != 'Id') {
                //         locations.add(r.shiftLocation.toUpperCase());
                //     } else {
                //         locations.add(r.shiftLocation);
                //     }           
                // }

                if (!rotas.contains(r.shiftRota.toUpperCase())) {
                    rotas.add(r.shiftRota.toUpperCase());
                }

                if (!jobRoles.contains(r.shiftTeam.toUpperCase())) {
                    if(settings.shiftImportSettings.Match_Job_Roles__c != 'Id') {
                        jobRoles.add(r.shiftTeam.trim());
                    } else {
                        jobRoles.add(r.shiftTeam);
                    }
                }

                if (settings.allowShift && r.shiftContact != null) {
                    if (!contacts.contains(r.shiftContact.toUpperCase())) {
                        contacts.add(r.shiftContact.trim());
                    }
                }
            }

            Map<String, List<SObject>> shiftsMap = new Map<String, List<SObject>>();
            Map<String, List<Id>> sitesMap = new Map<String, List<Id>>();
            // Map<String, List<Id>> locationsMap = new Map<String, List<Id>>();
            Map<String, List<Id>> rotasMap = new Map<String, List<Id>>();
            Map<String, List<Id>> teamMap = new Map<String, List<Id>>();
            Map<String, List<Id>> contactMap = new Map<String, List<Id>>();

            // Selective loading
            if (sites.size() > 0) {

                String trQuery = null;                
                if(settings.shiftImportSettings.Match_Sites__c != 'Id') {
                    trQuery = 'SELECT id, ' + settings.shiftImportSettings.Match_Sites__c +
                    ' FROM sirenum__Site__c' +
                    ' WHERE ' + settings.shiftImportSettings.Match_Sites__c + ' in: sites ';
                } else {
                    trQuery = 'SELECT id FROM sirenum__Site__c WHERE Id in: sites';
                }                

                try {
                    List<SObject> sitesFound = Database.query(trQuery);

                    for (SObject site : sitesFound) {
                        String keyValue = (String) site.get(settings.shiftImportSettings.Match_Sites__c);

                        if (keyValue == null) {
                            continue;
                        }

                        keyValue = keyValue.toUpperCase().trim();

                        if (sitesMap.containsKey(keyValue)) {
                            sitesMap.get(keyValue).add(site.Id);
                        } else {
                            sitesMap.put(keyValue, new List<Id>{
                                    site.Id
                            });
                        }
                    }
                } catch (Exception e) {
                    System.debug(LoggingLevel.ERROR, 'Loading Site: ' +  e);
                    throw new StringException('Custom settings: Match by Site is a bad field');
                }
            }

            if (rotas.size() > 0) {
                String trQuery = null;
                if(settings.shiftImportSettings.Match_Rotas__c != 'Id') {
                trQuery = 'SELECT id, ' + settings.shiftImportSettings.Match_Rotas__c +
                        ' FROM sirenum__rota__c' +
                        ' WHERE ' + settings.shiftImportSettings.Match_Rotas__c + ' in: rotas ';
                }
                else{
                    trQuery = 'SELECT id FROM sirenum__rota__c WHERE Id in: rotas';
                }

                try {
                    List<SObject> rotasFound = Database.query(trQuery);

                    for (SObject s : rotasFound) {
                        String keyValue = (String) s.get(settings.shiftImportSettings.Match_Rotas__c);

                        if (keyValue == null) {
                            continue;
                        }

                        keyValue = keyValue.toUpperCase().trim();

                        if (rotasMap.containsKey(keyValue)) {
                            rotasMap.get(keyValue).add(s.Id);
                        } else {
                            rotasMap.put(keyValue, new List<Id>{
                                    s.Id
                            });
                        }
                    }
                } catch (Exception e) {
                    throw new StringException('Custom settings: Match by Rota is a bad field');
                }
            }

            system.debug('SPC Job Roles Size > ' + jobRoles.size());
            system.debug('SPC JobRoes > ' + jobRoles);
            if (jobRoles.size() > 0) {

                String trQuery = null;
                if(settings.shiftImportSettings.Match_Job_Roles__c != 'Id') {
                    trQuery = 'SELECT id, ' + settings.shiftImportSettings.Match_Job_Roles__c +
                    ' FROM sirenum__team__c' +
                    ' WHERE ' + settings.shiftImportSettings.Match_Job_Roles__c + ' in: jobRoles ';
                } else {
                    trQuery = 'SELECT id FROM sirenum__team__c WHERE Id in: jobRoles';
                }

                
                try {
                    List<SObject> teamsFound = Database.query(trQuery);
                    for (SObject s : teamsFound) {
                        String keyValue = (String) s.get(settings.shiftImportSettings.Match_Job_Roles__c);

                        if (keyValue == null) {
                            continue;
                        }

                        keyValue = keyValue.toUpperCase().trim();

                        if (teamMap.containsKey(keyValue)) {
                            teamMap.get(keyValue).add(s.Id);
                        } else {
                            teamMap.put(keyValue, new List<Id>{
                                    s.Id
                            });
                        }
                    }
                } catch (Exception e) {
                    throw new StringException('Custom settings: Match by Job Role is an invalid field');
                }
            }

            if (contacts.size() > 0) {

                String trQuery = null;
                if(settings.shiftImportSettings.Match_Contacts__c != 'Id') {
                    trQuery = 'SELECT id, ' + settings.shiftImportSettings.Match_Contacts__c +
                    ' FROM Contact' +
                    ' WHERE ' + settings.shiftImportSettings.Match_Contacts__c + ' in: contacts ';
                } else {
                    trQuery = 'SELECT id FROM Contact WHERE Id in: contacts';
                }
                
                try {
                    List<SObject> contactsFound = Database.query(trQuery);
                    for (SObject s : contactsFound) {
                        String keyValue = (String) s.get(settings.shiftImportSettings.Match_Contacts__c);
                        if (keyValue == null) {
                            continue;
                        }

                        keyValue = keyValue.toUpperCase().trim();

                        if (contactMap.containsKey(keyValue)) {
                            contactMap.get(keyValue).add(s.Id);
                        } else {
                            contactMap.put(keyValue, new List<Id>{
                                    s.Id
                            });
                        }
                    }
                } catch (Exception e) {
                    throw new StringException('Custom settings: Match by Contact is a bad field');
                }
            }

            if (shifts.size() > 0) {
                String trQuery = 'SELECT id, sirenum__Broadcasts__c, ' + settings.shiftImportSettings.Match_Shifts__c + ' FROM sirenum__shift__c WHERE ' + settings.shiftImportSettings.Match_Shifts__c + ' in: shifts ';

                try {
                    List<SObject> shiftsFound = Database.query(trQuery);
                    for (SObject s : shiftsFound) {
                        String keyValue = (String) s.get(settings.shiftImportSettings.Match_Shifts__c);

                        if (keyValue == null) {
                            continue;
                        }

                        keyValue = keyValue.toUpperCase().trim();

                        if (shiftsMap.containsKey(keyValue)) {
                            shiftsMap.get(keyValue).add(s);
                        } else {
                            shiftsMap.put(keyValue, new List<SObject>{
                                    s
                            });
                        }
                    }
                } catch (Exception e) {
                    throw new StringException('Custom settings: Match by Shift is a bad field. ' + e.getMessage() + ' line: ' + e.getLineNumber());
                }
            }


            /*//////////////////////////////////////////
            //                                        //
            //              Processing                //
            //                                        //                
            *///////////////////////////////////////////            

            /* 
            
                Second phase
                
                                    */
            List<SObject> shiftsToUpsert = new List<SObject>();
            Set<String> shiftUniqueRefs = new Set<String>();
            Set<String> dbShiftIds = new Set<String>();

            //Maps to be populated for better error handling 
            //If a record fails due to DML error, the system will pre-populate the name given/found
            Map<String, String> siteNameMap = new Map<String, String>();
            // Map<String, String> locationNameMap = new Map<String, String>();
            Map<String, String> rotaNameMap = new Map<String, String>();
            Map<String, String> teamNameMap = new Map<String, String>();
            Map<String, String> contactNameMap = new Map<String, String>();

            for (Row r : rows) {
                SObject shift = Schema.getGlobalDescribe().get('sirenum__Shift__c').newSObject();
                SObject dbShift = null;
                Boolean isUpdate = false;
                Boolean isShiftDemand = false;
                Boolean isNamedShift = false;

                Boolean stopTransaction = false;


                if (r.status != null && r.status != '') {
                    infoMessage = r.status;
                }
                String StationUp = r.shiftStation != null ? r.shiftStation.toUpperCase() : '';
                // String LocationUp = r.shiftLocation != null ? r.shiftLocation.toUpperCase() : '';
                String RotaUp = r.shiftRota != null ? r.shiftRota.toUpperCase() : '';
                String TeamUp = r.shiftTeam != null ? r.shiftTeam.toUpperCase() : '';
                String ContactUp = (settings.allowShift == true && r.shiftContact != null) ? r.shiftContact.toUpperCase() : '';
                String ShiftUp = r.shiftReferenceN != null ? r.shiftReferenceN.toUpperCase() : '';

                //Check if the shift is being updated by a reference provided
                if (ShiftUp != '' && shiftsMap.containsKey(ShiftUp)) {
                    if (shiftsMap.get(ShiftUp).size() > 1) {
                        stopTransaction = true;
                        infoMessage += '* Found multiple shifts matching [' + settings.shiftImportSettings.Match_Shifts__c + '] = ' + ShiftUp + '; \r\n';
                    } else {
                        dbShift = shiftsMap.get(ShiftUp).get(0);
                        shift.put('id', (Id) dbShift.get('id'));
                        isUpdate = true;
                        dbShiftIds.add((String) dbShift.get('id'));
                        //Check if it is a demand
                        if (String.valueOf((Decimal) dbShift.get('sirenum__Broadcasts__c')) != null) {
                            isShiftDemand = true;
                        }
                    }
                }

                //Populate Site
                if (StationUp != '' && sitesMap.containsKey(StationUp)) {
                    if (sitesMap.get(StationUp).size() > 1) {
                        stopTransaction = true;
                        infoMessage += '* Found multiple Sites matching [' + settings.shiftImportSettings.Match_Sites__c + '] = ' + StationUp + '; \r\n';
                    } else {
                        shift.put('sirenum__site__c', sitesMap.get(StationUp).get(0));
                        siteNameMap.put(sitesMap.get(StationUp).get(0), StationUp);
                    }
                } else if (StationUp == '') {

                } else {
                    infoMessage += '* Site [' + settings.shiftImportSettings.Match_Sites__c + '] = ' + StationUp + ' not found; \r\n';
                }

                //Populate Location
                // if (LocationUp != '' && locationsMap.containsKey(LocationUp)) {
                //     if (locationsMap.get(LocationUp).size() > 1) {
                //         stopTransaction = true;
                //         infoMessage += '* Found multiple Locations matching [' + settings.shiftImportSettings.Match_Locations__c + '] = ' + LocationUp + '; \r\n';
                //     } else {
                //         shift.put('sirenum__Location__c', locationsMap.get(LocationUp).get(0));
                //         locationNameMap.put(locationsMap.get(LocationUp).get(0), LocationUp);
                //     }
                // } else if (LocationUp == '') {

                // } else {
                //     infoMessage += '* Site [' + settings.shiftImportSettings.Match_Locations__c + '] = ' + LocationUp + ' not found; \r\n';
                // }

                //Populate Job Role
                if (TeamUp != '' && teamMap.containsKey(TeamUp)) {
                    if (teamMap.get(TeamUp).size() > 1) {
                        stopTransaction = true;
                        infoMessage += '* Found multiple Job Roles matching [' + settings.shiftImportSettings.Match_Job_Roles__c + '] = ' + TeamUp + '; \r\n';
                    } else {
                        shift.put('sirenum__team__c', teamMap.get(TeamUp).get(0));
                        teamNameMap.put(teamMap.get(TeamUp).get(0), TeamUp);
                    }
                } else if (TeamUp == '') {

                } else {
                    infoMessage += '* Job Role [' + settings.shiftImportSettings.Match_Job_Roles__c + '] = ' + TeamUp + ' not found; \r\n';
                }

                //Populate Rota
                if (RotaUp != '' && rotasMap.containsKey(RotaUp)) {
                    if (rotasMap.get(RotaUp).size() > 1) {
                        stopTransaction = true;
                        infoMessage += '* Found multiple Rotas matching [' + settings.shiftImportSettings.Match_Rotas__c + '] = ' + RotaUp + '; \r\n';
                    } else {
                        shift.put('sirenum__rota__c', rotasMap.get(RotaUp).get(0));
                        rotaNameMap.put(rotasMap.get(RotaUp).get(0), RotaUp);
                    }
                } else if (RotaUp == '') {

                } else {
                    infoMessage += '* Rota [' + settings.shiftImportSettings.Match_Rotas__c + '] = ' + RotaUp + ' not found; \r\n';
                }

                //Populate contact
                if (settings.allowShift && r.shiftContact != null && r.shiftContact != '') {
                    if (ContactUp != '' && contactMap.containsKey(ContactUp)) {
                        if (contactMap.get(ContactUp).size() > 1) {
                            stopTransaction = true;
                            infoMessage += '* Found multiple Contacts matching [' + settings.shiftImportSettings.Match_Contacts__c + '] = ' + ContactUp + '; \r\n';
                        } else {
                            shift.put('sirenum__contact__c', contactMap.get(ContactUp).get(0));
                            isNamedShift = true;
                            contactNameMap.put(contactMap.get(ContactUp).get(0), ContactUp);
                        }
                    } else {
                        infoMessage += '* Contact [' + settings.shiftImportSettings.Match_Contacts__c + '] = ' + ContactUp + ' not found; \r\n';
                    }

                } else if (!settings.allowShift && (r.shiftContact != null && r.shiftContact != '')) {
                    infoMessage += '* Importing Shifts is not allowed in Custom Settings; \r\n';
                } else if (!settings.allowShiftDemands && (r.shiftContact == null || r.shiftContact == '')) {
                    infoMessage += '* Importing Shift Demands is not allowed in Custom Settings; \r\n';
                } else if (r.shiftContact == null || r.shiftContact == '') {
                    //Handle un-assigning shifts
                    shift.put('sirenum__contact__c', null);
                }

                // Check if trying to import shift demand against a worker
                if (r.shiftDemands != null && r.shiftContact != null && r.shiftContact != '') {
                    infoMessage += '* Shift Demands cannot be assigned to a person; \r\n';
                }

                //Populate openings
                if (r.shiftDemands != null && r.shiftDemands != 0) {
                    try {
                        shift.put('sirenum__Broadcasts__c', Integer.valueOf(r.shiftDemands));
                        isShiftDemand = true;
                    } catch (Exception e) {
                        infoMessage += '* Required Shifts is invalid: ' + r.shiftDemands + ' - please use whole numbers; \r\n';
                    }
                } else {
                    shift.put('sirenum__Broadcasts__c', null);
                }

                //If assigning shift demand against a person
                if (isUpdate && isShiftDemand && isNamedShift) {
                    system.debug('* Cannot update/assign Shift Demand against a person');
                    infoMessage += '* Cannot update/assign Shift Demand against a person; \r\n';
                }

                //Manage Cancellations
                if (isUpdate && r.shiftCancelled != null && r.shiftCancelled == 'Yes') {
                    shift.put('sirenum__Cancelled__c', true);
                    shift.put('sirenum__CancellationReason__c', settings.shiftImportSettings.Default_Cancellation_Reason__c);
                } else if (isUpdate && r.shiftCancelled != null && r.shiftCancelled == 'No') {
                    shift.put('sirenum__Cancelled__c', false);
                    shift.put('sirenum__CancellationReason__c', null);
                } else if (!isUpdate && r.shiftCancelled != null && r.shiftCancelled == 'Yes') {
                    infoMessage += '* Cannot import cancelled Shifts; \r\n';
                }

                //If Reference is provided, add it to the reference field as defined in custom settings
                if (r.shiftReferenceN != null && r.shiftReferenceN != '') {
                    if (shiftUniqueRefs.contains(r.shiftReferenceN)) {
                        //error - the import file contains more than one shift with a unique reference
                        infoMessage += '* There already is a shift with that reference number in the import file; \r\n';
                        stopTransaction = true;
                    } else {
                        shift.put(settings.shiftImportSettings.Match_Shifts__c, r.shiftReferenceN);
                        shiftUniqueRefs.add(r.shiftReferenceN);
                    }
                }

                //Add shift comments if any
                if (r.shiftComments != null && r.shiftComments != '') {
                    shift.put('Notes_Internal_Only__c', r.shiftComments.abbreviate(255));
                    shift.put('sirenum__Comments_By__c', 'AUTO');
                }

                 //Add PO Number if any
                 if (r.shiftPONumber != null && r.shiftPONumber != '') {
                    shift.put('PO_Number__c', r.shiftPONumber.abbreviate(255));
                }

                // Add Shift Type
                if (r.shiftType != null && r.shiftType != '') {
                    shift.put('Shift_Type__c', r.shiftType);
                }                

                // Add Booked By
                if (r.shiftBookedBy != null && r.shiftBookedBy != '') {
                    shift.put('Booked_By__c', r.shiftBookedBy);
                }

                //Check if start time is missing
                if (r.shiftAcStart == null || r.shiftAcStart == '') {
                    infoMessage += '* No Start Time;  \r\n';
                    stopTransaction = true;
                }
                //Check if end time is missing
                if (r.shiftAcEnd == null || r.shiftAcEnd == '') {
                    infoMessage += '* No End Time; \r\n';
                    stopTransaction = true;
                }
                //Check if date is missing
                if (r.shiftScheduledDate_parsed == null && r.shiftScheduledDate == null) {
                    infoMessage += '* No Scheduled Date;  \r\n';
                    stopTransaction = true;
                }

                //Check if Booking date is missing
                if (r.shiftBookingDate_parsed == null && r.shiftBookingDate == null) {
                    infoMessage += '* No Booking Date;  \r\n';
                    stopTransaction = true;
                }                

                // Check for valid scheduled date
                if (r.shiftScheduledDate_parsed == null) {
                    try {
                        parseTime(r.shiftScheduledDate);
                    } catch (Exception e) {
                        infoMessage += '* Invalid Scheduled Date: ' + r.shiftScheduledDate + ' - please use ISO format format YYYY-MM-DD;  \r\n';
                        stopTransaction = true;
                    }
                }

                // Check for valid booking date
                if (r.shiftBookingDate_parsed == null) {
                    try {
                        parseTime(r.shiftBookingDate);
                    } catch (Exception e) {
                        infoMessage += '* Invalid Booking Date: ' + r.shiftBookingDate + ' - please use ISO format format YYYY-MM-DD;  \r\n';
                        stopTransaction = true;
                    }
                }                

                //If stop transaction is not triggered
                if (stopTransaction == false) {
                    Time startTime;
                    Time endTime;
                    Boolean errorParsingTimes = false;

                    try {
                        startTime = parseTime(r.shiftAcStart);
                    } catch (Exception e) {
                        infoMessage += '* Bad Start time: ' + r.shiftAcStart + ' - please use HH:mm format;  \r\n';
                        stopTransaction = true;
                        errorParsingTimes = true;
                    }

                    try {
                        endTime = parseTime(r.shiftAcEnd);
                    } catch (Exception e) {
                        infoMessage += '* Bad End time: ' + r.shiftAcEnd + ' - please use HH:mm format;  \r\n';
                        stopTransaction = true;
                        errorParsingTimes = true;
                    }

                    if (!errorParsingTimes) {
                        if (r.shiftScheduledDate_parsed != null) {
                            Datetime schStart = Datetime.newInstance(r.shiftScheduledDate_parsed, startTime);
                            Datetime schEnd = Datetime.newInstance(r.shiftScheduledDate_parsed, endTime);

                            if (schStart < schEnd) {
                                shift.put('sirenum__Scheduled_Start_Time__c', schStart);
                                shift.put('sirenum__Scheduled_End_Time__c', schEnd);
                            } else {
                                shift.put('sirenum__Scheduled_Start_Time__c', schStart);
                                shift.put('sirenum__Scheduled_End_Time__c', schEnd.addDays(1));
                            }
                        } else {
                            infoMessage += '* Invalid Scheduled Date: ' + r.shiftScheduledDate_parsed + ' - please use ISO format format YYYY-MM-DD;  \r\n';
                            stopTransaction = true;
                            errorParsingTimes = true;
                        }
                    }

                    if (!errorParsingTimes) {
                        if (r.shiftBookingDate_parsed != null) {
                            shift.put('Booking_Date__c', r.shiftBookingDate_parsed);
                        } else {
                            infoMessage += '* Invalid Booking Date: ' + r.shiftBookingDate_parsed + ' - please use ISO format format YYYY-MM-DD;  \r\n';
                            stopTransaction = true;
                            errorParsingTimes = true;
                        }
                    }                   
                }

                //ERROR - Create a row for problematic shifts
                if (infoMessage != '') {
                    infoRow er = new infoRow();
                    er.infoReference = r.shiftReferenceN;
                    er.infoRota = (r.shiftRota == null) ? '' : r.shiftRota;
                    er.infoTeam = (r.shiftTeam == null) ? '' : r.shiftTeam;
                    er.infoSite = (r.shiftStation == null) ? '' : r.shiftStation;
                    // er.infoLocation = (r.shiftLocation == null) ? '' : r.shiftLocation;
                    er.infoPONumber = (r.shiftPONumber == null || r.shiftPONumber == '') ? '' : r.shiftPONumber;
                    er.infoScheduledDate = (r.shiftScheduledDate == null) ? '' : r.shiftScheduledDate_parsed != null ?
                        convertToDatetime(r.shiftScheduledDate_parsed).format('yyyy-MM-dd') : r.shiftScheduledDate;
                    er.infoBookingDate = (r.shiftBookingDate == null) ? '' : r.shiftBookingDate_parsed != null ?
                    String.valueOf(r.shiftBookingDate_parsed) : r.shiftBookingDate;
                    er.infoStart = (r.shiftAcStart == null || r.shiftAcStart == '') ? '' : String.valueOf(r.shiftAcStart);
                    er.infoEnd = (r.shiftAcEnd == null || r.shiftAcEnd == '') ? '' : String.valueOf(r.shiftAcEnd);
                    er.infoOpenings = r.shiftDemands == null ? '' : String.valueOf(r.shiftDemands);
                    er.infoComments = (r.shiftComments == null || r.shiftComments == '') ? '' : r.shiftComments;
                    er.infoShiftType = (r.shiftType == null || r.shiftType == '') ? '' : r.shiftType;
                    er.infoBookedBy = (r.shiftBookedBy == null || r.shiftBookedBy == '') ? '' : r.shiftBookedBy;
                    er.infoContact = (r.shiftContact == null || r.shiftContact == '') ? '' : r.shiftContact;
                    er.infoMessage = isUpdate ? 'Cannot update: \r\n ' + infoMessage : 'Cannot insert: \r\n' + infoMessage;
                    er.rawInfoMessage = infoMessage;
                    er.infoCancellation = r.shiftCancelled == null ? 'No' : r.shiftCancelled;
                    er.infoAuto = false;
                    er.isSuccess = false;
                    infoRows.add(er);

                    String failureRec = er.infoReference + ' ' + er.infoContact + ' ' + er.infoScheduledDate + ' ' + er.infoBookingDate + ' ' + er.infoStart + ' ' + er.infoEnd + ' ' + infoMessage + '; ';
                    failedImports.add(failureRec);
                    //reset
                    infoMessage = '';

                } else {
                    shiftsToUpsert.add(shift);
                }
            }

            /*//////////////////////////////////////////
            //                                        //
            //              Database                  //
            //                                        //                
            *///////////////////////////////////////////
            Set<Id> successes = new Set<Id>();

            List<sirenum__Shift__c> shiftsForDML = new List<sirenum__Shift__c>();

            for (SObject so : shiftsToUpsert) {
                shiftsForDML.add((sirenum__Shift__c) so);
            }

            if (shiftsForDML.size() > 0) {

                // Added to fail during a Test
                system.debug('SPC ThrowTestException > ' + throwTestException);
                if(throwTestException == true) {
                    for(sirenum__Shift__c s : shiftsForDML) {
                        s.sirenum__Scheduled_Start_Time__c = Datetime.newInstance(999, 1, 1, 0, 0, 0);
                    }
                }

                Database.UpsertResult[] srList = Database.upsert(shiftsForDML, false);

                Integer upsertResultIndex = 0;
                for (Database.UpsertResult sr : srList) {
                    
                    if (sr.isSuccess() && throwTestException == false) {
                        System.debug('Successfully inserted shift. Shift ID: ' + sr.getId());
                        successes.add(sr.getId());
                    } else {
                        SObject problematicShift = shiftsToUpsert.get(upsertResultIndex);
                        for (Database.Error err : sr.getErrors()) {
                            infoRow er = new infoRow();
                            String shiftReference = (String) problematicShift.get(settings.shiftImportSettings.Match_Shifts__c);
                            er.infoReference = shiftReference != null ? shiftReference : (String) problematicShift.get('name');
                            er.infoRota = problematicShift.get('sirenum__rota__c') != null ? rotaNameMap.get((String) problematicShift.get('sirenum__rota__c')) : 'N/A';
                            er.infoTeam = problematicShift.get('sirenum__team__c') != null ? teamNameMap.get((String) problematicShift.get('sirenum__team__c')) : 'N/A';
                            er.infoSite = problematicShift.get('sirenum__site__c') != null ? siteNameMap.get((String) problematicShift.get('sirenum__site__c')) : 'N/A';
                            // er.infoLocation = problematicShift.get('sirenum__Location__c') != null ? locationNameMap.get((String) problematicShift.get('sirenum__Location__c')) : 'N/A';
                            er.infoContact = (String) problematicShift.get('sirenum__contact__c') != null ? contactNameMap.get((String) problematicShift.get('sirenum__contact__c')) : 'N/A';
                            Datetime startTime = (Datetime) problematicShift.get('sirenum__Scheduled_Start_Time__c');
                            Datetime endTime = (Datetime) problematicShift.get('sirenum__Scheduled_End_Time__c');
                            er.infoScheduledDate = String.valueOf(startTime.format('yyyy-MM-dd'));
                            Datetime bookingDate = (Datetime) problematicShift.get('Booking_date__c');
                            er.infoBookingDate = String.valueOf(bookingDate);                                                        
                            er.infoStart = String.valueOf(startTime.time()).left(5);
                            er.infoEnd = String.valueOf(endTime.time()).left(5);
                            er.infoOpenings = problematicShift.get('sirenum__Broadcasts__c') == null ? '' : String.valueOf((Decimal) problematicShift.get('sirenum__Broadcasts__c'));
                            er.infoCancellation = (Boolean) problematicShift.get('sirenum__Cancelled__c') == false ? 'No' : 'Yes';
                            er.infoComments = (String) problematicShift.get('Notes_Internal_Only__c');
                            er.infoShiftType = (String) problematicShift.get('Shift_Type__c');
                            er.infoBookedBy = (String) problematicShift.get('Booked_By__c');
                            er.infoPONumber = (String) problematicShift.get('PO_Number__c');

                            er.infoAuto = false;
                            er.isSuccess = false;

                            er.infoMessage = (err.getFields().size() > 0 ? err.getFields().get(0) + ':' : '') + err.getMessage();


                            infoRows.add(er);
                        }
                    }
                    upsertResultIndex++;
                }
            }

            List<SObject> newShifts = new List<SObject>();
            String trQuery = null;
            try {
                trQuery = 'SELECT id, name, sirenum__Contact__c, sirenum__Cancelled__c, sirenum__Broadcasts__c,' +
                        'sirenum__Scheduled_Start_Time__c, sirenum__Scheduled_End_Time__c, sirenum__contact__r.name, sirenum__site__r.name,' +
                        'sirenum__Location__r.name, sirenum__comments__c, sirenum__team__r.name, sirenum__rota__r.name, Notes_Internal_Only__c, PO_Number__c, Booking_date__c, Shift_Type__c, Booked_By__c';

                //Make sure we do not double add the field for shift matching
                if (trQuery.indexOf(settings.shiftImportSettings.Match_Shifts__c) == -1 &&
                        settings.shiftImportSettings.Match_Shifts__c.toLowerCase() != 'name' &&
                        settings.shiftImportSettings.Match_Shifts__c.toLowerCase() != 'id') {
                    trQuery += ', ' + settings.shiftImportSettings.Match_Shifts__c;
                }

                trQuery += ' FROM sirenum__shift__c WHERE id in: successes ';
                newShifts = Database.query(trQuery);
            } catch (Exception e) {
                throw new StringException('Results saved, but found an internal error:' + e.getMessage() + ' **' + trQuery);
            }

            //SUCCESS - Create a row for each successfully inserted shift
            for (SObject s : newShifts) {
                infoRow info = new infoRow();
                info.infoId = s.Id;
                info.conId = (String) s.get('sirenum__contact__c');
                String shiftReference = (String) s.get(settings.shiftImportSettings.Match_Shifts__c);
                info.infoReference = shiftReference != null ? shiftReference : (String) s.get('name');

                info.infoRota = s.get('sirenum__rota__c') != null ? (String) s.getSObject('sirenum__Rota__r').get('Name') : '';
                info.infoTeam = s.get('sirenum__team__c') != null ? (String) s.getSObject('sirenum__Team__r').get('Name') : '';
                info.infoSite = s.get('sirenum__site__c') != null ? (String) s.getSObject('sirenum__Site__r').get('Name') : '';
                // info.infoLocation = s.get('sirenum__Location__c') != null ? (String) s.getSObject('sirenum__Location__r').get('Name') : '';
                Datetime startTime = (Datetime) s.get('sirenum__Scheduled_Start_Time__c');
                Datetime endTime = (Datetime) s.get('sirenum__Scheduled_End_Time__c');
                info.infoScheduledDate = String.valueOf(startTime.date().format());
                Date bookingDate = (Date) s.get('Booking_Date__c');
                info.infoBookingDate = string.valueOf(bookingDate.format());
                system.debug('info.infoBookingDate > ' + info.infoBookingDate);
                info.infoStart = String.valueOf(startTime.time()).left(5);
                info.infoEnd = String.valueOf(endTime.time()).left(5);

                info.infoOpenings = s.get('sirenum__Broadcasts__c') == null ? '' : String.valueOf((Decimal) s.get('sirenum__Broadcasts__c'));
                info.infoComments = (String) s.get('Notes_Internal_Only__c');
                info.infoShiftType = (String) s.get('Shift_Type__c');
                info.infoBookedBy = (String) s.get('Booked_By__c');
                info.infoPONumber = (String) s.get('PO_Number__c');
                info.infoContact = (String) s.get('sirenum__contact__c') != null ? (String) s.getSObject('sirenum__Contact__r').get('Name') : '';
                info.infoCancellation = (Boolean) s.get('sirenum__Cancelled__c') == false ? 'No' : 'Yes';
                Boolean isUpdatedShift = dbShiftIds.contains(s.Id);
                info.infoMessage = isUpdatedShift ? 'Updated ' : 'Inserted ';
                Boolean isShiftDemand = s.get('sirenum__Broadcasts__c') != null ? true : false;
                info.infoMessage += isShiftDemand ? 'Shift Demand ' : 'Shift ';
                info.infoMessage += info.conId != null ? '[Assigned]' : '[Requirement]';
                info.isSuccess = true;
                info.infoAuto = false;
                infoRows.add(info);
                successIds.add(s.Id);
            }

            //Now send an email and create a DB results
            importResultsTrail(settings, successIds, failedImports);
            return infoRows;
        } catch (Exception e) {
            throw new StringException('Error: ' + e.getMessage() + ' - ' + e.getLineNumber());
        }
    }

    public static void importResultsTrail(globalSettings settings, List<String> successIDs, List<String> failedImports) {
        //Handle leaving a trail
        ShiftImportLog__c itd = new ShiftImportLog__c();
        String SuccessesResult = '';

        for (String s : successIDs) {
            SuccessesResult += s + ', ';
        }

        itd.Successes__c = SuccessesResult;
        String ErrorsResult = '';

        for (String e : failedImports) {
            ErrorsResult += e + ' ';
        }

        itd.Errors__c = ErrorsResult;
        Database.insert(itd, false);

        //Send an email
        tempSettings tSettings = new tempSettings();

        if (tSettings.emailRecipient != null && tSettings.emailRecipient != '' && settings.shiftImportSettings.Send_Email_Results__c) {
            if (successIDs.size() > 0) {
                
                if (!Test.isRunningTest()) {
                    Messaging.reserveSingleEmailCapacity(1);
                }                

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                String[] toAddresses = new String[]{
                        tSettings.emailRecipient
                };

                mail.setToAddresses(toAddresses);
                mail.setSenderDisplayName('Import tool');
                mail.setSubject('Import Results');
                mail.setUseSignature(false);

                String BodyCompiled = 'You can delete these shifts by copying the results and pasting them in the Import Tool -> Settings section \r\n' +
                        ' Records: ' + SuccessesResult;

                mail.setPlainTextBody(BodyCompiled);
                mail.setHtmlBody(BodyCompiled);

                if (!Test.isRunningTest()) {
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[]{
                        mail
                    });
                }
            }
        }
    }

    // /*
    // Function to delete shifts
    // */
    // public void doDelete() {
    //     try {
    //         if (tSettings.emailRecipient == null || tSettings.emailRecipient == '') {
    //             throw new StringException('Please enter valid email');
    //         }

    //         if (tSettings.deleteLines != null && tSettings.deleteLines != '') {
    //             String[] itemsToDelete = tSettings.deleteLines.removeEnd(',').removeEnd(', ').split(', ');

    //             if (itemsToDelete.size() > 0) {
    //                 List<String> successes = new List<String>();
    //                 List<String> errors = new List<String>();
    //                 ShiftImportLog__c itd = new ShiftImportLog__c();
    //                 Boolean success = true;
    //                 Database.DeleteResult[] srList = Database.delete(itemsToDelete, false);

    //                 for (Database.DeleteResult sr : srList) {
    //                     if (sr.isSuccess()) {
    //                         System.debug('Successfully deleted record. Record ID: ' + sr.getId());
    //                         successes.add(sr.getId());
    //                     } else {
    //                         for (Database.Error err : sr.getErrors()) {
    //                             System.debug('The following error has occurred.');
    //                             System.debug(err.getStatusCode() + ': ' + err.getMessage());
    //                             System.debug('Record fields that affected this error: ' + err.getFields());

    //                             errors.add(sr.getId() + ' Error: ' + err.getStatusCode() + ': ' + err.getMessage());
    //                             success = false;
    //                         }
    //                     }
    //                 }

    //                 //If settings allow sending email results, then send them else don't 
    //                 if (gSettings.shiftImportSettings.Send_Email_Results__c) {
    //                     Messaging.reserveSingleEmailCapacity(1);
    //                     Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    //                     String[] toAddresses = new String[]{
    //                             tSettings.emailRecipient
    //                     };

    //                     mail.setToAddresses(toAddresses);

    //                     String resultType = success == true ? ': success' : ': Error ';
    //                     mail.setSenderDisplayName('Import tool');
    //                     mail.setSubject('Deletion ' + resultType);
    //                     mail.setUseSignature(false);

    //                     String SuccessesResult = '';

    //                     for (String s : successes) {
    //                         SuccessesResult += s + ', ';
    //                     }

    //                     String ErrorsResult = '';

    //                     for (String e : errors) {
    //                         ErrorsResult += e + ', ';
    //                     }

    //                     itd.Success_Deletions__c = SuccessesResult;
    //                     itd.Error_Deletions__c = ErrorsResult;
    //                     Database.insert(itd, false);
    //                     String BodyCompiled = 'The results from the operation are: ' +
    //                             ' Succsesses: ' + SuccessesResult + ' ' +
    //                             ' Errors: ' + ErrorsResult + ' .' ;

    //                     mail.setPlainTextBody(BodyCompiled);
    //                     mail.setHtmlBody(BodyCompiled);

    //                     if (!Test.isRunningTest()) {
    //                         Messaging.sendEmail(new Messaging.SingleEmailMessage[]{
    //                                 mail
    //                         });
    //                     }

    //                     ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.INFO, 'Success!');
    //                     ApexPages.addMessage(errorMsg);
    //                 }
    //             }
    //         }
    //     } catch (Exception e) {
    //         ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: ' + e.getMessage() + ' - ' + e.getLineNumber());
    //         ApexPages.addMessage(errorMsg);
    //     }
    // }

    /*
    PARSING FUNCTIONS
    */

    /**
    This function attempts to take a time string and to convert it to a time object
    */
    public static Time parseTime(String value) {
        Boolean isPM = false, isAM = false;
        value = value.toLowerCase();
        isAM = (value.contains('am'));
        isPM = (value.contains('pm'));
        value = value.replace('p', '').replace('a', '').replace('m', '').replace('.', ':').replace(' ', '');

        if (!value.contains(':') && value.length() > 2) {
            if (value.length() == 3) {
                value = value.left(1) + ':' + value.substring(1);
            } else {
                value = value.left(2) + ':' + value.substring(2);
            }
        }

        String[] parts = value.split(':');
        Integer h = 0, m = 0, s = 0;
        h = Integer.valueOf(parts[0]);

        if (parts.size() > 1) {
            m = Integer.valueOf(parts[1]);
        }

        if (parts.size() > 2) {
            s = Integer.valueOf(parts[2]);
        }

        if (isPM && h < 12) {
            h += 12;
        }

        if (isAM && h >= 12) {
            h -= 12;
        }

        Time t = Time.newInstance(h, m, s, 0);
        return t;
    }

    /**
    * Parse cancellation keywords
    */
    public static String parseCancellation(String shiftCancelled) {
        if (shiftCancelled == null || shiftCancelled == '') {
            return 'No';
        }

        if ('yes'.equalsIgnoreCase(shiftCancelled) ||
                'y'.equalsIgnoreCase(shiftCancelled) ||
                '1'.equalsIgnoreCase(shiftCancelled) ||
                'true'.equalsIgnoreCase(shiftCancelled) ||
                'cancelled'.equalsIgnoreCase(shiftCancelled) ||
                'cancel'.equalsIgnoreCase(shiftCancelled) ||
                'delete'.equalsIgnoreCase(shiftCancelled) ||
                'del'.equalsIgnoreCase(shiftCancelled)
                ) {
            return 'Yes';
        } else {
            return 'No';
        }
    }

    /**
     * Creates a new date instance from a date in an ISO string format
     *
     * @param value the date string in a standard date format “yyyy-MM-dd” in the local time zone.
     *
     * @return the new date instance
     */
    public static Date parseDate(Object value) {
        try {
            // Parse string in ISO format
            if (value instanceof String) {
                return Date.valueOf((String) value);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error parsing date: ' + e);
            throw e;
        }
        // Unknown type, return null
        return null;
    }

        /**
         * Auxiliary method to create a new instance of Datetime from an existing instance of Date.
         * This conversion considers the contextual time zone.
         *
         * @param value The date for which a date/time is required. Must not be null
         *
         * @return A new Datetime object with the same date as the date provided and ZERO_TIME as time.
         */
        public static Datetime convertToDatetime(Date value) {
            return Datetime.newInstance(value, Time.newInstance(0, 0, 0, 0));
        }
    }