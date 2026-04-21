@isTest
private class ShiftMatchManagerTest {
    
    // Test data setup
    @TestSetup
    static void setupTestData() {
        // Create Account
        Account acc = new Account(
            Name = 'Test Account',
            Shiftmatch_Last_Sync_Date__c = null,
            Shiftmatch_Counter__c = 0,
            tc9_pr__Available_Payment_Methods__c = 'Payee Australian Bank',
            tc9_pr__Maximum_Payment_Distributions__c = '2'
        );
        insert acc;

        contact con = new contact(lastName='test data');
        insert con;
        
        tc9_et__Award_Classifications_and_Levels__c award1 = new tc9_et__Award_Classifications_and_Levels__c(Name='Enrolled Nurse');
        tc9_et__Award_Classifications_and_Levels__c award2 = new tc9_et__Award_Classifications_and_Levels__c(Name='Registered Nurse');
        insert new List<tc9_et__Award_Classifications_and_Levels__c> { award1, award2 };

        sirenum__Job_Type__c jobType1 = new sirenum__Job_Type__c(Name = 'Enrolled Nurse');        
        sirenum__Job_Type__c jobType2 = new sirenum__Job_Type__c(Name = 'Registered Nurse');        
        insert new List<sirenum__Job_Type__c> { jobType1, jobType2 };

        sirenum__ProActiveContract__c contract = new sirenum__ProActiveContract__c(name = 'Text contract', sirenum__Client__c = acc.Id);
        insert contract;

        sirenum__Team__c jobRole = new sirenum__Team__c();
        jobRole.Name = 'Registered Nurse';
        jobRole.sirenum__Account__c = contract.Id;
        jobRole.tc9_ext_sirint__Award_Classification__c = award2.Id;
        jobRole.sirenum__Job_Type__c = jobType2.Id;
        insert jobRole;

        sirenum__Team__c multiJobRole = new sirenum__Team__c();
        multiJobRole.Name = 'Multi';
        multiJobRole.sirenum__Account__c = contract.Id;
        insert multiJobRole;


        insert new SIM_General_Settings__c(Shiftmatch_Endpoint__c = 'https://test.com/soap', Shiftmatch_Minimum_Interval_mins__c = 1);

           // Create a test shift
        sirenum__Shift__c shift = new sirenum__Shift__c(
            VMS_External_Id__c = acc.Id + '_SFT001',
            VMS_Source__c = ShiftMatchManager.SHIFTMATCH_VMS_SOURCE,
            //sirenum__Contact__c = con.Id,
            sirenum__Team__c = jobRole.Id,
            sirenum__Scheduled_Start_Time__c = System.now().addDays(5),
            sirenum__Scheduled_End_Time__c = System.now().addDays(5).addHours(8),
            sirenum__Broadcasts__c =1
        );
        insert shift;

        List<sirenum__TicketType__c> ticketType = new List<sirenum__TicketType__c> {
            new sirenum__TicketType__c (name='Enrolled Nurse', Is_Role_Competency__c = true),
            new sirenum__TicketType__c (name='Registered Nurse', Is_Role_Competency__c = true),
            new sirenum__TicketType__c (name='Intensive Care Experience'),
            new sirenum__TicketType__c (name='Sunrise Training'),
            new sirenum__TicketType__c (name='Medical/Surgical Experience')
        };        
        insert ticketType;

        sirenum__ticket__c ticket = new sirenum__ticket__c();
        ticket.sirenum__TicketType__c = ticketType[0].Id;
        ticket.sirenum__Owner__c = con.Id;
        insert ticket;

        VMS_Candidate__c candidate = new VMS_Candidate__c();
        candidate.VMS_Account__c = acc.Id;
        candidate.Candidate__c = con.Id;
        candidate.VMS_Source__c = ShiftMatchManager.SHIFTMATCH_VMS_SOURCE;
        insert candidate;

        VMS_Filled_Shift__c filledShift = new VMS_Filled_Shift__c();
        filledShift.VMS_Account__c = acc.Id;
        filledShift.Shift__c = shift.Id;
        filledShift.VMS_Source__c = ShiftMatchManager.SHIFTMATCH_VMS_SOURCE;
        insert filledShift;
       
        
        // Create Shiftmatch_Location__c records
        Shiftmatch_Location__c parentLocation = new Shiftmatch_Location__c(
            Name = '44090',
            Abbreviation__c = 'PAR',
            Description__c = 'Parent Location',
            Level__c = 1,
            Account__c = acc.Id
        );
        insert parentLocation;
        
        Shiftmatch_Location__c childLocation = new Shiftmatch_Location__c(
            Name = '200',
            Abbreviation__c = 'CHI',
            Description__c = 'Child Location',
            Level__c = 2,
            Parent_Location__c = parentLocation.Id,
            Account__c = acc.Id,
            Child_Account__c = acc.Id,
            Site__c = null,
            Location__c = null
        );
        insert childLocation;

        insert new List<sirenum__Sirenum_Condition_Membership__c> {
            new sirenum__Sirenum_Condition_Membership__c(sirenum__TicketType__c = ticketType[2].id, sirenum__Team__c = jobRole.Id),
            new sirenum__Sirenum_Condition_Membership__c(sirenum__TicketType__c = ticketType[3].id, sirenum__Team__c = jobRole.Id),
            new sirenum__Sirenum_Condition_Membership__c(sirenum__TicketType__c = ticketType[0].id, sirenum__Job_Type__c = jobType1.Id),
            new sirenum__Sirenum_Condition_Membership__c(sirenum__TicketType__c = ticketType[1].id, sirenum__Job_Type__c = jobType2.Id)
        };
        
        // Create Shiftmatch_Grading__c records
        List<Shiftmatch_Grading__c> grading = new List<Shiftmatch_Grading__c> { 
            new Shiftmatch_Grading__c(
                Name = 'EN1',
                Short_Description__c = 'Enrolled Nurse 1',
                Priority__c = 1,
                Long_Description__c = 'Enrolled Nurse 1',
                Account__c = acc.Id,
                Award_Classification__c = award1.Id,
                Job_Type__c = jobType1.Id
            ),
    
            new Shiftmatch_Grading__c(
                Name = 'RN1',
                Short_Description__c = 'Registered Nurse 1',
                Priority__c = 2,
                Long_Description__c = 'Registered Nurse 1',                
                Award_Classification__c = award2.Id,
                Job_Type__c = jobType2.Id,
                Account__c = acc.Id         
            )
        };
        insert grading;
        
        List<Shiftmatch_Skill__c> skills = new List<Shiftmatch_Skill__c> { 
            new Shiftmatch_Skill__c(
                Name = '7674',
                Description__c = 'ICU',
                Priority__c = 1,                
                Account__c = acc.Id,
                Competency__c = ticketType[2].Id             
            ),
    
            new Shiftmatch_Skill__c(
                Name = '200',
                Description__c = 'Sunrise Training',
                Priority__c = 2,
                Account__c = acc.Id,
                Status__c = 'Mandatory Induction',
                Competency__c = ticketType[3].Id             
            ),

            new Shiftmatch_Skill__c(
                Name = '100',
                Description__c = 'General',
                Priority__c = 2,
                Account__c = acc.Id,
                Status__c = 'Optional',
                Competency__c = ticketType[4].Id             
            )
        };
        insert skills;
        
        insert new Replacement_Skill__c (
            Shiftmatch_Skill__c = skills[2].Id,
            Shiftmatch_Location__c = childLocation.Id,
            Replacement_Skill__c = skills[0].Id
        );

        insert new List<Job_Type_Rank__c> {
            new Job_Type_Rank__c(
                Account__c = acc.Id,
                Job_Type__c = jobType1.Id,                
                Rank__c = 1
            ),
            new Job_Type_Rank__c(
                Account__c = acc.Id,
                Job_Type__c = jobType2.Id,                
                Rank__c = 2
            )
        };

        insert new Shiftmatch_Skill_Job_Type__c (
            Shiftmatch_Skill__c = skills[0].Id,
            Job_Type__c = jobType2.Id
        );

        // Create VMS Shift Payload
        VMS_Shift_Payload__c payload = new VMS_Shift_Payload__c(
            External_Shift_ID__c = acc.Id + '_SFT001',
            Status__c = 'Error',
            VMS_Source__c = ShiftMatchManager.SHIFTMATCH_VMS_SOURCE,
            VMS_Account__c = acc.Id,
            Body__c = 
                '{"statusDescription" : "available",' +
                '"status" : 10,' +
                '"skills" : {' +
                '"entry" : [ "ICU", "Sunrise Training", "General" ]' +
                '},' +
                '"skillPkids" : {' +
                '"payroll" : null,' +
                '"idCollection" : [ 7674, 200, 100 ]' +
                '},' +
                '"shiftStart" : "06:00",' +
                '"shiftEnd" : "15:00",' +
                '"shift" : "06:00",' +
                '"providerId" : 126,' +
                '"pkidKey" : "KAA098",' +
                '"pkid" : 24336098,' +
                '"locationPkid4" : 0,' +
                '"locationPkid3" : 0,' +
                '"locationPkid2" : 0,' +
                '"locationPkid1" : 200,' +
                '"locationPkid0" : 44090,' +
                '"location4" : "",' +
                '"location3" : "",' +
                '"location2" : "",' +
                '"location1" : "Child Location",' +
                '"location0" : "Parent Location",' +
                '"hours" : 9.0,' +
                '"gradingMin" : "RN1",' +
                '"gradingMax" : "RN1",' +
                '"deadline" : "2039-09-09T05:00:00+10:00",' +
                '"day" : "2039-09-09T00:00:00+10:00",' +
                '"agencyNotes" : ""}' 
        );
        insert payload;
    }



    public class ShiftMatchWebserviceStubMock implements HttpCalloutMock {
        private String method;
        ShiftMatchWebserviceStubMock() {
            this.method = 'getShortfalls';
        }

        ShiftMatchWebserviceStubMock(String method) {
            this.method = method;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'text/xml; charset=UTF-8');

            
            String soapBody = '';

            if (this.method == 'getLocations') {
                soapBody = getLocationResponse();
            }  
            
            if (this.method == 'getGradings') {
                soapBody = getGradingResponse();
            }  
            
            if (this.method == 'getSkills') {
                soapBody = getSkillResponse();
            }  

            if (this.method == 'getShortfalls') {
                soapBody = getShortfallResponse();
            }  

            if (this.method == 'getShortfalls') {
                soapBody = getShortfallResponse();
            }  
            
            if (this.method == 'generalError') {
                soapBody = getGeneralErrorResponse();
            }
           
            if (this.method == 'addUser') {
                soapBody = getAddUserResponse();
            }

            if (this.method == 'getUser') {
                soapBody = getUsersResponse();
            }

            if (this.method == 'addUserTaken') {
                soapBody = getAddUserTakenResponse();
            }

            res.setBody(soapBody);
            return res;
        }

        private String getLocationResponse() {
            return 
                '<S:Envelope xmlns:S="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">' + 
                '<SOAP-ENV:Header/>' + 
                '   <S:Body>' + 
                '      <ns0:getLocationsResponse xmlns:ns0="http://bridge.impl.webservice.cascom.gate121.com/">' + 
                '         <return>' + 
                '            <dataList/>' + 
                '            <dataObject xsi:type="ns0:bridgeLocation" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' + 
                '               <abbreviation/>' + 
                '               <child>' + 
                '                  <abbreviation>lv1</abbreviation>' + 
                '                  <child>' + 
                '                     <abbreviation>lv2</abbreviation>' + 
                '                     <child>' + 
                '                        <abbreviation>lv3</abbreviation>' + 
                '                        <description>level3</description>' + 
                '                        <level>3</level>' + 
                '                        <pkid>44093</pkid>' + 
                '                     </child>' + 
                '                     <description>level2</description>' + 
                '                     <level>2</level>' + 
                '                     <pkid>44092</pkid>' + 
                '                  </child>' + 
                '                  <description>level1</description>' + 
                '                  <level>1</level>' + 
                '                  <pkid>44091</pkid>' + 
                '               </child>' + 
                '			   <description>Base</description>' + 
                '               <level>0</level>' + 
                '               <pkid>44090</pkid>' + 
                '            </dataObject>' + 
                '            <mainMessage>location list</mainMessage>' + 
                '            <messages/>' + 
                '            <success>true</success>' + 
                '         </return>' + 
                '      </ns0:getLocationsResponse>' + 
                '   </S:Body>' + 
                '</S:Envelope>';
        }

        private String getUsersResponse() {
            return
                '<S:Envelope xmlns:S="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">' + 
                '   <SOAP-ENV:Header/>' + 
                '   <S:Body>' + 
                '      <ns0:getUsersResponse xmlns:ns0="http://bridge.impl.webservice.cascom.gate121.com/">' + 
                '         <return>' + 
                '            <dataList>' + 
                '               <userData>' + 
                '                  <contactInformation>' + 
                '                     <email/>' + 
                '                     <firstname>John</firstname>' + 
                '                     <lastname>Doe</lastname>' + 
                '                     <preferredName/>' + 
                '                  </contactInformation>' + 
                '                  <grading>RN1</grading>' + 
                '                  <locations>' + 
                '                     <entry>Base / level1 / level2 / level3</entry>' + 
                '                  </locations>' + 
                '                  <payroll>allianceuser</payroll>' + 
                '                  <pkid>428867</pkid>' + 
                '                  <role>Agency Casual</role>' + 
                '                  <skills>' + 
                '                     <entry>General</entry>' + 
                '                  </skills>' + 
                '               </userData>' + 
                '            </dataList>' + 
                '            <mainMessage>user list</mainMessage>' + 
                '            <messages/>' + 
                '            <success>true</success>' + 
                '         </return>' + 
                '      </ns0:getUsersResponse>' + 
                '   </S:Body>' + 
                '</S:Envelope>';
        }

        private String getGradingResponse() {
            return
                '<S:Envelope xmlns:S="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">' + 
                '   <SOAP-ENV:Header/>' + 
                '   <S:Body>' + 
                '      <ns0:getGradingsResponse xmlns:ns0="http://bridge.impl.webservice.cascom.gate121.com/">' + 
                '         <return>' + 
                '            <dataList>' + 
                '               <gradingData>' + 
                '                  <longDescription>Domestic</longDescription>' + 
                '                  <pkid>Domestic</pkid>' + 
                '                  <priority>2</priority>' + 
                '                  <shortDescription>Domestic</shortDescription>' + 
                '               </gradingData>' + 
                '               <gradingData>' + 
                '                  <longDescription>Environmental</longDescription>' + 
                '                  <pkid>Environmental</pkid>' + 
                '                  <priority>3</priority>' + 
                '                  <shortDescription>Environmental</shortDescription>' + 
                '               </gradingData>' + 
                '            </dataList>' + 
                '            <mainMessage>grading list</mainMessage>' + 
                '            <messages/>' + 
                '            <success>true</success>' + 
                '         </return>' + 
                '      </ns0:getGradingsResponse>' + 
                '   </S:Body>' + 
                '</S:Envelope>';
        }

        private String getSkillResponse() {
            return
                '<S:Envelope xmlns:S="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">' +
                '   <SOAP-ENV:Header/>' +
                '   <S:Body>' +
                '      <ns0:getSkillsResponse xmlns:ns0="http://bridge.impl.webservice.cascom.gate121.com/">' +
                '         <return>' +
                '            <dataList>' +
                '               <skillData>' +
                '                  <description>General</description>' +
                '                  <pkid>7674</pkid>' +
                '                  <priority>2</priority>' +
                '               </skillData>' +
                '               <skillData>' +
                '                  <description>ALS</description>' +
                '                  <pkid>7677</pkid>' +
                '                  <priority>5</priority>' +
                '               </skillData>' +
                '            </dataList>' +
                '            <mainMessage>skill list</mainMessage>' +
                '            <messages/>' +
                '            <success>true</success>' +
                '         </return>' +
                '      </ns0:getSkillsResponse>' +
                '   </S:Body>' +
                '</S:Envelope>';
        }

        private String getShortfallResponse() {
            return
                '<S:Envelope xmlns:S="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">' +
                '   <SOAP-ENV:Header/>' +
                '   <S:Body>' +
                '      <ns0:getShortfallsResponse xmlns:ns0="http://bridge.impl.webservice.cascom.gate121.com/">' +
                '         <return>' +
                '            <dataList>' +
                '               <shortfallData>' +
                '                  <agencyNotes/>' +
                '                  <day>2039-09-03T00:00:00+10:00</day>' +
                '                  <deadline>2039-09-03T05:00:00+10:00</deadline>' +
                '                  <gradingMax>RN1</gradingMax>' +
                '                  <gradingMin>RN1</gradingMin>' +
                '                  <hours>9.0</hours>' +
                '                  <location0>Parent Location</location0>' +
                '                  <location1>Child Location</location1>' +
                '                  <location2></location2>' +
                '                  <location3></location3>' +
                '                  <location4></location4>' +
                '                  <locationPkid0>44090</locationPkid0>' +
                '                  <locationPkid1>200</locationPkid1>' +
                '				  <locationPkid2>0</locationPkid2>' +
                '				  <locationPkid3>0</locationPkid3>' +
                '				  <locationPkid4>0</locationPkid4>' +
                '                  <pkid>24302978</pkid>' +
                '                  <pkidKey>JYS978</pkidKey>' +
                '                  <providerId>126</providerId>' +
                '                  <shift>06:00</shift>' +
                '                  <shiftEnd>15:00</shiftEnd>' +
                '                  <shiftStart>06:00</shiftStart>' +
                '                  <skillPkids>' +
                '                     <idCollection>7674</idCollection>' +
                '                  </skillPkids>' +
                '                  <skills>' +
                '                     <entry>ICU</entry>' +
                '                  </skills>' +
                '                  <status>10</status>' +
                '                  <statusDescription>available</statusDescription>' +
                '               </shortfallData>' +
                '               <shortfallData>' +
                '                  <agencyNotes/>' +
                '                  <day>2039-09-09T00:00:00+10:00</day>' +
                '                  <deadline>2039-09-09T05:00:00+10:00</deadline>' +
                '                  <gradingMax>RN1</gradingMax>' +
                '                  <gradingMin>EN1</gradingMin>' +
                '                  <hours>9.0</hours>' +
                '                  <location0>Parent Location</location0>' +
                '                  <location1>Child Location</location1>' +
                '                  <location2></location2>' +
                '                  <location3></location3>' +
                '                  <location4></location4>' +
                '                  <locationPkid0>44090</locationPkid0>' +
                '                  <locationPkid1>200</locationPkid1>' +
                '				  <locationPkid2>0</locationPkid2>' +
                '				  <locationPkid3>0</locationPkid3>' +
                '				  <locationPkid4>0</locationPkid4>				  ' +
                '                  <pkid>24336098</pkid>' +
                '                  <pkidKey>KAA098</pkidKey>' +
                '                  <providerId>126</providerId>' +
                '                  <shift>06:00</shift>' +
                '                  <shiftEnd>15:00</shiftEnd>' +
                '                  <shiftStart>06:00</shiftStart>' +
                '                  <skillPkids>' +
                '                     <idCollection>100</idCollection>' +                
                '                     <idCollection>200</idCollection>' +                
                '                  </skillPkids>' +
                '                  <skills>' +
                '                     <entry>General</entry>' +
                '                     <entry>Sunrise Training</entry>' +
                '                  </skills>' +
                '                  <status>10</status>' +
                '                  <statusDescription>available</statusDescription>' +
                '               </shortfallData>' +
                '            </dataList>' +
                '            <mainMessage>shortfall all list : count 2</mainMessage>' +
                '            <messages/>' +
                '            <success>true</success>' +
                '         </return>' +
                '      </ns0:getShortfallsResponse>' +
                '   </S:Body>' +
                '</S:Envelope>';
        }

        private String getGeneralErrorResponse() {
            return 
                '<S:Envelope xmlns:S="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">' +
                '<SOAP-ENV:Header/>' +
                '<S:Body>' +
                '    <ns0:addUserResponse xmlns:ns0="http://bridge.impl.webservice.cascom.gate121.com/">' + 
                '        <return>' +
                '            <exceptionName>com.gate121.cascom.exception.NoAccountException</exceptionName>' +
                '            <mainMessage>error : NoAccountException: We have no account with that Id</mainMessage>' +
                '            <success>false</success>' +
                '        </return>' +
                '    </ns0:addUserResponse>' +
                '</S:Body>' +
                '</S:Envelope>';
        }

        private String getAddUserTakenResponse() {
            return 
                '<S:Envelope xmlns:S="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">' +
                '<SOAP-ENV:Header/>' +
                '<S:Body>' +
                '    <ns0:addUserResponse xmlns:ns0="http://bridge.impl.webservice.cascom.gate121.com/">' + 
                '        <return>' +
                '            <exceptionName>com.gate121.cascom.exception.NoAccountException</exceptionName>' +
                '            <mainMessage>That shortfall is already taken</mainMessage>' +
                '            <success>false</success>' +
                '        </return>' +
                '    </ns0:addUserResponse>' +
                '</S:Body>' +
                '</S:Envelope>';
        }

        private String getAddUserResponse() {
            return 
                '<S:Envelope xmlns:S="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">' +
                '<SOAP-ENV:Header/>' +
                '<S:Body>' +
                '    <ns0:addUserResponse xmlns:ns0="http://bridge.impl.webservice.cascom.gate121.com/">' + 
                '        <return>' +                
                '            <mainMessage/>' +
                '            <success>true</success>' +
                '        </return>' +
                '    </ns0:addUserResponse>' +
                '</S:Body>' +
                '</S:Envelope>';
        }
         
    }    
    
    @isTest
    static void testRefreshShiftmatchLocationMapData() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        //setupMetadata(acc.Id);
        
        // Mock custom metadata access in the method
        Test.startTest();        
        // Use dynamically created metadata mock
        Test.setMock(HttpCalloutMock.class, new ShiftMatchWebserviceStubMock('getLocations'));
        
        ShiftMatchLocationService.refreshShiftmatchLocations(new List<Id>{acc.Id});
        Test.stopTest();
        
        // Verify locations were processed
        List<Shiftmatch_Location__c> locations = [
            SELECT Id, Name, Abbreviation__c, Description__c, Level__c, Parent_Location__c
            FROM Shiftmatch_Location__c 
            WHERE Account__c = :acc.Id
        ];
        
        System.assertEquals(4, locations.size());
    }
    
    @isTest
    static void testRefreshShiftmatchGradingMapData() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        //setupMetadata(acc.Id);
        
        // Mock custom metadata access in the method
        Test.startTest();
        // Use dynamically created metadata mock
        Test.setMock(HttpCalloutMock.class, new ShiftMatchWebserviceStubMock('getGradings'));
        
        ShiftMatchGradingService.refreshShiftmatchPayGrading(new List<Id>{acc.Id});

        Test.stopTest();        
        
        // Verify gradings were processed
        List<Shiftmatch_Grading__c> gradings = [
            SELECT Id, Name, Short_Description__c, Priority__c, Long_Description__c
            FROM Shiftmatch_Grading__c 
            WHERE Account__c = :acc.Id
        ];
        
        System.assertEquals(2, gradings.size());
    }

    @isTest
    static void testRefreshShiftmatchSkillMapData() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        //setupMetadata(acc.Id);
        
        // Mock custom metadata access in the method
        Test.startTest();
        // Use dynamically created metadata mock
        Test.setMock(HttpCalloutMock.class, new ShiftMatchWebserviceStubMock('getSkills'));
        
        ShiftMatchSkillService.refreshShiftmatchSkills(new List<Id>{acc.Id});

        Test.stopTest();        
        
        // Verify gradings were processed
        List<Shiftmatch_Skill__c> skills = [
            SELECT Id 
            FROM Shiftmatch_Skill__c 
            WHERE Account__c = :acc.Id
        ];
        
        System.assertEquals(2, skills.size());
    }

    @isTest
    static void testRefreshShiftmatchCandidateData() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        //setupMetadata(acc.Id);
        
        // Mock custom metadata access in the method
        Test.startTest();
        // Use dynamically created metadata mock
        Test.setMock(HttpCalloutMock.class, new ShiftMatchWebserviceStubMock('getUser'));
        
        ShiftMatchCandidateService.refreshShiftmatchCandidates(new List<Id>{acc.Id});

        Test.stopTest();        
        
        // Verify gradings were processed
        List<VMS_Candidate__c> candidates = [
            SELECT Id, name
            FROM VMS_Candidate__c
            WHERE VMS_Account__c = :acc.Id
        ];
        
        System.assertEquals(1, candidates.size());
        System.assertEquals('428867', candidates[0].name);
    }
        
    @isTest
    static void testReprocessShortfalls() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];        

        // Get existing payloads
        List<VMS_Shift_Payload__c> payloads = [
            SELECT Id
            FROM VMS_Shift_Payload__c            
        ];
                
        
        Test.startTest();

        ShiftMatchReprocessShortfallService.reprocessShiftmatchShortfalls(new List<List<Id>> {new List<Id>{payloads[0].Id}});
            
        Test.stopTest();

        List<sirenum__Shift__c> shifts = [SELECT Id FROM sirenum__Shift__c];
        System.assertEquals(2, shifts.size());            
    }

 

     @IsTest
    static void testSchedule() {  
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ShiftMatchWebserviceStubMock('getShortfalls'));        

        System.schedule('Test ShiftMatchScheduler', ShiftMatchScheduler.generateCronExpression(1), new ShiftMatchScheduler());        
        Test.stopTest();
    }
    
    @IsTest
    static void testProcessShortfalls() {  
        Test.startTest();        
        Test.setMock(HttpCalloutMock.class, new ShiftMatchWebserviceStubMock('getShortfalls'));        
        ShiftMatchManager manager = new ShiftMatchManager();
        manager.processShortfalls();        
        Test.stopTest();

        List<sirenum__Shift__c> shifts = [SELECT Id FROM sirenum__Shift__c where sirenum__Cancelled__c = false];
        System.assertEquals(2, shifts.size());            
    }
    
    @IsTest
    static void testProcessShortfalls_error() {  
        Test.startTest();        
        Test.setMock(HttpCalloutMock.class, new ShiftMatchWebserviceStubMock('generalError'));        
        ShiftMatchManager manager = new ShiftMatchManager();
        manager.processShortfalls();        
        Test.stopTest();

        List<sirenum__Shift__c> shifts = [SELECT Id FROM sirenum__Shift__c where sirenum__Cancelled__c = false];
        System.assertEquals(1, shifts.size());            
    }

    
    @isTest
    static void testHandlePublishedShiftsTrigger() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];        
        sirenum__Team__c jobRole = [SELECT Id FROM sirenum__Team__c LIMIT 1];
        sirenum__Shift__c demand = [SELECT Id FROM sirenum__Shift__c LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        // Create a test shift for the trigger
        sirenum__Shift__c shift = new sirenum__Shift__c(
            VMS_External_Id__c = acc.Id + '_SFT001',
            VMS_Source__c = ShiftMatchManager.SHIFTMATCH_VMS_SOURCE,
            sirenum__Contact__c = con.Id,
            sirenum__Team__c = jobRole.Id,
            sirenum__ShiftDemand__c = demand.Id,
            sirenum__Scheduled_Start_Time__c = System.now().addDays(5),
            sirenum__Scheduled_End_Time__c = System.now().addDays(5).addHours(8)
        );
        insert shift;        
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ShiftMatchWebserviceStubMock('addUser'));        

        shift.VMS_Send_Status__c = 'Ready To Send';        
        update shift;
        
        Test.stopTest();   
        
        List<sirenum__Shift__c> shifts = [SELECT Id FROM sirenum__Shift__c where VMS_Send_Status__c = 'Sent'];
        System.assertEquals(1, shifts.size());  
    }
    
    @isTest
    static void testHandlePublishedShiftsTrigger_taken() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];        
        sirenum__Team__c jobRole = [SELECT Id FROM sirenum__Team__c LIMIT 1];
        sirenum__Shift__c demand = [SELECT Id FROM sirenum__Shift__c LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        // Create a test shift for the trigger
        sirenum__Shift__c shift = new sirenum__Shift__c(
            VMS_External_Id__c = acc.Id + '_SFT001',
            VMS_Source__c = ShiftMatchManager.SHIFTMATCH_VMS_SOURCE,
            sirenum__Contact__c = con.Id,
            sirenum__Team__c = jobRole.Id,
            sirenum__ShiftDemand__c = demand.Id,
            sirenum__Scheduled_Start_Time__c = System.now().addDays(5),
            sirenum__Scheduled_End_Time__c = System.now().addDays(5).addHours(8)
        );
        insert shift;        
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ShiftMatchWebserviceStubMock('addUserTaken'));        

        shift.VMS_Send_Status__c = 'Ready To Send';        
        update shift;
        
        Test.stopTest(); 
        
        List<sirenum__Shift__c> shifts = [SELECT Id FROM sirenum__Shift__c where sirenum__Cancelled__c = true];
        System.assertEquals(1, shifts.size());  
    }

    @isTest
    static void testHandlePublishedShiftsTrigger_error() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];        
        sirenum__Team__c jobRole = [SELECT Id FROM sirenum__Team__c LIMIT 1];
        sirenum__Shift__c demand = [SELECT Id FROM sirenum__Shift__c LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        // Create a test shift for the trigger
        sirenum__Shift__c shift = new sirenum__Shift__c(
            VMS_External_Id__c = acc.Id + '_SFT001',
            VMS_Source__c = ShiftMatchManager.SHIFTMATCH_VMS_SOURCE,
            sirenum__Contact__c = con.Id,
            sirenum__Team__c = jobRole.Id,
            sirenum__ShiftDemand__c = demand.Id,
            sirenum__Scheduled_Start_Time__c = System.now().addDays(5),
            sirenum__Scheduled_End_Time__c = System.now().addDays(5).addHours(8)
        );
        insert shift;        
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ShiftMatchWebserviceStubMock('generalError'));        

        shift.VMS_Send_Status__c = 'Ready To Send';        
        update shift;
        
        Test.stopTest();  
        
        List<sirenum__Shift__c> shifts = [SELECT Id FROM sirenum__Shift__c where VMS_Send_Status__c = 'Ready To Send'];
        System.assertEquals(1, shifts.size());  
    }    

    @isTest
    static void testReprocessFilledShifts() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];        
        sirenum__Team__c jobRole = [SELECT Id FROM sirenum__Team__c LIMIT 1];
        sirenum__Shift__c demand = [SELECT Id FROM sirenum__Shift__c LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        // Create a test shift for the trigger
        sirenum__Shift__c shift = new sirenum__Shift__c(
            VMS_External_Id__c = acc.Id + '_SFT001',
            VMS_Source__c = ShiftMatchManager.SHIFTMATCH_VMS_SOURCE,
            sirenum__Contact__c = con.Id,
            sirenum__Team__c = jobRole.Id,
            sirenum__ShiftDemand__c = demand.Id,
            sirenum__Scheduled_Start_Time__c = System.now().addDays(5),
            sirenum__Scheduled_End_Time__c = System.now().addDays(5).addHours(8),
            VMS_Send_Status__c = 'Ready To Send'       
        );
        insert shift;        

        VMS_Filled_Shift__c filledShift = new VMS_Filled_Shift__c(
            Shift__c = shift.id,
            Status__c = 'Error',
            VMS_Account__c = acc.Id,
            VMS_Source__c = ShiftMatchManager.SHIFTMATCH_VMS_SOURCE
        );
        insert filledShift;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ShiftMatchWebserviceStubMock('addUser'));        
 
        ShiftMatchReprocessFilledShiftService.reprocessShiftmatchShortfalls(new List<List<Id>> {new List<Id>{filledShift.Id}});
        
        Test.stopTest();  
        
        List<sirenum__Shift__c> shifts = [SELECT Id FROM sirenum__Shift__c where VMS_Send_Status__c = 'Sent'];
        System.assertEquals(1, shifts.size());  
    }   
}