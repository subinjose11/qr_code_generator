import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/qr_item.dart';
import '../../domain/repositories/i_qr_repository.dart';

class SyncResult {
  final int uploadedCount;
  final int downloadedCount;
  final DateTime timestamp;

  const SyncResult({
    required this.uploadedCount,
    required this.downloadedCount,
    required this.timestamp,
  });
}

class SyncService {
  final IQrRepository _repository;
  final FirebaseFirestore _firestore;

  SyncService({
    required IQrRepository repository,
    FirebaseFirestore? firestore,
  })  : _repository = repository,
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userQrCol(String userId) {
    return _firestore.collection('users').doc(userId).collection('qr_codes');
  }

  /// Full two-way synchronization between local Hive and Cloud Firestore
  Future<SyncResult> syncAll(String userId) async {
    try {
      final col = _userQrCol(userId);
      final localItems = _repository.getAllItems();
      final localMap = {for (var item in localItems) item.id: item};

      // 1. Fetch remote items from Firestore
      final remoteSnapshot = await col.get();
      final remoteMap = <String, QrItem>{};

      for (var doc in remoteSnapshot.docs) {
        try {
          final data = doc.data();
          final item = QrItem.fromMap(data);
          remoteMap[item.id] = item;
        } catch (e) {
          debugPrint('Error parsing remote QR item ${doc.id}: $e');
        }
      }

      int uploaded = 0;
      int downloaded = 0;

      // 2. Upload any local items that are missing or newer in remote
      final batch = _firestore.batch();
      bool hasUploadBatch = false;

      for (var local in localItems) {
        final remote = remoteMap[local.id];
        if (remote == null || local.createdAt.isAfter(remote.createdAt)) {
          batch.set(col.doc(local.id), local.toMap(), SetOptions(merge: true));
          hasUploadBatch = true;
          uploaded++;
        }
      }

      if (hasUploadBatch) {
        await batch.commit();
      }

      // 3. Download remote items that are missing from local
      for (var entry in remoteMap.entries) {
        if (!localMap.containsKey(entry.key)) {
          await _repository.saveItem(entry.value);
          downloaded++;
        }
      }

      debugPrint('Sync finished: $uploaded uploaded, $downloaded downloaded');
      return SyncResult(
        uploadedCount: uploaded,
        downloadedCount: downloaded,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Sync error: $e');
      rethrow;
    }
  }

  /// Push a single item to cloud
  Future<void> syncSingleItem(String userId, QrItem item) async {
    try {
      await _userQrCol(userId).doc(item.id).set(item.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Sync single item error: $e');
    }
  }

  /// Delete an item from cloud
  Future<void> deleteFromCloud(String userId, String itemId) async {
    try {
      await _userQrCol(userId).doc(itemId).delete();
    } catch (e) {
      debugPrint('Delete from cloud error: $e');
    }
  }
}
