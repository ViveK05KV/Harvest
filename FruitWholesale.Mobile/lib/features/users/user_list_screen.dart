import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
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

  List<AppUser>? _items;
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
      final page = await _service.getPaged(1);
      setState(() => _items = page.items);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openForm({AppUser? user}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => UserFormScreen(user: user)),
    );
    if (changed == true) _load();
  }

  Future<void> _toggleActive(AppUser user) async {
    try {
      await _service.setActive(user.userId, !user.isActive);
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _items == null) {
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
    final items = _items ?? [];
    if (items.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          Icon(Icons.manage_accounts_outlined, size: 48),
          SizedBox(height: 12),
          Center(child: Text('No users yet')),
        ],
      );
    }

    final dateFormat = DateFormat('dd-MMM-yyyy');

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final user = items[index];
        return ListTile(
          title: Text(user.fullName),
          subtitle: Text('${user.username} · ${user.role} · Since ${dateFormat.format(user.createdAt)}'),
          trailing: Switch(value: user.isActive, onChanged: (_) => _toggleActive(user)),
          onTap: () => _openForm(user: user),
        );
      },
    );
  }
}
