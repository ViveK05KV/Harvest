import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../settings/company_settings_models.dart';
import '../settings/company_settings_service.dart';
import '../shop_master/shop_master_models.dart';
import '../shop_master/shop_master_service.dart';
import '../supply/supply_models.dart';
import '../supply/supply_service.dart';
import 'bill_pdf_builder.dart';

/// Bill preview for a single Supply invoice, with an editable Cash Received
/// field (pre-filled from the shop's same-day collections) and a Print
/// button that hands a receipt-style PDF to the OS print/share sheet.
/// Mirrors the web app's bill-print-dialog.component.
class BillPrintScreen extends StatefulWidget {
  final int supplyId;

  const BillPrintScreen({super.key, required this.supplyId});

  @override
  State<BillPrintScreen> createState() => _BillPrintScreenState();
}

class _BillPrintScreenState extends State<BillPrintScreen> {
  late final SupplyService _supplyService = SupplyService(context.read<ApiClient>());
  late final ShopMasterService _shopService = ShopMasterService(context.read<ApiClient>());
  late final CompanySettingsService _companyService = CompanySettingsService(context.read<ApiClient>());

  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _amountFormat = NumberFormat.currency(locale: 'en_IN', symbol: '');

  SupplyDetail? _supply;
  SupplyBillExtras? _extras;
  CompanySettings? _company;
  ShopMaster? _shop;
  String? _error;
  bool _loading = true;

  final _cashController = TextEditingController(text: '0');
  double _cashReceived = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final supply = await _supplyService.getById(widget.supplyId);
      final results = await Future.wait([
        _supplyService.getBillExtras(widget.supplyId),
        _companyService.get(),
        _shopService.getById(supply.shopId),
      ]);
      final extras = results[0] as SupplyBillExtras;
      setState(() {
        _supply = supply;
        _extras = extras;
        _company = results[1] as CompanySettings?;
        _shop = results[2] as ShopMaster;
        _cashReceived = extras.suggestedCashReceived;
        _cashController.text = _cashReceived == _cashReceived.roundToDouble()
            ? _cashReceived.toStringAsFixed(0)
            : _cashReceived.toString();
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get _netBalance => (_extras?.oldBalance ?? 0) + (_supply?.totalAmount ?? 0) - _cashReceived;

  Future<void> _print() async {
    final supply = _supply;
    final extras = _extras;
    if (supply == null || extras == null) return;
    final doc = await BillPdfBuilder.build(
      company: _company,
      supply: supply,
      shop: _shop,
      oldBalance: extras.oldBalance,
      cashReceived: _cashReceived,
    );
    await Printing.layoutPdf(onLayout: (_) => doc.save(), name: 'Bill-${supply.invoiceNo}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Print Bill')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)))
              : _buildBill(context),
      bottomNavigationBar: _loading || _error != null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _print,
                  icon: const Icon(Icons.print),
                  label: const Text('Print Bill'),
                ),
              ),
            ),
    );
  }

  Widget _buildBill(BuildContext context) {
    final supply = _supply!;
    final extras = _extras!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  _company?.companyName ?? 'Harvest Wholesale',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              if (_company?.address?.isNotEmpty == true)
                Center(child: Text(_company!.address!, textAlign: TextAlign.center)),
              if (_company?.phone?.isNotEmpty == true)
                Center(child: Text('Phone: ${_company!.phone}', textAlign: TextAlign.center)),
              const Divider(height: 24),
              _metaRow('Bill', supply.invoiceNo),
              _metaRow('Date', _dateFormat.format(supply.supplyDate)),
              _metaRow('Customer', supply.shopName ?? ''),
              if (_shop?.phone?.isNotEmpty == true) _metaRow('Phone', _shop!.phone!),
              const Divider(height: 24),
              Table(
                columnWidths: const {
                  0: FixedColumnWidth(22),
                  1: FlexColumnWidth(3),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(2),
                  4: FlexColumnWidth(2.4),
                },
                children: [
                  const TableRow(children: [
                    Text('#', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('Item Name', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('Rate', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('Qty', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('Amount', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                  for (var i = 0; i < supply.items.length; i++)
                    TableRow(children: [
                      Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text('${i + 1}')),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text(supply.items[i].fruitName ?? '')),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(_amountFormat.format(supply.items[i].unitPrice), textAlign: TextAlign.right),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          NumberFormat('#,##0.###').format(
                            (supply.items[i].boxCount ?? 0) > 0 ? supply.items[i].boxCount : supply.items[i].quantity,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(_amountFormat.format(supply.items[i].totalAmount), textAlign: TextAlign.right),
                      ),
                    ]),
                ],
              ),
              const Divider(height: 24),
              _summaryRow('Sales Amount', _amountFormat.format(supply.totalAmount)),
              _summaryRow('Old Balance', _amountFormat.format(extras.oldBalance)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Cash Received'),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: _cashController,
                        textAlign: TextAlign.right,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                        onChanged: (value) => setState(() => _cashReceived = double.tryParse(value) ?? 0),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              _summaryRow('Net Balance', _amountFormat.format(_netBalance), bold: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Flexible(child: Text(': $value', textAlign: TextAlign.right))],
        ),
      );

  Widget _summaryRow(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null),
            Text(value, style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null),
          ],
        ),
      );
}
