import 'package:caremate/features/auth/application/auth_coordinator.dart';
import 'package:caremate/features/auth/domain/auth_gateway.dart';
import 'package:caremate/features/auth/domain/auth_models.dart';
import 'package:caremate/features/auth/domain/session_store.dart';
import 'package:caremate/features/medications/domain/patient_medication_gateway.dart';
import 'package:caremate/features/medications/domain/patient_medication_models.dart';

AuthCoordinator authenticatedCoordinator() => AuthCoordinator(
  gateway: _RestorableAuthGateway(),
  sessionStore: _ExistingSessionStore(),
);

AuthCoordinator signedOutCoordinator() => AuthCoordinator(
  gateway: _RestorableAuthGateway(),
  sessionStore: _EmptySessionStore(),
);

InMemoryPatientMedicationGateway existingPatientGateway() =>
    InMemoryPatientMedicationGateway(
      profile: const PatientProfile(
        displayName: 'Test patient',
        id: 'test-profile',
        timezone: 'Asia/Dhaka',
        version: 1,
      ),
    );

class InMemoryPatientMedicationGateway implements PatientMedicationGateway {
  InMemoryPatientMedicationGateway({this.profile});

  PatientProfile? profile;
  final List<MedicationSummary> medications = [];

  @override
  Future<PatientProfile> createProfile({
    required String accessToken,
    required String displayName,
    required String timezone,
  }) async {
    return profile = PatientProfile(
      displayName: displayName,
      id: 'created-profile',
      timezone: timezone,
      version: 1,
    );
  }

  @override
  Future<List<PatientProfile>> listProfiles(String accessToken) async =>
      profile == null ? [] : [profile!];

  @override
  Future<MedicationSummary> createMedication({
    required String accessToken,
    required MedicationDraft draft,
    required String profileId,
  }) async {
    final medication = MedicationSummary(
      displayName: draft.displayName,
      form: draft.form,
      id: 'created-medication',
      quantityLabel:
          '${draft.quantityValue} ${draft.quantityUnit.toLowerCase()}',
      status: 'ACTIVE',
      strengthLabel: draft.strengthValue == null
          ? 'Strength not specified'
          : '${draft.strengthValue} ${draft.strengthUnit}',
    );
    medications.insert(0, medication);
    return medication;
  }

  @override
  Future<List<MedicationSummary>> listMedications({
    required String accessToken,
    required String profileId,
  }) async => List.unmodifiable(medications);
}

class _RestorableAuthGateway implements AuthGateway {
  @override
  Future<void> logout(String accessToken) async {}

  @override
  Future<AuthSession> refresh(String refreshToken) async => const AuthSession(
    accessToken: 'restored-access',
    refreshToken: 'rotated-refresh',
    userId: 'test-user',
  );

  @override
  Future<AuthChallenge> requestOtp({
    required String deviceInstallationId,
    required String locale,
    required String phoneNumber,
  }) => throw UnimplementedError();

  @override
  Future<AuthSession> verifyOtp({
    required String challengeId,
    required AuthDevice device,
    required String otp,
  }) => throw UnimplementedError();
}

class _ExistingSessionStore implements SessionStore {
  String? _refreshToken = 'existing-refresh';

  @override
  Future<void> clear() async => _refreshToken = null;

  @override
  Future<String> installationId() async => 'test-installation';

  @override
  Future<String?> readRefreshToken() async => _refreshToken;

  @override
  Future<void> writeRefreshToken(String token) async => _refreshToken = token;
}

class _EmptySessionStore implements SessionStore {
  @override
  Future<void> clear() async {}

  @override
  Future<String> installationId() async => 'test-installation';

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> writeRefreshToken(String token) async {}
}
