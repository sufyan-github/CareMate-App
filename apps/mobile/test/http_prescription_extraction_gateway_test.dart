import 'dart:convert';
import 'dart:io';

import 'package:caremate/features/prescription/data/http_prescription_extraction_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('uploads an authenticated multipart image and parses the draft', () async {
    final directory = await Directory.systemTemp.createTemp('caremate-ocr-');
    addTearDown(() => directory.delete(recursive: true));
    final image = File('${directory.path}/prescription.jpg');
    await image.writeAsBytes([1, 2, 3, 4]);

    final gateway = HttpPrescriptionExtractionGateway(
      baseUrl: 'http://caremate.test/api/v1',
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.path,
          '/api/v1/patient-profiles/profile-1/prescription-extractions',
        );
        expect(request.headers['authorization'], 'Bearer access-1');
        expect(request.headers['content-type'], startsWith('multipart/form-data'));
        expect(request.body, contains('Napa 500 mg'));
        expect(request.body, contains('image/jpeg'));
        return http.Response(
          jsonEncode({
            'data': {
              'id': 'draft-1',
              'language': 'ENGLISH',
              'medicines': [
                {
                  'confidence': 0.9,
                  'displayName': 'Napa',
                  'evidenceText': 'Napa 500 mg',
                },
              ],
              'provider': 'development',
              'rawText': 'Napa 500 mg',
              'warnings': ['Review required'],
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final draft = await gateway.extract(
      accessToken: 'access-1',
      imagePath: image.path,
      localOcrText: 'Napa 500 mg',
      profileId: 'profile-1',
    );

    expect(draft.medicines.single.displayName, 'Napa');
    expect(draft.rawText, 'Napa 500 mg');
  });
}
