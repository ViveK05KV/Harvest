import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/widgets/paginated_list_view.dart';
import 'user_form_screen.dart';
import 'user_models.dart';
import 'user_service.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  late final UserService _service = UserService(context.read<ApiClient>());
  Key _listKey = UniqueKey();

  void _reload() => setState(() => _listKey = UniqueKey());

  Future<void> _openForm({AppUser? user}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => UserFormScreen(user: user)),
    );
    if (changed == true) _reload();
  }

  Future<void> _toggleActive(AppUser user) async {
    try {
      await _service.setActive(user.userId, !user.isActive);
      _reload();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MMM-yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: PaginatedListView<AppUser>(
        key: _listKey,
        fetchPage: _service.getPaged,
        padding: const EdgeInsets.only(bottom: 88),
        emptyState: const Column(
          children: [
            SizedBox(height: 80),
            Icon(Icons.manage_accounts_outlined, size: 48),
            SizedBox(height: 12),
            Center(child: Text('No users yet')),
          ],
        ),
        itemBuilder: (context, user) => ListTile(
          title: Text(user.fullName),
          subtitle: Text('${user.username} · ${user.role} · Since ${dateFormat.format(user.createdAt)}'),
          trailing: Switch(value: user.isActive, onChanged: (_) => _toggleActive(user)),
          onTap: () => _openForm(user: user),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
