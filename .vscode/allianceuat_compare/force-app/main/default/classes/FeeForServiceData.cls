public with sharing class FeeForServiceData {
    public tc9_et__Invoice__c sfInvoice {get; set;}
    public BackingSheet backingSheet {get; set;}

    public Map<String, ItemGroup> itemGroupsMap {get; set;}

    public Decimal grandTotalHours {get; set;}
    public Decimal grandTotalShiftTotal {get; set;}
    public Decimal grandTotalBFeeColumn {get; set;}
    public Decimal grandTotalPFeeColumn {get; set;}
    public Decimal grandTotalICColumn {get; set;}
    public Decimal grandTotalOnCallColumn {get; set;}
    public Decimal grandTotalMiscColumn {get; set;}
    public Decimal grandTotalSubTotal {get; set;}
    public Decimal grandTotalGST {get; set;}
    public Decimal grandTotalIncGST {get; set;}

    public FeeForServiceData() {
        this.itemGroupsMap = new Map<String, ItemGroup>();
        grandTotalHours = 0;
        grandTotalShiftTotal = 0;
        grandTotalBFeeColumn = 0;
        grandTotalPFeeColumn = 0;
        grandTotalICColumn = 0;
        grandTotalOnCallColumn = 0;
        grandTotalMiscColumn = 0;
        grandTotalSubTotal = 0;
        grandTotalGST = 0;
        grandTotalIncGST = 0;

    }

    public FeeForServiceData(tc9_et__Invoice__c invoice) {
        this();
        this.sfInvoice = invoice;
    }

    public String getInvoiceCalendarPeriodStartDate() {
        return this.sfInvoice?.tc9_et__InvoiceItems__r != null && !this.sfInvoice?.tc9_et__InvoiceItems__r.isEmpty() && 
               this.sfInvoice?.tc9_et__InvoiceItems__r?.get(0)?.tc9_et__Pay_Transaction__r?.tc9_et__Invoice_Calendar_Period__r?.tc9_pr__Start_Date__c != null ? 
               ((Datetime)this.sfInvoice?.tc9_et__InvoiceItems__r?.get(0)?.tc9_et__Pay_Transaction__r?.tc9_et__Invoice_Calendar_Period__r.tc9_pr__Start_Date__c)
                                        .format('dd MMMM yyyy') : '';
    }

    public String getInvoiceCalendarPeriodEndDate() {
        return this.sfInvoice?.tc9_et__InvoiceItems__r != null && !this.sfInvoice?.tc9_et__InvoiceItems__r.isEmpty() && 
               this.sfInvoice?.tc9_et__InvoiceItems__r?.get(0)?.tc9_et__Pay_Transaction__r?.tc9_et__Invoice_Calendar_Period__r?.tc9_pr__End_Date__c != null ? 
               ((Datetime)this.sfInvoice?.tc9_et__InvoiceItems__r?.get(0)?.tc9_et__Pay_Transaction__r?.tc9_et__Invoice_Calendar_Period__r.tc9_pr__End_Date__c)
                                        .format('dd MMMM yyyy') : '';
    }

    public String getPurchaseOrderNumber() {
        return this.sfInvoice?.tc9_et__InvoiceItems__r != null && !this.sfInvoice?.tc9_et__InvoiceItems__r.isEmpty() ? 
               this.sfInvoice?.tc9_et__InvoiceItems__r?.get(0)?.tc9_et__Pay_Transaction__r?.tc9_et__Purchase_Order_Number__c ?? '' : '';
    }

    public List<ItemGroup> getItemGroups() {
        return this.itemGroupsMap.values();
    }

    public void calculateGrandTotals() {
        for (ItemGroup groups : itemGroupsMap.values()) {
            Decimal bFeeColumn = groups.bFeeColumn  ??  0;
            Decimal pFeeColumn = groups.pFeeColumn  ??  0;
            Decimal icColumn = groups.icColumn  ??  0;
            Decimal onCallColumn = groups.onCallColumn  ??  0;
            Decimal miscColumn = groups.miscColumn  ??  0;
            Decimal gstAllowance = groups.gstAllowance ?? 0;

            if(groups.subGroups.isEmpty()){
                groups.subGroups.put('allowance', groups.allowanceLine);
            }
    
            ItemLine firstLine = groups.subGroups.values()[0];
            firstLine.subTotal += bFeeColumn + pFeeColumn + icColumn + onCallColumn + miscColumn;
            firstLine.gst += gstAllowance;
            firstLine.totalIncGST = firstLine.subTotal + firstLine.gst;

            grandTotalbFeeColumn += bFeeColumn;
            grandTotalpFeeColumn += pFeeColumn;
            grandTotalicColumn += icColumn;
            grandTotalOnCallColumn += onCallColumn;
            grandTotalMiscColumn += miscColumn;
            
            for (ItemLine line : groups.subGroups.values()) {        
                grandTotalHours += line.hours != null ? line.hours : 0;
                grandTotalShiftTotal += line.shiftTotal != null ? line.shiftTotal : 0;
                grandTotalSubTotal += line.subTotal != null ? line.subTotal : 0;
                grandTotalGST += line.gst != null ? line.gst : 0;
                grandTotalIncGST += line.totalIncGST != null ? line.totalIncGST : 0;
            }

        }
    }

    public void addItem(tc9_et__Invoice_Item__c invItem) {
        String groupKey = invItem.tc9_et__Timesheet_Entry__c + '-' + invItem.tc9_et__Employee__c;
        String subGroupKey = String.valueOf(invItem.tc9_et__Invoice_Rate__c);

        if(itemGroupsMap == null) {
            this.itemGroupsMap = new Map<String, ItemGroup>();
        }
        
        if(this.itemGroupsMap.get(groupKey) != null) {
            this.itemGroupsMap.get(groupKey).addItem(invItem, subGroupKey);
            
        } else {
            ItemGroup invItemGroup = new ItemGroup();
            invItemGroup.addItem(invItem, subGroupKey);
            
            this.itemGroupsMap.put(groupKey, invItemGroup);
        }
    }
 
    
    public class ItemGroup implements Comparable {
        public Map<String, ItemLine> subGroups {get; set;}
        
        public ItemLine allowanceLine {get; set;}
        public Decimal bFeeColumn {get; set;}
        public Decimal pFeeColumn {get; set;}
        public Decimal icColumn {get; set;}
        public Decimal onCallColumn {get; set;}
        public Decimal miscColumn {get; set;}
        public Decimal gstAllowance {get; set;}

        public ItemGroup() {
            subGroups = new Map<String, ItemLine>();
            bFeeColumn = 0;
            pFeeColumn = 0;
            icColumn = 0;
            onCallColumn = 0;
            miscColumn = 0;
            gstAllowance = 0;
        }
        
        public void addItem(tc9_et__Invoice_Item__c item, String subGroupKey) {
            if(subGroups == null) {
                this.subGroups = new Map<String, ItemLine>();
            }

            if (item.RecordType.DeveloperName == 'Allowance') {
                Decimal allowance = item.tc9_et__Pay_Transaction__r.tc9_et__Invoice_Total_Ex_Tax__c ?? 0;
                this.gstAllowance += item.tc9_et__Pay_Transaction__r.tc9_et__Invoice_Total_Tax__c ?? 0;
    
                if (item.tc9_et__Pay_Code__r.BFee_Invoice_Allowance_Column__c) {
                    this.bFeeColumn += allowance;
                } else if (item.tc9_et__Pay_Code__r.PFee_Invoice_Allowance_Column__c) {
                    this.pFeeColumn += allowance;
                } else if (item.tc9_et__Pay_Code__r.IC_Invoice_Allowance_Column__c) {
                    this.icColumn += allowance;
                } else if (item.tc9_et__Pay_Code__r.On_Call_Invoice_Allowance_Column__c) {
                    this.onCallColumn += allowance;
                } else if (item.tc9_et__Pay_Code__r.Misc_Invoice_Allowance_Column__c) {
                    this.miscColumn += allowance;
                }

                if(this.allowanceLine == null){
                    this.allowanceLine = new ItemLine(item);
                }
                return;
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
        public String recordType {get; set;}
        public String name {get; set;}
        public String ward {get; set;}
        public String day {get; set;}
        public String shift {get; set;}
        public String timeRange {get; set;} 
        public String grade {get; set;}
        public String type {get; set;}
        public String timesheetActivityName {get; set;}
        public String projectCodeName {get; set;}
        public Decimal hours {get; set;}
        public Decimal rate {get; set;}
        public Decimal shiftTotal {get; set;}
        public Decimal subTotal {get; set;}
        public Decimal gst {get; set;}
        public Decimal totalIncGST {get; set;}

        public ItemLine(tc9_et__Invoice_Item__c item) {
            Time startTime = item.tc9_et__Timesheet_Entry__r.tc9_et__Start_Time__c;
            Time endTime = item.tc9_et__Timesheet_Entry__r.tc9_et__End_Time__c;

            String startTimeString  = startTime != null ? padLeft(startTime?.hour()) + ':' + padLeft(startTime?.minute()) : '';
            String endTimeString  = endTime != null ? padLeft(endTime?.hour()) + ':' + padLeft(endTime?.minute()) : '';

            this.startDate = item.tc9_et__Timesheet_Entry__r.tc9_et__Start_Date__c;
            this.recordType = item.RecordType.DeveloperName;
            this.name = item.tc9_et__Employee__r.Name;
            this.ward = item?.tc9_et__Timesheet_Entry__r?.tc9_ext_sirint__Site__r?.Name;
            this.day = item?.tc9_et__Timesheet_Entry__r?.tc9_et__Day__c;
            this.shift = item?.tc9_et__Timesheet_Entry__r?.tc9_ext_sirint__Shift__r?.Shift_Type__c;
            this.timeRange = startTimeString + ' - ' + endTimeString;
            this.grade = item?.tc9_et__Assignment__r.Invoice_Name__c;
            this.type = item.tc9_et__Pay_Code__r.tc9_et__Invoice_Name__c;
            this.timesheetActivityName = item.tc9_et__Pay_Transaction__r?.tc9_et__Timesheet_Entry__r?.tc9_et__Timesheet_Activity__r?.Name;
            this.projectCodeName = item.tc9_et__Pay_Transaction__r?.tc9_et__Timesheet_Entry__r?.tc9_et__Project_Code__r?.Name;
            this.hours = item.tc9_et__Timesheet_Entry__r.tc9_et__Total_Hours__c ?? 0;
            this.rate = item.tc9_et__Invoice_Rate__c  ?? 0;
            this.shiftTotal = item.tc9_et__Invoice_Total_Ex_Tax__c ?? 0;

            if(this.recordType == 'Payment'){
                this.subTotal = this.shiftTotal ;
                this.gst = item.tc9_et__Invoice_Total_Tax__c ?? 0;
            } else{
                this.subTotal = 0 ;
                this.gst = 0;
                this.shiftTotal = 0;
            }

            this.totalIncGST = this.subTotal + this.gst;
        }

        public void addTotal(tc9_et__Invoice_Item__c item) {
            Decimal shiftTotal = item.tc9_et__Invoice_Total_Ex_Tax__c ?? 0;
            Decimal hours = item.tc9_et__Timesheet_Entry__r.tc9_et__Total_Hours__c ?? 0;
            Decimal gst = item.tc9_et__Invoice_Total_Tax__c ?? 0;

            if(item.RecordType.DeveloperName == 'Payment'){
                this.gst += gst;
                this.subTotal = this.shiftTotal;
            } else{
                this.gst = 0;
                this.subTotal = 0;
            }
            

            this.shiftTotal += shiftTotal;
            this.hours  += hours;
            this.totalIncGST = this.gst + this.subTotal;
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

    

    public class BackingSheet {
        public List<Timesheet> timesheets {get; set;}
        
        public BackingSheet(List<Timesheet> timesheets) {
            this.timesheets = timesheets;
        }
        
    }
     
    
    public class Timesheet {
        public tc9_et__Timesheet__c sfTimesheet {get; set;}
        public List<TimesheetEntry> entries {get; set;}
        
        public Decimal totalHours {get; set;}
        public Boolean showSignatureColumn {get;set;}

        public Timesheet(){}

        public Timesheet(tc9_et__Timesheet__c sfTimesheet, List<tc9_et__Timesheet_Entry__c> entries, Map<Id,String> shiftToSignatureUrl) {
            this.sfTimesheet = sfTimesheet;
            this.entries = new List<TimesheetEntry>();
            this.totalHours = 0;
            
            String method = sfTimesheet?.tc9_et__Assignment__r?.tc9_pr__Client__r?.Primary_Approval_Method__c;
            showSignatureColumn = method == 'Signature Only' || method == 'PIN and Signature';

            if(entries != null && !entries.isEmpty()) {
                Map<String, tc9_et__Timesheet_Entry__c> uniqueTSEs = new Map<String, tc9_et__Timesheet_Entry__c>();
                Set<Id> shiftIds = new Set<Id>();

                for(tc9_et__Timesheet_Entry__c tse : entries) {
                    String key = tse.tc9_et__Start_Date__c + '-' + tse.tc9_et__Start_Time__c + '-' + tse.tc9_et__End_Time__c;
                    uniqueTSEs.put(key, tse);
                }

                for(tc9_et__Timesheet_Entry__c entry : uniqueTSEs.values()) {
                    TimesheetEntry tseWrap = new TimesheetEntry(entry);

                    String shiftId = entry.tc9_ext_sirint__Shift__c;
                    tseWrap.signatureUrl = shiftToSignatureUrl.get(shiftId);
                    this.entries.add(tseWrap);

                    Decimal hours = entry.tc9_et__Total_Hours__c ?? 0;
                    totalHours += hours;
                }
            }
        }

        public String getTeamName() {
            return this.entries != null && !this.entries.isEmpty() ? this.entries?.get(0)?.sfEntry?.tc9_ext_sirint__Shift__r?.sirenum__Team__r?.Name ?? '' : '';
        }
    }

    public class TimesheetEntry {
        public tc9_et__Timesheet_Entry__c sfEntry {get; set;}
        public String startTime {get; set;}
        public String endTime {get; set;}
        public String approvedDateTimeDisplay {get; set;}
        public String signatureUrl {get; set;}


        public TimesheetEntry(tc9_et__Timesheet_Entry__c sfEntry) {
            this.sfEntry = sfEntry;
            Time startTime = sfEntry.tc9_et__Start_Time__c;
            Time endTime = sfEntry.tc9_et__End_Time__c;

            this.startTime = startTime != null ? padLeft(startTime?.hour()) + ':' + padLeft(startTime?.minute()) : '';
            this.endTime = endTime != null ? padLeft(endTime?.hour()) + ':' + padLeft(endTime?.minute()) : '';
            
            DateTime approveDt = sfEntry.tc9_ext_sirint__Shift__r.sirenum__Approved_By_Client__c;
            if(approveDt != null) {
                this.approvedDateTimeDisplay = approveDt.format('dd/MM/yyyy, HH:mm a');
            }
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