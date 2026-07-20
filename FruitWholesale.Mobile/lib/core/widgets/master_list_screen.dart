import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../models/paginated_list.dart';

/// Generic list+search+activate/deactivate screen for simple master-data
/// modules (Shops, Suppliers, Fruits, Routes, Employees, Expense Categories) —
/// mirrors the shared `MasterDataApiService`/list-component pattern used by
/// the Angular client, so each module only supplies its model, service calls,
/// and row rendering instead of re-implementing list plumbing.
class MasterListScreen<T> extends StatefulWidget {
  final String title;
  final String emptyLabel;
  final IconData emptyIcon;
  final Future<PaginatedList<T>> Function(int pageNumber) fetchPaged;
  final int Function(T) idOf;
  final String Function(T) titleOf;
  final String Function(T) subtitleOf;
  final bool Function(T) isActiveOf;
  final Future<void> Function(int id, bool activate) onSetActive;
  final Widget Function(BuildContext context, {int? id}) formBuilder;

  const MasterListScreen({
    super.key,
    required this.title,
    required this.emptyLabel,
    required this.emptyIcon,
    required this.fetchPaged,
    required this.idOf,
    required this.titleOf,
    required this.subtitleOf,
    required this.isActiveOf,
    required this.onSetActive,
    required this.formBuilder,
  });

  @override
  State<MasterListScreen<T>> createState() => _MasterListScreenState<T>();
}

class _MasterListScreenState<T> extends State<MasterListScreen<T>> {
  List<T>? _items;
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
      final page = await widget.fetchPaged(1);
      setState(() => _items = page.items);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openForm({int? id}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => widget.formBuilder(context, id: id)),
    );
    if (changed == true) _load();
  }

  Future<void> _toggleActive(T item) async {
    final id = widget.idOf(item);
    final active = widget.isActiveOf(item);
    try {
      await widget.onSetActive(id, !active);
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
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
        children: [
          const SizedBox(height: 80),
          Icon(widget.emptyIcon, size: 48),
          const SizedBox(height: 12),
          Center(child: Text(widget.emptyLabel)),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        final active = widget.isActiveOf(item);
        return ListTile(
          title: Text(widget.titleOf(item)),
          subtitle: Text(widget.subtitleOf(item)),
          trailing: Switch(value: active, onChanged: (_) => _toggleActive(item)),
          onTap: () => _openForm(id: widget.idOf(item)),
        );
      },
    );
  }
}
