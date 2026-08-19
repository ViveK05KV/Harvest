import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../models/paginated_list.dart';
import '../theme/app_theme.dart';
import 'paginated_list_view.dart';

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

  /// Optional widget rendered between the app bar and the list — e.g. a
  /// filter dropdown. Owned entirely by the caller.
  final Widget? header;

  /// Optional extra widget rendered before the active/inactive switch on
  /// each row (e.g. an "Adjust Balance" icon button).
  final Widget? Function(T item)? trailingExtra;

  /// When this value changes between builds, the list is refetched — lets a
  /// parent-owned filter (e.g. a selected route) drive a reload without the
  /// caller needing to reach into this widget's internal state.
  final Object? filterSignal;

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
    this.header,
    this.trailingExtra,
    this.filterSignal,
  });

  @override
  State<MasterListScreen<T>> createState() => _MasterListScreenState<T>();
}

class _MasterListScreenState<T> extends State<MasterListScreen<T>> {
  Key _listKey = UniqueKey();

  // PaginatedListView only fetches once per widget identity, so force a
  // fresh instance (and thus a fresh fetch) whenever data may have changed.
  void _reload() => setState(() => _listKey = UniqueKey());

  @override
  void didUpdateWidget(covariant MasterListScreen<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filterSignal != oldWidget.filterSignal) _reload();
  }

  Future<void> _openForm({int? id}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => widget.formBuilder(context, id: id)),
    );
    if (changed == true) _reload();
  }

  Future<void> _toggleActive(T item) async {
    final id = widget.idOf(item);
    final active = widget.isActiveOf(item);
    try {
      await widget.onSetActive(id, !active);
      _reload();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          if (widget.header != null) widget.header!,
          Expanded(
            child: PaginatedListView<T>(
              key: _listKey,
              fetchPage: widget.fetchPaged,
              emptyState: Column(
                children: [
                  const SizedBox(height: 80),
                  Icon(widget.emptyIcon, size: 48),
                  const SizedBox(height: 12),
                  Center(child: Text(widget.emptyLabel)),
                ],
              ),
              padding: const EdgeInsets.only(bottom: 88),
              itemBuilder: (context, item) {
                final active = widget.isActiveOf(item);
                final extra = widget.trailingExtra?.call(item);
                return ListTile(
                  title: Text(widget.titleOf(item), style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600)),
                  subtitle: Text(widget.subtitleOf(item), style: const TextStyle(color: AppColors.mutedInk)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (extra != null) extra,
                      Switch(value: active, onChanged: (_) => _toggleActive(item)),
                    ],
                  ),
                  onTap: () => _openForm(id: widget.idOf(item)),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
