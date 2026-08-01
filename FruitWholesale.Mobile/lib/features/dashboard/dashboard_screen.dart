import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/auth/auth_service.dart';
import '../ledgers/ledger_models.dart';
import '../ledgers/ledger_service.dart';
import '../shop_master/shop_master_service.dart';
import '../stock/stock_models.dart';
import '../stock/stock_service.dart';
import '../supplier_master/supplier_master_service.dart';
import 'dashboard_models.dart';
import 'dashboard_service.dart';

class _PayableRow {
  final String name;
  final double amount;
  const _PayableRow({required this.name, required this.amount});
}

class _CashTapeRow {
  final String time;
  final String label;
  final String note;
  final double amount;
  final bool isIn;
  final double balance;
  const _CashTapeRow({
    required this.time,
    required this.label,
    required this.note,
    required this.amount,
    required this.isIn,
    required this.balance,
  });
}

const _kGreen = Color(0xFF1F7A48);
const _kGreenDark = Color(0xFF193126);
const _kAmber = Color(0xFFC57C11);
const _kSlate = Color(0xFF52675A);
const _kRed = Color(0xFFC0392B);
const _kMuted = Color(0xFF42594B);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardService _service = DashboardService(context.read<ApiClient>());
  late final StockService _stockService = StockService(context.read<ApiClient>());
  late final ShopMasterService _shopService = ShopMasterService(context.read<ApiClient>());
  late final SupplierMasterService _supplierService = SupplierMasterService(context.read<ApiClient>());
  late final LedgerService _ledgerService = LedgerService(context.read<ApiClient>());

  DashboardSummary? _summary;
  DashboardCharts? _charts;
  String? _error;
  bool _loading = true;

  DashboardPeriod _svpPeriod = DashboardPeriod.thisWeek;
  bool _svpLoading = true;
  SalesVsPurchases? _svp;

  List<TrendPoint> _cashTrend = [];
  List<TrendPoint> _profitTrend = [];

  List<_PayableRow> _payables = [];
  int _supplierCount = 0;
  int _shopsWithBalanceCount = 0;
  double _overLimitAmount = 0;
  int _overLimitShopCount = 0;

  bool _cashTapeLoading = true;
  List<_CashTapeRow> _cashTape = [];

  bool _stockLoading = true;
  List<CurrentStock> _stock = [];

  @override
  void initState() {
    super.initState();
    _load();
    _loadSalesVsPurchases();
    _loadStock();
    _loadCashTrend();
    _loadProfitTrend();
    _loadPayables();
    _loadCustomerRisk();
    _loadCashTape();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([_service.getSummary(), _service.getCharts()]);
      setState(() {
        _summary = results[0] as DashboardSummary;
        _charts = results[1] as DashboardCharts;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadSalesVsPurchases() async {
    setState(() => _svpLoading = true);
    try {
      final result = await _service.getSalesVsPurchases(_svpPeriod);
      setState(() => _svp = result);
    } on ApiException {
      // Leave whatever was there; the period selector can be retried.
    } finally {
      if (mounted) setState(() => _svpLoading = false);
    }
  }

  Future<void> _loadStock() async {
    setState(() => _stockLoading = true);
    try {
      final items = await _stockService.getCurrentStock();
      setState(() => _stock = items);
    } on ApiException {
      // Stock section just stays empty; not worth failing the whole dashboard.
    } finally {
      if (mounted) setState(() => _stockLoading = false);
    }
  }

  Future<void> _loadCashTrend() async {
    try {
      final points = await _service.getCashTrend();
      if (mounted) setState(() => _cashTrend = points);
    } on ApiException {
      // Sparkline just stays empty.
    }
  }

  Future<void> _loadProfitTrend() async {
    try {
      final points = await _service.getProfitTrend();
      if (mounted) setState(() => _profitTrend = points);
    } on ApiException {
      // Sparkline just stays empty.
    }
  }

  Future<void> _loadPayables() async {
    try {
      final suppliers = await _supplierService.getAllActive();
      final withBalance = suppliers.where((s) => s.currentOutstanding > 0).toList();
      final sorted = [...withBalance]..sort((a, b) => b.currentOutstanding.compareTo(a.currentOutstanding));
      if (!mounted) return;
      setState(() {
        _supplierCount = withBalance.length;
        _payables = sorted.take(3).map((s) => _PayableRow(name: s.supplierName, amount: s.currentOutstanding)).toList();
      });
    } on ApiException {
      // Payables list just stays empty.
    }
  }

  Future<void> _loadCustomerRisk() async {
    try {
      final shops = await _shopService.getAllActive();
      final overLimit = shops.where((s) => s.creditLimit > 0 && s.currentOutstanding > s.creditLimit).toList();
      if (!mounted) return;
      setState(() {
        _shopsWithBalanceCount = shops.where((s) => s.currentOutstanding > 0).length;
        _overLimitShopCount = overLimit.length;
        _overLimitAmount = overLimit.fold(0.0, (sum, s) => sum + (s.currentOutstanding - s.creditLimit));
      });
    } on ApiException {
      // Risk indicator just stays at zero.
    }
  }

  Future<void> _loadCashTape() async {
    setState(() => _cashTapeLoading = true);
    try {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final result = await _ledgerService.getCashLedger(pageNumber: 1, pageSize: 50, fromDate: todayStr, toDate: todayStr);
      final rows = result.items.reversed
          .take(8)
          .map((e) => _CashTapeRow(
                time: DateFormat('h:mm a').format(e.transactionDate.toLocal()),
                label: cashLedgerTypeLabels[e.transactionType] ?? e.transactionType,
                note: e.narration ?? e.paymentMode,
                amount: e.cashIn > 0 ? e.cashIn : e.cashOut,
                isIn: e.cashIn > 0,
                balance: e.runningBalance,
              ))
          .toList();
      if (mounted) setState(() => _cashTape = rows);
    } on ApiException {
      // Cash tape just stays empty.
    } finally {
      if (mounted) setState(() => _cashTapeLoading = false);
    }
  }

  Future<void> _reloadAll() => Future.wait([
        _load(),
        _loadSalesVsPurchases(),
        _loadStock(),
        _loadCashTrend(),
        _loadProfitTrend(),
        _loadPayables(),
        _loadCustomerRisk(),
        _loadCashTape(),
      ]);

  bool get _isBackOffice => context.read<AuthService>().user?.role.isBackOffice ?? false;

  double _maxStockForBar() => _stock.isEmpty ? 1 : _stock.map((i) => i.currentStock).reduce(math.max).clamp(1, double.infinity);

  List<CurrentStock> _lowStockItems() {
    final sorted = [...(_stock)]..sort((a, b) => a.currentStock.compareTo(b.currentStock));
    return sorted.take(6).toList();
  }

  double? _todayMarginPercent() {
    final s = _summary;
    if (s == null || s.todayProfit == null || s.todayProfit == 0 || s.todaySales == 0) return null;
    return (s.todayProfit! / s.todaySales) * 100;
  }

  double _customerAtRiskPercent() {
    final s = _summary;
    if (s == null || s.customerOutstanding <= 0) return 0;
    return math.min(100, ((_overLimitAmount / s.customerOutstanding) * 100).roundToDouble());
  }

  ({double sales, double purchases, double margin}) _periodTotals() {
    final sales = (_svp?.sales ?? []).fold(0.0, (sum, p) => sum + p.amount);
    final purchases = (_svp?.purchases ?? []).fold(0.0, (sum, p) => sum + p.amount);
    return (sales: sales, purchases: purchases, margin: sales - purchases);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(onRefresh: _reloadAll, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading && _summary == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          Center(child: Text(_error!, textAlign: TextAlign.center)),
        ],
      );
    }

    final s = _summary!;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final backOffice = _isBackOffice && s.totalProfit != null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('LIVE BUSINESS SNAPSHOT',
            style: const TextStyle(color: _kGreen, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
        const SizedBox(height: 4),
        Text(DateFormat('EEEE, d MMMM y').format(DateTime.now()),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: _kGreenDark)),
        const SizedBox(height: 20),

        _CashHeroCard(summary: s, sparklineData: _cashTrend, currency: currency),
        const SizedBox(height: 12),
        _CustomerOutstandingCard(
          summary: s,
          currency: currency,
          shopsWithBalanceCount: _shopsWithBalanceCount,
          atRiskPercent: _customerAtRiskPercent(),
          overLimitAmount: _overLimitAmount,
          overLimitShopCount: _overLimitShopCount,
        ),
        const SizedBox(height: 12),
        _SupplierOutstandingCard(summary: s, currency: currency, supplierCount: _supplierCount, payables: _payables),
        const SizedBox(height: 12),
        backOffice
            ? _TotalProfitCard(summary: s, currency: currency)
            : _NetWorthCard(summary: s, currency: currency),

        const SizedBox(height: 20),
        _TodayStrip(summary: s, currency: currency),

        const SizedBox(height: 24),
        _ChartCard(
          kicker: 'CASH FLOW',
          title: 'Sales, Purchases & Margin',
          period: _svpPeriod,
          onPeriodChanged: (p) {
            setState(() => _svpPeriod = p);
            _loadSalesVsPurchases();
          },
          child: Column(
            children: [
              _svpLoading || _svp == null
                  ? const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()))
                  : SizedBox(height: 180, child: _SalesVsPurchasesBarChart(data: _svp!)),
              const SizedBox(height: 12),
              _PeriodTotalsRow(totals: _periodTotals(), currency: currency),
            ],
          ),
        ),

        const SizedBox(height: 16),
        _SectionHeader(kicker: 'INVENTORY', title: 'Stock needing attention'),
        const SizedBox(height: 8),
        _stockLoading
            ? const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator()))
            : _StockList(items: _lowStockItems(), maxStock: _maxStockForBar()),

        if (backOffice) ...[
          const SizedBox(height: 24),
          _ProfitSnapshotCard(
            summary: s,
            currency: currency,
            marginPercent: _todayMarginPercent(),
            sparklineData: _profitTrend,
          ),
        ],

        const SizedBox(height: 16),
        _SectionHeader(kicker: 'SPENDING', title: 'Where the money went'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              height: 200,
              child: _ExpensesDoughnut(items: _charts?.expensesByCategory ?? []),
            ),
          ),
        ),

        const SizedBox(height: 16),
        _SectionHeader(kicker: 'CASH LEDGER', title: "Today's cash entries"),
        const SizedBox(height: 8),
        _cashTapeLoading
            ? const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator()))
            : _CashTape(rows: _cashTape, currency: currency),
      ],
    );
  }
}

class _CashHeroCard extends StatelessWidget {
  const _CashHeroCard({required this.summary, required this.sparklineData, required this.currency});
  final DashboardSummary summary;
  final List<TrendPoint> sparklineData;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _kGreenDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CASH BALANCE',
                          style: TextStyle(color: Color(0xFFB7D4BD), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                      const SizedBox(height: 6),
                      Text(currency.format(summary.currentCashBalance),
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const Icon(Icons.account_balance_wallet, color: Colors.white70),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('+${currency.format(summary.todayCollection)} in',
                    style: const TextStyle(color: Color(0xFF9EE6B4), fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(width: 12),
                Text('−${currency.format(summary.todayPurchases + summary.todayExpenses)} out',
                    style: const TextStyle(color: Color(0xFFF2A79E), fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(height: 48, child: _Sparkline(points: sparklineData, color: const Color(0xFF7FD6A0))),
          ],
        ),
      ),
    );
  }
}

class _CustomerOutstandingCard extends StatelessWidget {
  const _CustomerOutstandingCard({
    required this.summary,
    required this.currency,
    required this.shopsWithBalanceCount,
    required this.atRiskPercent,
    required this.overLimitAmount,
    required this.overLimitShopCount,
  });
  final DashboardSummary summary;
  final NumberFormat currency;
  final int shopsWithBalanceCount;
  final double atRiskPercent;
  final double overLimitAmount;
  final int overLimitShopCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('CUSTOMER OUTSTANDING',
                    style: TextStyle(color: _kAmber, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                const Icon(Icons.storefront, color: _kAmber, size: 20),
              ],
            ),
            const SizedBox(height: 6),
            Text(currency.format(summary.customerOutstanding),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _kGreenDark)),
            const SizedBox(height: 2),
            Text('$shopsWithBalanceCount ${shopsWithBalanceCount == 1 ? 'shop' : 'shops'} with a balance',
                style: const TextStyle(color: _kMuted, fontSize: 12)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (atRiskPercent / 100).clamp(0, 1),
                minHeight: 6,
                backgroundColor: const Color(0xFFEDF1ED),
                color: _kAmber,
              ),
            ),
            if (overLimitAmount > 0) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: _kRed),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${currency.format(overLimitAmount)} over credit limit · $overLimitShopCount ${overLimitShopCount == 1 ? 'shop' : 'shops'}',
                      style: const TextStyle(color: _kRed, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SupplierOutstandingCard extends StatelessWidget {
  const _SupplierOutstandingCard({required this.summary, required this.currency, required this.supplierCount, required this.payables});
  final DashboardSummary summary;
  final NumberFormat currency;
  final int supplierCount;
  final List<_PayableRow> payables;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SUPPLIER OUTSTANDING',
                    style: TextStyle(color: _kSlate, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                const Icon(Icons.local_shipping, color: _kSlate, size: 20),
              ],
            ),
            const SizedBox(height: 6),
            Text(currency.format(summary.supplierOutstanding),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _kGreenDark)),
            const SizedBox(height: 2),
            Text('$supplierCount ${supplierCount == 1 ? 'supplier' : 'suppliers'}', style: const TextStyle(color: _kMuted, fontSize: 12)),
            const SizedBox(height: 10),
            if (payables.isEmpty)
              const Text('No outstanding balances.', style: TextStyle(color: _kMuted, fontSize: 12))
            else
              ...payables.map(
                (p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(p.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                      Text(currency.format(p.amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TotalProfitCard extends StatelessWidget {
  const _TotalProfitCard({required this.summary, required this.currency});
  final DashboardSummary summary;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL PROFIT', style: TextStyle(color: _kGreen, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFE6F4EA), borderRadius: BorderRadius.circular(6)),
                  child: const Text('ADMIN', style: TextStyle(color: _kGreen, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(currency.format(summary.totalProfit ?? 0), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _kGreenDark)),
            const SizedBox(height: 2),
            const Text('All time', style: TextStyle(color: _kMuted, fontSize: 12)),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Net business worth', style: TextStyle(color: _kMuted, fontSize: 12)),
                Text(currency.format(summary.netBusinessWorth), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard({required this.summary, required this.currency});
  final DashboardSummary summary;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('NET BUSINESS WORTH',
                    style: TextStyle(color: _kGreen, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                const Icon(Icons.trending_up, color: _kGreen, size: 20),
              ],
            ),
            const SizedBox(height: 6),
            Text(currency.format(summary.netBusinessWorth), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _kGreen)),
            const SizedBox(height: 2),
            const Text('Cash + receivables − payables', style: TextStyle(color: _kMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _TodayStrip extends StatelessWidget {
  const _TodayStrip({required this.summary, required this.currency});
  final DashboardSummary summary;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final tiles = <(String, double)>[
      ('Sales', summary.todaySales),
      ('Collections', summary.todayCollection),
      ('Purchases', summary.todayPurchases),
      ('Expenses', summary.todayExpenses),
      ('Net Cash', summary.todayCollection - summary.todayPurchases - summary.todayExpenses),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TODAY', style: TextStyle(color: _kGreen, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    Text(DateFormat('d MMM').format(DateTime.now()), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              ),
              for (final (label, value) in tiles)
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(color: _kMuted, fontSize: 11)),
                      Text(currency.format(value), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodTotalsRow extends StatelessWidget {
  const _PeriodTotalsRow({required this.totals, required this.currency});
  final ({double sales, double purchases, double margin}) totals;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    Widget tile(String label, double value, Color color) => Expanded(
          child: Column(
            children: [
              Text(label, style: const TextStyle(color: _kMuted, fontSize: 11)),
              const SizedBox(height: 2),
              Text(currency.format(value), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
            ],
          ),
        );
    return Row(
      children: [
        tile('Sales', totals.sales, _kGreenDark),
        tile('Purchases', totals.purchases, _kGreenDark),
        tile('Margin', totals.margin, _kGreen),
      ],
    );
  }
}

class _ProfitSnapshotCard extends StatelessWidget {
  const _ProfitSnapshotCard({required this.summary, required this.currency, required this.marginPercent, required this.sparklineData});
  final DashboardSummary summary;
  final NumberFormat currency;
  final double? marginPercent;
  final List<TrendPoint> sparklineData;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('PROFIT', style: TextStyle(color: _kGreen, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    Text('Snapshot', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFE6F4EA), borderRadius: BorderRadius.circular(6)),
                  child: const Text('ADMIN', style: TextStyle(color: _kGreen, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Today', style: TextStyle(color: _kMuted, fontSize: 11)),
                      Text(currency.format(summary.todayProfit ?? 0), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                ),
                if (marginPercent != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Margin', style: TextStyle(color: _kMuted, fontSize: 11)),
                      Text('${marginPercent!.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _kGreenDark)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(height: 60, child: _Sparkline(points: sparklineData, color: _kGreen)),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('All-time', style: TextStyle(color: _kMuted, fontSize: 12)),
                Text(currency.format(summary.totalProfit ?? 0), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.points, required this.color});
  final List<TrendPoint> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: [for (int i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].amount)],
            isCurved: true,
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.18)),
          ),
        ],
      ),
    );
  }
}

class _ExpensesDoughnut extends StatelessWidget {
  const _ExpensesDoughnut({required this.items});
  final List<CategoryAmount> items;

  static const _palette = [
    Color(0xFF1F6F43),
    Color(0xFF91B982),
    Color(0xFFD89A27),
    Color(0xFFD8DFD7),
    Color(0xFF64766B),
    Color(0xFFEFBD67),
    Color(0xFFB8CCB5),
    Color(0xFF355847),
  ];

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('No expenses recorded yet.', style: TextStyle(color: _kMuted)));
    final total = items.fold(0.0, (sum, i) => sum + i.amount);
    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 32,
              sectionsSpace: 2,
              sections: [
                for (int i = 0; i < items.length; i++)
                  PieChartSectionData(
                    value: items[i].amount,
                    color: _palette[i % _palette.length],
                    showTitle: false,
                    radius: 42,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < items.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: _palette[i % _palette.length], shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${items[i].category} · ${total == 0 ? 0 : (items[i].amount / total * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CashTape extends StatelessWidget {
  const _CashTape({required this.rows, required this.currency});
  final List<_CashTapeRow> rows;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No cash movement recorded today.', style: TextStyle(color: _kMuted)));
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(width: 56, child: Text(row.time, style: const TextStyle(fontSize: 11, color: _kMuted))),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(row.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(row.note, style: const TextStyle(fontSize: 11, color: _kMuted), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${row.isIn ? '+' : '−'}${currency.format(row.amount)}',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: row.isIn ? _kGreen : _kRed)),
                        Text(currency.format(row.balance), style: const TextStyle(fontSize: 11, color: _kMuted)),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.kicker,
    required this.title,
    required this.period,
    required this.onPeriodChanged,
    required this.child,
  });

  final String kicker;
  final String title;
  final DashboardPeriod period;
  final ValueChanged<DashboardPeriod> onPeriodChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _SectionHeader(kicker: kicker, title: title)),
                DropdownButton<DashboardPeriod>(
                  value: period,
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF354139)),
                  items: [
                    for (final p in DashboardPeriod.values) DropdownMenuItem(value: p, child: Text(p.label)),
                  ],
                  onChanged: (value) {
                    if (value != null) onPeriodChanged(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _SalesVsPurchasesBarChart extends StatelessWidget {
  const _SalesVsPurchasesBarChart({required this.data});
  final SalesVsPurchases data;

  @override
  Widget build(BuildContext context) {
    final sales = data.sales;
    final purchases = data.purchases;
    final count = sales.length;
    if (count == 0) return const Center(child: Text('No data for this period.'));

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= count || (value - i).abs() > 0.01) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(sales[i].label, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (int i = 0; i < count; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(toY: sales[i].amount, color: _kGreen, width: 6, borderRadius: BorderRadius.circular(3)),
              BarChartRodData(toY: i < purchases.length ? purchases[i].amount : 0, color: _kAmber, width: 6, borderRadius: BorderRadius.circular(3)),
            ]),
        ],
      ),
    );
  }
}

class _StockList extends StatelessWidget {
  const _StockList({required this.items, required this.maxStock});
  final List<CurrentStock> items;
  final double maxStock;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No stock recorded yet.', style: TextStyle(color: _kMuted)));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(width: 90, child: Text(item.fruitName, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (item.currentStock / maxStock).clamp(0, 1).toDouble(),
                          minHeight: 7,
                          backgroundColor: const Color(0xFFEDF1ED),
                          color: _levelColor(item.currentStock / maxStock),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${item.currentStock.toStringAsFixed(item.currentStock == item.currentStock.roundToDouble() ? 0 : 2)} ${item.unit}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _levelColor(double ratio) {
    if (ratio < 0.25) return _kRed;
    if (ratio < 0.6) return _kAmber;
    return _kGreen;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.kicker, required this.title});
  final String kicker;
  final String title;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(kicker, style: const TextStyle(color: _kGreen, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.05)),
    const SizedBox(height: 3),
    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF213428))),
  ]);
}
