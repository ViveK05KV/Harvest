import { Injectable } from '@angular/core';
import * as XLSX from 'xlsx';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { saveAs } from 'file-saver';

export interface ExportColumn {
  header: string;
  field: string;
}

@Injectable({ providedIn: 'root' })
export class ExportService {
  exportToExcel<T extends object>(rows: T[], columns: ExportColumn[], fileName: string): void {
    const data = rows.map((row) => {
      const source = row as unknown as Record<string, unknown>;
      const record: Record<string, unknown> = {};
      for (const col of columns) {
        record[col.header] = source[col.field];
      }
      return record;
    });
    const worksheet = XLSX.utils.json_to_sheet(data);
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Sheet1');
    const buffer = XLSX.write(workbook, { bookType: 'xlsx', type: 'array' });
    saveAs(new Blob([buffer], { type: 'application/octet-stream' }), `${fileName}.xlsx`);
  }

  exportToPdf<T extends object>(rows: T[], columns: ExportColumn[], fileName: string, title: string): void {
    const doc = new jsPDF({ orientation: columns.length > 5 ? 'landscape' : 'portrait' });
    doc.setFontSize(14);
    doc.text(title, 14, 15);

    autoTable(doc, {
      startY: 22,
      head: [columns.map((c) => c.header)],
      body: rows.map((row) => {
        const source = row as unknown as Record<string, unknown>;
        return columns.map((c) => String(source[c.field] ?? ''));
      }),
      styles: { fontSize: 8 },
      headStyles: { fillColor: [21, 101, 192] }
    });

    doc.save(`${fileName}.pdf`);
  }
}
