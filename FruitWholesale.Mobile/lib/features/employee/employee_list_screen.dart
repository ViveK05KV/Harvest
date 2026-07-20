import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/widgets/master_list_screen.dart';
import 'employee_form_screen.dart';
import 'employee_models.dart';
import 'employee_service.dart';

class EmployeeListScreen extends StatelessWidget {
  const EmployeeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = EmployeeService(context.read<ApiClient>());
    return MasterListScreen<Employee>(
      title: 'Employees',
      emptyLabel: 'No employees yet',
      emptyIcon: Icons.badge_outlined,
      fetchPaged: service.getPaged,
      idOf: (e) => e.employeeId,
      titleOf: (e) => e.fullName,
      subtitleOf: (e) => e.phone ?? '',
      isActiveOf: (e) => e.isActive,
      onSetActive: service.setActive,
      formBuilder: (context, {id}) => EmployeeFormScreen(employeeId: id),
    );
  }
}
