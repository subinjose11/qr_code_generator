import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/qr_item.dart';
import '../../data/models/qr_type.dart';
import '../../domain/repositories/i_qr_repository.dart';
import 'repository_provider.dart';

enum HistoryFilter { all, created, scanned, favorites }

class QrHistoryState {
  final List<QrItem> items;
  final bool isLoading;
  final String searchQuery;
  final HistoryFilter currentFilter;

  const QrHistoryState({
    this.items = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.currentFilter = HistoryFilter.all,
  });

  QrHistoryState copyWith({
    List<QrItem>? items,
    bool? isLoading,
    String? searchQuery,
    HistoryFilter? currentFilter,
  }) {
    return QrHistoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      currentFilter: currentFilter ?? this.currentFilter,
    );
  }

  List<QrItem> get filteredItems {
    List<QrItem> list;
    switch (currentFilter) {
      case HistoryFilter.all:
        list = items;
        break;
      case HistoryFilter.created:
        list = items.where((i) => !i.isScanned).toList();
        break;
      case HistoryFilter.scanned:
        list = items.where((i) => i.isScanned).toList();
        break;
      case HistoryFilter.favorites:
        list = items.where((i) => i.isFavorite).toList();
        break;
    }

    if (searchQuery.trim().isEmpty) {
      return list;
    }

    final query = searchQuery.toLowerCase().trim();
    return list.where((item) {
      return item.title.toLowerCase().contains(query) ||
          item.formattedPayload.toLowerCase().contains(query) ||
          item.type.title.toLowerCase().contains(query);
    }).toList();
  }

  int get totalCount => items.length;
  int get createdCount => items.where((i) => !i.isScanned).length;
  int get scannedCount => items.where((i) => i.isScanned).length;
  int get favoritesCount => items.where((i) => i.isFavorite).length;
}

class QrHistoryNotifier extends StateNotifier<QrHistoryState> {
  final IQrRepository repository;

  QrHistoryNotifier({required this.repository}) : super(const QrHistoryState());

  Future<void> loadItems() async {
    state = state.copyWith(isLoading: true);

    if (!repository.isInitialized) {
      await repository.init();
    }

    final items = repository.getAllItems();
    state = state.copyWith(items: items, isLoading: false);
  }

  void setFilter(HistoryFilter filter) {
    if (state.currentFilter != filter) {
      state = state.copyWith(currentFilter: filter);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> saveItem(QrItem item) async {
    await repository.saveItem(item);
    await loadItems();
  }

  Future<void> deleteItem(String id) async {
    await repository.deleteItem(id);
    await loadItems();
  }

  Future<void> toggleFavorite(String id) async {
    await repository.toggleFavorite(id);
    await loadItems();
  }

  Future<void> clearAll() async {
    await repository.clearAll();
    state = state.copyWith(items: []);
  }
}

/// Riverpod provider exposing QrHistoryNotifier and its reactive state
final qrHistoryProvider = StateNotifierProvider<QrHistoryNotifier, QrHistoryState>((ref) {
  final repo = ref.watch(qrRepositoryProvider);
  return QrHistoryNotifier(repository: repo)..loadItems();
});
