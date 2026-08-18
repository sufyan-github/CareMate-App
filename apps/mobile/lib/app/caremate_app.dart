import 'dart:async';

import 'package:caremate/app/preferences/caremate_preferences.dart';
import 'package:caremate/app/theme/caremate_theme.dart';
import 'package:caremate/features/auth/application/auth_coordinator.dart';
import 'package:caremate/features/auth/data/http_auth_gateway.dart';
import 'package:caremate/features/auth/data/file_refresh_session_lock.dart';
import 'package:caremate/features/auth/data/secure_session_store.dart';
import 'package:caremate/features/auth/presentation/auth_flow_page.dart';
import 'package:caremate/features/care/data/http_care_access_gateway.dart';
import 'package:caremate/features/care/data/flutter_caregiver_alert_notifier.dart';
import 'package:caremate/features/care/domain/care_access_gateway.dart';
import 'package:caremate/features/care/domain/caregiver_alert_notifier.dart';
import 'package:caremate/features/insights/data/http_insights_gateway.dart';
import 'package:caremate/features/insights/domain/insights_gateway.dart';
import 'package:caremate/features/medications/data/http_patient_medication_gateway.dart';
import 'package:caremate/features/medications/domain/patient_medication_gateway.dart';
import 'package:caremate/features/medications/presentation/authenticated_experience.dart';
import 'package:caremate/features/more/data/http_account_settings_gateway.dart';
import 'package:caremate/features/more/domain/account_settings_gateway.dart';
import 'package:caremate/features/prescription/data/mlkit_prescription_text_recognizer.dart';
import 'package:caremate/features/prescription/data/http_prescription_extraction_gateway.dart';
import 'package:caremate/features/prescription/domain/prescription_extraction_gateway.dart';
import 'package:caremate/features/prescription/domain/prescription_text_recognizer.dart';
import 'package:caremate/features/reminders/domain/reminder_scheduler.dart';
import 'package:caremate/features/reminders/data/flutter_reminder_scheduler.dart';
import 'package:caremate/features/sync/data/caremate_local_database.dart';
import 'package:caremate/features/sync/data/drift_dose_mutation_store.dart';
import 'package:caremate/features/sync/data/encrypted_local_database_factory.dart';
import 'package:caremate/features/sync/data/http_dose_sync_gateway.dart';
import 'package:caremate/features/sync/data/workmanager_sync_scheduler.dart';
import 'package:caremate/features/sync/domain/background_sync_scheduler.dart';
import 'package:caremate/features/sync/domain/dose_sync_gateway.dart';
import 'package:caremate/features/sync/domain/dose_sync_models.dart';
import 'package:caremate/features/simple_mode/data/flutter_tts_dose_announcement_service.dart';
import 'package:caremate/features/simple_mode/domain/dose_announcement_service.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';

class CareMateApp extends StatefulWidget {
  const CareMateApp({
    this.accountSettingsGateway,
    this.authCoordinator,
    this.backgroundSyncScheduler,
    this.careAccessGateway,
    this.caregiverAlertNotifier,
    this.patientMedicationGateway,
    this.insightsGateway,
    this.doseMutationStore,
    this.doseSyncGateway,
    this.prescriptionExtractionGateway,
    this.prescriptionTextRecognizer,
    this.preferencesController,
    this.reminderScheduler,
    this.doseAnnouncementService,
    this.competitionDemo = const bool.fromEnvironment(
      'COMPETITION_DEMO',
      defaultValue: false,
    ),
    super.key,
  });

  final AccountSettingsGateway? accountSettingsGateway;
  final AuthCoordinator? authCoordinator;
  final BackgroundSyncScheduler? backgroundSyncScheduler;
  final CareAccessGateway? careAccessGateway;
  final CaregiverAlertNotifier? caregiverAlertNotifier;
  final PatientMedicationGateway? patientMedicationGateway;
  final InsightsGateway? insightsGateway;
  final DoseMutationStore? doseMutationStore;
  final DoseSyncGateway? doseSyncGateway;
  final PrescriptionExtractionGateway? prescriptionExtractionGateway;
  final PrescriptionTextRecognizer? prescriptionTextRecognizer;
  final CareMatePreferencesController? preferencesController;
  final ReminderScheduler? reminderScheduler;
  final DoseAnnouncementService? doseAnnouncementService;
  final bool competitionDemo;

  @override
  State<CareMateApp> createState() => _CareMateAppState();
}

class _CareMateAppState extends State<CareMateApp> {
  late final AccountSettingsGateway _accountSettingsGateway;
  late final AuthCoordinator _authCoordinator;
  late final CareAccessGateway _careAccessGateway;
  late final CaregiverAlertNotifier _caregiverAlertNotifier;
  late final bool _ownsCoordinator;
  late final BackgroundSyncScheduler _backgroundSyncScheduler;
  late final DoseMutationStore _doseMutationStore;
  late final DoseSyncGateway _doseSyncGateway;
  late final PatientMedicationGateway _patientMedicationGateway;
  late final InsightsGateway _insightsGateway;
  late final PrescriptionExtractionGateway _prescriptionExtractionGateway;
  late final PrescriptionTextRecognizer _prescriptionTextRecognizer;
  late final CareMatePreferencesController _preferencesController;
  late final ReminderScheduler _reminderScheduler;
  late final DoseAnnouncementService _doseAnnouncementService;
  late final bool _ownsPreferencesController;
  String? _loadedPreferencesForUser;
  CareMateLocalDatabase? _inMemoryDatabase;

  @override
  void initState() {
    super.initState();
    _ownsPreferencesController = widget.preferencesController == null;
    _preferencesController =
        widget.preferencesController ?? CareMatePreferencesController();
    unawaited(_preferencesController.initialize());
    _accountSettingsGateway =
        widget.accountSettingsGateway ??
        HttpAccountSettingsGateway(
          baseUrl: const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://10.0.2.2:3000/api/v1',
          ),
        );
    _ownsCoordinator = widget.authCoordinator == null;
    final usesInjectedApi = widget.patientMedicationGateway != null;
    _careAccessGateway =
        widget.careAccessGateway ??
        HttpCareAccessGateway(
          baseUrl: const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://10.0.2.2:3000/api/v1',
          ),
        );
    _caregiverAlertNotifier =
        widget.caregiverAlertNotifier ??
        (usesInjectedApi
            ? const NoopCaregiverAlertNotifier()
            : FlutterCaregiverAlertNotifier());
    _authCoordinator =
        widget.authCoordinator ??
        AuthCoordinator(
          gateway: HttpAuthGateway(
            baseUrl: const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://10.0.2.2:3000/api/v1',
            ),
          ),
          refreshLock: const FileRefreshSessionLock(),
          sessionStore: SecureSessionStore(),
        );
    _authCoordinator.addListener(_handleAuthStatus);
    _patientMedicationGateway =
        widget.patientMedicationGateway ??
        HttpPatientMedicationGateway(
          baseUrl: const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://10.0.2.2:3000/api/v1',
          ),
        );
    _insightsGateway =
        widget.insightsGateway ??
        HttpInsightsGateway(
          baseUrl: const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://10.0.2.2:3000/api/v1',
          ),
        );
    _doseMutationStore =
        widget.doseMutationStore ??
        (usesInjectedApi
            ? _inMemoryStore()
            : LazyDoseMutationStore(() async {
                final database = await EncryptedLocalDatabaseFactory().open();
                return DriftDoseMutationStore(database);
              }));
    _doseSyncGateway =
        widget.doseSyncGateway ??
        (usesInjectedApi
            ? const UnavailableDoseSyncGateway()
            : HttpDoseSyncGateway(
                baseUrl: const String.fromEnvironment(
                  'API_BASE_URL',
                  defaultValue: 'http://10.0.2.2:3000/api/v1',
                ),
              ));
    _backgroundSyncScheduler =
        widget.backgroundSyncScheduler ??
        (usesInjectedApi
            ? const NoopBackgroundSyncScheduler()
            : const WorkmanagerSyncScheduler());
    _prescriptionExtractionGateway =
        widget.prescriptionExtractionGateway ??
        HttpPrescriptionExtractionGateway(
          baseUrl: const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://10.0.2.2:3000/api/v1',
          ),
        );
    _prescriptionTextRecognizer =
        widget.prescriptionTextRecognizer ?? MlKitPrescriptionTextRecognizer();
    _reminderScheduler = widget.reminderScheduler ?? FlutterReminderScheduler();
    _doseAnnouncementService =
        widget.doseAnnouncementService ?? FlutterTtsDoseAnnouncementService();
    _authCoordinator.initialize();
  }

  @override
  void dispose() {
    _authCoordinator.removeListener(_handleAuthStatus);
    if (_ownsCoordinator) _authCoordinator.dispose();
    if (_ownsPreferencesController) _preferencesController.dispose();
    _inMemoryDatabase?.close();
    super.dispose();
  }

  DoseMutationStore _inMemoryStore() {
    final database = CareMateLocalDatabase(NativeDatabase.memory());
    _inMemoryDatabase = database;
    return DriftDoseMutationStore(database);
  }

  Future<void> _logout() async {
    await _authCoordinator.logout();
    try {
      await _doseMutationStore.clearAll();
    } on Object {
      // Credentials are already gone; account binding prevents cross-user reads.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CareMate',
      theme: CareMateTheme.light,
      darkTheme: CareMateTheme.dark,
      themeMode: ThemeMode.system,
      builder: (context, child) => AnimatedBuilder(
        animation: _preferencesController,
        child: child,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          final currentScale = media.textScaler.scale(1);
          final scale = _preferencesController.largeText
              ? currentScale < 1.25
                    ? 1.25
                    : currentScale
              : currentScale;
          return CareMatePreferencesScope(
            controller: _preferencesController,
            child: MediaQuery(
              data: media.copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
          );
        },
      ),
      home: AnimatedBuilder(
        animation: _authCoordinator,
        builder: (context, _) => switch (_authCoordinator.status) {
          AuthStatus.restoring => const _RestoringSessionPage(),
          AuthStatus.signedIn => AuthenticatedExperience(
            accountSettingsGateway: _accountSettingsGateway,
            accessToken: _authCoordinator.session!.accessToken,
            accessTokenProvider: _currentAccessToken,
            backgroundSyncScheduler: _backgroundSyncScheduler,
            careAccessGateway: _careAccessGateway,
            caregiverAlertNotifier: _caregiverAlertNotifier,
            competitionDemo: widget.competitionDemo,
            gateway: _patientMedicationGateway,
            insightsGateway: _insightsGateway,
            installationId: _authCoordinator.sessionStore.installationId,
            doseMutationStore: _doseMutationStore,
            doseAnnouncementService: _doseAnnouncementService,
            doseSyncGateway: _doseSyncGateway,
            onLogout: _logout,
            prescriptionExtractionGateway: _prescriptionExtractionGateway,
            prescriptionTextRecognizer: _prescriptionTextRecognizer,
            reminderScheduler: _reminderScheduler,
            refreshAccessToken: _authCoordinator.refreshAccessToken,
            userId: _authCoordinator.session!.userId,
          ),
          AuthStatus.signedOut ||
          AuthStatus.awaitingOtp => AuthFlowPage(coordinator: _authCoordinator),
        },
      ),
    );
  }

  Future<String> _currentAccessToken() async =>
      (await _authCoordinator.sessionStore.readSession())?.accessToken ??
      _authCoordinator.session!.accessToken;

  void _handleAuthStatus() {
    final session = _authCoordinator.session;
    if (_authCoordinator.status != AuthStatus.signedIn || session == null) {
      return;
    }
    if (_loadedPreferencesForUser == session.userId) return;
    _loadedPreferencesForUser = session.userId;
    unawaited(_loadAccountPreferences(session.accessToken, session.userId));
  }

  Future<void> _loadAccountPreferences(
    String accessToken,
    String userId,
  ) async {
    try {
      final preferences = await _accountSettingsGateway.getPreferences(
        accessToken,
      );
      if (_loadedPreferencesForUser != userId) return;
      await _preferencesController.setLocale(
        preferences.locale,
        persist: false,
      );
      await _preferencesController.setSimpleMode(
        preferences.simpleMode,
        persist: false,
      );
      await _preferencesController.setVoicePromptsEnabled(
        preferences.voicePromptsEnabled,
        persist: false,
      );
    } on Object {
      // Device locale and locally saved preferences keep the app usable offline.
    }
  }
}

class _RestoringSessionPage extends StatelessWidget {
  const _RestoringSessionPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Semantics(
          label: 'Restoring your secure CareMate session',
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
