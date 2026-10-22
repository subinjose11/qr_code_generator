import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qr/qr.dart';
import '../../data/models/qr_style_config.dart';

class QrCanvasWidget extends StatefulWidget {
  final String data;
  final QrStyleConfig config;
  final double size;

  const QrCanvasWidget({
    super.key,
    required this.data,
    required this.config,
    this.size = 260.0,
  });

  @override
  State<QrCanvasWidget> createState() => _QrCanvasWidgetState();
}

class _QrCanvasWidgetState extends State<QrCanvasWidget> {
  ui.Image? _customLogoImage;
  String? _loadedLogoPath;

  @override
  void initState() {
    super.initState();
    _checkAndLoadLogo();
  }

  @override
  void didUpdateWidget(covariant QrCanvasWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.customLogoPath != widget.config.customLogoPath ||
        oldWidget.config.logoType != widget.config.logoType) {
      _checkAndLoadLogo();
    }
  }

  Future<void> _checkAndLoadLogo() async {
    if (widget.config.logoType == QrLogoType.customFile &&
        widget.config.customLogoPath != null &&
        widget.config.customLogoPath!.isNotEmpty) {
      if (_loadedLogoPath == widget.config.customLogoPath && _customLogoImage != null) {
        return;
      }
      try {
        final file = File(widget.config.customLogoPath!);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          if (mounted) {
            setState(() {
              _customLogoImage = frame.image;
              _loadedLogoPath = widget.config.customLogoPath;
            });
          }
        }
      } catch (e) {
        debugPrint('Error loading logo: $e');
      }
    } else {
      if (_customLogoImage != null) {
        setState(() {
          _customLogoImage = null;
          _loadedLogoPath = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final validData = widget.data.isEmpty ? 'https://example.com' : widget.data;

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.config.background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: QrCustomPainter(
          data: validData,
          config: widget.config,
          customLogoImage: _customLogoImage,
        ),
      ),
    );
  }
}

class QrCustomPainter extends CustomPainter {
  final String data;
  final QrStyleConfig config;
  final ui.Image? customLogoImage;

  QrCustomPainter({
    required this.data,
    required this.config,
    this.customLogoImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    QrCode qrCode;
    try {
      qrCode = QrCode.fromData(
        data: data,
        errorCorrectLevel: QrErrorCorrectLevel.H,
      );
    } catch (_) {
      try {
        qrCode = QrCode.fromData(
          data: data,
          errorCorrectLevel: QrErrorCorrectLevel.M,
        );
      } catch (_) {
        return;
      }
    }

    final qrImage = QrImage(qrCode);
    final moduleCount = qrImage.moduleCount;

    // ISO/IEC 18004 specifies a standard Quiet Zone of at least 4 modules
    const quietZoneModules = 4;
    final totalModules = moduleCount + (quietZoneModules * 2);
    final cellSize = size.width / totalModules;
    final padding = cellSize * quietZoneModules;

    // 1. Draw Background (full canvas with high contrast)
    final bgPaint = Paint()
      ..color = config.isTransparentBackground ? Colors.transparent : config.background
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 2. Setup Foreground Shader / Paint
    final fgPaint = Paint()..isAntiAlias = true;
    if (config.useGradient) {
      if (config.isRadialGradient) {
        fgPaint.shader = ui.Gradient.radial(
          Offset(size.width / 2, size.height / 2),
          size.width * 0.65,
          [config.foreground, config.gradient2],
        );
      } else {
        final rad = config.gradientAngle * pi / 180.0;
        final dx = cos(rad) * size.width;
        final dy = sin(rad) * size.height;
        fgPaint.shader = ui.Gradient.linear(
          Offset(padding, padding),
          Offset(padding + dx, padding + dy),
          [config.foreground, config.gradient2],
        );
      }
    } else {
      fgPaint.color = config.foreground;
    }

    // 3. Logo Exclusion Zone
    final hasLogo = (config.logoType == QrLogoType.customFile && customLogoImage != null) ||
        (config.logoType == QrLogoType.preset && config.logoPreset != null);

    final centerModule = moduleCount / 2;
    // Cap logo size to 20% to preserve Reed-Solomon correction
    final safeLogoRatio = config.logoSizeRatio.clamp(0.15, 0.22);
    final logoRadiusModules = hasLogo ? (moduleCount * safeLogoRatio / 2) + 0.5 : 0.0;

    // Helper: is in finder eye (7x7 corners)
    bool isTopLeftFinder(int r, int c) => r < 7 && c < 7;
    bool isTopRightFinder(int r, int c) => r < 7 && c >= moduleCount - 7;
    bool isBottomLeftFinder(int r, int c) => r >= moduleCount - 7 && c < 7;
    bool isFinderPattern(int r, int c) =>
        isTopLeftFinder(r, c) || isTopRightFinder(r, c) || isBottomLeftFinder(r, c);

    // Helper: is timing track (Row 6 or Col 6 between finder patterns)
    bool isTimingTrack(int r, int c) =>
        (r == 6 && c >= 7 && c < moduleCount - 7) ||
        (c == 6 && r >= 7 && r < moduleCount - 7);

    bool isInLogoZone(int r, int c) {
      if (!hasLogo) return false;
      return (r - centerModule).abs() <= logoRadiusModules &&
          (c - centerModule).abs() <= logoRadiusModules;
    }

    // 4. Paint Body Modules
    for (int r = 0; r < moduleCount; r++) {
      for (int c = 0; c < moduleCount; c++) {
        if (isFinderPattern(r, c)) continue;
        if (isInLogoZone(r, c)) continue;

        if (qrImage.isDark(r, c)) {
          final x = padding + (c * cellSize);
          final y = padding + (r * cellSize);
          // Always keep timing tracks solid so scanners never lose coordinate tracking
          final isTiming = isTimingTrack(r, c);
          _drawBodyModule(canvas, fgPaint, x, y, cellSize, isTimingTrack: isTiming);
        }
      }
    }

    // 5. Paint Custom Finder Corner Eyes
    _drawFinderEye(canvas, padding, padding, cellSize, config.eyeShape, config.eyeballShape);
    _drawFinderEye(canvas, padding + (moduleCount - 7) * cellSize, padding, cellSize,
        config.eyeShape, config.eyeballShape);
    _drawFinderEye(canvas, padding, padding + (moduleCount - 7) * cellSize, cellSize,
        config.eyeShape, config.eyeballShape);

    // 6. Paint Logo Center
    if (hasLogo) {
      final logoPxSize = (moduleCount * cellSize) * safeLogoRatio;
      final logoRect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: logoPxSize,
        height: logoPxSize,
      );

      // Safe background pill/circle for logo with clean border
      final logoBgPaint = Paint()
        ..color = config.isTransparentBackground ? Colors.white : config.background
        ..style = PaintingStyle.fill;
      final badgeRect = logoRect.inflate(cellSize * 0.7);
      canvas.drawRRect(
        RRect.fromRectAndRadius(badgeRect, Radius.circular(cellSize * 1.0)),
        logoBgPaint,
      );

      final borderPaint = Paint()
        ..color = config.foreground.withValues(alpha: 0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(badgeRect, Radius.circular(cellSize * 1.0)),
        borderPaint,
      );

      if (config.logoType == QrLogoType.customFile && customLogoImage != null) {
        canvas.save();
        canvas.clipRRect(
          RRect.fromRectAndRadius(logoRect, Radius.circular(cellSize * 0.6)),
        );
        paintImage(
          canvas: canvas,
          rect: logoRect,
          image: customLogoImage!,
          fit: BoxFit.contain,
        );
        canvas.restore();
      } else if (config.logoType == QrLogoType.preset && config.logoPreset != null) {
        _drawPresetLogo(canvas, logoRect, config.logoPreset!, config.foreground);
      }
    }
  }

  void _drawBodyModule(
    Canvas canvas,
    Paint paint,
    double x,
    double y,
    double size, {
    bool isTimingTrack = false,
  }) {
    // If it's a timing track module, draw it as a crisp square for guaranteed camera lock
    if (isTimingTrack || config.bodyPattern == QrBodyPattern.square) {
      canvas.drawRect(Rect.fromLTWH(x, y, size + 0.35, size + 0.35), paint);
      return;
    }

    switch (config.bodyPattern) {
      case QrBodyPattern.square:
        canvas.drawRect(Rect.fromLTWH(x, y, size + 0.35, size + 0.35), paint);
        break;
      case QrBodyPattern.rounded:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + size * 0.04, y + size * 0.04, size * 0.92, size * 0.92),
            Radius.circular(size * 0.25),
          ),
          paint,
        );
        break;
      case QrBodyPattern.dots:
        canvas.drawCircle(
          Offset(x + size / 2, y + size / 2),
          size * 0.46,
          paint,
        );
        break;
      case QrBodyPattern.diamond:
        final path = Path()
          ..moveTo(x + size / 2, y + size * 0.05)
          ..lineTo(x + size * 0.95, y + size / 2)
          ..lineTo(x + size / 2, y + size * 0.95)
          ..lineTo(x + size * 0.05, y + size / 2)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case QrBodyPattern.bars:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + size * 0.08, y + size * 0.02, size * 0.84, size * 0.96),
            Radius.circular(size * 0.30),
          ),
          paint,
        );
        break;
    }
  }

  void _drawFinderEye(
    Canvas canvas,
    double x,
    double y,
    double cellSize,
    QrEyeShape eyeShape,
    QrEyeballShape eyeballShape,
  ) {
    final framePaint = Paint()
      ..color = config.eyeFrame
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final eyeballPaint = Paint()
      ..color = config.eyeball
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final eyeOuterRect = Rect.fromLTWH(x, y, cellSize * 7, cellSize * 7);
    final eyeInnerHoleRect =
        Rect.fromLTWH(x + cellSize, y + cellSize, cellSize * 5, cellSize * 5);
    final eyeballRect =
        Rect.fromLTWH(x + cellSize * 2, y + cellSize * 2, cellSize * 3, cellSize * 3);

    // 1. Draw Outer Frame Shape
    Path outerPath;
    switch (eyeShape) {
      case QrEyeShape.square:
        outerPath = Path()..addRect(eyeOuterRect);
        break;
      case QrEyeShape.rounded:
        outerPath = Path()
          ..addRRect(RRect.fromRectAndRadius(eyeOuterRect, Radius.circular(cellSize * 1.8)));
        break;
      case QrEyeShape.circle:
        outerPath = Path()..addOval(eyeOuterRect);
        break;
      case QrEyeShape.leaf:
        outerPath = Path()
          ..addRRect(RRect.fromRectAndCorners(
            eyeOuterRect,
            topLeft: Radius.circular(cellSize * 3.5),
            bottomRight: Radius.circular(cellSize * 3.5),
            topRight: Radius.circular(cellSize * 0.5),
            bottomLeft: Radius.circular(cellSize * 0.5),
          ));
        break;
    }

    // Hollow cutout
    Path innerHolePath;
    switch (eyeShape) {
      case QrEyeShape.square:
        innerHolePath = Path()..addRect(eyeInnerHoleRect);
        break;
      case QrEyeShape.rounded:
        innerHolePath = Path()
          ..addRRect(RRect.fromRectAndRadius(eyeInnerHoleRect, Radius.circular(cellSize * 1.0)));
        break;
      case QrEyeShape.circle:
        innerHolePath = Path()..addOval(eyeInnerHoleRect);
        break;
      case QrEyeShape.leaf:
        innerHolePath = Path()
          ..addRRect(RRect.fromRectAndCorners(
            eyeInnerHoleRect,
            topLeft: Radius.circular(cellSize * 2.5),
            bottomRight: Radius.circular(cellSize * 2.5),
            topRight: Radius.circular(cellSize * 0.3),
            bottomLeft: Radius.circular(cellSize * 0.3),
          ));
        break;
    }

    // Ensure the 1-module gap between frame and eyeball is crisp background
    final bgHolePaint = Paint()
      ..color = config.isTransparentBackground ? Colors.white : config.background
      ..style = PaintingStyle.fill;
    canvas.drawPath(innerHolePath, bgHolePaint);

    final combinedFrame = Path.combine(PathOperation.difference, outerPath, innerHolePath);
    canvas.drawPath(combinedFrame, framePaint);

    // 2. Draw Inner Eyeball
    switch (eyeballShape) {
      case QrEyeballShape.square:
        canvas.drawRect(eyeballRect, eyeballPaint);
        break;
      case QrEyeballShape.circle:
      case QrEyeballShape.dot:
        canvas.drawOval(eyeballRect, eyeballPaint);
        break;
      case QrEyeballShape.diamond:
        final path = Path()
          ..moveTo(eyeballRect.center.dx, eyeballRect.top)
          ..lineTo(eyeballRect.right, eyeballRect.center.dy)
          ..lineTo(eyeballRect.center.dx, eyeballRect.bottom)
          ..lineTo(eyeballRect.left, eyeballRect.center.dy)
          ..close();
        canvas.drawPath(path, eyeballPaint);
        break;
    }
  }

  void _drawPresetLogo(Canvas canvas, Rect rect, String preset, Color color) {
    IconData icon;
    switch (preset.toLowerCase()) {
      case 'whatsapp':
        icon = Icons.chat;
        break;
      case 'instagram':
        icon = Icons.camera_alt;
        break;
      case 'wifi':
        icon = Icons.wifi;
        break;
      case 'phone':
        icon = Icons.phone;
        break;
      case 'mail':
        icon = Icons.email;
        break;
      case 'link':
        icon = Icons.link;
        break;
      case 'star':
        icon = Icons.star;
        break;
      case 'location':
        icon = Icons.location_on;
        break;
      case 'cart':
        icon = Icons.shopping_bag;
        break;
      default:
        icon = Icons.qr_code_2;
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: rect.width * 0.65,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        rect.center.dx - (textPainter.width / 2),
        rect.center.dy - (textPainter.height / 2),
      ),
    );
  }

  @override
  bool shouldRepaint(covariant QrCustomPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.config != config ||
        oldDelegate.customLogoImage != customLogoImage;
  }
}
