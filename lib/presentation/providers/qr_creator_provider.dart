import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/payload_serializer.dart';
import '../../data/models/qr_item.dart';
import '../../data/models/qr_style_config.dart';
import '../../data/models/qr_type.dart';

class QrCreatorState {
  final QrType selectedType;
  final String title;
  final Map<String, String> fields;
  final String formattedPayload;
  final QrStyleConfig styleConfig;
  final String? editingItemId;
  final DateTime? createdAt;
  final bool isScanned;

  const QrCreatorState({
    this.selectedType = QrType.url,
    this.title = '',
    this.fields = const {},
    this.formattedPayload = 'https://example.com',
    this.styleConfig = const QrStyleConfig(),
    this.editingItemId,
    this.createdAt,
    this.isScanned = false,
  });

  bool get isEditing => editingItemId != null;

  QrCreatorState copyWith({
    QrType? selectedType,
    String? title,
    Map<String, String>? fields,
    String? formattedPayload,
    QrStyleConfig? styleConfig,
    String? editingItemId,
    DateTime? createdAt,
    bool? isScanned,
  }) {
    return QrCreatorState(
      selectedType: selectedType ?? this.selectedType,
      title: title ?? this.title,
      fields: fields ?? this.fields,
      formattedPayload: formattedPayload ?? this.formattedPayload,
      styleConfig: styleConfig ?? this.styleConfig,
      editingItemId: editingItemId ?? this.editingItemId,
      createdAt: createdAt ?? this.createdAt,
      isScanned: isScanned ?? this.isScanned,
    );
  }
}

class QrCreatorNotifier extends StateNotifier<QrCreatorState> {
  QrCreatorNotifier() : super(const QrCreatorState());

  void selectType(QrType type) {
    final payload = PayloadSerializer.serialize(type, const {});
    state = QrCreatorState(
      selectedType: type,
      title: type.title,
      fields: const {},
      formattedPayload: payload,
      styleConfig: const QrStyleConfig(),
    );
  }

  void initFromItem(QrItem item) {
    state = QrCreatorState(
      selectedType: item.type,
      title: item.title,
      fields: const {},
      formattedPayload: item.formattedPayload,
      styleConfig: item.styleConfig,
      editingItemId: item.id,
      createdAt: item.createdAt,
      isScanned: item.isScanned,
    );
  }

  void updateTitle(String newTitle) {
    state = state.copyWith(title: newTitle);
  }

  void updateField(String key, String value) {
    final newFields = Map<String, String>.from(state.fields);
    newFields[key] = value;
    final newPayload = PayloadSerializer.serialize(state.selectedType, newFields);
    state = state.copyWith(
      fields: newFields,
      formattedPayload: newPayload,
    );
  }

  void setFields(Map<String, String> newFields) {
    final newPayload = PayloadSerializer.serialize(state.selectedType, newFields);
    state = state.copyWith(
      fields: Map.from(newFields),
      formattedPayload: newPayload,
    );
  }

  void updateStyleConfig(QrStyleConfig Function(QrStyleConfig) update) {
    state = state.copyWith(styleConfig: update(state.styleConfig));
  }

  void setStyleConfig(QrStyleConfig newConfig) {
    state = state.copyWith(styleConfig: newConfig);
  }

  QrItem buildItem() {
    return QrItem(
      id: state.editingItemId ?? const Uuid().v4(),
      title: state.title.trim().isNotEmpty ? state.title.trim() : state.selectedType.title,
      type: state.selectedType,
      rawData: state.fields.values.join(' | '),
      formattedPayload: state.formattedPayload,
      styleConfig: state.styleConfig,
      createdAt: state.createdAt ?? DateTime.now(),
      isScanned: state.isScanned,
    );
  }

  void reset() {
    state = const QrCreatorState();
  }
}

/// Riverpod provider exposing QrCreatorNotifier and its reactive state
final qrCreatorProvider = StateNotifierProvider<QrCreatorNotifier, QrCreatorState>((ref) {
  return QrCreatorNotifier();
});
