class CarePermissions {
  const CarePermissions({
    required this.canReceiveMissedDoseAlerts,
    required this.canViewMedicationPlan,
    this.canViewDoseOutcomes = false,
  });

  final bool canReceiveMissedDoseAlerts;
  final bool canViewMedicationPlan;
  final bool canViewDoseOutcomes;

  Map<String, dynamic> toJson() => {
    'canReceiveMissedDoseAlerts': canReceiveMissedDoseAlerts,
    'canViewMedicationPlan': canViewMedicationPlan,
    'canViewDoseOutcomes': canViewDoseOutcomes,
  };

  factory CarePermissions.fromJson(Map<String, dynamic> json) =>
      CarePermissions(
        canReceiveMissedDoseAlerts:
            json['canReceiveMissedDoseAlerts'] as bool? ?? false,
        canViewMedicationPlan: json['canViewMedicationPlan'] as bool? ?? false,
        canViewDoseOutcomes: json['canViewDoseOutcomes'] as bool? ?? false,
      );
}

class CareInvitation {
  const CareInvitation({
    required this.deliveryStatus,
    required this.id,
    required this.inviteePhoneMasked,
    required this.patientDisplayName,
    required this.permissions,
    required this.status,
  });

  final String deliveryStatus;
  final String id;
  final String inviteePhoneMasked;
  final String patientDisplayName;
  final CarePermissions permissions;
  final String status;

  factory CareInvitation.fromJson(Map<String, dynamic> json) => CareInvitation(
    deliveryStatus: json['deliveryStatus'] as String? ?? 'IN_APP_PENDING',
    id: json['id'] as String,
    inviteePhoneMasked: json['inviteePhoneMasked'] as String? ?? '',
    patientDisplayName: json['patientDisplayName'] as String? ?? '',
    permissions: CarePermissions.fromJson(
      json['permissions'] as Map<String, dynamic>? ?? const {},
    ),
    status: json['status'] as String? ?? 'PENDING',
  );
}

class CaregiverAlert {
  const CaregiverAlert({
    required this.acknowledgedAt,
    required this.callPhoneE164,
    required this.deliveredAt,
    required this.generatedAt,
    required this.id,
    required this.medicationName,
    required this.patientDisplayName,
    required this.plannedAt,
    required this.resolvedAt,
    required this.resolvedMinutesLate,
    required this.status,
  });

  final DateTime? acknowledgedAt;
  final String callPhoneE164;
  final DateTime? deliveredAt;
  final DateTime generatedAt;
  final String id;
  final String? medicationName;
  final String patientDisplayName;
  final DateTime plannedAt;
  final DateTime? resolvedAt;
  final int? resolvedMinutesLate;
  final String status;

  factory CaregiverAlert.fromJson(Map<String, dynamic> json) => CaregiverAlert(
    acknowledgedAt: _optionalDate(json['acknowledgedAt']),
    callPhoneE164: json['callPhoneE164'] as String,
    deliveredAt: _optionalDate(json['deliveredAt']),
    generatedAt: DateTime.parse(json['generatedAt'] as String),
    id: json['id'] as String,
    medicationName: json['medicationName'] as String?,
    patientDisplayName: json['patientDisplayName'] as String,
    plannedAt: DateTime.parse(json['plannedAt'] as String),
    resolvedAt: _optionalDate(json['resolvedAt']),
    resolvedMinutesLate: json['resolvedMinutesLate'] as int?,
    status: json['status'] as String,
  );

  static DateTime? _optionalDate(Object? value) =>
      value is String ? DateTime.parse(value) : null;
}

class CareAccessFailure implements Exception {
  const CareAccessFailure(this.message);

  final String message;
}

abstract class CareAccessGateway {
  Future<List<CareInvitation>> listForProfile({
    required String accessToken,
    required String profileId,
  });

  Future<CareInvitation> createInvitation({
    required String accessToken,
    required String phoneNumber,
    required String profileId,
    required CarePermissions permissions,
  });

  Future<CareInvitation> revoke({
    required String accessToken,
    required String invitationId,
  });

  Future<List<CareInvitation>> listIncoming({required String accessToken});

  Future<CareInvitation> accept({
    required String accessToken,
    required String invitationId,
  });

  Future<CareInvitation> decline({
    required String accessToken,
    required String invitationId,
  });

  Future<List<CaregiverAlert>> listAlerts({
    required String accessToken,
    required String profileId,
  });

  Future<void> acknowledgeAlert({
    required String accessToken,
    required String alertId,
  });

  Future<int> updateMissedDoseGrace({
    required String accessToken,
    required int expectedVersion,
    required int minutes,
    required String profileId,
  });

  Future<void> simulateMiss({
    required String accessToken,
    required int minutesLate,
    required String profileId,
  });
}
