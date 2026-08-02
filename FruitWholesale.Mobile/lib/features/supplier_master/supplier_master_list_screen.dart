import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/auth/auth_service.dart';
import '../../core/models/user_role.dart';
import '../../core/widgets/balance_adjustment_dialog.dart';
import '../../core/widgets/master_list_screen.dart';
import 'supplier_master_form_screen.dart';
import 'supplier_master_models.dart';
import 'supplier_master_service.dart';

class SupplierMasterListScreen extends StatefulWidget {
  const SupplierMasterListScreen({super.key});

  @override
  State<SupplierMasterListScreen> createState() => _SupplierMasterListScreenState();
}

class _SupplierMasterListScreenState extends State<SupplierMasterListScreen> {
  late final SupplierMasterService _service = SupplierMasterService(context.read<ApiClient>());

  int _reloadNonce = 0;

  bool get _canAdjustBalance {
    final role = context.read<AuthService>().user?.role;
    return role == UserRole.admin || role == UserRole.accountant;
  }

  Future<void> _adjustBalance(SupplierMaster supplier) async {
    final result = await showBalanceAdjustmentDialog(context, entityName: supplier.supplierName);
    if (result == null || !mounted) return;
    try {
      await _service.applyBalanceAdjustment(supplier.supplierId, amount: result.amount, isIncrease: result.isIncrease, narration: result.narration);
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
    return MasterListScreen<SupplierMaster>(
      title: 'Suppliers',
      emptyLabel: 'No suppliers yet',
      emptyIcon: Icons.groups_outlined,
      fetchPaged: _service.getPaged,
      filterSignal: _reloadNonce,
      idOf: (s) => s.supplierId,
      titleOf: (s) => s.supplierName,
      subtitleOf: (s) => s.phone ?? '',
      isActiveOf: (s) => s.isActive,
      onSetActive: _service.setActive,
      formBuilder: (context, {id}) => SupplierMasterFormScreen(supplierId: id),
      trailingExtra: _canAdjustBalance
          ? (supplier) => IconButton(
                icon: const Icon(Icons.account_balance_wallet_outlined),
                tooltip: 'Adjust Balance',
                onPressed: () => _adjustBalance(supplier),
              )
          : null,
    );
  }
}
