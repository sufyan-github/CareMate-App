class PatientProfile {
  const PatientProfile({
    required this.displayName,
    required this.id,
    required this.timezone,
    required this.version,
  });

  final String displayName;
  final String id;
  final String timezone;
  final int version;
}

class MedicationDraft {
  const MedicationDraft({
    required this.displayName,
    required this.form,
    required this.mealRelation,
    required this.quantityUnit,
    required this.quantityValue,
    required this.route,
    this.notes,
    this.sourceText,
    this.strengthUnit,
    this.strengthValue,
  });

  final String displayName;
  final String form;
  final String mealRelation;
  final String? notes;
  final String quantityUnit;
  final double quantityValue;
  final String route;
  final String? sourceText;
  final String? strengthUnit;
  final double? strengthValue;
}

class MedicationSummary {
  const MedicationSummary({
    required this.displayName,
    required this.form,
    required this.id,
    required this.quantityLabel,
    required this.status,
    required this.strengthLabel,
  });

  final String displayName;
  final String form;
  final String id;
  final String quantityLabel;
  final String status;
  final String strengthLabel;
}
