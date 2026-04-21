/* 
 * Class to build out the MessageMedia Response when a message is sent 
 */
public with sharing class SMSResponseMM {

    public list<Messages> messages{get;set;}
	public class Messages{
		public String message_expiry_timestamp{get;set;}
		public String format{get;set;}
		public list<String> message_flags{get;set;}
		public String destination_number{get;set;}
		public String message_id{get;set;}
		public Boolean delivery_report{get;set;}
		public String callback_url{get;set;}
        public Metadata metadata{get;set;}
        public String status{get;set;}
    }

    public class Metadata{
        public String salesforce_message_id{get;set;}
    }

}