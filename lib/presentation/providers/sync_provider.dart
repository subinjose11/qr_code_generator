import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/sync_service.dart';
import 'auth_provider.dart';
import 'qr_history_provider.dart';
import 'repository_provider.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final repository = ref.watch(qrRepositoryProvider);
  return SyncService(repository: repository);
});

class SyncState {
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final SyncResult? lastResult;
  final String? errorMessage;

  const SyncState({
    this.isSyncing = false,
    this.lastSyncTime,
    this.lastResult,
    this.errorMessage,
  });

  SyncState copyWith({
    bool? isSyncing,
    DateTime? lastSyncTime,
    SyncResult? lastResult,
    String? errorMessage,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastResult: lastResult ?? this.lastResult,
      errorMessage: errorMessage,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  final Ref _ref;

  SyncNotifier(this._ref) : super(const SyncState());

  Future<SyncResult?> syncNow() async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) {
      state = state.copyWith(errorMessage: 'Please sign in to sync with cloud.');
      return null;
    }

    state = state.copyWith(isSyncing: true, errorMessage: null);

    try {
      final syncService = _ref.read(syncServiceProvider);
      final result = await syncService.syncAll(user.uid);

      // Refresh the history list so downloaded items appear immediately
      await _ref.read(qrHistoryProvider.notifier).loadItems();

      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: result.timestamp,
        lastResult: result,
      );
      return result;
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(ref);
});
