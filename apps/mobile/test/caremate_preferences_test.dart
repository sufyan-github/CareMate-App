import 'package:caremate/app/preferences/caremate_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restores the saved language and larger-text preference', () async {
    final store = _MemoryPreferenceStore();
    final first = CareMatePreferencesController(store: store);

    await first.setLocale('bn-BD');
    await first.setLargeText(true);
    first.dispose();

    final restored = CareMatePreferencesController(store: store);
    await restored.initialize();

    expect(restored.locale, 'bn-BD');
    expect(restored.largeText, isTrue);
    restored.dispose();
  });

  test(
    'an explicit saved English preference overrides the device default',
    () async {
      final store = _MemoryPreferenceStore()
        ..values['caremate.preference.locale'] = 'en-BD';
      final controller = CareMatePreferencesController(store: store);

      await controller.initialize();

      expect(controller.locale, 'en-BD');
      controller.dispose();
    },
  );
}

class _MemoryPreferenceStore implements CareMatePreferenceStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
