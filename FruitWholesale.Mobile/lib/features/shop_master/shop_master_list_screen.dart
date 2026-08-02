import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/lookup_service.dart';
import '../../core/auth/auth_service.dart';
import '../../core/models/route_option.dart';
import '../../core/models/user_role.dart';
import '../../core/widgets/balance_adjustment_dialog.dart';
import '../../core/widgets/master_list_screen.dart';
import 'shop_master_form_screen.dart';
import 'shop_master_models.dart';
import 'shop_master_service.dart';

class ShopMasterListScreen extends StatefulWidget {
  const ShopMasterListScreen({super.key});

  @override
  State<ShopMasterListScreen> createState() => _ShopMasterListScreenState();
}

class _ShopMasterListScreenState extends State<ShopMasterListScreen> {
  late final ShopMasterService _service = ShopMasterService(context.read<ApiClient>());
  late final LookupService _lookupService = LookupService(context.read<ApiClient>());

  List<RouteOption> _routes = [];
  int? _routeId;
  int _reloadNonce = 0;

  @override
  void initState() {
    super.initState();
    _lookupService.getActiveRoutes().then((routes) {
      if (mounted) setState(() => _routes = routes);
    });
  }

  bool get _canAdjustBalance {
    final role = context.read<AuthService>().user?.role;
    return role == UserRole.admin || role == UserRole.accountant;
  }

  Future<void> _adjustBalance(ShopMaster shop) async {
    final result = await showBalanceAdjustmentDialog(context, entityName: shop.shopName);
    if (result == null || !mounted) return;
    try {
      await _service.applyBalanceAdjustment(shop.shopId, amount: result.amount, isIncrease: result.isIncrease, narration: result.narration);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Balance adjustment applied.')));
      setState(() => _reloadNonce++);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterListScreen<ShopMaster>(
      title: 'Shops',
      emptyLabel: 'No shops yet',
      emptyIcon: Icons.store_outlined,
      fetchPaged: (page) => _service.getPaged(page, routeId: _routeId),
      filterSignal: (_routeId, _reloadNonce),
      idOf: (s) => s.shopId,
      titleOf: (s) => s.shopName,
      subtitleOf: (s) => [s.routeName, s.phone].where((v) => v != null && v.isNotEmpty).join(' · '),
      isActiveOf: (s) => s.isActive,
      onSetActive: _service.setActive,
      formBuilder: (context, {id}) => ShopMasterFormScreen(shopId: id),
      header: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: DropdownButtonFormField<int?>(
          initialValue: _routeId,
          decoration: const InputDecoration(labelText: 'Route', isDense: true),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('All routes')),
            for (final route in _routes) DropdownMenuItem(value: route.routeId, child: Text(route.routeName)),
          ],
          onChanged: (value) => setState(() => _routeId = value),
        ),
      ),
      trailingExtra: _canAdjustBalance
          ? (shop) => IconButton(
                icon: const Icon(Icons.account_balance_wallet_outlined),
                tooltip: 'Adjust Balance',
                onPressed: () => _adjustBalance(shop),
              )
          : null,
    );
  }
}
