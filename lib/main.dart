import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/router/app_router.dart';
import 'data/repositories/qr_repository.dart';
import 'domain/repositories/i_qr_repository.dart';
import 'firebase_options.dart';
import 'presentation/providers/repository_provider.dart';
import 'presentation/providers/theme_provider.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize Firebase & Crashlytics
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (!kIsWeb) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  final repository = QrRepository();
  await repository.init();

  FlutterNativeSplash.remove();

  runApp(QrStudioApp(repository: repository));
}

ThemeData _buildM3Theme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  const primaryColor = Color(0xFF00008B); // Dark Blue (#00008B)

  final colorScheme = ColorScheme.fromSeed(
    seedColor: primaryColor,
    primary: primaryColor,
    onPrimary: Colors.white,
    brightness: brightness,
  );

  final baseTextTheme = isDark
      ? ThemeData.dark().textTheme
      : ThemeData.light().textTheme;
  final appTextTheme = GoogleFonts.plusJakartaSansTextTheme(baseTextTheme);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    primaryColor: primaryColor,
    brightness: brightness,
    scaffoldBackgroundColor: colorScheme.surface,
    textTheme: appTextTheme,
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1.5,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      centerTitle: false,
      surfaceTintColor: colorScheme.surfaceTint,
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 1,
      height: 72,
      backgroundColor: colorScheme.surfaceContainer,
      indicatorColor: isDark
          ? const Color(0xFF16255E)
          : const Color(0xFF00008B).withValues(alpha: 0.15),
      indicatorShape: const StadiumBorder(),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFF93C5FD) : primaryColor,
          );
        }
        return TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(
            color: isDark ? const Color(0xFF93C5FD) : primaryColor,
          );
        }
        return IconThemeData(color: colorScheme.onSurfaceVariant);
      }),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: isDark ? Colors.white : primaryColor,
      unselectedLabelColor: isDark
          ? const Color(0xFF94A3B8)
          : colorScheme.onSurfaceVariant,
      indicatorColor: isDark ? Colors.white : primaryColor,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 13,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(
        color: isDark
            ? const Color(0xFF334155)
            : colorScheme.outlineVariant.withValues(alpha: 0.5),
      ),
      backgroundColor: isDark
          ? const Color(0xFF1E2333)
          : colorScheme.surfaceContainerHigh,
      selectedColor: isDark
          ? const Color(0xFF162A4A)
          : colorScheme.primaryContainer,
      checkmarkColor: isDark ? const Color(0xFF60A5FA) : colorScheme.primary,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? const Color(0xFFE2E8F0) : colorScheme.onSurface,
      ),
      secondaryLabelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : colorScheme.onPrimaryContainer,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 2,
      highlightElevation: 4,
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      showDragHandle: true,
      dragHandleColor: colorScheme.outlineVariant,
      backgroundColor: colorScheme.surfaceContainer,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      elevation: 3,
      backgroundColor: colorScheme.surfaceContainerHigh,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        side: WidgetStatePropertyAll(
          BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      hintStyle: TextStyle(
        color: isDark
            ? Colors.white70
            : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      ),
      labelStyle: TextStyle(
        color: isDark ? Colors.white70 : colorScheme.onSurfaceVariant,
      ),
      floatingLabelStyle: TextStyle(
        color: isDark ? Colors.white : colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
      prefixIconColor: isDark ? Colors.white70 : colorScheme.onSurfaceVariant,
      suffixIconColor: isDark ? Colors.white70 : colorScheme.onSurfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.6)
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.6)
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? Colors.white : colorScheme.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        side: isDark
            ? BorderSide(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                width: 1,
              )
            : null,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        side: BorderSide(
          color: isDark ? const Color(0xFF3B82F6) : primaryColor,
          width: 1.5,
        ),
        foregroundColor: isDark ? const Color(0xFF93C5FD) : primaryColor,
      ),
    ),
  );
}

class QrStudioApp extends StatelessWidget {
  final IQrRepository? repository;
  final bool showSplash;

  const QrStudioApp({super.key, this.repository, this.showSplash = true});

  @override
  Widget build(BuildContext context) {
    final app = _QrStudioAppView(showSplash: showSplash);

    if (repository != null) {
      return ProviderScope(
        overrides: [qrRepositoryProvider.overrideWithValue(repository!)],
        child: app,
      );
    }

    return app;
  }
}

class _QrStudioAppView extends ConsumerStatefulWidget {
  final bool showSplash;
  const _QrStudioAppView({this.showSplash = true});

  @override
  ConsumerState<_QrStudioAppView> createState() => _QrStudioAppViewState();
}

class _QrStudioAppViewState extends ConsumerState<_QrStudioAppView> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.createRouter(showSplash: widget.showSplash);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'QRLink',
      debugShowCheckedModeBanner: false,
      theme: _buildM3Theme(Brightness.light),
      darkTheme: _buildM3Theme(Brightness.dark),
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}
