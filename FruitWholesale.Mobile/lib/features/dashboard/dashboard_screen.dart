import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/auth/auth_service.dart';
import '../shop_master/shop_master_service.dart';
import '../supplier_master/supplier_master_service.dart';
import 'dashboard_models.dart';
import 'dashboard_service.dart';

class _PayableRow {
  final String name;
  final double amount;
  const _PayableRow({required this.name, required this.amount});
}

// Colors below mirror the Angular client's dashboard.component.scss exactly
// (class name noted per constant) so the two dashboards read as one product.
const _kHeaderTitle = Color(0xFF193126); // .dashboard-header h1
const _kEyebrow = Color(0xFF4F745F); // .eyebrow / .card-kicker / today-strip-label .kicker

const _kCashCardBg = Color(0xFF141C17); // .hero-card--cash
const _kCashCardText = Color(0xFFEAF5EC);
const _kCashKicker = Color(0xFF8BA899); // .hero-card--cash .hero-kicker
const _kCashIn = Color(0xFF7FD6A0); // .hero-inout .in
const _kCashOut = Color(0xFFE3A79B); // .hero-inout .out

const _kHeroKicker = Color(0xFF78837C); // .hero-kicker (default)
const _kHeroKickerSlate = Color(0xFF5F7A6A); // .hero-kicker--slate
const _kHeroKickerGreen = Color(0xFF2C7A4E); // .hero-kicker--green
const _kHeroIcon = Color(0xFFA8B1A9); // .hero-icon (default)
const _kHeroIconSlate = Color(0xFF7D9187); // .hero-icon--slate
const _kHeroIconGreen = Color(0xFF3F9C69); // .hero-icon--green
const _kHeroValueDark = Color(0xFF121614); // .hero-value--dark
const _kHeroValueGreen = Color(0xFF1C6B45); // .hero-value--green
const _kHeroSub = Color(0xFF7B8A80); // .hero-sub / .muted
const _kProgressTrack = Color(0xFFF0F3EF); // .hero-progress
const _kProgressFill = Color(0xFFC0392B); // .hero-progress-fill
const _kAlertRed = Color(0xFFB03A2E); // .hero-alert
const _kPayableRow = Color(0xFF4C6155); // .hero-payables-row
const _kPayableAmount = Color(0xFF354139); // .hero-payables-row .amount
const _kAdminBadgeBg = Color(0xFFE9F3EB); // .hero-admin-badge
const _kAdminBadgeText = Color(0xFF237647); // .hero-admin-badge
const _kFootnoteText = Color(0xFF6C7F72); // .hero-footnote
const _kFootnoteStrong = Color(0xFF1D3125); // .hero-footnote strong

const _kTileLabel = Color(0xFF718177); // .tile-label
const _kTileValue = Color(0xFF1D3125); // .tile-value
const _kTileValueGreen = Color(0xFF1C6B45); // .tile-value--green

const _kChartTitle = Color(0xFF16281E); // .chart-card h3
const _kLegendText = Color(0xFF78837C); // .chart-legend-item

const _kDonutTotal = Color(0xFF121614); // .spending-donut-center .total-value
const _kDonutLabelMuted = Color(0xFF9AA39C); // .total-label / .pct
const _kSpendingLabel = Color(0xFF3C453F); // .spending-legend-row .label

const _kSalesBarColor = Color(0xFF1C6B45); // salesVsPurchasesData 'Sales'
const _kPurchasesBarColor = Color(0xFFC3D4C8); // salesVsPurchasesData 'Purchases'

// Matches dashboard.component.ts's expensePalette exactly.
const _kExpensePalette = [
  Color(0xFF1C6B45),
  Color(0xFF7FA88F),
  Color(0xFFC99A3D),
  Color(0xFFC3D4C8),
  Color(0xFF5F7A6A),
  Color(0xFFEFBD67),
  Color(0xFFA8C4B0),
  Color(0xFF3C453F),
];

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardService _service = DashboardService(context.read<ApiClient>());
  late final ShopMasterService _shopService = ShopMasterService(context.read<ApiClient>());
  late final SupplierMasterService _supplierService = SupplierMasterService(context.read<ApiClient>());

  DashboardSummary? _summary;
  DashboardCharts? _charts;
  String? _error;
  bool _loading = true;

  DashboardPeriod _svpPeriod = DashboardPeriod.thisWeek;
  bool _svpLoading = true;
  SalesVsPurchases? _svp;
  int _svpRequestId = 0;

  List<TrendPoint> _cashTrend = [];
  List<TrendPoint> _profitTrend = [];

  List<_PayableRow> _payables = [];
  int _supplierCount = 0;
  int _shopsWithBalanceCount = 0;
  double _overLimitAmount = 0;
  int _overLimitShopCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _loadSalesVsPurchases();
    _loadCashTrend();
    _loadProfitTrend();
    _loadPayables();
    _loadCustomerRisk();
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
    // Guard against a slower, stale-period response landing after a newer one -
    // switching the period dropdown quickly must not let an older response overwrite it.
    final requestId = ++_svpRequestId;
    setState(() => _svpLoading = true);
    try {
      final result = await _service.getSalesVsPurchases(_svpPeriod);
      if (!mounted || requestId != _svpRequestId) return;
      setState(() => _svp = result);
    } on ApiException {
      // Leave whatever was there; the period selector can be retried.
    } finally {
      if (mounted && requestId == _svpRequestId) setState(() => _svpLoading = false);
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

  Future<void> _reloadAll() => Future.wait([
        _load(),
        _loadSalesVsPurchases(),
        _loadCashTrend(),
        _loadProfitTrend(),
        _loadPayables(),
        _loadCustomerRisk(),
      ]);

  bool get _isBackOffice => context.read<AuthService>().user?.role.isBackOffice ?? false;

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
        const Text('LIVE BUSINESS SNAPSHOT', style: TextStyle(color: _kEyebrow, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
        const SizedBox(height: 4),
        Text(DateFormat('EEEE, d MMMM y').format(DateTime.now()),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: _kHeaderTitle)),
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
        if (backOffice) ...[
          _TotalProfitCard(summary: s, currency: currency, sparklineData: _profitTrend),
          const SizedBox(height: 12),
        ],
        _NetWorthCard(summary: s, currency: currency),
        const SizedBox(height: 12),
        _SupplierOutstandingCard(
          summary: s,
          currency: currency,
          supplierCount: _supplierCount,
          payables: _payables,
        ),

        const SizedBox(height: 20),
        _TodayStrip(summary: s, currency: currency, showProfit: s.todayProfit != null),

        const SizedBox(height: 24),
        _ChartCard(
          kicker: 'CASH FLOW',
          title: 'Sales vs purchases',
          period: _svpPeriod,
          onPeriodChanged: (p) {
            setState(() => _svpPeriod = p);
            _loadSalesVsPurchases();
          },
          legend: const [
            _LegendItem(label: 'Sales', color: _kSalesBarColor),
            _LegendItem(label: 'Purchases', color: _kPurchasesBarColor),
          ],
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
        _SectionHeader(kicker: 'SPENDING', title: 'Where the money went'),
        const SizedBox(height: 8),
        _ExpensesDoughnutCard(items: _charts?.expensesByCategory ?? []),
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
      color: _kCashCardBg,
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
                      const Text('CASH BALANCE', style: TextStyle(color: _kCashKicker, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                      const SizedBox(height: 6),
                      Text(currency.format(summary.currentCashBalance),
                          style: const TextStyle(color: _kCashCardText, fontSize: 26, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                Icon(Icons.account_balance_wallet, color: _kCashCardText.withValues(alpha: 0.7)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('+${currency.format(summary.todayCollection)} in', style: const TextStyle(color: _kCashIn, fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(width: 12),
                Text('−${currency.format(summary.todayPurchases + summary.todayExpenses)} out',
                    style: const TextStyle(color: _kCashOut, fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(height: 48, child: _Sparkline(points: sparklineData, color: _kCashIn)),
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
                const Text('CUSTOMER OUTSTANDING', style: TextStyle(color: _kHeroKicker, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                const Icon(Icons.storefront, color: _kHeroIcon, size: 20),
              ],
            ),
            const SizedBox(height: 6),
            Text(currency.format(summary.customerOutstanding), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _kHeroValueDark)),
            const SizedBox(height: 2),
            Text('$shopsWithBalanceCount ${shopsWithBalanceCount == 1 ? 'customer' : 'customers'} with a balance', style: const TextStyle(color: _kHeroSub, fontSize: 12)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (atRiskPercent / 100).clamp(0, 1),
                minHeight: 6,
                backgroundColor: _kProgressTrack,
                color: _kProgressFill,
              ),
            ),
            if (overLimitAmount > 0) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: _kAlertRed),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${currency.format(overLimitAmount)} over credit limit · $overLimitShopCount ${overLimitShopCount == 1 ? 'customer' : 'customers'}',
                      style: const TextStyle(color: _kAlertRed, fontSize: 12, fontWeight: FontWeight.w600),
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
  const _SupplierOutstandingCard({
    required this.summary,
    required this.currency,
    required this.supplierCount,
    required this.payables,
  });
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
                const Text('SUPPLIER OUTSTANDING', style: TextStyle(color: _kHeroKickerSlate, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                const Icon(Icons.local_shipping, color: _kHeroIconSlate, size: 20),
              ],
            ),
            const SizedBox(height: 6),
            Text(currency.format(summary.supplierOutstanding), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _kHeroValueDark)),
            const SizedBox(height: 2),
            Text('$supplierCount ${supplierCount == 1 ? 'supplier' : 'suppliers'}', style: const TextStyle(color: _kHeroSub, fontSize: 12)),
            const SizedBox(height: 10),
            if (payables.isEmpty)
              const Text('No outstanding balances.', style: TextStyle(color: _kHeroSub, fontSize: 12))
            else
              ...payables.map(
                (p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(p.name, style: const TextStyle(fontSize: 13, color: _kPayableRow), overflow: TextOverflow.ellipsis)),
                      Text(currency.format(p.amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPayableAmount)),
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
  const _TotalProfitCard({required this.summary, required this.currency, required this.sparklineData});
  final DashboardSummary summary;
  final NumberFormat currency;
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
                const Text('TOTAL PROFIT', style: TextStyle(color: _kHeroKicker, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _kAdminBadgeBg, borderRadius: BorderRadius.circular(6)),
                  child: const Text('ADMIN', style: TextStyle(color: _kAdminBadgeText, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(currency.format(summary.totalProfit ?? 0), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _kHeroValueDark)),
            const SizedBox(height: 2),
            const Text('All time', style: TextStyle(color: _kHeroSub, fontSize: 12)),
            const SizedBox(height: 10),
            SizedBox(height: 48, child: _Sparkline(points: sparklineData, color: _kHeroValueGreen)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Today's Profit", style: TextStyle(color: _kFootnoteText, fontSize: 12)),
                Text(currency.format(summary.todayProfit ?? 0), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _kFootnoteStrong)),
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
                const Text('NET BUSINESS WORTH', style: TextStyle(color: _kHeroKickerGreen, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                const Icon(Icons.trending_up, color: _kHeroIconGreen, size: 20),
              ],
            ),
            const SizedBox(height: 6),
            Text(currency.format(summary.netBusinessWorth), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _kHeroValueGreen)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cash + Receivables', style: TextStyle(color: _kFootnoteText, fontSize: 12)),
                Text(
                  currency.format(summary.currentCashBalance + summary.customerOutstanding + summary.employeeLoanTotal),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _kFootnoteStrong),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayStrip extends StatelessWidget {
  const _TodayStrip({required this.summary, required this.currency, required this.showProfit});
  final DashboardSummary summary;
  final NumberFormat currency;
  final bool showProfit;

  @override
  Widget build(BuildContext context) {
    final tiles = <(String, double, bool)>[
      ('Sales', summary.todaySales, false),
      ('Collections', summary.todayCollection, false),
      ('Purchases', summary.todayPurchases, false),
      ('Expenses', summary.todayExpenses + summary.todaySalary, false),
      if (showProfit) ("Today's Profit", summary.todayProfit ?? 0, false),
      ('Net Cash', summary.todayCollection - summary.todayPurchases - summary.todayExpenses, true),
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
                    const Text('TODAY', style: TextStyle(color: _kEyebrow, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    Text(DateFormat('d MMM').format(DateTime.now()), style: const TextStyle(color: _kHeroSub, fontSize: 11)),
                  ],
                ),
              ),
              for (final (label, value, green) in tiles)
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(color: _kTileLabel, fontSize: 11)),
                      Text(currency.format(value), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: green ? _kTileValueGreen : _kTileValue)),
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
              Text(label, style: const TextStyle(color: _kTileLabel, fontSize: 11)),
              const SizedBox(height: 2),
              Text(currency.format(value), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
            ],
          ),
        );
    return Row(
      children: [
        tile('Sales', totals.sales, _kTileValue),
        tile('Purchases', totals.purchases, _kTileValue),
        tile('Margin', totals.margin, _kTileValueGreen),
      ],
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

class _ExpensesDoughnutCard extends StatelessWidget {
  const _ExpensesDoughnutCard({required this.items});
  final List<CategoryAmount> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: SizedBox(height: 200, child: _ExpensesDoughnut(items: items)),
      ),
    );
  }
}

class _ExpensesDoughnut extends StatelessWidget {
  const _ExpensesDoughnut({required this.items});
  final List<CategoryAmount> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('No expenses recorded.', style: TextStyle(color: _kHeroSub)));
    final total = items.fold(0.0, (sum, i) => sum + i.amount);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 110,
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  centerSpaceRadius: 32,
                  sectionsSpace: 2,
                  sections: [
                    for (int i = 0; i < items.length; i++)
                      PieChartSectionData(
                        value: items[i].amount,
                        color: _kExpensePalette[i % _kExpensePalette.length],
                        showTitle: false,
                        radius: 22,
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹').format(total),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kDonutTotal)),
                  const Text('total', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w500, color: _kDonutLabelMuted)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < items.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(width: 9, height: 9, decoration: BoxDecoration(color: _kExpensePalette[i % _kExpensePalette.length], borderRadius: BorderRadius.circular(3))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(items[i].category, style: const TextStyle(fontSize: 12, color: _kSpendingLabel), overflow: TextOverflow.ellipsis),
                      ),
                      Text(NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹').format(items[i].amount),
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: _kDonutTotal)),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${total == 0 ? 0 : (items[i].amount / total * 100).toStringAsFixed(0)}%',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 11, color: _kDonutLabelMuted),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 9, height: 9, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 11.5, color: _kLegendText)),
        ],
      );
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.kicker,
    required this.title,
    required this.period,
    required this.onPeriodChanged,
    required this.child,
    this.legend,
  });

  final String kicker;
  final String title;
  final DashboardPeriod period;
  final ValueChanged<DashboardPeriod> onPeriodChanged;
  final Widget child;
  final List<_LegendItem>? legend;

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
            if (legend != null) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 14, runSpacing: 4, children: legend!),
            ],
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
              BarChartRodData(toY: sales[i].amount, color: _kSalesBarColor, width: 6, borderRadius: BorderRadius.circular(3)),
              BarChartRodData(toY: i < purchases.length ? purchases[i].amount : 0, color: _kPurchasesBarColor, width: 6, borderRadius: BorderRadius.circular(3)),
            ]),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.kicker, required this.title});
  final String kicker;
  final String title;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(kicker, style: const TextStyle(color: _kEyebrow, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.05)),
    const SizedBox(height: 3),
    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: _kChartTitle)),
  ]);
}
