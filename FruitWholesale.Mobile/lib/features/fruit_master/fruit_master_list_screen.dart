import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/widgets/master_list_screen.dart';
import 'fruit_master_form_screen.dart';
import 'fruit_master_models.dart';
import 'fruit_master_service.dart';

class FruitMasterListScreen extends StatelessWidget {
  const FruitMasterListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FruitMasterService(context.read<ApiClient>());
    return MasterListScreen<FruitMaster>(
      title: 'Fruits',
      emptyLabel: 'No fruits yet',
      emptyIcon: Icons.local_florist_outlined,
      fetchPaged: service.getPaged,
      idOf: (f) => f.fruitId,
      titleOf: (f) => f.fruitName,
      subtitleOf: (f) => f.unit,
      isActiveOf: (f) => f.isActive,
      onSetActive: service.setActive,
      formBuilder: (context, {id}) => FruitMasterFormScreen(fruitId: id),
    );
  }
}
