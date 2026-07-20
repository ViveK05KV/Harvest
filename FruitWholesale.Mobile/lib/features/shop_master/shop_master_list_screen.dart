import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/widgets/master_list_screen.dart';
import 'shop_master_form_screen.dart';
import 'shop_master_models.dart';
import 'shop_master_service.dart';

class ShopMasterListScreen extends StatelessWidget {
  const ShopMasterListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ShopMasterService(context.read<ApiClient>());
    return MasterListScreen<ShopMaster>(
      title: 'Shops',
      emptyLabel: 'No shops yet',
      emptyIcon: Icons.store_outlined,
      fetchPaged: service.getPaged,
      idOf: (s) => s.shopId,
      titleOf: (s) => s.shopName,
      subtitleOf: (s) => [s.routeName, s.phone].where((v) => v != null && v.isNotEmpty).join(' · '),
      isActiveOf: (s) => s.isActive,
      onSetActive: service.setActive,
      formBuilder: (context, {id}) => ShopMasterFormScreen(shopId: id),
    );
  }
}
