class CarePermissions {
  const CarePermissions({
    required this.canReceiveMissedDoseAlerts,
    required this.canViewMedicationPlan,
  });

  final bool canReceiveMissedDoseAlerts;
  final bool canViewMedicationPlan;

  Map<String, dynamic> toJson() => {
    'canReceiveMissedDoseAlerts': canReceiveMissedDoseAlerts,
    'canViewMedicationPlan': canViewMedicationPlan,
  };

  factory CarePermissions.fromJson(Map<String, dynamic> json) =>
      CarePermissions(
        canReceiveMissedDoseAlerts:
            json['canReceiveMissedDoseAlerts'] as bool? ?? false,
        canViewMedicationPlan: json['canViewMedicationPlan'] as bool? ?? false,
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
}
