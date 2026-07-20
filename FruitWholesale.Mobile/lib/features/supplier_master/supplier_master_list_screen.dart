import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/widgets/master_list_screen.dart';
import 'supplier_master_form_screen.dart';
import 'supplier_master_models.dart';
import 'supplier_master_service.dart';

class SupplierMasterListScreen extends StatelessWidget {
  const SupplierMasterListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = SupplierMasterService(context.read<ApiClient>());
    return MasterListScreen<SupplierMaster>(
      title: 'Suppliers',
      emptyLabel: 'No suppliers yet',
      emptyIcon: Icons.groups_outlined,
      fetchPaged: service.getPaged,
      idOf: (s) => s.supplierId,
      titleOf: (s) => s.supplierName,
      subtitleOf: (s) => s.phone ?? '',
      isActiveOf: (s) => s.isActive,
      onSetActive: service.setActive,
      formBuilder: (context, {id}) => SupplierMasterFormScreen(supplierId: id),
    );
  }
}
