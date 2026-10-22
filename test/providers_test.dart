import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_generator/data/models/qr_item.dart';
import 'package:qr_code_generator/data/models/qr_style_config.dart';
import 'package:qr_code_generator/data/models/qr_type.dart';
import 'package:qr_code_generator/domain/repositories/i_qr_repository.dart';
import 'package:qr_code_generator/presentation/providers/qr_creator_provider.dart';
import 'package:qr_code_generator/presentation/providers/qr_history_provider.dart';
import 'package:qr_code_generator/presentation/providers/repository_provider.dart';
import 'package:qr_code_generator/presentation/providers/scanner_provider.dart';

class FakeQrRepository implements IQrRepository {
  final List<QrItem> _storage = [];
  bool _initialized = false;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> init() async {
    _initialized = true;
  }

  @override
  List<QrItem> getAllItems() => List.unmodifiable(_storage);

  @override
  List<QrItem> getCreatedItems() =>
      _storage.where((i) => !i.isScanned).toList();

  @override
  List<QrItem> getScannedItems() => _storage.where((i) => i.isScanned).toList();

  @override
  List<QrItem> getFavorites() => _storage.where((i) => i.isFavorite).toList();

  @override
  Future<void> saveItem(QrItem item) async {
    final idx = _storage.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      _storage[idx] = item;
    } else {
      _storage.insert(0, item);
    }
  }

  @override
  Future<void> deleteItem(String id) async {
    _storage.removeWhere((i) => i.id == id);
  }

  @override
  Future<void> toggleFavorite(String id) async {
    final idx = _storage.indexWhere((i) => i.id == id);
    if (idx >= 0) {
      final current = _storage[idx];
      _storage[idx] = current.copyWith(isFavorite: !current.isFavorite);
    }
  }

  @override
  Future<void> clearAll() async {
    _storage.clear();
  }
}

void main() {
  group('Riverpod DI & qrHistoryProvider Tests', () {
    late FakeQrRepository fakeRepo;
    late ProviderContainer container;

    setUp(() {
      fakeRepo = FakeQrRepository();
      container = ProviderContainer(
        overrides: [qrRepositoryProvider.overrideWithValue(fakeRepo)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Dependency injection injects fakeRepo via qrRepositoryProvider', () {
      final injected = container.read(qrRepositoryProvider);
      expect(injected, same(fakeRepo));
    });

    test('Loads items from repository', () async {
      final item = QrItem(
        id: '1',
        title: 'Test QR',
        type: QrType.url,
        rawData: 'https://antigravity.google.com',
        formattedPayload: 'https://antigravity.google.com',
        styleConfig: const QrStyleConfig(),
        createdAt: DateTime.now(),
      );
      await fakeRepo.saveItem(item);

      await container.read(qrHistoryProvider.notifier).loadItems();

      final state = container.read(qrHistoryProvider);
      expect(state.items.length, 1);
      expect(state.items.first.title, 'Test QR');
    });

    test('Saves, toggles favorite, and deletes items', () async {
      final item = QrItem(
        id: 'fav-1',
        title: 'Favorite QR',
        type: QrType.wifi,
        rawData: 'WIFI:S:MyNet;;',
        formattedPayload: 'WIFI:S:MyNet;;',
        styleConfig: const QrStyleConfig(),
        createdAt: DateTime.now(),
      );

      final notifier = container.read(qrHistoryProvider.notifier);
      await notifier.saveItem(item);

      var state = container.read(qrHistoryProvider);
      expect(state.totalCount, 1);
      expect(state.items.first.isFavorite, false);

      await notifier.toggleFavorite('fav-1');
      state = container.read(qrHistoryProvider);
      expect(state.items.first.isFavorite, true);
      expect(state.favoritesCount, 1);

      await notifier.deleteItem('fav-1');
      state = container.read(qrHistoryProvider);
      expect(state.totalCount, 0);
    });

    test('Filters items by created, scanned, and favorites', () async {
      final createdItem = QrItem(
        id: 'c1',
        title: 'Created Item',
        type: QrType.text,
        rawData: 'Hello',
        formattedPayload: 'Hello',
        styleConfig: const QrStyleConfig(),
        createdAt: DateTime.now(),
        isScanned: false,
      );

      final scannedItem = QrItem(
        id: 's1',
        title: 'Scanned Item',
        type: QrType.url,
        rawData: 'https://example.com',
        formattedPayload: 'https://example.com',
        styleConfig: const QrStyleConfig(),
        createdAt: DateTime.now(),
        isScanned: true,
      );

      final notifier = container.read(qrHistoryProvider.notifier);
      await notifier.saveItem(createdItem);
      await notifier.saveItem(scannedItem);

      var state = container.read(qrHistoryProvider);
      expect(state.createdCount, 1);
      expect(state.scannedCount, 1);

      notifier.setFilter(HistoryFilter.created);
      state = container.read(qrHistoryProvider);
      expect(state.filteredItems.length, 1);
      expect(state.filteredItems.first.id, 'c1');

      notifier.setFilter(HistoryFilter.scanned);
      state = container.read(qrHistoryProvider);
      expect(state.filteredItems.length, 1);
      expect(state.filteredItems.first.id, 's1');
    });

    test('Searches items by title and payload', () async {
      final item1 = QrItem(
        id: '1',
        title: 'Portfolio Website',
        type: QrType.url,
        rawData: 'https://portfolio.me',
        formattedPayload: 'https://portfolio.me',
        styleConfig: const QrStyleConfig(),
        createdAt: DateTime.now(),
      );

      final item2 = QrItem(
        id: '2',
        title: 'Office WiFi',
        type: QrType.wifi,
        rawData: 'WIFI:S:OfficeNet;;',
        formattedPayload: 'WIFI:S:OfficeNet;;',
        styleConfig: const QrStyleConfig(),
        createdAt: DateTime.now(),
      );

      final notifier = container.read(qrHistoryProvider.notifier);
      await notifier.saveItem(item1);
      await notifier.saveItem(item2);

      notifier.setSearchQuery('office');
      var state = container.read(qrHistoryProvider);
      expect(state.filteredItems.length, 1);
      expect(state.filteredItems.first.id, '2');

      notifier.setSearchQuery('portfolio');
      state = container.read(qrHistoryProvider);
      expect(state.filteredItems.length, 1);
      expect(state.filteredItems.first.id, '1');
    });
  });

  group('qrCreatorProvider Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Selects type and updates payload dynamically', () {
      final notifier = container.read(qrCreatorProvider.notifier);
      notifier.selectType(QrType.phone);
      expect(container.read(qrCreatorProvider).selectedType, QrType.phone);

      notifier.updateField('phone', '+1234567890');
      expect(
        container.read(qrCreatorProvider).formattedPayload,
        'tel:+1234567890',
      );

      final item = notifier.buildItem();
      expect(item.type, QrType.phone);
      expect(item.formattedPayload, 'tel:+1234567890');
    });

    test('Updates style configuration', () {
      final notifier = container.read(qrCreatorProvider.notifier);
      notifier.updateStyleConfig(
        (c) =>
            c.copyWith(bodyPattern: QrBodyPattern.dots, frameText: 'SCAN HERE'),
      );

      final state = container.read(qrCreatorProvider);
      expect(state.styleConfig.bodyPattern, QrBodyPattern.dots);
      expect(state.styleConfig.frameText, 'SCAN HERE');
    });
  });

  group('scannerProvider Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Normalizes and processes raw scan data for URL', () {
      final notifier = container.read(scannerProvider.notifier);
      final item = notifier.processRawData('www.google.com');

      expect(item.type, QrType.url);
      expect(item.formattedPayload, 'https://www.google.com');
      expect(item.isScanned, true);
      expect(container.read(scannerProvider).lastScannedItem?.id, item.id);
    });

    test('Detects Wi-Fi network payloads', () {
      final notifier = container.read(scannerProvider.notifier);
      final item = notifier.processRawData(
        'WIFI:S:HomeNet;T:WPA;P:secret123;;',
      );

      expect(item.type, QrType.wifi);
      expect(item.formattedPayload, 'WIFI:S:HomeNet;T:WPA;P:secret123;;');
      expect(item.isScanned, true);
    });

    test('Detects vCard contact payloads', () {
      final notifier = container.read(scannerProvider.notifier);
      final item = notifier.processRawData(
        'BEGIN:VCARD\nFN:John Doe\nTEL:5551234\nEND:VCARD',
      );

      expect(item.type, QrType.vCard);
      expect(item.isScanned, true);
    });
  });
}
