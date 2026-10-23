import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kThemePreferenceKey = 'app_theme_mode';

/// Optional SharedPreferences instance provider (injected in main)
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  SharedPreferences? _prefs;

  ThemeModeNotifier([this._prefs]) : super(_loadInitialMode(_prefs)) {
    if (_prefs == null) {
      _initFallback();
    }
  }

  static ThemeMode _loadInitialMode(SharedPreferences? prefs) {
    if (prefs == null) return ThemeMode.light;
    final saved = prefs.getString(_kThemePreferenceKey);
    if (saved != null) {
      for (final mode in ThemeMode.values) {
        if (mode.name == saved) return mode;
      }
    }
    return ThemeMode.light;
  }

  Future<void> _initFallback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _prefs = prefs;
      final saved = prefs.getString(_kThemePreferenceKey);
      if (saved != null) {
        for (final mode in ThemeMode.values) {
          if (mode.name == saved) {
            state = mode;
            break;
          }
        }
      }
    } catch (_) {
      // Graceful fallback for headless/test environments
    }
  }

  void toggle() {
    if (state == ThemeMode.light) {
      setMode(ThemeMode.dark);
    } else if (state == ThemeMode.dark) {
      setMode(ThemeMode.system);
    } else {
      setMode(ThemeMode.light);
    }
  }

  void setMode(ThemeMode mode) {
    state = mode;
    _savePreference(mode);
  }

  Future<void> _savePreference(ThemeMode mode) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.setString(_kThemePreferenceKey, mode.name);
    } catch (_) {
      // Graceful fallback
    }
  }
}
