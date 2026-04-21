public with sharing class NursingAllowanceInlineData {
    public static final List<String> FILE_TYPES = new List<String> { 'JPG', 'JPEG', 'PNG', 'GIF', 'VISIO', 'TIFF', 'TIF', 'heic' };
    public tc9_et__Invoice__c sfInvoice {get; set;}
    public BackingSheet backingSheet {get; set;}

    public Map<String, ItemGroup> itemGroupsMap {get; set;}

    public Decimal grandTotalHours {get; set;}
    public Decimal grandTotalShiftTotal {get; set;}
    public Decimal grandTotalShiftColumn {get; set;}
    public Decimal grandTotalLaunColumn {get; set;}
    public Decimal grandTotalUnifColumn {get; set;}
    public Decimal grandTotalQualColumn {get; set;}
    public Decimal grandTotalOnCallColumn {get; set;}
    public Decimal grandTotalMiscColumn {get; set;}
    public Decimal grandTotalSubTotal {get; set;}
    public Decimal grandTotalGST {get; set;}
    public Decimal grandTotalIncGST {get; set;}

    public NursingAllowanceInlineData() {
        this.itemGroupsMap = new Map<String, ItemGroup>();
        grandTotalHours = 0;
        grandTotalShiftTotal = 0;
        grandTotalShiftColumn = 0;
        grandTotalLaunColumn = 0;
        grandTotalUnifColumn = 0;
        grandTotalQualColumn = 0;
        grandTotalOnCallColumn = 0;
        grandTotalMiscColumn = 0;
        grandTotalSubTotal = 0;
        grandTotalGST = 0;
        grandTotalIncGST = 0;

    }

    public NursingAllowanceInlineData(tc9_et__Invoice__c invoice) {
        this.itemGroupsMap = new Map<String, ItemGroup>();
        this.sfInvoice = invoice;
        grandTotalHours = 0;
        grandTotalShiftTotal = 0;
        grandTotalShiftColumn = 0;
        grandTotalLaunColumn = 0;
        grandTotalUnifColumn = 0;
        grandTotalQualColumn = 0;
        grandTotalOnCallColumn = 0;
        grandTotalMiscColumn = 0;
        grandTotalSubTotal = 0;
        grandTotalGST = 0;
        grandTotalIncGST = 0;
    }

    public String getInvoiceCalendarPeriodStartDate() {
        return this.sfInvoice?.tc9_et__InvoiceItems__r != null && !this.sfInvoice?.tc9_et__InvoiceItems__r.isEmpty() && 
               this.sfInvoice?.tc9_et__InvoiceItems__r?.get(0)?.tc9_et__Pay_Transaction__r?.tc9_et__Invoice_Calendar_Period__r?.tc9_pr__Start_Date__c != null ? 
               ((Datetime)this.sfInvoice?.tc9_et__InvoiceItems__r?.get(0)?.tc9_et__Pay_Transaction__r?.tc9_et__Invoice_Calendar_Period__r.tc9_pr__Start_Date__c)
                                        .format('dd/MM/yyyy') : '';
    }

    public String getInvoiceCalendarPeriodEndDate() {
        return this.sfInvoice?.tc9_et__InvoiceItems__r != null && !this.sfInvoice?.tc9_et__InvoiceItems__r.isEmpty() && 
               this.sfInvoice?.tc9_et__InvoiceItems__r?.get(0)?.tc9_et__Pay_Transaction__r?.tc9_et__Invoice_Calendar_Period__r?.tc9_pr__End_Date__c != null ? 
               ((Datetime)this.sfInvoice?.tc9_et__InvoiceItems__r?.get(0)?.tc9_et__Pay_Transaction__r?.tc9_et__Invoice_Calendar_Period__r.tc9_pr__End_Date__c)
                                        .format('dd/MM/yyyy') : '';
    }

    public String getPurchaseOrderNumber() {
        return this.sfInvoice?.Purchase_Order_Number__c ?? '';
    }

    public List<ItemGroup> getItemGroups() {
        List<ItemGroup> itemGroups = this.itemGroupsMap.values();
        itemGroups.sort();
        return itemGroups;
    }

    public void calculateGrandTotals() {
        for(ItemGroup groups : itemGroupsMap.values()) {
            Decimal shiftColumn = groups.shiftColumn  ??  0;
            Decimal launColumn = groups.launColumn  ??  0;
            Decimal unifColumn = groups.unifColumn  ??  0;
            Decimal qualColumn = groups.qualColumn  ??  0;
            Decimal onCallColumn = groups.onCallColumn  ??  0;
            Decimal miscColumn = groups.miscColumn  ??  0;
            Decimal gstAllowance = groups.gstAllowance ?? 0;

            if(groups.subGroups.isEmpty()){
                groups.subGroups.put('allowance', groups.allowanceLine);
            }
    
            ItemLine firstLine = groups.subGroups.values()[0];
            firstLine.subTotal += shiftColumn + launColumn + unifColumn + qualColumn + onCallColumn + miscColumn;
            firstLine.gst += gstAllowance;
            firstLine.totalIncGST = firstLine.subTotal + firstLine.gst;

            grandTotalLaunColumn += launColumn;
            grandTotalUnifColumn += unifColumn;
            grandTotalQualColumn += qualColumn;
            grandTotalOnCallColumn += onCallColumn;
            grandTotalMiscColumn += miscColumn;
    
            for(ItemLine lines : groups.subGroups.values()) {
                grandTotalHours += lines.hours != null ? lines.hours : 0;
                grandTotalShiftTotal += lines.shiftTotal != null ? lines.shiftTotal : 0;
                grandTotalShiftColumn += shiftColumn;
                grandTotalSubTotal += lines.subTotal != null ? lines.subTotal : 0;
                grandTotalGST += lines.gst != null ? lines.gst : 0;
                grandTotalIncGST += lines.totalIncGST != null ? lines.totalIncGST : 0;
            }
        }
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
        
        // ===== UPDATED: GROUPING LOGIC FOR EXPENSES WITHOUT SHIFTS =====
        // For items WITH a Shift: group by Date + Shift ID + Employee + Award Level
        // For items WITHOUT a Shift (expenses): group by Date + Employee + 'EXPENSE' marker
        String groupingId = invItem?.tc9_et__Pay_Transaction__r?.Shift__c;
        String groupKey;
        
        if (groupingId != null) {
            // Has Shift - normal grouping
            groupKey = startDateString + groupingId + '-' + invItem.tc9_et__Employee__r.Name + '-' + invItem?.tc9_et__Assignment__r?.tc9_et__Award_Level__c;
        } else {
            // No Shift (expenses) - group by date+employee with a marker to separate from shifts
            // Use 'ZZZ' prefix to sort after shifts on the same date
            groupKey = startDateString + 'ZZZ-EXPENSE-' + invItem.tc9_et__Employee__r.Name;
        }
        // ===== END UPDATE =====

        String subGroupKey = invItem.tc9_et__Pay_Code__c + '-' + String.valueOf(invItem.tc9_et__Invoice_Rate__c);

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

    public String getAllowanceType(tc9_et__Invoice_Item__c invItem){
        if(invItem.tc9_et__Pay_Code__r.RecordType.DeveloperName == 'Allowance') {
            if (invItem.tc9_et__Pay_Code__r.Shift_Invoice_Allowance_Column__c) {
                return 'Shift';
            } else if (invItem.tc9_et__Pay_Code__r.Laun_Invoice_Allowance_Column__c) {
                return 'Laun';
            } else if (invItem.tc9_et__Pay_Code__r.Unif_Invoice_Allowance_Column__c) {
                return 'Unif';
            } else if (invItem.tc9_et__Pay_Code__r.Qual_Invoice_Allowance_Column__c) {
                return 'Qual';
            } else if (invItem.tc9_et__Pay_Code__r.On_Call_Invoice_Allowance_Column__c) {
                return 'On Call';
            } else if (invItem.tc9_et__Pay_Code__r.Misc_Invoice_Allowance_Column__c) {
                return 'Misc';
            }
        }
        return '';
    }

    public class ItemGroup implements Comparable {
        public Map<String, ItemLine> subGroups {get; set;}
        public Date startDate {get; set;}
        
        public ItemLine allowanceLine {get; set;}
        public Decimal shiftColumn {get; set;}
        public Decimal launColumn {get; set;}
        public Decimal unifColumn {get; set;}
        public Decimal qualColumn {get; set;}
        public Decimal onCallColumn {get; set;}
        public Decimal miscColumn {get; set;}
        public Decimal gstAllowance {get; set;}

        public ItemGroup() {
            subGroups = new Map<String, ItemLine>();
            shiftColumn = 0;
            launColumn = 0;
            unifColumn = 0;
            qualColumn = 0;
            onCallColumn = 0;
            miscColumn = 0;
            gstAllowance = 0;
        }
            
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

            if(item.RecordType.DeveloperName == 'Allowance'){
                Decimal allowance = item.tc9_et__Pay_Transaction__r.tc9_et__Invoice_Total_Ex_Tax__c ?? 0;
                this.gstAllowance += item.tc9_et__Pay_Transaction__r.tc9_et__Invoice_Total_Tax__c ?? 0;

                if (item.tc9_et__Pay_Code__r.Shift_Invoice_Allowance_Column__c) {
                    this.shiftColumn += allowance;

                } else if (item.tc9_et__Pay_Code__r.Laun_Invoice_Allowance_Column__c) {
                    this.launColumn += allowance;

                } else if (item.tc9_et__Pay_Code__r.Unif_Invoice_Allowance_Column__c) {
                    this.unifColumn += allowance;

                } else if (item.tc9_et__Pay_Code__r.Qual_Invoice_Allowance_Column__c) {
                    this.qualColumn += allowance;

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
            this.subTotal = this.subTotal ?? 0;
            this.gst = this.gst ?? 0;
            this.shiftTotal = this.shiftTotal ?? 0;

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

            this.recordType = item.RecordType.DeveloperName;
            this.name = item.tc9_et__Employee__r.Name;

            // ===== UPDATED: DATE LOGIC WITH FALLBACK FOR EXPENSES =====
            // Primary: Use Shift Start Date
            Date itemStartDate = item?.tc9_et__Pay_Transaction__r?.Shift__r?.tc9_ext_sirint__TSE_Start_Date__c;
            
            // Fallback: For Expenses without shifts, use Entry Date from Pay Transaction
            if (itemStartDate == null && item.tc9_et__Pay_Transaction__r?.tc9_pr__Entry_Date__c != null) {
                itemStartDate = item.tc9_et__Pay_Transaction__r.tc9_pr__Entry_Date__c;
            }
            this.startDate = itemStartDate;
            // ===== END UPDATE =====
            
            this.ward = item.tc9_et__Pay_Transaction__r?.Shift__r?.sirenum__Site__r?.Name;

            // Day fallback: Use TSE day if available, otherwise calculate from date
            this.day = item?.tc9_et__Timesheet_Entry__r?.tc9_et__Day__c;
            if(this.day == null && this.startDate != null) {
                // Calculate day from date (Allowances/Cancellations without TSE)
                DateTime dt = DateTime.newInstance(this.startDate.year(), this.startDate.month(), this.startDate.day());
                this.day = dt.format('EEEE'); // Returns full day name (e.g., 'Monday')
            }
            
            this.shift = item?.tc9_et__Pay_Transaction__r?.Shift__r?.Shift_Type__c;
            this.timeRange = startTimeString + ' - ' + endTimeString;
            this.grade = item?.tc9_et__Assignment__r.Invoice_Name__c;
            this.type = item.tc9_et__Pay_Code__r.tc9_et__Invoice_Name__c;
            this.timesheetActivityName = item.tc9_et__Pay_Transaction__r?.tc9_et__Timesheet_Entry__r?.tc9_et__Timesheet_Activity__r?.Name;
            this.projectCodeName = item.tc9_et__Pay_Transaction__r?.tc9_et__Timesheet_Entry__r?.tc9_et__Project_Code__r?.Name;
            this.hours = item.tc9_et__Quantity__c ?? 0;
            this.rate = item.tc9_et__Invoice_Rate__c  ?? 0;
            this.shiftTotal = item.tc9_et__Invoice_Total_Ex_Tax__c ?? 0;

            if(this.recordType != 'Allowance'){
                this.gst = item.tc9_et__Invoice_Total_Tax__c ?? 0;
            }

            this.subTotal = this.shiftTotal;
            this.totalIncGST = this.subTotal + this.gst;
        }

        public void addTotal(tc9_et__Invoice_Item__c item) {
            Decimal shiftTotal = item.tc9_et__Invoice_Total_Ex_Tax__c ?? 0;
            Decimal hours = item.tc9_et__Quantity__c ?? 0;
            Decimal gst = item.tc9_et__Invoice_Total_Tax__c ?? 0;

            if(item.RecordType.DeveloperName != 'Allowance'){
                this.gst += gst;
            } 

            this.shiftTotal += shiftTotal;
            this.subTotal = this.shiftTotal;
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

    public static Map<Id,String> getShiftSignatureUrls(Set<Id> shiftIds) {

        Map<Id,String> result = new Map<Id,String>();
    
        if(shiftIds == null || shiftIds.isEmpty()) {
            return result;
        }
    
        for(ContentDocumentLink cdl : [SELECT LinkedEntityId, ContentDocument.LatestPublishedVersionId, ContentDocument.CreatedDate
                                       FROM ContentDocumentLink
                                       WHERE LinkedEntityId IN :shiftIds
                                       AND ContentDocument.Title LIKE '%Esign%'
                                       AND ContentDocument.FileExtension IN :FILE_TYPES
                                       ORDER BY LinkedEntityId, ContentDocument.CreatedDate DESC]) {
                            
            String shiftId = cdl.LinkedEntityId;
            if(!result.containsKey(shiftId)) {
                result.put(shiftId, '/sfc/servlet.shepherd/version/download/' + cdl.ContentDocument.LatestPublishedVersionId);
            }
        }
    
        return result;
    }
    
}