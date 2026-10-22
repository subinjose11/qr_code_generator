import 'qr_style_config.dart';
import 'qr_type.dart';

class QrItem {
  final String id;
  final String title;
  final QrType type;
  final String rawData;
  final String formattedPayload;
  final QrStyleConfig styleConfig;
  final DateTime createdAt;
  final bool isFavorite;
  final bool isScanned; // true if saved from scanner, false if created

  const QrItem({
    required this.id,
    required this.title,
    required this.type,
    required this.rawData,
    required this.formattedPayload,
    required this.styleConfig,
    required this.createdAt,
    this.isFavorite = false,
    this.isScanned = false,
  });

  QrItem copyWith({
    String? id,
    String? title,
    QrType? type,
    String? rawData,
    String? formattedPayload,
    QrStyleConfig? styleConfig,
    DateTime? createdAt,
    bool? isFavorite,
    bool? isScanned,
  }) {
    return QrItem(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      rawData: rawData ?? this.rawData,
      formattedPayload: formattedPayload ?? this.formattedPayload,
      styleConfig: styleConfig ?? this.styleConfig,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      isScanned: isScanned ?? this.isScanned,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type.index,
      'rawData': rawData,
      'formattedPayload': formattedPayload,
      'styleConfig': styleConfig.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': isFavorite,
      'isScanned': isScanned,
    };
  }

  factory QrItem.fromMap(Map<String, dynamic> map) {
    return QrItem(
      id: map['id'] as String,
      title: map['title'] as String,
      type: QrType.values[map['type'] as int? ?? 0],
      rawData: map['rawData'] as String? ?? '',
      formattedPayload: map['formattedPayload'] as String? ?? '',
      styleConfig: map['styleConfig'] != null
          ? QrStyleConfig.fromMap(Map<String, dynamic>.from(map['styleConfig'] as Map))
          : const QrStyleConfig(),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      isFavorite: map['isFavorite'] as bool? ?? false,
      isScanned: map['isScanned'] as bool? ?? false,
    );
  }
}
