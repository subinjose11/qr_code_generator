import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/qr_item.dart';
import '../../data/models/qr_style_config.dart';
import '../../data/models/qr_type.dart';
import '../../presentation/screens/customizer_screen.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/input_form_screen.dart';
import '../../presentation/screens/profile_screen.dart';
import '../../presentation/screens/scanner_screen.dart';
import '../../presentation/screens/splash_screen.dart';

/// Centralized GoRouter routing configuration for Web & Mobile.
class AppRouter {
  static const String splash = '/splash';
  static const String home = '/';
  static const String scan = '/scan';
  static const String customize = '/customize';
  static const String profile = '/profile';

  static String createPath(QrType type) => '/create/${type.name}';

  static GoRouter createRouter({
    bool showSplash = true,
    String? initialLocation,
  }) {
    return GoRouter(
      initialLocation: initialLocation ?? (showSplash ? splash : home),
      debugLogDiagnostics: false,
      routes: [
        GoRoute(
          path: splash,
          name: 'splash',
          builder: (context, state) => const QrLinkSplashScreen(),
        ),
        GoRoute(
          path: profile,
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: home,
          name: 'home',
          builder: (context, state) {
            final tab = state.uri.queryParameters['tab'];
            final initialIndex = tab == 'mycodes' ? 1 : 0;
            return HomeScreen(initialIndex: initialIndex);
          },
          routes: [
            GoRoute(
              path: 'scan',
              name: 'scan',
              builder: (context, state) => const ScannerScreen(),
            ),
            GoRoute(
              path: 'create/:type',
              name: 'create',
              builder: (context, state) {
                final typeParam = state.pathParameters['type'] ?? 'url';
                final type = QrType.values.firstWhere(
                  (t) => t.name.toLowerCase() == typeParam.toLowerCase(),
                  orElse: () => QrType.url,
                );
                return InputFormScreen(type: type);
              },
            ),
            GoRoute(
              path: 'customize',
              name: 'customize',
              builder: (context, state) {
                final item = state.extra as QrItem?;
                if (item != null) {
                  return CustomizerScreen(initialItem: item);
                }
                // Fallback for direct browser URL visits or reloads
                final fallback = QrItem(
                  id: const Uuid().v4(),
                  title: 'Website / URL',
                  type: QrType.url,
                  rawData: 'https://',
                  formattedPayload: 'https://',
                  styleConfig: const QrStyleConfig(),
                  createdAt: DateTime.now(),
                );
                return CustomizerScreen(initialItem: fallback);
              },
            ),
          ],
        ),
      ],
    );
  }
}
