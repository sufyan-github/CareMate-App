class PrescriptionMedicineCandidate {
  const PrescriptionMedicineCandidate({
    required this.displayName,
    required this.evidenceText,
    required this.confidence,
  });

  final String displayName;
  final String evidenceText;
  final double confidence;

  PrescriptionConfidenceBand get confidenceBand => switch (confidence) {
    >= 0.85 => PrescriptionConfidenceBand.high,
    >= 0.60 => PrescriptionConfidenceBand.medium,
    _ => PrescriptionConfidenceBand.low,
  };

  factory PrescriptionMedicineCandidate.fromJson(Map<String, dynamic> json) =>
      PrescriptionMedicineCandidate(
        displayName: json['displayName'] as String? ?? '',
        evidenceText: json['evidenceText'] as String? ?? '',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      );
}

enum PrescriptionConfidenceBand { high, medium, low }

class PrescriptionExtractionDraft {
  const PrescriptionExtractionDraft({
    required this.id,
    required this.language,
    required this.medicines,
    required this.provider,
    required this.rawText,
    required this.warnings,
  });

  final String id;
  final String language;
  final List<PrescriptionMedicineCandidate> medicines;
  final String provider;
  final String rawText;
  final List<String> warnings;

  factory PrescriptionExtractionDraft.fromJson(Map<String, dynamic> json) =>
      PrescriptionExtractionDraft(
        id: json['id'] as String,
        language: json['language'] as String? ?? 'UNKNOWN',
        medicines: (json['medicines'] as List<dynamic>? ?? const [])
            .map(
              (item) => PrescriptionMedicineCandidate.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList(growable: false),
        provider: json['provider'] as String? ?? 'unknown',
        rawText: json['rawText'] as String? ?? '',
        warnings: (json['warnings'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList(growable: false),
      );
}

class PrescriptionExtractionFailure implements Exception {
  const PrescriptionExtractionFailure(this.message);

  final String message;
}

abstract class PrescriptionExtractionGateway {
  Future<PrescriptionExtractionDraft> extract({
    required String accessToken,
    required String imagePath,
    required String profileId,
    String? localOcrText,
  });
}
