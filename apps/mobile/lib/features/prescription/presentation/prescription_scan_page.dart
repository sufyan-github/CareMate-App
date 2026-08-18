import 'package:caremate/app/design/caremate_tokens.dart';
import 'package:caremate/app/preferences/caremate_preferences.dart';
import 'package:caremate/app/widgets/caremate_status_card.dart';
import 'package:caremate/features/prescription/domain/prescription_extraction_gateway.dart';
import 'package:caremate/features/prescription/domain/prescription_text_recognizer.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PrescriptionScanPage extends StatefulWidget {
  const PrescriptionScanPage({
    required this.accessToken,
    required this.extractionGateway,
    required this.profileId,
    required this.recognizer,
    super.key,
  });

  final String accessToken;
  final PrescriptionExtractionGateway extractionGateway;
  final String profileId;
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
  String? _notice;
  List<String> _warnings = const [];
  List<PrescriptionMedicineCandidate> _candidates = const [];

  @override
  void dispose() {
    _medicineName.dispose();
    _sourceText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = CareMateStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(copy.pick('Prescription scan', 'প্রেসক্রিপশন স্ক্যান')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            CareMateStatusCard(
              icon: Icons.fact_check_outlined,
              message: copy.pick(
                'AI and OCR create an unverified draft only. Compare every field with the prescription before saving.',
                'AI ও OCR শুধু একটি অযাচাইকৃত খসড়া তৈরি করে। সংরক্ষণের আগে প্রেসক্রিপশনের সঙ্গে প্রতিটি তথ্য মিলিয়ে নিন।',
              ),
              title: copy.pick('Review required', 'যাচাই করা প্রয়োজন'),
              tone: CareMateStatusTone.warning,
            ),
            const SizedBox(height: 18),
            if (!_isReviewing) ...[
              Text(
                copy.pick(
                  'Add a clear prescription image',
                  'পরিষ্কার প্রেসক্রিপশনের ছবি দিন',
                ),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                copy.pick(
                  'Use good lighting and keep the whole prescription inside the frame. Cloud review can help with Bangla and handwriting.',
                  'ভালো আলো ব্যবহার করুন এবং পুরো প্রেসক্রিপশন ফ্রেমে রাখুন। ক্লাউড যাচাই বাংলা ও হাতের লেখা বুঝতে সহায়তা করতে পারে।',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isProcessing
                    ? null
                    : () => _pickAndRecognize(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(copy.pick('Take photo', 'ছবি তুলুন')),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isProcessing
                    ? null
                    : () => _pickAndRecognize(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(
                  copy.pick('Choose from gallery', 'গ্যালারি থেকে নিন'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isProcessing ? null : _startManualEntry,
                child: Text(
                  copy.pick(
                    'Enter prescription text manually',
                    'প্রেসক্রিপশনের লেখা নিজে লিখুন',
                  ),
                ),
              ),
              if (_isProcessing) ...[
                const SizedBox(height: 20),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    copy.pick(
                      'Creating a review draft…',
                      'যাচাইয়ের খসড়া তৈরি হচ্ছে…',
                    ),
                  ),
                ),
              ],
            ] else ...[
              Text(
                copy.pick('Review AI/OCR draft', 'AI/OCR খসড়া যাচাই করুন'),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                copy.pick(
                  'Select the best supported name or correct it below. Nothing is saved until you review the medicine form.',
                  'প্রমাণের সঙ্গে সবচেয়ে ভালো মেলা নাম বেছে নিন বা নিচে ঠিক করুন। ওষুধের ফর্ম যাচাই না করা পর্যন্ত কিছু সংরক্ষিত হবে না।',
                ),
              ),
              if (_notice case final message?) ...[
                const SizedBox(height: 12),
                CareMateStatusCard(
                  message: message,
                  title: copy.pick('Draft status', 'খসড়ার অবস্থা'),
                ),
              ],
              if (_warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                CareMateStatusCard(
                  icon: Icons.warning_amber_rounded,
                  message: _warnings.join('\n'),
                  title: copy.pick(
                    'Check these details',
                    'এই তথ্যগুলো যাচাই করুন',
                  ),
                  tone: CareMateStatusTone.warning,
                ),
              ],
              if (_candidates.isNotEmpty) ...[
                const SizedBox(height: CareMateSpacing.lg),
                Text(
                  copy.pick('Detected medicine names', 'শনাক্ত করা ওষুধের নাম'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: CareMateSpacing.xs),
                Text(
                  copy.pick(
                    'Confidence is a model estimate, not medical verification. Choose only a name you can see on the prescription.',
                    'আত্মবিশ্বাসের মাত্রা মডেলের অনুমান, চিকিৎসাগত যাচাই নয়। প্রেসক্রিপশনে দেখা যায় এমন নামই বেছে নিন।',
                  ),
                ),
                const SizedBox(height: CareMateSpacing.sm),
                for (final candidate in _candidates)
                  _CandidateCard(
                    candidate: candidate,
                    onSelect: () => setState(
                      () => _medicineName.text = candidate.displayName,
                    ),
                    selected:
                        _medicineName.text.trim() == candidate.displayName,
                  ),
              ],
              const SizedBox(height: 20),
              TextField(
                key: const Key('ocr-medicine-name-input'),
                controller: _medicineName,
                decoration: InputDecoration(
                  labelText: copy.pick(
                    'Medicine name to verify',
                    'যাচাই করার ওষুধের নাম',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                key: const Key('ocr-source-text-input'),
                controller: _sourceText,
                minLines: 5,
                maxLines: 10,
                decoration: InputDecoration(
                  alignLabelWithHint: true,
                  labelText: copy.pick('Extracted text', 'শনাক্ত করা লেখা'),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('review-ocr-draft-button'),
                onPressed: _continueToMedicationReview,
                child: Text(
                  copy.pick(
                    'Review medicine details',
                    'ওষুধের তথ্য যাচাই করুন',
                  ),
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _isReviewing = false;
                  _error = null;
                  _notice = null;
                  _warnings = const [];
                  _candidates = const [];
                }),
                child: Text(
                  copy.pick('Choose another image', 'অন্য ছবি বেছে নিন'),
                ),
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
      _notice = null;
      _warnings = const [];
      _candidates = const [];
      _isProcessing = true;
    });
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2400,
      );
      if (image == null) return;
      var localText = '';
      try {
        localText = await widget.recognizer.recognize(image.path);
      } on Exception {
        // Cloud OCR can still recover a draft when the local Latin preview fails.
      }

      if (!mounted) return;
      final useCloud = await _requestCloudConsent();
      if (!mounted) return;
      PrescriptionExtractionDraft? cloudDraft;
      if (useCloud) {
        try {
          cloudDraft = await widget.extractionGateway.extract(
            accessToken: widget.accessToken,
            imagePath: image.path,
            localOcrText: localText,
            profileId: widget.profileId,
          );
        } on PrescriptionExtractionFailure catch (failure) {
          _notice = failure.message;
        }
      } else {
        _notice =
            'Cloud OCR was skipped. This review uses only the on-device preview.';
      }

      final text = cloudDraft?.rawText.trim().isNotEmpty ?? false
          ? cloudDraft!.rawText
          : localText;
      if (text.trim().isEmpty && cloudDraft?.medicines.isEmpty != false) {
        setState(() {
          _error =
              'No readable text was found. Try a clearer image or enter it manually.';
        });
        return;
      }
      final suggestedName = cloudDraft?.medicines
          .map((candidate) => candidate.displayName.trim())
          .firstWhere((name) => name.isNotEmpty, orElse: () => '');
      _sourceText.text = text;
      _medicineName.text = suggestedName?.isNotEmpty ?? false
          ? suggestedName!
          : _firstUsefulLine(text);
      _warnings = cloudDraft?.warnings ?? const [];
      _candidates = cloudDraft?.medicines ?? const [];
      if (cloudDraft != null) {
        _notice =
            'Cloud OCR draft created (${cloudDraft.language.toLowerCase()}). It has not changed your medication list.';
      }
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
      _notice = 'Manual entry selected. Check the prescription carefully.';
      _warnings = const [];
      _candidates = const [];
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

  Future<bool> _requestCloudConsent() async {
    final copy = CareMateStrings.of(context);
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          copy.pick('Use cloud AI/OCR?', 'ক্লাউড AI/OCR ব্যবহার করবেন?'),
        ),
        content: Text(
          copy.pick(
            'For better Bangla and handwriting recognition, this prescription image will be securely sent to providers configured by the CareMate server. It is used only to create a draft for your review.',
            'বাংলা ও হাতের লেখা ভালোভাবে শনাক্ত করতে প্রেসক্রিপশনের ছবিটি CareMate সার্ভারে নির্ধারিত সেবায় নিরাপদে পাঠানো হবে। এটি শুধু আপনার যাচাইয়ের খসড়া তৈরিতে ব্যবহৃত হবে।',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(copy.pick('On-device only', 'শুধু এই ডিভাইসে')),
          ),
          FilledButton(
            key: const Key('allow-cloud-ocr-button'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(copy.pick('Use cloud AI/OCR', 'ক্লাউড AI/OCR ব্যবহার')),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.candidate,
    required this.onSelect,
    required this.selected,
  });

  final PrescriptionMedicineCandidate candidate;
  final VoidCallback onSelect;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final copy = CareMateStrings.of(context);
    final confidenceLabel = switch (candidate.confidenceBand) {
      PrescriptionConfidenceBand.high => copy.pick('High', 'উচ্চ'),
      PrescriptionConfidenceBand.medium => copy.pick('Medium', 'মাঝারি'),
      PrescriptionConfidenceBand.low => copy.pick('Low', 'কম'),
    };
    final percent = (candidate.confidence.clamp(0, 1) * 100).round();
    return Card(
      margin: const EdgeInsets.only(bottom: CareMateSpacing.xs),
      child: RadioGroup<bool>(
        groupValue: selected,
        onChanged: (_) => onSelect(),
        child: RadioListTile<bool>(
          key: Key('ocr-candidate-${candidate.displayName}'),
          value: true,
          title: Text(
            candidate.displayName,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            copy.pick(
              'OCR confidence: $confidenceLabel ($percent%)\nVisible evidence: ${candidate.evidenceText}',
              'OCR আত্মবিশ্বাস: $confidenceLabel ($percent%)\nছবিতে দেখা প্রমাণ: ${candidate.evidenceText}',
            ),
          ),
        ),
      ),
    );
  }
}
