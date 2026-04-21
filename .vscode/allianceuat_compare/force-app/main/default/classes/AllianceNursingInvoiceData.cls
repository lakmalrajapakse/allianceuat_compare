public class AllianceNursingInvoiceData {

    public tc9_et__Invoice__c sfInvoice {get; set;}
    public Map<String, ItemGroup> itemGroupsMap {get; set;} 
    public List<Id> attachmentIds {get; set;}

    public String employeeName {get; set;}
    public String customerId {get; set;}
    public String purchaseOrder {get; set;}
    public String worksite {get; set;}
    public String clientName {get; set;}
    public String clientStreet {get; set;}
    public String clientCity {get; set;}
    public String clientState {get; set;}
    public String clientPostcode {get; set;}

    public AllianceNursingInvoiceData(){
        this.itemGroupsMap = new Map<String, ItemGroup>();
    }
    
    public AllianceNursingInvoiceData(tc9_et__Invoice__c invoice) {
        this.itemGroupsMap = new Map<String, ItemGroup>();
        this.sfInvoice = invoice;
        this.employeeName = invoice.tc9_et__Invoice_To_Contact__r.Name;
    }
    
    public List<ItemGroup> getItemGroups() {
        return this.itemGroupsMap.values();
    }

    private void populateClientDetail(tc9_et__Invoice_Item__c item) {
        this.clientName = this.clientName ?? item.tc9_et__Client__r.Name;
        this.clientStreet = this.clientStreet ?? item.tc9_et__Client__r.BillingStreet;
        this.clientCity = this.clientCity ?? item.tc9_et__Client__r.BillingCity;
        this.clientState = this.clientState ?? item.tc9_et__Client__r.BillingState;
        this.clientPostcode = this.clientPostcode ?? item.tc9_et__Client__r.BillingPostalcode;
        this.customerId = this.customerId ?? item.tc9_et__Client__r.Customer_ID__c;
        this.purchaseOrder = this.purchaseOrder ?? item.tc9_et__Pay_Transaction__r.tc9_et__Purchase_Order_Number__c;
        this.worksite = this.worksite ?? item.tc9_et__Pay_Transaction__r.tc9_et__Timesheet_Entry__r.tc9_ext_sirint__Site__r.Name;
    }

    public void addItem(tc9_et__Invoice_Item__c item, String groupKey, String subGroupKey) {
        if(itemGroupsMap == null) {
            this.itemGroupsMap = new Map<String, ItemGroup>();
        }
        
        if(this.itemGroupsMap.get(groupKey) != null) {
            this.itemGroupsMap.get(groupKey).addItem(item, subGroupKey);
            
        } else {
            ItemGroup itemGroup = new ItemGroup();
            itemGroup.addItem(item, subGroupKey);
            
            this.itemGroupsMap.put(groupKey, itemGroup);
        }

        populateClientDetail(item);
    }
    
    
    public class ItemGroup implements Comparable {
        public Map<String, ItemLine> subGroups {get; set;}
        
            
        public void addItem(tc9_et__Invoice_Item__c item, String subGroupKey) {
            if(subGroups == null) {
                this.subGroups = new Map<String, ItemLine>();
            }
            
            if(this.subGroups.get(subGroupKey) != null) {
                this.subGroups.get(subGroupKey).addTotal(item);
            } else {
                this.subGroups.put(subGroupKey, new ItemLine(item));
            }
        }

        public ItemLine getFirstGroupItemLine() {
            return subGroups.values()[0];
        }
        
        public List<ItemLine> getFollowingGroupItemLines() {
            if(subGroups.size() == 1) {
                return new List<ItemLine>();
            }
            
            List<ItemLine> tmpSubGroups = subGroups.values().clone();
            tmpSubGroups.remove(0);
            
            return tmpSubGroups;
        }

        public Integer compareTo(Object wrapperObj){
            return 1;
        }
    }
    
    public class ItemLine implements Comparable {
        public Date startDate {get; set;}
        public String shiftTimeString {get; set;} 
        public String timesheetFormula {get; set;}
        public String employeeName {get; set;}
        public String position {get; set;}
        public String payCodeType {get; set;}
        public Decimal quantity {get; set;}
        public Decimal rate {get; set;}
        public Decimal exGst {get; set;}
        public Decimal gst {get; set;}
        public Decimal total {get; set;}
        
        public ItemLine(tc9_et__Invoice_Item__c item) {
            Time startTime = item.tc9_et__Pay_Transaction__r.tc9_et__Timesheet_Entry__r.tc9_et__Start_Time__c;
            Time endTime = item.tc9_et__Pay_Transaction__r.tc9_et__Timesheet_Entry__r.tc9_et__End_Time__c;

            String startTimeString  = padLeft(startTime?.hour()) + padLeft(startTime?.minute());
            String endTimeString  = padLeft(endTime?.hour()) + padLeft(endTime?.minute());

            this.startDate = item.tc9_et__Pay_Transaction__r.tc9_et__Timesheet_Entry__r.tc9_et__Timesheet__r.tc9_et__Start_Date__c;
            this.shiftTimeString = startTimeString + ' - ' + endTimeString;
            this.timesheetFormula = item.tc9_et__Pay_Transaction__r.tc9_et__Timesheet_Entry__r.tc9_et__Timesheet_Formula__c;
            this.employeeName = item.tc9_et__Assignment__r.tc9_pr__Employee__r.Name;
            this.position = item.tc9_et__Assignment__r.tc9_pr__Assignment_Name__c;
            this.payCodeType = item.tc9_et__Pay_Code__r.Name;
            this.rate = item.tc9_et__Invoice_Rate__c ?? 0;
            this.quantity = item.tc9_et__Quantity__c ?? 0;
            this.exGst = item.tc9_et__Invoice_Total_Ex_Tax__c ?? 0;
            this.gst = item.tc9_et__Invoice_Total_Tax__c ?? 0;
            this.total = item.tc9_et__Invoice_Total_Inc_Tax__c ?? 0;
        }

        public void addTotal(tc9_et__Invoice_Item__c item) {
            Decimal quantity = item.tc9_et__Quantity__c ?? 0;
            Decimal exGst = item.tc9_et__Invoice_Total_Ex_Tax__c ?? 0;
            Decimal gst = item.tc9_et__Invoice_Total_Tax__c ?? 0;
            Decimal total = item.tc9_et__Invoice_Total_Inc_Tax__c ?? 0;

            this.quantity += quantity;
            this.exGst += exGst;
            this.gst += gst;
            this.total += total;
        }
        
        public Integer compareTo(Object wrapperObj){
            return 1;
        }

        private String padLeft(Integer toPad) {
            if(toPad == null) {
                return '00';
            }

            String toPadStr = String.valueOf(toPad);
            return toPadStr.leftPad(2, '0');
        }
    }
}