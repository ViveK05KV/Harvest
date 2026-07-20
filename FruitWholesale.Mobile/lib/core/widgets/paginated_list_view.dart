import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../models/paginated_list.dart';

/// Infinite-scroll list backed by the backend's page-based `PaginatedList<T>`.
///
/// Handles initial load, pull-to-refresh, and automatic "load more" as the
/// user scrolls near the bottom — fixing the app-wide bug where every list
/// screen only ever fetched page 1 and silently hid everything past it.
class PaginatedListView<T> extends StatefulWidget {
  final Future<PaginatedList<T>> Function(int pageNumber) fetchPage;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Widget emptyState;
  final EdgeInsets padding;

  const PaginatedListView({
    super.key,
    required this.fetchPage,
    required this.itemBuilder,
    required this.emptyState,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final _scrollController = ScrollController();
  final List<T> _items = [];

  int _page = 1;
  bool _hasNextPage = true;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasNextPage || _loadingMore || _loading) return;
    final threshold = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.position.pixels >= threshold) {
      _loadMore();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.fetchPage(1);
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _page = 1;
        _hasNextPage = page.hasNextPage;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final page = await widget.fetchPage(_page + 1);
      setState(() {
        _items.addAll(page.items);
        _page += 1;
        _hasNextPage = page.hasNextPage;
      });
    } on ApiException {
      // Leave the already-loaded items visible; the user can retry by scrolling again.
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
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
    if (_items.isEmpty) {
      return RefreshIndicator(onRefresh: _loadFirstPage, child: ListView(children: [widget.emptyState]));
    }

    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      child: ListView.separated(
        controller: _scrollController,
        padding: widget.padding,
        itemCount: _items.length + (_hasNextPage ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            );
          }
          return widget.itemBuilder(context, _items[index]);
        },
      ),
    );
  }
}
