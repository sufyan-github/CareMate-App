import 'package:caremate/app/caremate_app.dart';
import 'package:caremate/app/preferences/caremate_preferences.dart';
import 'package:caremate/features/medications/domain/patient_medication_models.dart';
import 'package:caremate/features/more/domain/account_settings_gateway.dart';
import 'package:caremate/features/simple_mode/domain/dose_announcement_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/auth_test_support.dart';

void main() {
  test('builds a deterministic Bangla dose announcement without logging', () {
    const announcement = DoseAnnouncement(
      mealRelation: 'AFTER',
      medicationName: 'Napa',
      plannedLocalDateTime: '2026-08-18T08:00',
      quantityLabel: '1 tablet',
    );

    expect(
      announcement.banglaText,
      'সকাল ৮টা — Napa, ১ ট্যাবলেট, খাবারের পরে।',
    );
  });

  testWidgets('Simple Mode presents one accessible pictogram dose at 200%', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final patientGateway = _dueDoseGateway();
    final accountGateway = accountSettingsGateway();
    accountGateway.preferences = const AccountPreferences(
      allowAnalytics: false,
      locale: 'bn-BD',
      showMedicineOnLockScreen: false,
      simpleMode: true,
      voicePromptsEnabled: true,
    );
    final preferenceController = CareMatePreferencesController(
      store: _MemoryPreferenceStore(),
    );
    await preferenceController.setLocale('bn-BD');
    await preferenceController.setSimpleMode(true);
    final announcements = _RecordingAnnouncementService();

    await tester.pumpWidget(
      CareMateApp(
        accountSettingsGateway: accountGateway,
        authCoordinator: authenticatedCoordinator(),
        doseAnnouncementService: announcements,
        patientMedicationGateway: patientGateway,
        preferencesController: preferenceController,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('simple-mode-page')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byKey(const Key('medication-pictogram-Napa')), findsOneWidget);

    final confirm = find.byKey(const Key('simple-confirm-dose-occurrence-1'));
    final scroll = find.byKey(const Key('simple-dose-scroll-occurrence-1'));
    await tester.dragUntilVisible(
      find.text('খাবারের পরে'),
      scroll,
      const Offset(0, -240),
    );
    expect(find.text('খাবারের পরে'), findsOneWidget);
    await tester.dragUntilVisible(confirm, scroll, const Offset(0, -300));
    final later = find.byKey(const Key('simple-snooze-dose-occurrence-1'));
    expect(find.text('খেয়েছি'), findsOneWidget);
    expect(find.text('পরে'), findsOneWidget);
    final confirmSize = tester.getSize(confirm);
    final laterSize = tester.getSize(later);
    expect(confirmSize.height, greaterThanOrEqualTo(76));
    expect(laterSize.height, greaterThanOrEqualTo(76));
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(
      find.byKey(const Key('speak-dose-occurrence-1')),
    );
    await tester.tap(find.byKey(const Key('speak-dose-occurrence-1')));
    await tester.pump();
    expect(announcements.spoken.single.banglaText, contains('খাবারের পরে'));

    await tester.tap(find.byKey(const Key('exit-simple-mode-button')));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(accountGateway.preferences.simpleMode, isFalse);
  });

  testWidgets('Simple Mode records confirm and protects skip behind hold', (
    tester,
  ) async {
    final patientGateway = _dueDoseGateway();
    final accountGateway = accountSettingsGateway();
    accountGateway.preferences = const AccountPreferences(
      allowAnalytics: false,
      locale: 'en-BD',
      showMedicineOnLockScreen: false,
      simpleMode: true,
      voicePromptsEnabled: false,
    );
    final preferenceController = CareMatePreferencesController(
      store: _MemoryPreferenceStore(),
    );
    await preferenceController.setSimpleMode(true);

    await tester.pumpWidget(
      CareMateApp(
        accountSettingsGateway: accountGateway,
        authCoordinator: authenticatedCoordinator(),
        doseAnnouncementService: _RecordingAnnouncementService(),
        patientMedicationGateway: patientGateway,
        preferencesController: preferenceController,
      ),
    );
    await tester.pumpAndSettle();

    final later = find.byKey(const Key('simple-snooze-dose-occurrence-1'));
    await tester.dragUntilVisible(
      later,
      find.byKey(const Key('simple-dose-scroll-occurrence-1')),
      const Offset(0, -300),
    );
    await tester.longPress(later);
    await tester.pumpAndSettle();
    expect(find.text('এই ডোজটি বাদ দেবেন?'), findsOneWidget);
    await tester.tap(find.text('ফিরে যান'));
    await tester.pumpAndSettle();
    expect(patientGateway.doseOutcomes, isEmpty);

    final confirm = find.byKey(const Key('simple-confirm-dose-occurrence-1'));
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(find.text('Waiting to sync'), findsOneWidget);
  });
}

InMemoryPatientMedicationGateway _dueDoseGateway() {
  final gateway = existingPatientGateway();
  gateway.medications.add(
    const MedicationSummary(
      displayName: 'Napa',
      form: 'TABLET',
      id: 'medicine-1',
      mealRelation: 'AFTER',
      quantityLabel: '1 tablet',
      status: 'ACTIVE',
      strengthLabel: '500 mg',
    ),
  );
  final due = DateTime.now().subtract(const Duration(minutes: 2));
  gateway.activeSchedule = MedicationSchedulePlan(
    occurrences: [
      ScheduleOccurrencePreview(
        plannedAt: due,
        plannedLocalDateTime:
            '${due.year.toString().padLeft(4, '0')}-'
            '${due.month.toString().padLeft(2, '0')}-'
            '${due.day.toString().padLeft(2, '0')}T08:00',
      ),
    ],
    quantityRequired: 1,
    quantityUnit: 'TABLET',
  );
  return gateway;
}

class _RecordingAnnouncementService implements DoseAnnouncementService {
  final List<DoseAnnouncement> spoken = [];

  @override
  Future<void> speak(DoseAnnouncement announcement) async {
    spoken.add(announcement);
  }
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
