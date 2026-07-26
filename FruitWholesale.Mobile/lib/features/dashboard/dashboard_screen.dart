import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import 'dashboard_models.dart';
import 'dashboard_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardService _service = DashboardService(context.read<ApiClient>());

  DashboardSummary? _summary;
  DashboardCharts? _charts;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Operations overview')),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
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
      // Admin-only: API leaves these null for other roles.
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
