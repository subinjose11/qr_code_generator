import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/qr_item.dart';
import 'qr_frame_wrapper.dart';

class ExportDialog extends StatefulWidget {
  final QrItem item;

  const ExportDialog({super.key, required this.item});

  static Future<void> show(BuildContext context, QrItem item) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExportDialog(item: item),
    );
  }

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isProcessing = false;
  double _exportPixelRatio = 3.0; // 1.0 (Standard), 2.0 (High), 4.0 (4K Print Ready)

  Future<Uint8List?> _captureImage(double pixelRatio) async {
    return await _screenshotController.captureFromWidget(
      Container(
        color: widget.item.styleConfig.isTransparentBackground
            ? Colors.transparent
            : widget.item.styleConfig.background,
        padding: const EdgeInsets.all(24),
        child: QrFrameWrapper(
          data: widget.item.formattedPayload,
          config: widget.item.styleConfig,
          qrSize: 320,
        ),
      ),
      pixelRatio: pixelRatio,
      delay: const Duration(milliseconds: 100),
    );
  }

  // Save image to Gallery
  Future<void> _saveToGallery() async {
    setState(() => _isProcessing = true);
    try {
      final imageBytes = await _captureImage(_exportPixelRatio);
      if (imageBytes != null) {
        final hasAccess = await Gal.hasAccess();
        if (!hasAccess) {
          await Gal.requestAccess();
        }
        await Gal.putImageBytes(
          imageBytes,
          name: 'QR_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Saved to photo gallery!'),
                ],
              ),
              backgroundColor: Color(0xFF059669),
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // Native Share Sheet
  Future<void> _shareImage() async {
    setState(() => _isProcessing = true);
    try {
      final imageBytes = await _captureImage(3.0);
      if (imageBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/qr_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = await File(path).writeAsBytes(imageBytes);

        final payload = widget.item.formattedPayload.trim();
        final shareText = payload.isNotEmpty
            ? 'Scan the attached QR code or tap the link:\n👉 $payload'
            : 'Scan the attached QR code for: ${widget.item.title}';

        await Share.shareXFiles(
          [XFile(file.path)],
          text: shareText,
          subject: widget.item.title,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // Generate and Print PDF
  Future<void> _printOrExportPdf() async {
    setState(() => _isProcessing = true);
    try {
      final imageBytes = await _captureImage(3.0);
      if (imageBytes == null) return;

      final pdfDoc = pw.Document();
      final pdfImage = pw.MemoryImage(imageBytes);

      pdfDoc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    widget.item.title,
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Container(
                    width: 320,
                    height: 320,
                    child: pw.Image(pdfImage),
                  ),
                  pw.SizedBox(height: 14),
                  pw.Text(
                    widget.item.formattedPayload,
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfDoc.save(),
        name: '${widget.item.title}_QR.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Export & Download QR',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'High-resolution format ready for digital & print',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Quality selector via Material 3 SegmentedButton
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<double>(
              segments: const [
                ButtonSegment<double>(
                  value: 1.5,
                  label: Text('HD (1.5x)'),
                  icon: Icon(Icons.hd_outlined, size: 16),
                ),
                ButtonSegment<double>(
                  value: 3.0,
                  label: Text('2K High (3x)'),
                  icon: Icon(Icons.high_quality_outlined, size: 16),
                ),
                ButtonSegment<double>(
                  value: 5.0,
                  label: Text('4K Print (5x)'),
                  icon: Icon(Icons.four_k_outlined, size: 16),
                ),
              ],
              selected: {_exportPixelRatio},
              onSelectionChanged: (newSelection) {
                setState(() => _exportPixelRatio = newSelection.first);
              },
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isProcessing ? null : _saveToGallery,
                  icon: const Icon(Icons.download, size: 20),
                  label: const Text('Save PNG'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _isProcessing ? null : _shareImage,
                  icon: const Icon(Icons.share_outlined, size: 20),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isProcessing ? null : _printOrExportPdf,
              icon: const Icon(Icons.print_outlined, size: 20),
              label: const Text('Print / Save PDF Label'),
            ),
          ),

          if (_isProcessing) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }
}
