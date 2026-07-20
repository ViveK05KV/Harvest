import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/widgets/master_list_screen.dart';
import 'route_master_form_screen.dart';
import 'route_master_models.dart';
import 'route_master_service.dart';

class RouteMasterListScreen extends StatelessWidget {
  const RouteMasterListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = RouteMasterService(context.read<ApiClient>());
    return MasterListScreen<RouteMaster>(
      title: 'Routes',
      emptyLabel: 'No routes yet',
      emptyIcon: Icons.alt_route_outlined,
      fetchPaged: service.getPaged,
      idOf: (r) => r.routeId,
      titleOf: (r) => r.routeName,
      subtitleOf: (r) => '${r.shopCount} shop${r.shopCount == 1 ? '' : 's'}',
      isActiveOf: (r) => r.isActive,
      onSetActive: service.setActive,
      formBuilder: (context, {id}) => RouteMasterFormScreen(routeId: id),
    );
  }
}
