import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class CareMatePreferenceStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}

class SecureCareMatePreferenceStore implements CareMatePreferenceStore {
  SecureCareMatePreferenceStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

class CareMatePreferencesController extends ChangeNotifier {
  CareMatePreferencesController({CareMatePreferenceStore? store})
    : _store = store ?? SecureCareMatePreferenceStore(),
      _locale = PlatformDispatcher.instance.locale.languageCode == 'bn'
          ? 'bn-BD'
          : 'en-BD';

  static const _largeTextKey = 'caremate.preference.large-text';
  static const _localeKey = 'caremate.preference.locale';

  final CareMatePreferenceStore _store;
  bool _largeText = false;
  String _locale;

  bool get isBangla => _locale == 'bn-BD';
  bool get largeText => _largeText;
  String get locale => _locale;

  Future<void> initialize() async {
    try {
      final savedLocale = await _store.read(_localeKey);
      final savedLargeText = await _store.read(_largeTextKey);
      if (savedLocale == 'bn-BD' || savedLocale == 'en-BD') {
        _locale = savedLocale!;
      }
      _largeText = savedLargeText == 'true';
      notifyListeners();
    } on Object {
      // Device preferences are optional; safe defaults remain available.
    }
  }

  Future<void> setLargeText(bool enabled) async {
    if (_largeText == enabled) return;
    _largeText = enabled;
    notifyListeners();
    try {
      await _store.write(_largeTextKey, enabled.toString());
    } on Object {
      // The active session keeps the preference if secure storage is unavailable.
    }
  }

  Future<void> setLocale(String locale, {bool persist = true}) async {
    final normalized = locale == 'bn-BD' ? 'bn-BD' : 'en-BD';
    if (_locale != normalized) {
      _locale = normalized;
      notifyListeners();
    }
    if (!persist) return;
    try {
      await _store.write(_localeKey, normalized);
    } on Object {
      // The account preference remains authoritative if local storage fails.
    }
  }
}

class CareMatePreferencesScope
    extends InheritedNotifier<CareMatePreferencesController> {
  const CareMatePreferencesScope({
    required CareMatePreferencesController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static CareMatePreferencesController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<CareMatePreferencesScope>();
    assert(scope != null, 'CareMatePreferencesScope is missing.');
    return scope!.notifier!;
  }

  static CareMatePreferencesController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<CareMatePreferencesScope>()
      ?.notifier;
}

class CareMateStrings {
  const CareMateStrings._(this.isBangla);

  final bool isBangla;

  static CareMateStrings of(BuildContext context) => CareMateStrings._(
    CareMatePreferencesScope.maybeOf(context)?.isBangla ?? false,
  );

  String pick(String english, String bangla) => isBangla ? bangla : english;
}
