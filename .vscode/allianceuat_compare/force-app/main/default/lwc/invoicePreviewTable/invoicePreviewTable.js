import { LightningElement, api, track } from 'lwc';
import getInvoices from '@salesforce/apex/InvoicePreviewController.getInvoices';
import countInvoices from '@salesforce/apex/InvoicePreviewController.countInvoices';
import getSelectedInvoicePdfs from '@salesforce/apex/InvoicePreviewController.getSelectedInvoicePdfs';
import { loadScript } from 'lightning/platformResourceLoader';
import PDFLIB from '@salesforce/resourceUrl/pdf_lib';

export default class InvoicePreviewTable extends LightningElement {
  @api branchId;
  @api startDate;
  @api endDate;
  @api maxCount = 1000;

  @track rows = [];
  loading = false;
  error;
  tooMany = false;
  pdfLibLoaded = false;

  columns = [
    { label: 'Invoice', fieldName: 'Name' },
    { label: 'Date', fieldName: 'tc9_et__Invoice_Date__c', type: 'date-local' },
    { label: 'Account', fieldName: 'AccountName', type: 'text' },
    { label: 'Total (Inc Tax)', fieldName: 'tc9_et__Invoice_Total_Inc_Tax__c', type: 'currency' },
    { label: 'Balance Due', fieldName: 'tc9_et__Balance_Due__c', type: 'currency' }
  ];

  connectedCallback() {
    loadScript(this, PDFLIB)
      .then(() => { this.pdfLibLoaded = true; })
      .catch(() => { /* ok to proceed; we'll block generate if not loaded */ });

    this.load();
  }

  @api async load() {
    this.loading = true;
    this.error = undefined;
    this.rows = [];
    this.tooMany = false;

    try {
      if (this.branchId && this.startDate && this.endDate) {
        const total = await countInvoices({
          branchId: this.branchId,
          startDate: this.startDate,
          endDate: this.endDate
        });

        if (total > this.maxCount) {
          this.tooMany = true;
          return;
        }

        const raw = await getInvoices({
          branchId: this.branchId,
          startDate: this.startDate,
          endDate: this.endDate
        });

        this.rows = (raw || []).map(r => ({
          ...r,
          AccountName: r?.tc9_et__Invoice_To_Account__r?.Name || ''
        }));
      }
    } catch (e) {
      this.error = e?.body?.message || e?.message || 'Error loading invoices';
    } finally {
      this.loading = false;
    }
  }

  get hasRows() {
    return Array.isArray(this.rows) && this.rows.length > 0;
  }
  get showEmpty() {
    return !this.loading && !this.error && !this.hasRows && !this.tooMany;
  }

  async handleGenerate() {
    try {
      this.loading = true;
      this.error = undefined;

      if (!this.pdfLibLoaded) {
        this.error = 'PDF engine not loaded yet. Please wait a moment and try again.';
        return;
      }

      const invoiceIds = (this.rows || []).map(r => r.Id);
      if (!invoiceIds.length) {
        this.error = 'No invoices loaded.';
        return;
      }

      const files = await getSelectedInvoicePdfs({ invoiceIds });

      if (!files || !files.length) {
        this.error = 'No PDFs found on the selected invoices.';
        return;
      }

      const { PDFDocument } = window.PDFLib;
      const merged = await PDFDocument.create();

      for (const f of files) {
        const bytes = Uint8Array.from(atob(f.base64), c => c.charCodeAt(0));
        const src = await PDFDocument.load(bytes);
        const pages = await merged.copyPages(src, src.getPageIndices());
        pages.forEach(p => merged.addPage(p));
      }

      const mergedBytes = await merged.save();
      const blob = new Blob([mergedBytes], { type: 'application/pdf' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'Consolidated_Invoices.pdf';
      a.click();
      URL.revokeObjectURL(url);

    } catch (e) {
      this.error = e?.body?.message || e?.message || 'Merge failed';
    } finally {
      this.loading = false;
    }
  }
}