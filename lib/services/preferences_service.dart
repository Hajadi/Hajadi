import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small key/value store for everything that must survive a cold start:
/// the chosen language, theme, onboarding progress and the offline cache.
class PreferencesService {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static Future<PreferencesService> create() async =>
      PreferencesService(await SharedPreferences.getInstance());

  static const String _kLocale = 'locale';
  static const String _kTheme = 'themeMode';
  static const String _kOnboarded = 'onboardingDone';
  static const String _kDemoUid = 'demoUid';
  static const String _kCachePrefix = 'cache.';

  String? get languageCode => _prefs.getString(_kLocale);

  Future<void> setLanguageCode(String code) => _prefs.setString(_kLocale, code);

  ThemeMode get themeMode => switch (_prefs.getString(_kTheme)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  Future<void> setThemeMode(ThemeMode mode) =>
      _prefs.setString(_kTheme, mode.name);

  bool get onboardingDone => _prefs.getBool(_kOnboarded) ?? false;

  Future<void> setOnboardingDone({bool value = true}) =>
      _prefs.setBool(_kOnboarded, value);

  String? get demoUid => _prefs.getString(_kDemoUid);

  Future<void> setDemoUid(String? uid) async {
    if (uid == null) {
      await _prefs.remove(_kDemoUid);
    } else {
      await _prefs.setString(_kDemoUid, uid);
    }
  }

  /// Offline cache for list payloads (search results, favourites…). Firestore
  /// keeps its own cache for live documents; this covers the derived lists the
  /// home screen shows before any stream has produced a first frame.
  Future<void> writeCache(String key, Object value) =>
      _prefs.setString('$_kCachePrefix$key', json.encode(value));

  List<Map<String, dynamic>> readCachedList(String key) {
    final String? raw = _prefs.getString('$_kCachePrefix$key');
    if (raw == null) {
      return const <Map<String, dynamic>>[];
    }
    try {
      final dynamic decoded = json.decode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
      }
    } catch (_) {
      // Corrupt cache entry — behave as a cache miss.
    }
    return const <Map<String, dynamic>>[];
  }

  Future<void> clearCache() async {
    for (final String key in _prefs.getKeys().toList()) {
      if (key.startsWith(_kCachePrefix)) {
        await _prefs.remove(key);
      }
    }
  }
}
