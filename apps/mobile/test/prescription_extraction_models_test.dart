import 'package:caremate/features/prescription/domain/prescription_extraction_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses an evidence-bound prescription draft', () {
    final draft = PrescriptionExtractionDraft.fromJson({
      'id': 'draft-1',
      'language': 'MIXED',
      'provider': 'google-document-ai+openai',
      'rawText': 'Napa 500 mg',
      'warnings': ['Verify handwriting'],
      'medicines': [
        {
          'displayName': 'Napa',
          'evidenceText': 'Napa 500 mg',
          'confidence': 0.82,
        },
      ],
    });

    expect(draft.id, 'draft-1');
    expect(draft.language, 'MIXED');
    expect(draft.medicines.single.displayName, 'Napa');
    expect(draft.medicines.single.evidenceText, 'Napa 500 mg');
    expect(
      draft.medicines.single.confidenceBand,
      PrescriptionConfidenceBand.medium,
    );
    expect(draft.warnings, ['Verify handwriting']);
  });

  test('bands OCR confidence conservatively for review UI', () {
    PrescriptionMedicineCandidate candidate(double confidence) =>
        PrescriptionMedicineCandidate(
          confidence: confidence,
          displayName: 'Napa',
          evidenceText: 'Napa 500 mg',
        );

    expect(candidate(0.85).confidenceBand, PrescriptionConfidenceBand.high);
    expect(candidate(0.60).confidenceBand, PrescriptionConfidenceBand.medium);
    expect(candidate(0.59).confidenceBand, PrescriptionConfidenceBand.low);
  });
}
