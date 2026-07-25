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
      appBar: AppBar(title: const Text('Dashboard')),
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
                      Icon(icon, color: Theme.of(context).colorScheme.primary),
                      const Spacer(),
                      Text(currencyFormat.format(amount), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(label, style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Top Selling Fruits', style: Theme.of(context).textTheme.titleMedium),
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
        Text('Top Customers', style: Theme.of(context).textTheme.titleMedium),
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
}
