import 'package:caremate/app/preferences/caremate_preferences.dart';
import 'package:caremate/features/medications/domain/patient_medication_models.dart';
import 'package:caremate/features/simple_mode/domain/dose_announcement_service.dart';
import 'package:caremate/features/today/presentation/today_page.dart';
import 'package:flutter/material.dart';

class SimpleTodayPage extends StatefulWidget {
  const SimpleTodayPage({
    required this.announcementService,
    required this.canManage,
    required this.medications,
    required this.occurrences,
    required this.onDoseAction,
    required this.voicePromptsEnabled,
    super.key,
  });

  final DoseAnnouncementService announcementService;
  final bool canManage;
  final List<MedicationSummary> medications;
  final List<DoseOccurrenceSummary> occurrences;
  final DoseActionCallback? onDoseAction;
  final bool voicePromptsEnabled;

  @override
  State<SimpleTodayPage> createState() => _SimpleTodayPageState();
}

class _SimpleTodayPageState extends State<SimpleTodayPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final copy = CareMateStrings.of(context);
    if (widget.occurrences.isEmpty) {
      return SafeArea(
        top: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.event_available_outlined, size: 96),
                const SizedBox(height: 20),
                Text(
                  copy.pick('No doses planned today', 'আজ কোনো ডোজ নেই'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  copy.pick(
                    'CareMate will show one large dose card here when it is time.',
                    'সময় হলে CareMate এখানে একটি বড় ডোজ কার্ড দেখাবে।',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      key: const Key('simple-mode-page'),
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    copy.pick("Today's dose", 'আজকের ডোজ'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Semantics(
                  label: copy.pick(
                    'Dose ${_selectedIndex + 1} of ${widget.occurrences.length}',
                    '${widget.occurrences.length}টির মধ্যে ${_selectedIndex + 1} নম্বর ডোজ',
                  ),
                  child: Chip(
                    label: Text(
                      '${_selectedIndex + 1}/${widget.occurrences.length}',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              itemCount: widget.occurrences.length,
              onPageChanged: (index) => setState(() => _selectedIndex = index),
              itemBuilder: (context, index) {
                final occurrence = widget.occurrences[index];
                final medication = _medicationFor(occurrence);
                return _SimpleDoseCard(
                  announcementService: widget.announcementService,
                  canManage: widget.canManage,
                  medication: medication,
                  occurrence: occurrence,
                  onDoseAction: widget.onDoseAction,
                  voicePromptsEnabled: widget.voicePromptsEnabled,
                );
              },
            ),
          ),
          if (widget.occurrences.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Text(
                copy.pick(
                  'Swipe left or right for another dose',
                  'অন্য ডোজ দেখতে ডানে বা বামে সরান',
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  MedicationSummary? _medicationFor(DoseOccurrenceSummary occurrence) {
    for (final medication in widget.medications) {
      if (medication.displayName == occurrence.medicationName) {
        return medication;
      }
    }
    return null;
  }
}

class _SimpleDoseCard extends StatelessWidget {
  const _SimpleDoseCard({
    required this.announcementService,
    required this.canManage,
    required this.medication,
    required this.occurrence,
    required this.onDoseAction,
    required this.voicePromptsEnabled,
  });

  final DoseAnnouncementService announcementService;
  final bool canManage;
  final MedicationSummary? medication;
  final DoseOccurrenceSummary occurrence;
  final DoseActionCallback? onDoseAction;
  final bool voicePromptsEnabled;

  bool get _isDue => !occurrence.plannedAt.isAfter(DateTime.now());
  bool get _canConfirm => const {
    'SCHEDULED',
    'REMINDER_SENT',
    'SNOOZED',
    'MISSED',
  }.contains(occurrence.status);
  bool get _canSnooze =>
      const {'SCHEDULED', 'REMINDER_SENT'}.contains(occurrence.status);
  bool get _canSkip => const {
    'SCHEDULED',
    'REMINDER_SENT',
    'SNOOZED',
  }.contains(occurrence.status);

  @override
  Widget build(BuildContext context) {
    final copy = CareMateStrings.of(context);
    final enabled =
        canManage && onDoseAction != null && _isDue && !occurrence.pendingSync;
    final mealRelation = medication?.mealRelation ?? 'UNSPECIFIED';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Semantics(
        container: true,
        label:
            '${occurrence.medicationName}, ${occurrence.quantityLabel}, '
            '${_friendlyTime(occurrence.plannedLocalDateTime)}, '
            '${_mealLabel(context, mealRelation)}',
        onLongPressHint: voicePromptsEnabled
            ? copy.pick('Read this dose in Bangla', 'ডোজটি বাংলায় শুনুন')
            : null,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onLongPress: voicePromptsEnabled
                ? () => _speak(context, mealRelation)
                : null,
            child: ListView(
              key: Key('simple-dose-scroll-${occurrence.id}'),
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: _MedicationPictogram(
                    form: medication?.form ?? 'TABLET',
                    medicationName: occurrence.medicationName,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  occurrence.medicationName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  occurrence.quantityLabel,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _PictureInstruction(
                  icon: _timeIcon(occurrence.plannedLocalDateTime),
                  label: _friendlyTime(occurrence.plannedLocalDateTime),
                ),
                const SizedBox(height: 12),
                _PictureInstruction(
                  icon: _mealIcon(mealRelation),
                  label: _mealLabel(context, mealRelation),
                ),
                const SizedBox(height: 12),
                Center(child: _StatusChip(occurrence: occurrence)),
                if (voicePromptsEnabled) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 64,
                    child: OutlinedButton.icon(
                      key: Key('speak-dose-${occurrence.id}'),
                      onPressed: () => _speak(context, mealRelation),
                      icon: const Icon(Icons.volume_up_outlined, size: 30),
                      label: Text(copy.pick('Hear in Bangla', 'বাংলায় শুনুন')),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  height: 76,
                  child: FilledButton.icon(
                    key: Key('simple-confirm-dose-${occurrence.id}'),
                    onPressed: enabled && _canConfirm
                        ? () => _runAction(context, DoseAction.confirm)
                        : null,
                    icon: const Icon(Icons.check_circle_outline, size: 34),
                    label: Text(
                      copy.pick('I confirmed it', 'খেয়েছি'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Semantics(
                  onLongPressHint: _canSkip
                      ? copy.pick(
                          'Hold to mark this dose skipped',
                          'ডোজটি বাদ দিতে চেপে ধরে রাখুন',
                        )
                      : null,
                  child: GestureDetector(
                    onLongPress: enabled && _canSkip
                        ? () => _confirmSkip(context)
                        : null,
                    child: SizedBox(
                      height: 76,
                      child: OutlinedButton.icon(
                        key: Key('simple-snooze-dose-${occurrence.id}'),
                        onPressed: enabled && _canSnooze
                            ? () => _runAction(
                                context,
                                DoseAction.snooze,
                                snoozeMinutes: 10,
                              )
                            : null,
                        icon: const Icon(Icons.alarm_outlined, size: 34),
                        label: Text(
                          copy.pick('Later', 'পরে'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  copy.pick(
                    'These are self-reported actions. Hold Later to record a skip.',
                    'এগুলো আপনার জানানো তথ্য। বাদ দিতে “পরে” বোতামটি চেপে ধরে রাখুন।',
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _speak(BuildContext context, String mealRelation) async {
    try {
      await announcementService.speak(
        DoseAnnouncement(
          mealRelation: mealRelation,
          medicationName: occurrence.medicationName,
          plannedLocalDateTime: occurrence.plannedLocalDateTime,
          quantityLabel: occurrence.quantityLabel,
        ),
      );
    } on DoseAnnouncementUnavailable {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            CareMateStrings.of(context).pick(
              'Bangla voice is not installed on this phone. You can still use the pictures and large buttons.',
              'এই ফোনে বাংলা কণ্ঠ ইনস্টল নেই। ছবি ও বড় বোতাম ব্যবহার করতে পারবেন।',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _runAction(
    BuildContext context,
    DoseAction action, {
    int? snoozeMinutes,
  }) async {
    final saved = await onDoseAction!(
      occurrence,
      action,
      snoozeMinutes: snoozeMinutes,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? CareMateStrings.of(
                  context,
                ).pick('Saved on this phone.', 'এই ফোনে সংরক্ষিত হয়েছে।')
              : CareMateStrings.of(context).pick(
                  'Could not save. Try again.',
                  'সংরক্ষণ হয়নি। আবার চেষ্টা করুন।',
                ),
        ),
      ),
    );
  }

  Future<void> _confirmSkip(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('এই ডোজটি বাদ দেবেন?'),
        content: const Text(
          'CareMate আপনার পছন্দটি সংরক্ষণ করবে। নিশ্চিত না হলে চিকিৎসক বা ফার্মাসিস্টের সাথে কথা বলুন।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ফিরে যান'),
          ),
          FilledButton(
            key: const Key('simple-confirm-skip-button'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('বাদ দিন'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _runAction(context, DoseAction.skip);
    }
  }
}

class _MedicationPictogram extends StatelessWidget {
  const _MedicationPictogram({
    required this.form,
    required this.medicationName,
  });

  final String form;
  final String medicationName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = <Color>[
      colors.primary,
      colors.tertiary,
      colors.secondary,
      colors.error,
    ];
    final band = palette[medicationName.hashCode.abs() % palette.length];
    final bandForeground =
        ThemeData.estimateBrightnessForColor(band) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return Semantics(
      key: Key('medication-pictogram-$medicationName'),
      image: true,
      label: '${_formLabel(form)} pictogram',
      child: Container(
        width: 144,
        height: 144,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          border: Border.all(color: colors.outlineVariant, width: 2),
          borderRadius: BorderRadius.circular(36),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: Icon(_formIcon(form), size: 84, color: colors.onSurface),
            ),
            Container(
              width: double.infinity,
              height: 22,
              color: band,
              alignment: Alignment.center,
              child: Text(
                _formLabel(form),
                style: TextStyle(
                  color: bandForeground,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PictureInstruction extends StatelessWidget {
  const _PictureInstruction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.occurrence});

  final DoseOccurrenceSummary occurrence;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(
      occurrence.pendingSync ? Icons.cloud_upload_outlined : Icons.info_outline,
    ),
    label: Text(
      occurrence.pendingSync
          ? CareMateStrings.of(
              context,
            ).pick('Waiting to sync', 'সিঙ্কের অপেক্ষায়')
          : switch (occurrence.status) {
              'CONFIRMED' => CareMateStrings.of(
                context,
              ).pick('Confirmed', 'নিশ্চিত করা হয়েছে'),
              'SKIPPED' => CareMateStrings.of(
                context,
              ).pick('Skipped', 'বাদ দেওয়া হয়েছে'),
              'MISSED' => CareMateStrings.of(
                context,
              ).pick('No response yet', 'এখনও উত্তর নেই'),
              'SNOOZED' => CareMateStrings.of(
                context,
              ).pick('Later', 'পরে মনে করাবে'),
              _ => CareMateStrings.of(context).pick('Planned', 'পরিকল্পিত'),
            },
    ),
  );
}

IconData _formIcon(String form) => switch (form.toUpperCase()) {
  'CAPSULE' => Icons.medication_liquid_outlined,
  'SYRUP' || 'LIQUID' => Icons.local_drink_outlined,
  'DROPS' || 'DROP' => Icons.water_drop_outlined,
  'INHALER' => Icons.air_outlined,
  'INJECTION' => Icons.vaccines_outlined,
  _ => Icons.medication_outlined,
};

String _formLabel(String form) => switch (form.toUpperCase()) {
  'CAPSULE' => 'CAPSULE',
  'SYRUP' || 'LIQUID' => 'SYRUP',
  'DROPS' || 'DROP' => 'DROPS',
  'INHALER' => 'INHALER',
  'INJECTION' => 'INJECTION',
  _ => 'TABLET',
};

IconData _timeIcon(String localDateTime) {
  final hour = int.parse(
    localDateTime.substring(localDateTime.length - 5, localDateTime.length - 3),
  );
  if (hour < 11) return Icons.wb_twilight_outlined;
  if (hour < 16) return Icons.wb_sunny_outlined;
  if (hour < 19) return Icons.nights_stay_outlined;
  return Icons.dark_mode_outlined;
}

IconData _mealIcon(String relation) => switch (relation.toUpperCase()) {
  'BEFORE' => Icons.first_page,
  'WITH' => Icons.restaurant,
  'AFTER' => Icons.last_page,
  'EMPTY_STOMACH' => Icons.no_food_outlined,
  _ => Icons.restaurant_menu,
};

String _mealLabel(BuildContext context, String relation) {
  final copy = CareMateStrings.of(context);
  return switch (relation.toUpperCase()) {
    'BEFORE' => copy.pick('Before food', 'খাবারের আগে'),
    'WITH' => copy.pick('With food', 'খাবারের সাথে'),
    'AFTER' => copy.pick('After food', 'খাবারের পরে'),
    'EMPTY_STOMACH' => copy.pick('On an empty stomach', 'খালি পেটে'),
    _ => copy.pick('Follow your instructions', 'নির্দেশনা অনুসরণ করুন'),
  };
}

String _friendlyTime(String localDateTime) {
  final time = localDateTime.substring(localDateTime.length - 5);
  final parts = time.split(':').map(int.parse).toList(growable: false);
  final period = parts.first >= 12 ? 'PM' : 'AM';
  final hour = parts.first % 12 == 0 ? 12 : parts.first % 12;
  return '$hour:${parts.last.toString().padLeft(2, '0')} $period';
}
