import '../../data/models/qr_item.dart';

abstract class IQrRepository {
  bool get isInitialized;
  Future<void> init();
  List<QrItem> getAllItems();
  List<QrItem> getCreatedItems();
  List<QrItem> getScannedItems();
  List<QrItem> getFavorites();
  Future<void> saveItem(QrItem item);
  Future<void> deleteItem(String id);
  Future<void> toggleFavorite(String id);
  Future<void> clearAll();
}
