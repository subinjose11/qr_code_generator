import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/repositories/i_qr_repository.dart';
import '../models/qr_item.dart';

class QrRepository implements IQrRepository {
  static const String _boxName = 'qr_items_box';
  late Box _box;
  bool _isInitialized = false;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> init() async {
    if (_isInitialized) return;
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
    _isInitialized = true;
  }

  @override
  List<QrItem> getAllItems() {
    if (!_isInitialized) return [];
    final items = <QrItem>[];
    for (var key in _box.keys) {
      final data = _box.get(key);
      if (data is Map) {
        try {
          items.add(QrItem.fromMap(Map<String, dynamic>.from(data)));
        } catch (e) {
          debugPrint('Error parsing QR item: $e');
        }
      }
    }
    // Sort reverse chronological
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  @override
  List<QrItem> getCreatedItems() {
    return getAllItems().where((item) => !item.isScanned).toList();
  }

  @override
  List<QrItem> getScannedItems() {
    return getAllItems().where((item) => item.isScanned).toList();
  }

  @override
  List<QrItem> getFavorites() {
    return getAllItems().where((item) => item.isFavorite).toList();
  }

  @override
  Future<void> saveItem(QrItem item) async {
    await _box.put(item.id, item.toMap());
  }

  @override
  Future<void> deleteItem(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> toggleFavorite(String id) async {
    final data = _box.get(id);
    if (data is Map) {
      final item = QrItem.fromMap(Map<String, dynamic>.from(data));
      final updated = item.copyWith(isFavorite: !item.isFavorite);
      await _box.put(id, updated.toMap());
    }
  }

  @override
  Future<void> clearAll() async {
    await _box.clear();
  }
}
