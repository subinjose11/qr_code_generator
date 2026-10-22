import 'package:flutter/material.dart';
import '../../data/models/qr_style_config.dart';
import 'qr_canvas_widget.dart';

class QrFrameWrapper extends StatelessWidget {
  final String data;
  final QrStyleConfig config;
  final double qrSize;

  const QrFrameWrapper({
    super.key,
    required this.data,
    required this.config,
    this.qrSize = 240.0,
  });

  @override
  Widget build(BuildContext context) {
    Widget qrCore = QrCanvasWidget(
      data: data,
      config: config,
      size: qrSize,
    );

    Widget framedWidget;
    switch (config.frameType) {
      case QrFrameType.none:
        framedWidget = qrCore;
        break;

      case QrFrameType.bottomBanner:
        framedWidget = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              )
            ],
            border: Border.all(color: config.frameBg, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              qrCore,
              const SizedBox(height: 14),
              Container(
                width: qrSize,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: config.frameBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  config.frameText.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: config.frameTextCol,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        );
        break;

      case QrFrameType.topBanner:
        framedWidget = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              )
            ],
            border: Border.all(color: config.frameBg, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: qrSize,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: config.frameBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  config.frameText.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: config.frameTextCol,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              qrCore,
            ],
          ),
        );
        break;

      case QrFrameType.speechBubble:
        framedWidget = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
                decoration: BoxDecoration(
                  color: config.frameBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_rounded, size: 16, color: config.frameTextCol),
                    const SizedBox(width: 8),
                    Text(
                      config.frameText,
                      style: TextStyle(
                        color: config.frameTextCol,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              qrCore,
            ],
          ),
        );
        break;

      case QrFrameType.ticketHeader:
        framedWidget = Container(
          width: qrSize + 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: config.frameBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Text(
                  config.frameText.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: config.frameTextCol,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    fontSize: 13,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: qrCore,
              ),
            ],
          ),
        );
        break;

      case QrFrameType.polaroid:
        framedWidget = Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              qrCore,
              const SizedBox(height: 16),
              Text(
                config.frameText,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
        break;

      case QrFrameType.badge:
        framedWidget = Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: config.frameBg, width: 3),
            boxShadow: [
              BoxShadow(
                color: config.frameBg.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              qrCore,
              const SizedBox(height: 10),
              Text(
                config.frameText,
                style: TextStyle(
                  color: config.frameBg,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
        break;

      case QrFrameType.stamp:
        framedWidget = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: config.frameBg,
              width: 2.5,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              qrCore,
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: config.frameBg, width: 1.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  config.frameText.toUpperCase(),
                  style: TextStyle(
                    color: config.frameBg,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
        break;
    }

    return framedWidget;
  }
}

