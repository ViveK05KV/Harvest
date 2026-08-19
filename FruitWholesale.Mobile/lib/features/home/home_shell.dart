import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_service.dart';
import '../../core/models/nav_item.dart';
import '../../core/models/user_role.dart';
import '../../core/theme/app_theme.dart';
import '../settings/company_settings_models.dart';
import '../settings/company_settings_service.dart';
import '../bill_printing/bill_printing_list_screen.dart';
import '../collections/collections_list_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../daily_expense/daily_expense_list_screen.dart';
import '../employee/employee_list_screen.dart';
import '../employee_work_log/employee_work_log_list_screen.dart';
import '../expense_category/expense_category_list_screen.dart';
import '../fruit_master/fruit_master_list_screen.dart';
import '../ledgers/cash_ledger_screen.dart';
import '../ledgers/shop_ledger_screen.dart';
import '../ledgers/supplier_ledger_screen.dart';
import '../profit/profit_screen.dart';
import '../purchase/purchase_list_screen.dart';
import '../reports/reports_screen.dart';
import '../route_master/route_master_list_screen.dart';
import '../settings/settings_screen.dart';
import '../shop_master/shop_master_list_screen.dart';
import '../shop_return/shop_return_list_screen.dart';
import '../stock/stock_screen.dart';
import '../supplier_master/supplier_master_list_screen.dart';
import '../supplier_payment/supplier_payment_list_screen.dart';
import '../supplier_return/supplier_return_list_screen.dart';
import '../supply/supply_form_screen.dart';
import '../supply/supply_list_screen.dart';
import '../users/user_list_screen.dart';

/// Post-login shell: drawer navigation grouped and role-filtered exactly like
/// the Angular sidenav (`main-layout.component.ts`). "Back office" = Admin,
/// Manager, Accountant. Staff only ever sees Supply, Shop Returns,
/// Collections, and Stock. Admin has full access, including Administration
/// (Users, Settings). Manager has everything except Administration and Users
/// management, plus Reports/Profit Calculator if the admin has switched
/// those on for Manager from Settings.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const List<UserRole> _backOffice = [UserRole.admin, UserRole.manager, UserRole.accountant];

  static const _sidebarBg = AppColors.sidebarBg;
  static const _sidebarAccent = AppColors.primary;
  static const _sidebarText = AppColors.sidebarText;
  static const _sidebarMuted = AppColors.sidebarMuted;

  late final List<NavGroup> _groups = [
    NavGroup(items: [
      NavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, builder: (_) => const DashboardScreen(), roles: _backOffice),
    ], label: 'Overview'),
    NavGroup(label: 'Transactions', items: [
      NavItem(label: 'Supply', icon: Icons.local_shipping_outlined, builder: (_) => const SupplyListScreen()),
      NavItem(label: 'Collections', icon: Icons.payments_outlined, builder: (_) => const CollectionsListScreen()),
      NavItem(label: 'Purchases', icon: Icons.shopping_cart_outlined, builder: (_) => const PurchaseListScreen(), roles: _backOffice),
      NavItem(
        label: 'Supplier Payments',
        icon: Icons.account_balance_wallet_outlined,
        builder: (_) => const SupplierPaymentListScreen(),
        roles: _backOffice,
      ),
      NavItem(label: 'Sales Returns', icon: Icons.assignment_return_outlined, builder: (_) => const ShopReturnListScreen()),
      NavItem(
        label: 'Purchase Returns',
        icon: Icons.keyboard_return_outlined,
        builder: (_) => const SupplierReturnListScreen(),
        roles: _backOffice,
      ),
      NavItem(label: 'Billing', icon: Icons.print_outlined, builder: (_) => const BillPrintingListScreen()),
      NavItem(
        label: 'Expenses',
        icon: Icons.receipt_long_outlined,
        builder: (_) => const DailyExpenseListScreen(),
        roles: _backOffice,
      ),
      NavItem(
        label: 'Salary Management',
        icon: Icons.work_history_outlined,
        builder: (_) => const EmployeeWorkLogListScreen(),
        roles: _backOffice,
      ),
    ]),
    NavGroup(label: 'Ledgers', items: [
      NavItem(label: 'Shop Ledger', icon: Icons.storefront_outlined, builder: (_) => const ShopLedgerScreen(), roles: _backOffice),
      NavItem(
        label: 'Supplier Ledger',
        icon: Icons.inventory_2_outlined,
        builder: (_) => const SupplierLedgerScreen(),
        roles: _backOffice,
      ),
      NavItem(label: 'Cash Ledger', icon: Icons.account_balance_outlined, builder: (_) => const CashLedgerScreen(), roles: _backOffice),
      // Stock is open to Staff too, unlike the rest of this group.
      NavItem(label: 'Inventory', icon: Icons.inventory_outlined, builder: (_) => const StockScreen()),
    ]),
    NavGroup(label: 'Reports', items: [
      NavItem(
        label: 'Reports',
        icon: Icons.assessment_outlined,
        builder: (_) => const ReportsScreen(),
        roles: [UserRole.admin],
        managerUnlockedBy: (s) => s?.reportsVisibleToManagers ?? false,
      ),
      NavItem(
        label: 'Profit Calculator',
        icon: Icons.trending_up,
        builder: (_) => const ProfitScreen(),
        roles: [UserRole.admin],
        managerUnlockedBy: (s) => s?.profitVisibleToManagers ?? false,
      ),
    ]),
    NavGroup(label: 'Masters', items: [
      NavItem(label: 'Shops', icon: Icons.store_outlined, builder: (_) => const ShopMasterListScreen(), roles: _backOffice),
      NavItem(label: 'Suppliers', icon: Icons.groups_outlined, builder: (_) => const SupplierMasterListScreen(), roles: _backOffice),
      NavItem(label: 'Fruits', icon: Icons.local_florist_outlined, builder: (_) => const FruitMasterListScreen(), roles: _backOffice),
      NavItem(label: 'Routes', icon: Icons.alt_route_outlined, builder: (_) => const RouteMasterListScreen(), roles: _backOffice),
      NavItem(label: 'Employees', icon: Icons.badge_outlined, builder: (_) => const EmployeeListScreen(), roles: _backOffice),
      NavItem(
        label: 'Expense Categories',
        icon: Icons.category_outlined,
        builder: (_) => const ExpenseCategoryListScreen(),
        roles: _backOffice,
      ),
    ]),
    NavGroup(label: 'Administration', items: [
      NavItem(
        label: 'Users',
        icon: Icons.manage_accounts_outlined,
        builder: (_) => const UserListScreen(),
        roles: [UserRole.admin],
      ),
      NavItem(
        label: 'Settings',
        icon: Icons.settings_outlined,
        // Every role can reach Settings now (self-service password/username);
        // no roles restriction.
        builder: (_) => SettingsScreen(
          companySettings: _companySettings,
          onCompanySettingsChanged: (s) => setState(() => _companySettings = s),
        ),
      ),
    ]),
  ];

  late NavItem _selected;
  CompanySettings? _companySettings;

  @override
  void initState() {
    super.initState();
    final role = context.read<AuthService>().user!.role;
    final visibleGroups = _groups.map((g) => g.visibleItems(role, _companySettings)).where((items) => items.isNotEmpty).toList();
    // Staff's home is Supply; every other role lands on Dashboard.
    final home = role == UserRole.staff
        ? visibleGroups.expand((items) => items).firstWhere((item) => item.label == 'Supply')
        : visibleGroups.first.first;
    _selected = home;
    _loadCompanySettings();
  }

  // Best-effort: only used to unlock Reports/Profit Calculator for Manager
  // and to seed the Settings screen's "Manager Access" toggles. A failure
  // here just leaves the nav at its Admin-only floor, same as before.
  Future<void> _loadCompanySettings() async {
    try {
      final settings = await CompanySettingsService(context.read<ApiClient>()).get();
      if (mounted) setState(() => _companySettings = settings);
    } catch (_) {
      // ignore
    }
  }

  void _select(NavItem item) {
    setState(() => _selected = item);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final role = auth.user!.role;
    final visibleGroups = _groups
        .map((g) => NavGroup(label: g.label, items: g.visibleItems(role, _companySettings)))
        .where((g) => g.items.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_selected.label),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart_outlined),
            tooltip: 'Create Sale',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupplyFormScreen())),
          ),
          PopupMenuButton<String>(
            icon: const CircleAvatar(child: Icon(Icons.person)),
            onSelected: (value) {
              if (value == 'logout') auth.logout();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  '${auth.user!.fullName}\n${auth.user!.role.toApi}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        backgroundColor: _sidebarBg,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: Image.asset('assets/branding/harvest-logo.png', fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Harvest Wholesale',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            for (final group in visibleGroups) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  group.label.toUpperCase(),
                  style: const TextStyle(color: _sidebarMuted, fontSize: 11, letterSpacing: 0.8, fontWeight: FontWeight.w500),
                ),
              ),
              for (final item in group.items)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    leading: Icon(item.icon),
                    title: Text(item.label),
                    selected: item.label == _selected.label,
                    selectedTileColor: _sidebarAccent,
                    selectedColor: Colors.white,
                    iconColor: _sidebarText,
                    textColor: _sidebarText,
                    onTap: () => _select(item),
                  ),
                ),
            ],
          ],
        ),
      ),
      body: _selected.builder(context),
    );
  }
}
