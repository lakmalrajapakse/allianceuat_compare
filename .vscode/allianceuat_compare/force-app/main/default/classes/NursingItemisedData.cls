public with sharing class NursingItemisedData {
    public tc9_et__Invoice__c sfInvoice {get; set;}
    public BackingSheet backingSheet {get; set;}

    public Map<String, ItemGroup> itemGroupsMap {get; set;} 

    public NursingItemisedData() {
        this.itemGroupsMap = new Map<String, ItemGroup>();
    }

    public NursingItemisedData(tc9_et__Invoice__c invoice) {
        this.itemGroupsMap = new Map<String, ItemGroup>();
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
        return this.sfInvoice?.Purchase_Order_Number__c ?? '';
    }

    public List<ItemGroup> getItemGroups() {
        List<ItemGroup> itemGroups = this.itemGroupsMap.values();
        itemGroups.sort();
        return itemGroups;
    }

    public void addItem(tc9_et__Invoice_Item__c invItem) {
        // ===== UPDATED: DATE LOGIC WITH FALLBACK FOR EXPENSES AND CANCELLATIONS =====
        Date startDate = invItem?.tc9_et__Pay_Transaction__r?.Shift__r?.tc9_ext_sirint__TSE_Start_Date__c;
        
        // Fallback 1: If Pay Transaction has no Shift, use Entry Date (for Expenses without shifts)
        if (startDate == null && invItem.tc9_et__Pay_Transaction__r?.tc9_pr__Entry_Date__c != null) {
            startDate = invItem.tc9_et__Pay_Transaction__r.tc9_pr__Entry_Date__c;
        }
        
        // Fallback 2: For Allowances use Timesheet Entry Start Date
        if (startDate == null && (invItem?.tc9_et__Pay_Code__r?.RecordType.DeveloperName == 'Allowance' || invItem?.RecordType.Name == 'Allowance')) {
            startDate = invItem?.tc9_et__Timesheet_Entry__r?.tc9_et__Start_Date__c;
        }
        // ===== END UPDATE =====
        
        String startDateString = startDate != null ? String.valueOf(startDate) : null;
        
        // ===== UPDATED: GROUPING LOGIC TO GROUP EXPENSES WITH SHIFTS =====
        // Use Shift ID as primary grouping key (so expenses group with their shift)
        // Fall back to Timesheet Entry if no Shift exists
        String groupingId = invItem?.tc9_et__Pay_Transaction__r?.Shift__c;
        if (groupingId == null) {
            groupingId = invItem.tc9_et__Timesheet_Entry__c;
        }
        
        String groupKey = startDateString + groupingId + '-' + invItem.tc9_et__Employee__r.Name + '-' + invItem?.tc9_et__Assignment__r?.tc9_et__Award_Level__c;
        // ===== END UPDATE =====
        
        String subGroupKey = invItem.tc9_et__Pay_Code__r.Name + '-' + invItem.tc9_et__Invoice_Rate__c;

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
        public Date startDate {get; set;}
        
        public void addItem(tc9_et__Invoice_Item__c item, String subGroupKey) {
            // ===== UPDATED: DATE LOGIC WITH FALLBACK =====
            this.startDate = item?.tc9_et__Pay_Transaction__r?.Shift__r?.tc9_ext_sirint__TSE_Start_Date__c;
            
            // Fallback to Entry Date if no Shift date
            if (this.startDate == null && item.tc9_et__Pay_Transaction__r?.tc9_pr__Entry_Date__c != null) {
                this.startDate = item.tc9_et__Pay_Transaction__r.tc9_pr__Entry_Date__c;
            }
            // ===== END UPDATE =====
            
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
            ItemGroup other = (ItemGroup) wrapperObj;

            if (this.startDate == null && other.startDate == null) return 0;
            if (this.startDate == null) return -1;
            if (other.startDate == null) return 1;
        
            if (this.startDate > other.startDate) return 1;
            if (this.startDate < other.startDate) return -1;
            return 0;
        }
    }
    
    public class ItemLine implements Comparable {
        public Date startDate {get; set;}
        public String name {get; set;}
        public String facility {get; set;}
        public String authoriser {get; set;}
        public String positionDescription {get; set;}
        public String timeRange {get; set;} 
        public String shift {get; set;}
        public Decimal quantity {get; set;}
        public Decimal rate {get; set;}
        public String type {get; set;}
        public String timesheetActivityName {get; set;}
        public String projectCodeName {get; set;}
        public Decimal total {get; set;}
        public Decimal gst {get; set;}
        public Decimal totalIncGST {get; set;}

        
        public ItemLine(tc9_et__Invoice_Item__c item) {
            // ===== UPDATED: TIME LOGIC WITH FALLBACK FOR CANCELLATIONS =====
            Time startTime = item.tc9_et__Timesheet_Entry__r?.tc9_et__Start_Time__c;
            Time endTime = item.tc9_et__Timesheet_Entry__r?.tc9_et__End_Time__c;
            
            // Fallback: If timesheet entry times are null, use shift times (for Cancellations)
            if (startTime == null && item.tc9_et__Pay_Transaction__r?.Shift__r?.tc9_ext_sirint__TSE_Start_Time__c != null) {
                startTime = item.tc9_et__Pay_Transaction__r.Shift__r.tc9_ext_sirint__TSE_Start_Time__c;
            }
            if (endTime == null && item.tc9_et__Pay_Transaction__r?.Shift__r?.tc9_ext_sirint__TSE_End_Time__c != null) {
                endTime = item.tc9_et__Pay_Transaction__r.Shift__r.tc9_ext_sirint__TSE_End_Time__c;
            }

            String startTimeString = startTime != null ? padLeft(startTime?.hour()) + ':' + padLeft(startTime?.minute()) : '';
            String endTimeString = endTime != null ? padLeft(endTime?.hour()) + ':' + padLeft(endTime?.minute()) : '';
            // ===== END UPDATE =====

            // ===== UPDATED: DATE LOGIC WITH FALLBACK FOR EXPENSES =====
            // Primary: Use Shift Start Date
            Date itemStartDate = item?.tc9_et__Pay_Transaction__r?.Shift__r?.tc9_ext_sirint__TSE_Start_Date__c;
            
            // Fallback: For Expenses without shifts, use Entry Date from Pay Transaction
            if (itemStartDate == null && item.tc9_et__Pay_Transaction__r?.tc9_pr__Entry_Date__c != null) {
                itemStartDate = item.tc9_et__Pay_Transaction__r.tc9_pr__Entry_Date__c;
            }
            this.startDate = itemStartDate;
            // ===== END UPDATE =====
            
            this.name = item.tc9_et__Employee__r.Name;
            this.facility = item.tc9_et__Pay_Transaction__r?.Shift__r?.sirenum__Site__r?.Name;
            this.authoriser = item.tc9_et__Timesheet_Entry__r?.tc9_ext_sirint__Shift__r?.Authoriser__c;
            this.positionDescription = item.tc9_et__Assignment__r?.Invoice_Name__c;
            this.timeRange = startTimeString + ' - ' + endTimeString;
            this.shift = item?.tc9_et__Pay_Transaction__r?.Shift__r?.Shift_Type__c;
            this.rate = item.tc9_et__Invoice_Rate__c ?? 0;
            this.type = item.tc9_et__Pay_Code__r?.tc9_et__Invoice_Name__c;
            this.timesheetActivityName = item.tc9_et__Pay_Transaction__r?.tc9_et__Timesheet_Entry__r?.tc9_et__Timesheet_Activity__r?.Name;
            this.projectCodeName = item.tc9_et__Pay_Transaction__r?.tc9_et__Timesheet_Entry__r?.tc9_et__Project_Code__r?.Name;
            this.quantity = item.tc9_et__Quantity__c ?? 0;
            this.total = item.tc9_et__Invoice_Total_Ex_Tax__c ?? 0;
            this.gst = item.tc9_et__Invoice_Total_Tax__c ?? 0;
            this.totalIncGST = item.tc9_et__Invoice_Total_Inc_Tax__c ?? 0;
        }

        public void addTotal(tc9_et__Invoice_Item__c item) {
            Decimal quantity = item.tc9_et__Quantity__c ?? 0;
            Decimal total = item.tc9_et__Invoice_Total_Ex_Tax__c ?? 0;
            Decimal gst = item.tc9_et__Invoice_Total_Tax__c ?? 0;
            Decimal totalIncGST = item.tc9_et__Invoice_Total_Inc_Tax__c ?? 0;
            
            this.quantity += quantity;
            this.total += total;
            this.gst += gst;
            this.totalIncGST += totalIncGST;
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
     
    public class InvoiceItem {
        public tc9_et__Invoice_Item__c sfItem {get; set;}
        public String startTime {get; set;}
        public String endTime {get; set;}
        public String approvedDateTimeDisplay {get; set;}
        public String signatureUrl {get; set;}


        public InvoiceItem(tc9_et__Invoice_Item__c item) {
            this.sfItem = item;
            Time startTime = item.tc9_et__Pay_Transaction__r?.Shift__r?.tc9_ext_sirint__TSE_Start_Time__c;
            Time endTime = item.tc9_et__Pay_Transaction__r?.Shift__r?.tc9_ext_sirint__TSE_End_Time__c;

            this.startTime = startTime != null ? padLeft(startTime?.hour()) + ':' + padLeft(startTime?.minute()) : '';
            this.endTime = endTime != null ? padLeft(endTime?.hour()) + ':' + padLeft(endTime?.minute()) : '';
            
            DateTime approveDt = sfItem.tc9_et__Pay_Transaction__r?.Shift__r?.sirenum__Approved_By_Client__c;
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
    
    public class Timesheet {
        public tc9_et__Timesheet__c sfTimesheet {get; set;}
        public List<TimesheetEntry> entries {get; set;}
        public List<InvoiceItem> items {get; set;}

        public Decimal totalHours {get; set;}
        public Boolean showSignatureColumn {get;set;}

        public Timesheet(){}

        public Timesheet(tc9_et__Timesheet__c sfTimesheet, List<tc9_et__Timesheet_Entry__c> entries, List<tc9_et__Invoice_Item__c> items, Map<Id,String> shiftToSignatureUrl) {
            this.sfTimesheet = sfTimesheet;
            this.entries = new List<TimesheetEntry>();
            this.items = new List<InvoiceItem>();
            this.totalHours = 0;
            String method = sfTimesheet?.tc9_et__Assignment__r?.tc9_pr__Client__r?.Primary_Approval_Method__c;

            showSignatureColumn = method == 'Signature Only' || method == 'PIN and Signature';

            if(entries != null) {
                for(tc9_et__Timesheet_Entry__c entry : entries) {
                    this.entries.add(new TimesheetEntry(entry));
                }
            }

            if(items != null) {

                Map<String, tc9_et__Invoice_Item__c> uniqueItems = new Map<String, tc9_et__Invoice_Item__c>();
                Set<Id> shiftIds = new Set<Id>();

                for(tc9_et__Invoice_Item__c item : items) {

                    String key =
                        item.tc9_et__Pay_Transaction__r?.Shift__r?.tc9_ext_sirint__TSE_Start_Date__c + '-' +
                        item.tc9_et__Pay_Transaction__r?.Shift__r?.tc9_ext_sirint__TSE_Start_Time__c + '-' +
                        item.tc9_et__Pay_Transaction__r?.Shift__r?.tc9_ext_sirint__TSE_End_Time__c;

                    uniqueItems.put(key, item);
                }


                for(tc9_et__Invoice_Item__c item : uniqueItems.values()) {
                    InvoiceItem invItem = new InvoiceItem(item);
                    String shiftId = item.tc9_et__Pay_Transaction__r?.Shift__c;
                    invItem.signatureUrl = shiftToSignatureUrl.get(shiftId);
                    this.items.add(invItem);

                    Decimal hours = item.tc9_et__Timesheet_Entry__r?.tc9_et__Total_Hours__c ?? 0;
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

        public TimesheetEntry(tc9_et__Timesheet_Entry__c sfEntry) {
            this.sfEntry = sfEntry;
            Time startTime = sfEntry.tc9_et__Start_Time__c;
            Time endTime = sfEntry.tc9_et__End_Time__c;

            this.startTime = startTime != null ? padLeft(startTime?.hour()) + ':' + padLeft(startTime?.minute()) : '';
            this.endTime = endTime != null ? padLeft(endTime?.hour()) + ':' + padLeft(endTime?.minute()) : '';
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