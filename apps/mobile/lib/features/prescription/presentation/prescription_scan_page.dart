import 'package:caremate/features/prescription/domain/prescription_text_recognizer.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PrescriptionScanPage extends StatefulWidget {
  const PrescriptionScanPage({required this.recognizer, super.key});

  final PrescriptionTextRecognizer recognizer;

  @override
  State<PrescriptionScanPage> createState() => _PrescriptionScanPageState();
}

class _PrescriptionScanPageState extends State<PrescriptionScanPage> {
  final _picker = ImagePicker();
  final _medicineName = TextEditingController();
  final _sourceText = TextEditingController();
  bool _isProcessing = false;
  bool _isReviewing = false;
  String? _error;

  @override
  void dispose() {
    _medicineName.dispose();
    _sourceText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prescription scan')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'OCR creates an unverified draft only. Check every field against the prescription before saving.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (!_isReviewing) ...[
              Text(
                'Add a clear prescription image',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Use good lighting and keep the medicine label inside the frame. English printed text works best in this build.',
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isProcessing
                    ? null
                    : () => _pickAndRecognize(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Take photo'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isProcessing
                    ? null
                    : () => _pickAndRecognize(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Choose from gallery'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isProcessing ? null : _startManualEntry,
                child: const Text('Enter extracted text manually'),
              ),
              if (_isProcessing) ...[
                const SizedBox(height: 20),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 8),
                const Center(child: Text('Reading the image on this device…')),
              ],
            ] else ...[
              Text(
                'Review OCR draft',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Correct the draft below. Nothing becomes a medication until you continue and save the medicine form.',
              ),
              const SizedBox(height: 20),
              TextField(
                key: const Key('ocr-medicine-name-input'),
                controller: _medicineName,
                decoration: const InputDecoration(
                  labelText: 'Medicine name from image',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                key: const Key('ocr-source-text-input'),
                controller: _sourceText,
                minLines: 5,
                maxLines: 10,
                decoration: const InputDecoration(
                  alignLabelWithHint: true,
                  labelText: 'Extracted text',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('review-ocr-draft-button'),
                onPressed: _continueToMedicationReview,
                child: const Text('Continue to medicine review'),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _isReviewing = false;
                  _error = null;
                }),
                child: const Text('Choose another image'),
              ),
            ],
            if (_error case final message?) ...[
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndRecognize(ImageSource source) async {
    setState(() {
      _error = null;
      _isProcessing = true;
    });
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2400,
      );
      if (image == null) return;
      final text = await widget.recognizer.recognize(image.path);
      if (text.isEmpty) {
        setState(() {
          _error =
              'No readable text was found. Try a clearer image or enter it manually.';
        });
        return;
      }
      _sourceText.text = text;
      _medicineName.text = _firstUsefulLine(text);
      setState(() => _isReviewing = true);
    } on Exception {
      setState(() {
        _error =
            'The image could not be read. Your photo was not saved; try again or enter it manually.';
      });
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _startManualEntry() {
    _sourceText.clear();
    _medicineName.clear();
    setState(() {
      _error = null;
      _isReviewing = true;
    });
  }

  void _continueToMedicationReview() {
    final sourceText = _sourceText.text.trim();
    final medicineName = _medicineName.text.trim();
    if (sourceText.isEmpty && medicineName.isEmpty) {
      setState(() => _error = 'Enter the text you can read from the image.');
      return;
    }
    Navigator.pop(
      context,
      PrescriptionDraftResult(
        medicineName: medicineName,
        sourceText: sourceText,
      ),
    );
  }

  String _firstUsefulLine(String text) => text
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .firstWhere((line) => line.length >= 2, orElse: () => '');
}
