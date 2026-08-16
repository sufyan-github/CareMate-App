abstract interface class PrescriptionTextRecognizer {
  Future<String> recognize(String imagePath);
}

class PrescriptionDraftResult {
  const PrescriptionDraftResult({
    required this.medicineName,
    required this.sourceText,
  });

  final String medicineName;
  final String sourceText;
}
