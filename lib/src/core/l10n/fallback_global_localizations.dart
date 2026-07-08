import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Flutter ships Material/Cupertino/Widgets localizations for many locales,
/// but not Tigrinya (`ti`) or Oromo (`om`). App copy still uses those locales;
/// fall back to English so Drawer, date pickers, etc. do not crash.
class FallbackMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationsDelegate();

  static const Locale _fallback = Locale('en');

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    final target = GlobalMaterialLocalizations.delegate.isSupported(locale)
        ? locale
        : _fallback;
    return GlobalMaterialLocalizations.delegate.load(target);
  }

  @override
  bool shouldReload(FallbackMaterialLocalizationsDelegate old) => false;
}

class FallbackWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const FallbackWidgetsLocalizationsDelegate();

  static const Locale _fallback = Locale('en');

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<WidgetsLocalizations> load(Locale locale) {
    final target = GlobalWidgetsLocalizations.delegate.isSupported(locale)
        ? locale
        : _fallback;
    return GlobalWidgetsLocalizations.delegate.load(target);
  }

  @override
  bool shouldReload(FallbackWidgetsLocalizationsDelegate old) => false;
}

class FallbackCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationsDelegate();

  static const Locale _fallback = Locale('en');

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    final target = GlobalCupertinoLocalizations.delegate.isSupported(locale)
        ? locale
        : _fallback;
    return GlobalCupertinoLocalizations.delegate.load(target);
  }

  @override
  bool shouldReload(FallbackCupertinoLocalizationsDelegate old) => false;
}

const List<LocalizationsDelegate<dynamic>> fallbackGlobalLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
  FallbackMaterialLocalizationsDelegate(),
  FallbackWidgetsLocalizationsDelegate(),
  FallbackCupertinoLocalizationsDelegate(),
];
