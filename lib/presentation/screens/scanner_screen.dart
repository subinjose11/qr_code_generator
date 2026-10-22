import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../data/models/qr_item.dart';
import '../../data/models/qr_type.dart';
import '../providers/qr_history_provider.dart';
import '../providers/scanner_provider.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );
  bool _isProcessingScan = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessingScan) return;
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue;
      if (code != null && code.isNotEmpty) {
        _handleScannedData(code);
      }
    }
  }

  Future<void> _scanFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final barcodes = await _controller.analyzeImage(image.path);
      if (barcodes != null && barcodes.barcodes.isNotEmpty) {
        final code = barcodes.barcodes.first.rawValue;
        if (code != null) {
          _handleScannedData(code);
          return;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No QR code detected in the selected image.'),
          ),
        );
      }
    }
  }

  Future<void> _launchExternal(String raw) async {
    final success = await ref
        .read(scannerProvider.notifier)
        .launchExternal(raw);
    if (!success && mounted) {
      final isUpi = raw.startsWith('upi://');
      Clipboard.setData(ClipboardData(text: raw));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUpi
                ? 'No UPI payment app (Google Pay, PhonePe, Paytm, BHIM) found on this device. Payment link copied to clipboard!'
                : 'Could not open link in external application. Copied to clipboard!',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleScannedData(String rawData) {
    setState(() => _isProcessingScan = true);

    final item = ref.read(scannerProvider.notifier).processRawData(rawData);

    // Auto-save to repository via qrHistoryProvider
    ref.read(qrHistoryProvider.notifier).saveItem(item);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildResultSheet(ctx, item),
    ).whenComplete(() {
      if (mounted) {
        setState(() => _isProcessingScan = false);
      }
    });
  }

  Widget _buildResultSheet(BuildContext context, QrItem item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isUrl =
        item.formattedPayload.startsWith('http://') ||
        item.formattedPayload.startsWith('https://');
    final isPhone = item.formattedPayload.startsWith('tel:');
    final isEmail = item.formattedPayload.startsWith('mailto:');
    final isSms = item.formattedPayload.startsWith('sms:');
    final isUpi = item.formattedPayload.startsWith('upi://') || item.type == QrType.upi;

    String actionLabel = 'Open Link';
    IconData actionIcon = Icons.open_in_browser;
    if (isUpi) {
      actionLabel = 'Pay via UPI App';
      actionIcon = Icons.payment;
    } else if (isPhone) {
      actionLabel = 'Call Number';
      actionIcon = Icons.call;
    } else if (isEmail) {
      actionLabel = 'Send Email';
      actionIcon = Icons.mail;
    } else if (isSms) {
      actionLabel = 'Send SMS';
      actionIcon = Icons.sms;
    } else if (isUrl) {
      actionLabel = 'Open Website';
      actionIcon = Icons.public;
    }

    final hasAction = isUrl || isPhone || isEmail || isSms || isUpi;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: item.type.brandColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.type.icon,
                  color: item.type.brandColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.type.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Successfully scanned and saved to history',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
            ),
            child: SelectableText(
              item.formattedPayload,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (hasAction) ...[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _launchExternal(item.formattedPayload),
                    icon: Icon(actionIcon),
                    label: Text(actionLabel),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: item.formattedPayload),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard!')),
                    );
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Text'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // Viewfinder overlay
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF60A5FA), width: 3),
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),

          // Controls Bar (Torch, Flip, Gallery)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.filledTonal(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Row(
                  children: [
                    IconButton.filledTonal(
                      icon: const Icon(Icons.photo_library_outlined),
                      onPressed: _scanFromGallery,
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.flash_on),
                      onPressed: () => _controller.toggleTorch(),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.flip_camera_ios),
                      onPressed: () => _controller.switchCamera(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom prompt
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xB31E293B),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Point camera at QR code or choose an image',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
