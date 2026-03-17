import 'package:flutter/material.dart';

class PaginationConfig {
  static const int defaultPageSize = 50;
  static const int maxPageSize = 100;
  static const int prefetchDistance = 200;
  static const Duration debounceDelay = Duration(milliseconds: 300);
}

class PaginationController<T> extends ChangeNotifier {
  final Future<List<T>> Function(int offset, int limit) fetchPage;
  final int pageSize;

  PaginationController({
    required this.fetchPage,
    this.pageSize = PaginationConfig.defaultPageSize,
  });

  final List<T> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;

  List<T> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  Future<void> loadInitial() async {
    _items.clear();
    _currentPage = 0;
    _hasMore = true;
    await _loadMore();
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;
    await _loadMore();
  }

  Future<void> _loadMore() async {
    _isLoading = true;
    notifyListeners();

    try {
      final newItems = await fetchPage(
        _currentPage * pageSize,
        pageSize,
      );

      if (newItems.isEmpty) {
        _hasMore = false;
      } else {
        _items.addAll(newItems);
        _currentPage++;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void refresh() {
    loadInitial();
  }
}

class PaginatedListView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext, T) itemBuilder;
  final bool isLoading;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final RefreshCallback? onRefresh;
  final EdgeInsets padding;

  const PaginatedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.isLoading,
    required this.hasMore,
    required this.onLoadMore,
    this.onRefresh,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    Widget listView = ListView.builder(
      padding: padding,
      itemCount: items.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < items.length) {
          return itemBuilder(context, items[index]);
        } else {
          // Loading indicator at bottom
          onLoadMore();
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );

    if (onRefresh != null) {
      listView = RefreshIndicator(
        onRefresh: onRefresh!,
        child: listView,
      );
    }

    return listView;
  }
}