import 'package:flutter/material.dart';

enum QrBodyPattern {
  square,
  rounded,
  dots,
  diamond,
  bars,
}

enum QrEyeShape {
  square,
  rounded,
  circle,
  leaf,
}

enum QrEyeballShape {
  square,
  circle,
  diamond,
  dot,
}

enum QrFrameType {
  none,
  bottomBanner,
  topBanner,
  speechBubble,
  ticketHeader,
  polaroid,
  badge,
  stamp,
}

enum QrLogoType {
  none,
  preset,
  customFile,
}

class QrStyleConfig {
  final QrBodyPattern bodyPattern;
  final QrEyeShape eyeShape;
  final QrEyeballShape eyeballShape;

  final int foregroundColor;
  final int backgroundColor;
  final bool isTransparentBackground;

  final bool useGradient;
  final bool isRadialGradient;
  final int gradientColor2;
  final double gradientAngle; // in degrees, e.g. 45.0

  final bool customEyeColor;
  final int eyeFrameColor;
  final int eyeballColor;

  final QrLogoType logoType;
  final String? logoPreset;
  final String? customLogoPath;
  final double logoSizeRatio; // 0.18 - 0.26

  final QrFrameType frameType;
  final String frameText;
  final int frameColor;
  final int frameTextColor;

  const QrStyleConfig({
    this.bodyPattern = QrBodyPattern.square,
    this.eyeShape = QrEyeShape.square,
    this.eyeballShape = QrEyeballShape.square,
    this.foregroundColor = 0xFF000000,
    this.backgroundColor = 0xFFFFFFFF,
    this.isTransparentBackground = false,
    this.useGradient = false,
    this.isRadialGradient = false,
    this.gradientColor2 = 0xFF2563EB,
    this.gradientAngle = 45.0,
    this.customEyeColor = false,
    this.eyeFrameColor = 0xFF000000,
    this.eyeballColor = 0xFF000000,
    this.logoType = QrLogoType.none,
    this.logoPreset,
    this.customLogoPath,
    this.logoSizeRatio = 0.22,
    this.frameType = QrFrameType.none,
    this.frameText = 'SCAN ME',
    this.frameColor = 0xFF000000,
    this.frameTextColor = 0xFFFFFFFF,
  });

  Color get foreground => Color(foregroundColor);
  Color get background => isTransparentBackground ? Colors.transparent : Color(backgroundColor);
  Color get gradient2 => Color(gradientColor2);
  Color get eyeFrame => customEyeColor ? Color(eyeFrameColor) : foreground;
  Color get eyeball => customEyeColor ? Color(eyeballColor) : foreground;
  Color get frameBg => Color(frameColor);
  Color get frameTextCol => Color(frameTextColor);

  QrStyleConfig copyWith({
    QrBodyPattern? bodyPattern,
    QrEyeShape? eyeShape,
    QrEyeballShape? eyeballShape,
    int? foregroundColor,
    int? backgroundColor,
    bool? isTransparentBackground,
    bool? useGradient,
    bool? isRadialGradient,
    int? gradientColor2,
    double? gradientAngle,
    bool? customEyeColor,
    int? eyeFrameColor,
    int? eyeballColor,
    QrLogoType? logoType,
    String? logoPreset,
    String? customLogoPath,
    double? logoSizeRatio,
    QrFrameType? frameType,
    String? frameText,
    int? frameColor,
    int? frameTextColor,
  }) {
    return QrStyleConfig(
      bodyPattern: bodyPattern ?? this.bodyPattern,
      eyeShape: eyeShape ?? this.eyeShape,
      eyeballShape: eyeballShape ?? this.eyeballShape,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      isTransparentBackground: isTransparentBackground ?? this.isTransparentBackground,
      useGradient: useGradient ?? this.useGradient,
      isRadialGradient: isRadialGradient ?? this.isRadialGradient,
      gradientColor2: gradientColor2 ?? this.gradientColor2,
      gradientAngle: gradientAngle ?? this.gradientAngle,
      customEyeColor: customEyeColor ?? this.customEyeColor,
      eyeFrameColor: eyeFrameColor ?? this.eyeFrameColor,
      eyeballColor: eyeballColor ?? this.eyeballColor,
      logoType: logoType ?? this.logoType,
      logoPreset: logoPreset ?? this.logoPreset,
      customLogoPath: customLogoPath ?? this.customLogoPath,
      logoSizeRatio: logoSizeRatio ?? this.logoSizeRatio,
      frameType: frameType ?? this.frameType,
      frameText: frameText ?? this.frameText,
      frameColor: frameColor ?? this.frameColor,
      frameTextColor: frameTextColor ?? this.frameTextColor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bodyPattern': bodyPattern.index,
      'eyeShape': eyeShape.index,
      'eyeballShape': eyeballShape.index,
      'foregroundColor': foregroundColor,
      'backgroundColor': backgroundColor,
      'isTransparentBackground': isTransparentBackground,
      'useGradient': useGradient,
      'isRadialGradient': isRadialGradient,
      'gradientColor2': gradientColor2,
      'gradientAngle': gradientAngle,
      'customEyeColor': customEyeColor,
      'eyeFrameColor': eyeFrameColor,
      'eyeballColor': eyeballColor,
      'logoType': logoType.index,
      'logoPreset': logoPreset,
      'customLogoPath': customLogoPath,
      'logoSizeRatio': logoSizeRatio,
      'frameType': frameType.index,
      'frameText': frameText,
      'frameColor': frameColor,
      'frameTextColor': frameTextColor,
    };
  }

  factory QrStyleConfig.fromMap(Map<String, dynamic> map) {
    return QrStyleConfig(
      bodyPattern: QrBodyPattern.values[map['bodyPattern'] as int? ?? 0],
      eyeShape: QrEyeShape.values[map['eyeShape'] as int? ?? 0],
      eyeballShape: QrEyeballShape.values[map['eyeballShape'] as int? ?? 0],
      foregroundColor: map['foregroundColor'] as int? ?? 0xFF000000,
      backgroundColor: map['backgroundColor'] as int? ?? 0xFFFFFFFF,
      isTransparentBackground: map['isTransparentBackground'] as bool? ?? false,
      useGradient: map['useGradient'] as bool? ?? false,
      isRadialGradient: map['isRadialGradient'] as bool? ?? false,
      gradientColor2: map['gradientColor2'] as int? ?? 0xFF2563EB,
      gradientAngle: (map['gradientAngle'] as num?)?.toDouble() ?? 45.0,
      customEyeColor: map['customEyeColor'] as bool? ?? false,
      eyeFrameColor: map['eyeFrameColor'] as int? ?? 0xFF000000,
      eyeballColor: map['eyeballColor'] as int? ?? 0xFF000000,
      logoType: QrLogoType.values[map['logoType'] as int? ?? 0],
      logoPreset: map['logoPreset'] as String?,
      customLogoPath: map['customLogoPath'] as String?,
      logoSizeRatio: (map['logoSizeRatio'] as num?)?.toDouble() ?? 0.22,
      frameType: QrFrameType.values[map['frameType'] as int? ?? 0],
      frameText: map['frameText'] as String? ?? 'SCAN ME',
      frameColor: map['frameColor'] as int? ?? 0xFF000000,
      frameTextColor: map['frameTextColor'] as int? ?? 0xFFFFFFFF,
    );
  }
}
