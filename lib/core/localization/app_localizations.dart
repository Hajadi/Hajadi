import 'dart:convert';

import 'package:flutter/cupertino.dart' show CupertinoLocalizations;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_localizations/flutter_localizations.dart';

import 'strings.dart';

export 'strings.dart';

/// Loads translations from `assets/i18n/<languageCode>.json`.
///
/// English is always loaded as a fallback so a missing key in `fr`/`ht`
/// degrades to English instead of showing a raw key to the user.
class AppLocalizations {
  AppLocalizations(this.locale, this._values, this._fallback);

  final Locale locale;
  final Map<String, String> _values;
  final Map<String, String> _fallback;

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('ht'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// Delegates required by [MaterialApp]. Material/Cupertino/Widgets
  /// localizations have no Haitian Creole bundle upstream, so `ht` borrows the
  /// French bundle for built-in widget strings (date pickers, tooltips…).
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    _CreoleMaterialLocalizationsDelegate(),
    _CreoleWidgetsLocalizationsDelegate(),
    _CreoleCupertinoLocalizationsDelegate(),
  ];

  static AppLocalizations of(BuildContext context) {
    final AppLocalizations? result =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(result != null, 'No AppLocalizations found in context');
    return result!;
  }

  static Future<Map<String, String>> _loadBundle(String languageCode) async {
    final String raw = await rootBundle
        .loadString('assets/i18n/$languageCode.json');
    final Map<String, dynamic> decoded =
        json.decode(raw) as Map<String, dynamic>;
    return decoded.map((String k, dynamic v) => MapEntry<String, String>(k, '$v'));
  }

  static Future<AppLocalizations> load(Locale locale) async {
    final Map<String, String> fallback = await _loadBundle('en');
    if (locale.languageCode == 'en') {
      return AppLocalizations(locale, fallback, fallback);
    }
    Map<String, String> values;
    try {
      values = await _loadBundle(locale.languageCode);
    } catch (_) {
      values = fallback;
    }
    return AppLocalizations(locale, values, fallback);
  }

  /// Raw lookup. Falls back to English, then to the key itself.
  String raw(String key) => _values[key] ?? _fallback[key] ?? key;

  /// Lookup with `{placeholder}` substitution.
  String sub(String key, Map<String, Object?> args) {
    String value = raw(key);
    args.forEach((String name, Object? arg) {
      value = value.replaceAll('{$name}', '$arg');
    });
    return value;
  }

  /// Typed accessors for every key in the catalog.
  late final Strings s = Strings(this);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => <String>['en', 'fr', 'ht']
      .contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) => AppLocalizations.load(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

const Locale _kCreoleFallback = Locale('fr');

class _CreoleMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _CreoleMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ht';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(_kCreoleFallback);

  @override
  bool shouldReload(_CreoleMaterialLocalizationsDelegate old) => false;
}

class _CreoleWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _CreoleWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ht';

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      GlobalWidgetsLocalizations.delegate.load(_kCreoleFallback);

  @override
  bool shouldReload(_CreoleWidgetsLocalizationsDelegate old) => false;
}

class _CreoleCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _CreoleCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ht';

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(_kCreoleFallback);

  @override
  bool shouldReload(_CreoleCupertinoLocalizationsDelegate old) => false;
}

/// `context.l10n.login` reads better than digging the delegate out by hand.
extension AppLocalizationsX on BuildContext {
  Strings get l10n => AppLocalizations.of(this).s;
  AppLocalizations get l10nRaw => AppLocalizations.of(this);
}
