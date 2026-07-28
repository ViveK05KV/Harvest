import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../stock/stock_models.dart';
import '../stock/stock_service.dart';
import 'dashboard_models.dart';
import 'dashboard_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardService _service = DashboardService(context.read<ApiClient>());
  late final StockService _stockService = StockService(context.read<ApiClient>());

  DashboardSummary? _summary;
  DashboardCharts? _charts;
  String? _error;
  bool _loading = true;

  DashboardPeriod _salesPeriod = DashboardPeriod.thisWeek;
  bool _salesTrendLoading = true;
  List<TrendPoint> _salesTrend = [];

  DashboardPeriod _svpPeriod = DashboardPeriod.thisWeek;
  bool _svpLoading = true;
  SalesVsPurchases? _svp;

  bool _stockLoading = true;
  List<CurrentStock> _stock = [];

  @override
  void initState() {
    super.initState();
    _load();
    _loadSalesTrend();
    _loadSalesVsPurchases();
    _loadStock();
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
      setState(() => _loading = false);
    }
  }

  Future<void> _loadSalesTrend() async {
    setState(() => _salesTrendLoading = true);
    try {
      final points = await _service.getSalesTrend(_salesPeriod);
      setState(() => _salesTrend = points);
    } on ApiException {
      // Leave whatever was there; the period selector can be retried.
    } finally {
      if (mounted) setState(() => _salesTrendLoading = false);
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

  Future<void> _reloadAll() => Future.wait([_load(), _loadSalesTrend(), _loadSalesVsPurchases(), _loadStock()]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Operations overview')),
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

    final summary = _summary!;
    final charts = _charts!;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    final cards = <(String, double, IconData)>[
      ('Current Cash Balance', summary.currentCashBalance, Icons.account_balance_wallet),
      ("Today's Collection", summary.todayCollection, Icons.payments),
      ("Today's Sales", summary.todaySales, Icons.point_of_sale),
      ("Today's Purchases", summary.todayPurchases, Icons.shopping_cart),
      ("Today's Expenses", summary.todayExpenses, Icons.receipt_long),
      ('Customer Outstanding', summary.customerOutstanding, Icons.storefront),
      ('Supplier Outstanding', summary.supplierOutstanding, Icons.local_shipping),
      ('Net Business Worth', summary.netBusinessWorth, Icons.trending_up),
      // Admin/Accountant-only: API leaves these null for other roles.
      if (summary.totalProfit != null) ("Today's Profit", summary.todayProfit ?? 0, Icons.trending_up),
      if (summary.totalProfit != null) ('Total Profit', summary.totalProfit!, Icons.savings),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('LIVE BUSINESS SNAPSHOT', style: TextStyle(color: Color(0xFF4F745F), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
        const SizedBox(height: 5),
        Text('Today at a glance', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF193126))),
        const SizedBox(height: 4),
        const Text('A clear view of your cash, sales, and collections.', style: TextStyle(color: Color(0xFF42594B), fontWeight: FontWeight.w500)),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            for (final (label, amount, icon) in cards)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(color: _toneFor(icon).$1, shape: BoxShape.circle),
                        child: Icon(icon, color: _toneFor(icon).$2, size: 20),
                      ),
                      const Spacer(),
                      Text(currencyFormat.format(amount), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1D3125))),
                      Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF42594B), fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        _ChartCard(
          kicker: 'REVENUE',
          title: 'Sales Overview',
          period: _salesPeriod,
          onPeriodChanged: (p) {
            setState(() => _salesPeriod = p);
            _loadSalesTrend();
          },
          child: _salesTrendLoading
              ? const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()))
              : SizedBox(height: 180, child: _SalesLineChart(points: _salesTrend)),
        ),
        const SizedBox(height: 16),
        _ChartCard(
          kicker: 'CASH FLOW',
          title: 'Sales vs Purchases',
          period: _svpPeriod,
          onPeriodChanged: (p) {
            setState(() => _svpPeriod = p);
            _loadSalesVsPurchases();
          },
          child: _svpLoading || _svp == null
              ? const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()))
              : SizedBox(height: 180, child: _SalesVsPurchasesBarChart(data: _svp!)),
        ),
        const SizedBox(height: 24),
        const _SectionHeader(kicker: 'INVENTORY', title: 'Stock products'),
        const SizedBox(height: 8),
        _stockLoading
            ? const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator()))
            : _StockList(items: _stock),
        const SizedBox(height: 24),
        const _SectionHeader(kicker: 'DEMAND', title: 'Top selling fruits'),
        const SizedBox(height: 8),
        if (charts.topSellingFruits.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No sales recorded yet.'))
        else
          Card(
            child: Column(
              children: [
                for (final fruit in charts.topSellingFruits)
                  ListTile(
                    dense: true,
                    title: Text(fruit.fruitName),
                    trailing: Text(currencyFormat.format(fruit.totalAmount)),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        const _SectionHeader(kicker: 'RELATIONSHIPS', title: 'Top customers'),
        const SizedBox(height: 8),
        if (charts.topCustomers.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No sales recorded yet.'))
        else
          Card(
            child: Column(
              children: [
                for (final customer in charts.topCustomers)
                  ListTile(
                    dense: true,
                    title: Text(customer.shopName),
                    trailing: Text(currencyFormat.format(customer.totalAmount)),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  (Color, Color) _toneFor(IconData icon) {
    if (icon == Icons.shopping_cart || icon == Icons.storefront) return (const Color(0xFFFFF1D8), const Color(0xFFC57C11));
    if (icon == Icons.receipt_long || icon == Icons.local_shipping) return (const Color(0xFFEDF0ED), const Color(0xFF52675A));
    return (const Color(0xFFE9F3EB), const Color(0xFF2E8A53));
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

class _SalesLineChart extends StatelessWidget {
  const _SalesLineChart({required this.points});
  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const Center(child: Text('No data for this period.'));

    return LineChart(
      LineChartData(
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
                if (i < 0 || i >= points.length || (value - i).abs() > 0.01) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(points[i].label, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (int i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].amount)],
            isCurved: true,
            color: const Color(0xFF1F7A48),
            barWidth: 2.5,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: const Color(0xFF1F7A48).withValues(alpha: 0.12)),
          ),
        ],
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
              BarChartRodData(toY: sales[i].amount, color: const Color(0xFF277A4B), width: 6, borderRadius: BorderRadius.circular(3)),
              BarChartRodData(toY: i < purchases.length ? purchases[i].amount : 0, color: const Color(0xFFC57C11), width: 6, borderRadius: BorderRadius.circular(3)),
            ]),
        ],
      ),
    );
  }
}

class _StockList extends StatelessWidget {
  const _StockList({required this.items});
  final List<CurrentStock> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No stock recorded yet.'));
    }
    final sorted = [...items]..sort((a, b) => a.currentStock.compareTo(b.currentStock));
    final lowest = sorted.take(8).toList();
    final maxStock = items.fold(0.0, (m, i) => i.currentStock > m ? i.currentStock : m).clamp(1, double.infinity);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            for (final item in lowest)
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
    if (ratio < 0.25) return const Color(0xFFC0392B);
    if (ratio < 0.6) return const Color(0xFFC57C11);
    return const Color(0xFF277A4B);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.kicker, required this.title});
  final String kicker;
  final String title;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(kicker, style: const TextStyle(color: Color(0xFF4F745F), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.05)),
    const SizedBox(height: 3),
    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF213428))),
  ]);
}
