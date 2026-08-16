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
    expect(draft.warnings, ['Verify handwriting']);
  });
}
