/**
 * @description       : 
 * @author            : James Ridge
 * @group             : 
 * @last modified on  : 11-18-2022
 * @last modified by  : James Ridge
**/
public with sharing class SIM_LookupSearchController {
    private final static Integer MAX_RESULTS = 5;

    @AuraEnabled(Cacheable=true)
    public static String getSelectedRecords(Searchable searcher, List<String> selectedIds) {

        List<SIM_LookupSearchResult> results = new List<SIM_LookupSearchResult>();
        
        if(!isSearcherValid(searcher))
            return JSON.serialize(new SIM_Response.SuccessResponse(results));

        try{
            List<String> expr = new List<String>();
            expr.add('SELECT ' + String.join(getSearcherFields(searcher), ', '));
            expr.add('FROM ' + String.escapeSingleQuotes(searcher.objectName));
            expr.add('WHERE Id IN (\'' + String.join(new List<String>(new Set<String>(selectedIds)), '\', \'') + '\')');

            List<sObject> recents = Database.query(String.join(expr, ' '));

            if(recents.isEmpty()) 
                return JSON.serialize(new SIM_Response.SuccessResponse(results));

            for (sObject record : recents) {
                results.add(new SIM_LookupSearchResult(
                    record.Id, 
                    searcher.objectName, 
                    searcher.iconName, 
                    (String)record.get(searcher.title), 
                    (!String.isBlank(searcher.subtitle) ? (String)record.get(searcher.subtitle): ''))
                );
            }

            return JSON.serialize(new SIM_Response.SuccessResponse(results));
        }catch(Exception e){
            return JSON.serialize(new SIM_Response.ErrorResponse(String.format(
                Label.CRM_GeneralApexFailure,
                new Object[]{
                    e.getMessage(),
                    e.getLineNumber(),
                    e.getStackTraceString()
                }
            )));
        }
    }

    @AuraEnabled(Cacheable=true)
    public static String search(Searchable searcher, List<String> selectedIds) {
        List<SIM_LookupSearchResult> results = new List<SIM_LookupSearchResult>();

        if(!isSearcherValid(searcher))
            return JSON.serialize(new SIM_Response.SuccessResponse(results));

        try{    
            String find = 'FIND \'' + String.escapeSingleQuotes(searcher.searchTerm) + '*\' IN ALL FIELDS';
            String returning = 'RETURNING ' + getReturning(searcher.objectName, getSearcherFields(searcher));
            String limitter = 'LIMIT ' + (searcher.maxSearchResults == null ? MAX_RESULTS : searcher.maxSearchResults);
            String query = find + ' ' + returning + ' ' + limitter;

            List<List<SObject>> searchResults = System.Search.query(query);

            if(searchResults == null || searchResults.isEmpty()) 
                return JSON.serialize(new SIM_Response.SuccessResponse(results));

            for (sObject record : searchResults[0]) {
                results.add(new SIM_LookupSearchResult(
                    record.Id, 
                    searcher.objectName, 
                    searcher.iconName, 
                    (String)record.get(searcher.title), 
                    (!String.isBlank(searcher.subtitle) ? (String)record.get(searcher.subtitle): ''))
                );
            }

            // Optionnaly sort all results on title
            results.sort();

            return JSON.serialize(new SIM_Response.SuccessResponse(results));
        }catch(Exception e){
            return JSON.serialize(new SIM_Response.ErrorResponse(String.format(
                Label.CRM_GeneralApexFailure,
                new Object[]{
                    e.getMessage(),
                    e.getLineNumber(),
                    e.getStackTraceString()
                }
            )));
        }
    }

    @AuraEnabled(Cacheable=true)
    public static String getRecentlyViewed(Searchable searcher) {
        List<SIM_LookupSearchResult> results = new List<SIM_LookupSearchResult>();
        
        if(!isSearcherValid(searcher))
            return JSON.serialize(new SIM_Response.SuccessResponse(results));

        try{
            Set<Id> recentIds = new Set<Id>();
            for(RecentlyViewed rv : queryRecentByType(searcher)) {
                recentIds.add(rv.Id);
            }

            List<String> expr = new List<String>();
            expr.add('SELECT ' + String.join(getSearcherFields(searcher), ', '));
            expr.add('FROM ' + String.escapeSingleQuotes(searcher.objectName));
            expr.add('WHERE Id IN (\'' + String.join(new List<Id>(recentIds), '\', \'') + '\')');

            List<sObject> recents = Database.query(String.join(expr, ' '));

            if(recents.isEmpty()) 
                return JSON.serialize(new SIM_Response.SuccessResponse(results));

            for (sObject record : recents) {
                results.add(new SIM_LookupSearchResult(
                    record.Id, 
                    searcher.objectName, 
                    searcher.iconName, 
                    (String)record.get(searcher.title), 
                    (!String.isBlank(searcher.subtitle) ? (String)record.get(searcher.subtitle): ''))
                );
            }

            return JSON.serialize(new SIM_Response.SuccessResponse(results));
        }catch(Exception e){
            return JSON.serialize(new SIM_Response.ErrorResponse(String.format(
                Label.CRM_GeneralApexFailure,
                new Object[]{
                    e.getMessage(),
                    e.getLineNumber(),
                    e.getStackTraceString()
                }
            )));
        }
    }

    private static List<RecentlyViewed> queryRecentByType(Searchable searcher) {
		return [
			SELECT Id
			FROM RecentlyViewed
			WHERE Type = :searcher.objectName
			LIMIT :(searcher.maxSearchResults == null ? MAX_RESULTS : searcher.maxSearchResults)];
	}

    private static Boolean isSearcherValid(Searchable searcher){
        if(String.isBlank(searcher.title)) return false;
        if(String.isBlank(searcher.objectName)) return false;

        return true;
    }

    private static String getReturning(String objectName, List<String> fields) {
		List<String> returning = new List<String>();
		String objectWithFields = objectName + (fields.isEmpty() ? '' : joinReturnFields(fields));
		returning.add(objectWithFields);
		return String.join(returning, ', ');
	}
    private static String joinReturnFields(List<String> fields) {
		return ' (' + String.escapeSingleQuotes(String.join(fields, ', ')) + ')';
	}
    private static List<String> getSearcherFields(Searchable searcher){
		Set<String> sarchFields = new Set<String>{'Id', 'Name'};
        if(!String.isBlank(searcher.title))
            sarchFields.add(searcher.title);
        if(!String.isBlank(searcher.subtitle))
            sarchFields.add(searcher.subtitle);
		return new List<String>(sarchFields);
	}

    public class Searchable {
		@AuraEnabled
		public String searchTerm {get;set;}
		@AuraEnabled
		public String objectName {get;set;}
		@AuraEnabled
        public String title {get;set;}
        @AuraEnabled
        public String subtitle {get;set;}
        @AuraEnabled
		public String iconName {get;set;}
        @AuraEnabled
        public Integer maxSearchResults {get;set;}
	}
}