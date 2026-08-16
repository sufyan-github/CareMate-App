import 'dart:convert';

import 'package:caremate/features/prescription/domain/prescription_extraction_gateway.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class HttpPrescriptionExtractionGateway
    implements PrescriptionExtractionGateway {
  HttpPrescriptionExtractionGateway({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  @override
  Future<PrescriptionExtractionDraft> extract({
    required String accessToken,
    required String imagePath,
    required String profileId,
    String? localOcrText,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          '$baseUrl/patient-profiles/$profileId/prescription-extractions',
        ),
      )..headers['authorization'] = 'Bearer $accessToken';
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imagePath,
          contentType: _contentType(imagePath),
        ),
      );
      if (localOcrText?.trim().isNotEmpty ?? false) {
        request.fields['localOcrText'] = localOcrText!.trim();
      }

      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamed);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = body['error'] as Map<String, dynamic>? ?? const {};
        throw PrescriptionExtractionFailure(
          _errorMessage(error['message'] ?? body['message']) ??
              'The prescription service could not read this image.',
        );
      }
      return PrescriptionExtractionDraft.fromJson(
        body['data'] as Map<String, dynamic>,
      );
    } on PrescriptionExtractionFailure {
      rethrow;
    } on Exception {
      throw const PrescriptionExtractionFailure(
        'Cloud OCR is unavailable. You can still review the on-device text or enter it manually.',
      );
    }
  }

  MediaType _contentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    return MediaType('image', 'jpeg');
  }

  String? _errorMessage(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value;
    if (value is List<dynamic>) {
      final messages = value.map((item) => item.toString()).join(' ');
      return messages.trim().isEmpty ? null : messages;
    }
    return null;
  }
}
