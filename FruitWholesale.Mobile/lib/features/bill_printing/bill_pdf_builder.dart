import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../settings/company_settings_models.dart';
import '../shop_master/shop_master_models.dart';
import '../supply/supply_models.dart';

/// Builds a narrow thermal-receipt-style bill PDF, mirroring the web app's
/// print layout (bill-print-dialog.component.html): company heading, invoice
/// meta, numbered item lines, then Sales Amount / Old Balance / Cash Received
/// / Net Balance.
class BillPdfBuilder {
  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _amountFormat = NumberFormat('#,##0.00');
  static final _qtyFormat = NumberFormat('#,##0.###');

  static Future<pw.Document> build({
    required CompanySettings? company,
    required SupplyDetail supply,
    required ShopMaster? shop,
    required double oldBalance,
    required double cashReceived,
  }) async {
    final doc = pw.Document();
    final netBalance = oldBalance + supply.totalAmount - cashReceived;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        build: (context) {
          return pw.DefaultTextStyle(
            style: const pw.TextStyle(fontSize: 9),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Center(
                  child: pw.Text(
                    company?.companyName ?? 'Harvest Wholesale',
                    style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                if (company?.address != null && company!.address!.isNotEmpty)
                  pw.Center(child: pw.Text(company.address!, style: const pw.TextStyle(fontSize: 8))),
                if (company?.phone != null && company!.phone!.isNotEmpty)
                  pw.Center(child: pw.Text('Phone: ${company.phone}', style: const pw.TextStyle(fontSize: 8))),
                _dashedRule(),
                _metaRow('Bill', supply.invoiceNo),
                _metaRow('Date', _dateFormat.format(supply.supplyDate)),
                _metaRow('Customer', supply.shopName ?? ''),
                if (shop?.phone != null && shop!.phone!.isNotEmpty) _metaRow('Phone', shop.phone!),
                _dashedRule(),
                _itemsTable(supply.items),
                _dashedRule(),
                _summaryRow('Sales Amount', _amountFormat.format(supply.totalAmount)),
                _summaryRow('Old Balance', _amountFormat.format(oldBalance)),
                _summaryRow('Cash Received', _amountFormat.format(cashReceived)),
                _dashedRule(),
                _summaryRow('Net Balance', _amountFormat.format(netBalance), bold: true),
              ],
            ),
          );
        },
      ),
    );
    return doc;
  }

  static pw.Widget _dashedRule() => pw.Container(
        margin: const pw.EdgeInsets.symmetric(vertical: 4),
        height: 0.6,
        color: PdfColors.grey600,
      );

  static pw.Widget _metaRow(String label, String value) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [pw.Text(label), pw.Text(': $value')],
      );

  static pw.Widget _summaryRow(String label, String value, {bool bold = false}) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null),
          pw.Text(value, style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null),
        ],
      );

  static pw.Widget _itemsTable(List<SupplyItem> items) {
    return pw.Table(
      columnWidths: const {
        0: pw.FixedColumnWidth(14),
        1: pw.FlexColumnWidth(3),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
        4: pw.FlexColumnWidth(2.4),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.6))),
          children: [
            pw.Text('#'),
            pw.Text('Item Name'),
            pw.Text('Rate', textAlign: pw.TextAlign.right),
            pw.Text('Qty', textAlign: pw.TextAlign.right),
            pw.Text('Amount', textAlign: pw.TextAlign.right),
          ],
        ),
        for (var i = 0; i < items.length; i++)
          pw.TableRow(
            children: [
              pw.Text('${i + 1}'),
              pw.Text(items[i].fruitName ?? ''),
              pw.Text(_amountFormat.format(items[i].unitPrice), textAlign: pw.TextAlign.right),
              pw.Text(
                _qtyFormat.format((items[i].boxCount ?? 0) > 0 ? items[i].boxCount : items[i].quantity),
                textAlign: pw.TextAlign.right,
              ),
              pw.Text(_amountFormat.format(items[i].totalAmount), textAlign: pw.TextAlign.right),
            ],
          ),
      ],
    );
  }
}
