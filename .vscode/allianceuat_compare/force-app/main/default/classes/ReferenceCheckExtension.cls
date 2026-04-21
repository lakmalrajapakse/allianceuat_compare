public with sharing class ReferenceCheckExtension {
    // Put variables here
    public b3o__Reference__c record {get;set;}

    public ReferenceCheckExtension(ApexPages.StandardController stdController) {
        System.debug(LOGGINGLEVEL.ERROR, stdController.getId());
        
        this.record = [SELECT Id, 
            Name, 
            b3o__First_Name_Referee__c, 
            b3o__Last_Name_Referee__c, 
            b3o__Contact__r.FirstName, 
            b3o__Contact__r.LastName, 
            b3o__Position_Referee__c, 
            b3o__Email_Referee__c, 
            b3o__Phone_Referee__c,
            Happy_to_provide_References__c, 
            permission_to_disclose_this_reference__c, 
            Permission_to_disclose_reference_check__c, 
            AHPRA_based_investigations_or_disputes__c, 
            AHPRA_based_investigations_yes__c, 
            Describe_clinical_community_setting__c, 
            Applicant_s_duties_responsibilies__c, 
            Rating_applicant_s_ability_to_do_tasks__c,
            Ability_to_carry_out_daily_routines_1_3__c, 
            Applicant_can_work_unsupervised__c, 
            Work_well_unsupervised_No__c, 
            Worked_well_unsupervised__c, 
            Communication_Documentation_Skills__c, 
            Communication_Skills_1_3__c, 
            Clinical_Skills__c, 
            Clinical_Skill_More_Information__c, 
            Handling_medication_administration__c, 
            Handling_medication_administration_No__c, 
            Dealing_with_emergency_situation__c, 
            Dealing_with_emergency_situation_1_3__c, 
            Adhering_to_OHS_guidelines__c, 
            Adhering_to_OHS_guidelines_No__c, 
            Rehire_applicant_further_comments__c, 
            Rehire_applicant_further_comments_Yes__c
            FROM b3o__Reference__c 
            WHERE Id =:stdController.getId()];
    }

    public String firstNameApos {
        get {
            return this.record.b3o__Contact__r.FirstName + '\'s' ;
        }
    } 

    public boolean ratingDailyTasks {
        get {
            boolean result;
            switch on this.record.Rating_applicant_s_ability_to_do_tasks__c{
                when '1', '2', '3'{
                    result = true;
                }
                when '4', '5'{
                    result = false;
                }
            }
            return result;
        }
    } 

    public boolean ratingCommSkills {
        get {
            boolean result;
            switch on this.record.Communication_Documentation_Skills__c{
                when '1', '2','3'{
                    result = true;
                }
                when '4', '5'{
                    result = false;
                }
            }
            return result;
        }
    } 

    
    public boolean ratingClinicalSkills {
        get {
            boolean result;
            switch on this.record.Clinical_Skills__c{
                when 'Needing assistance'{
                    result = true;
                }
                when else{
                    result = false;
                }
            }
            return result;
        }
    } 

    public boolean ratingEmergencySits {
        get {
            boolean result;
            switch on this.record.Dealing_with_emergency_situation__c{
                when '1', '2','3'{
                    result = true;
                }
                when '4', '5'{
                    result = false;
                }
            }
            return result;
        }
    } 

    public String respProvideRefs{
        get {
            String result = responseYesNo(this.record.Happy_to_provide_References__c);
            return result;
        }
    }

    public String respDiscloseRefs{
        get {
            String result = responseYesNo(this.record.Permission_to_disclose_reference_check__c);
            return result;
        }
    }

    public String respAHPRAInvDisps{
        get {
            String result = responseYesNo(this.record.AHPRA_based_investigations_or_disputes__c);
            return result;
        }
    }

    public String respApplUnsupervised{
        get {
            String result = responseYesNo(this.record.Applicant_can_work_unsupervised__c);
            return result;
        }
    }

    public String respHandlingMeds{
        get {
            String result = responseYesNo(this.record.Handling_medication_administration__c);
            return result;
        }
    }

    public String respOHSGuidelines{
        get {
            String result = responseYesNo(this.record.Adhering_to_OHS_guidelines__c);
            return result;
        }
    }
    
    public String respRehireAppl{
        get {
            String result = responseYesNo(this.record.Rehire_applicant_further_comments__c);
            return result;
        }
    }

    private String responseYesNo(String reply){
            String result = '';
            switch on reply{
                when 'Yes'{
                    result += '<b>Yes</b> | No' ;     
                }
                when 'No'{
                    result += 'Yes | <b>No</b>' ; 
                }
            }
            return result;    
    }

    public String respDailyTasks {
        get {
            String result = responseRating(this.record.Rating_applicant_s_ability_to_do_tasks__c);
            return result;
        }
    }

    public String respCommSkills{
        get {
            String result = responseRating(this.record.Communication_Documentation_Skills__c);
            return result;
        }
    }
    
    public String respClinicalSkills {
        get {
            // String result = responseRating(this.record.Clinical_Skills__c);
            String result = '';
            switch on this.record.Clinical_Skills__c{
                when 'Needing assistance'{
                    result += 'Highly skilled | Competent | <b>Needing assistance</b> | Not applicable' ;     
                }
                when 'Highly skilled'{
                    result += '<b>Highly skilled</b> | Competent | Needing assistance | Not applicable' ;     
                }
                when 'Competent'{
                    result += 'Highly skilled | <b>Competent</b> | Needing assistance | Not applicable' ;     
                }
                when 'Not applicable'{
                    result += 'Highly skilled | Competent | Needing assistance | <b>Not applicable</b>' ;     
                }
            }
            return result;
        }
    }

    public String respEmergencySits {
        get {
            String result = responseRating(this.record.Dealing_with_emergency_situation__c);
            return result;
        }
    }

    private String responseRating(String rating){
            String result = '';
            switch on rating{
                when '1'{
                    result += '<b>1</b> | 2 | 3 | 4 | 5' ;     
                }
                when '2'{
                    result += '1 | <b>2</b> | 3 | 4 | 5' ;
                }
                when '3'{
                    result += '1 | 2 | <b>3</b> | 4 | 5' ;
                }
                when '4'{
                    result += '1 | 2 | 3 | <b>4</b> | 5' ;
                }
                when '5'{
                    result += '1 | 2 | 3 | 4 | <b>5</b>' ;
                }
            }
            return result;
    }

}