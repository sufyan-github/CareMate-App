import 'package:caremate/features/auth/application/auth_coordinator.dart';
import 'package:caremate/features/auth/domain/auth_gateway.dart';
import 'package:caremate/features/auth/domain/auth_models.dart';
import 'package:caremate/features/auth/domain/session_store.dart';
import 'package:caremate/features/care/domain/care_access_gateway.dart';
import 'package:caremate/features/medications/domain/patient_medication_gateway.dart';
import 'package:caremate/features/medications/domain/patient_medication_models.dart';
import 'package:caremate/features/more/domain/account_settings_gateway.dart';

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

InMemoryCareAccessGateway emptyCareAccessGateway() =>
    InMemoryCareAccessGateway();

InMemoryAccountSettingsGateway accountSettingsGateway() =>
    InMemoryAccountSettingsGateway();

class InMemoryAccountSettingsGateway implements AccountSettingsGateway {
  AccountPreferences preferences = const AccountPreferences(
    allowAnalytics: false,
    locale: 'en-BD',
    showMedicineOnLockScreen: false,
  );
  final List<DeviceSession> sessions = [
    DeviceSession(
      appVersion: '1.0.0',
      current: true,
      deviceName: 'This phone',
      id: 'current-session',
      lastSeenAt: DateTime(2026, 8, 17, 10, 30),
      platform: 'ANDROID',
      status: 'ACTIVE',
    ),
    DeviceSession(
      appVersion: '1.0.0',
      current: false,
      deviceName: 'Other phone',
      id: 'other-session',
      lastSeenAt: DateTime(2026, 8, 16, 8),
      platform: 'ANDROID',
      status: 'ACTIVE',
    ),
  ];
  bool deletionRequested = false;
  bool loggedOutAll = false;

  @override
  Future<AccountPreferences> getPreferences(String accessToken) async =>
      preferences;

  @override
  Future<AccountPreferences> updatePreferences({
    required String accessToken,
    bool? allowAnalytics,
    String? locale,
    bool? showMedicineOnLockScreen,
  }) async {
    return preferences = AccountPreferences(
      allowAnalytics: allowAnalytics ?? preferences.allowAnalytics,
      locale: locale ?? preferences.locale,
      showMedicineOnLockScreen:
          showMedicineOnLockScreen ?? preferences.showMedicineOnLockScreen,
    );
  }

  @override
  Future<List<DeviceSession>> listSessions(String accessToken) async =>
      List.unmodifiable(sessions);

  @override
  Future<void> revokeSession({
    required String accessToken,
    required String sessionId,
  }) async {
    final index = sessions.indexWhere((session) => session.id == sessionId);
    final current = sessions[index];
    sessions[index] = DeviceSession(
      appVersion: current.appVersion,
      current: current.current,
      deviceName: current.deviceName,
      id: current.id,
      lastSeenAt: current.lastSeenAt,
      platform: current.platform,
      status: 'REVOKED',
    );
  }

  @override
  Future<void> logoutAll(String accessToken) async => loggedOutAll = true;

  @override
  Future<void> requestAccountDeletion(String accessToken) async =>
      deletionRequested = true;
}

class InMemoryCareAccessGateway implements CareAccessGateway {
  InMemoryCareAccessGateway({
    List<CareInvitation> initialInvitations = const [],
    this.onAccepted,
  }) {
    invitations.addAll(initialInvitations);
  }

  final void Function()? onAccepted;
  final List<CareInvitation> invitations = [];

  @override
  Future<CareInvitation> createInvitation({
    required String accessToken,
    required String phoneNumber,
    required String profileId,
    required CarePermissions permissions,
  }) async {
    final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final invitation = CareInvitation(
      deliveryStatus: 'IN_APP_PENDING',
      id: 'care-${invitations.length + 1}',
      inviteePhoneMasked: '••••••${digits.substring(digits.length - 4)}',
      patientDisplayName: 'Test patient',
      permissions: permissions,
      status: 'PENDING',
    );
    invitations.insert(0, invitation);
    return invitation;
  }

  @override
  Future<List<CareInvitation>> listForProfile({
    required String accessToken,
    required String profileId,
  }) async => List.unmodifiable(invitations);

  @override
  Future<CareInvitation> revoke({
    required String accessToken,
    required String invitationId,
  }) async {
    final index = invitations.indexWhere((item) => item.id == invitationId);
    final current = invitations[index];
    final revoked = CareInvitation(
      deliveryStatus: current.deliveryStatus,
      id: current.id,
      inviteePhoneMasked: current.inviteePhoneMasked,
      patientDisplayName: current.patientDisplayName,
      permissions: current.permissions,
      status: 'REVOKED',
    );
    invitations[index] = revoked;
    return revoked;
  }

  @override
  Future<List<CareInvitation>> listIncoming({
    required String accessToken,
  }) async => invitations
      .where((invitation) => invitation.status == 'PENDING')
      .toList(growable: false);

  @override
  Future<CareInvitation> accept({
    required String accessToken,
    required String invitationId,
  }) async {
    final accepted = _withStatus(invitationId, 'ACCEPTED');
    onAccepted?.call();
    return accepted;
  }

  @override
  Future<CareInvitation> decline({
    required String accessToken,
    required String invitationId,
  }) async => _withStatus(invitationId, 'DECLINED');

  CareInvitation _withStatus(String invitationId, String status) {
    final index = invitations.indexWhere((item) => item.id == invitationId);
    final current = invitations[index];
    final updated = CareInvitation(
      deliveryStatus: current.deliveryStatus,
      id: current.id,
      inviteePhoneMasked: current.inviteePhoneMasked,
      patientDisplayName: current.patientDisplayName,
      permissions: current.permissions,
      status: status,
    );
    invitations[index] = updated;
    return updated;
  }
}

class InMemoryPatientMedicationGateway implements PatientMedicationGateway {
  InMemoryPatientMedicationGateway({this.profile});

  PatientProfile? profile;
  final List<MedicationSummary> medications = [];
  MedicationDraft? lastCreatedDraft;

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
    lastCreatedDraft = draft;
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
