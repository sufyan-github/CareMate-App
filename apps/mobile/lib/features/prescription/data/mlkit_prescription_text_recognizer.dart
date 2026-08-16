import 'package:caremate/features/prescription/domain/prescription_text_recognizer.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class MlKitPrescriptionTextRecognizer implements PrescriptionTextRecognizer {
  @override
  Future<String> recognize(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      return result.text.trim();
    } finally {
      await recognizer.close();
    }
  }
}
