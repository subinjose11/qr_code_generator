import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/qr_repository.dart';
import '../../domain/repositories/i_qr_repository.dart';

/// Riverpod Provider for Dependency Injection of the QR Repository contract.
final qrRepositoryProvider = Provider<IQrRepository>((ref) {
  return QrRepository();
});
