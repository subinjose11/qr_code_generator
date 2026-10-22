import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/qr_item.dart';
import '../../data/models/qr_style_config.dart';
import '../../data/models/qr_type.dart';

class ScannerState {
  final bool isProcessing;
  final QrItem? lastScannedItem;

  const ScannerState({this.isProcessing = false, this.lastScannedItem});

  ScannerState copyWith({bool? isProcessing, QrItem? lastScannedItem}) {
    return ScannerState(
      isProcessing: isProcessing ?? this.isProcessing,
      lastScannedItem: lastScannedItem ?? this.lastScannedItem,
    );
  }
}

class ScannerNotifier extends StateNotifier<ScannerState> {
  ScannerNotifier() : super(const ScannerState());

  void setProcessing(bool value) {
    state = state.copyWith(isProcessing: value);
  }

  QrItem processRawData(String rawData) {
    final trimmed = rawData.trim();
    String normalized = trimmed;
    QrType detectedType = QrType.text;

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      detectedType = QrType.url;
    } else if (trimmed.startsWith('www.') ||
        RegExp(r'^[a-zA-Z0-9-]+\.[a-zA-Z]{2,}(/.*)?$').hasMatch(trimmed)) {
      detectedType = QrType.url;
      normalized = 'https://$trimmed';
    } else if (trimmed.startsWith('WIFI:')) {
      detectedType = QrType.wifi;
    } else if (trimmed.startsWith('BEGIN:VCARD')) {
      detectedType = QrType.vCard;
    } else if (trimmed.startsWith('mailto:')) {
      detectedType = QrType.email;
    } else if (trimmed.startsWith('tel:')) {
      detectedType = QrType.phone;
    } else if (trimmed.startsWith('sms:')) {
      detectedType = QrType.sms;
    }

    final item = QrItem(
      id: const Uuid().v4(),
      title: 'Scanned ${detectedType.title}',
      type: detectedType,
      rawData: rawData,
      formattedPayload: normalized,
      styleConfig: const QrStyleConfig(),
      createdAt: DateTime.now(),
      isScanned: true,
    );

    state = state.copyWith(lastScannedItem: item);
    return item;
  }

  Future<bool> launchExternal(String raw) async {
    try {
      String toLaunch = raw.trim();
      if (!toLaunch.contains('://') &&
          (toLaunch.startsWith('www.') ||
              RegExp(
                r'^[a-zA-Z0-9-]+\.[a-zA-Z]{2,}(/.*)?$',
              ).hasMatch(toLaunch))) {
        toLaunch = 'https://$toLaunch';
      }
      final uri = Uri.parse(toLaunch);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      return true;
    } catch (_) {
      try {
        final uri = Uri.parse(raw);
        return await launchUrl(uri);
      } catch (e) {
        debugPrint('Could not launch: $e');
        return false;
      }
    }
  }

  void reset() {
    state = const ScannerState();
  }
}

/// Riverpod provider exposing ScannerNotifier and its reactive state
final scannerProvider = StateNotifierProvider<ScannerNotifier, ScannerState>((
  ref,
) {
  return ScannerNotifier();
});
