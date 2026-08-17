import 'package:caremate/features/medications/application/patient_medication_coordinator.dart';
import 'package:caremate/features/medications/domain/patient_medication_models.dart';
import 'package:flutter/material.dart';

class ScheduleSetupPage extends StatefulWidget {
  const ScheduleSetupPage({
    required this.coordinator,
    required this.medication,
    this.schedule,
    super.key,
  });

  final PatientMedicationCoordinator coordinator;
  final MedicationSummary medication;
  final MedicationScheduleSummary? schedule;

  @override
  State<ScheduleSetupPage> createState() => _ScheduleSetupPageState();
}

class _ScheduleSetupPageState extends State<ScheduleSetupPage> {
  late DateTime _startDate;
  late DateTime _endDate;
  final List<String> _times = ['08:00'];
  final Set<int> _daysOfWeek = {};
  final List<DateTime> _excludedDates = [];
  String _recurrence = 'DAILY';
  bool _openEnded = false;
  String? _localError;
  MedicationSchedulePlan? _preview;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate =
        widget.schedule?.startDate ?? DateTime(now.year, now.month, now.day);
    _endDate = widget.schedule?.endDate ?? _startDate;
    if (widget.schedule case final schedule?) {
      _openEnded = schedule.endDate == null;
      _recurrence = schedule.recurrence;
      _daysOfWeek.addAll(schedule.daysOfWeek);
      _excludedDates.addAll(schedule.excludedDates);
      _times
        ..clear()
        ..addAll(schedule.times);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.coordinator,
      builder: (context, _) => _buildPage(context),
    );
  }

  Widget _buildPage(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.schedule == null
              ? 'Set medication schedule'
              : 'Edit medication schedule',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const CircleAvatar(
                  child: Icon(Icons.medication_outlined),
                ),
                title: Text(
                  widget.medication.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${widget.medication.strengthLabel} · ${widget.medication.quantityLabel}',
                ),
              ),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: _recurrence,
              decoration: const InputDecoration(labelText: 'Frequency'),
              items: const [
                DropdownMenuItem(value: 'DAILY', child: Text('Every day')),
                DropdownMenuItem(
                  value: 'WEEKLY',
                  child: Text('Selected weekdays'),
                ),
              ],
              onChanged: (value) => setState(() {
                _recurrence = value ?? 'DAILY';
                if (_recurrence == 'WEEKLY' && _daysOfWeek.isEmpty) {
                  _daysOfWeek.add(_isoWeekday(DateTime.now()));
                }
                _preview = null;
                _localError = null;
              }),
            ),
            if (_recurrence == 'WEEKLY') ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (index) {
                  final day = index + 1;
                  const labels = [
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun',
                  ];
                  return FilterChip(
                    label: Text(labels[index]),
                    selected: _daysOfWeek.contains(day),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _daysOfWeek.add(day);
                      } else {
                        _daysOfWeek.remove(day);
                      }
                      _preview = null;
                      _localError = null;
                    }),
                  );
                }),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              'How long?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _DateButton(
                    label: 'Start date',
                    value: _startDate,
                    onPressed: () => _chooseDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateButton(
                    label: 'End date',
                    value: _endDate,
                    onPressed: _openEnded
                        ? null
                        : () => _chooseDate(isStart: false),
                  ),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _openEnded,
              onChanged: (value) => setState(() {
                _openEnded = value;
                _preview = null;
                if (!value && _endDate.isBefore(_startDate)) {
                  _endDate = _startDate;
                }
              }),
              title: const Text('No end date'),
              subtitle: const Text(
                'CareMate will keep a rolling 30-day occurrence horizon.',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Dates to skip (optional)',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addExcludedDate,
                  icon: const Icon(Icons.event_busy_outlined),
                  label: const Text('Skip date'),
                ),
              ],
            ),
            if (_excludedDates.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _excludedDates
                    .map(
                      (date) => InputChip(
                        label: Text(_dateLabel(date)),
                        onDeleted: () => setState(() {
                          _excludedDates.remove(date);
                          _preview = null;
                        }),
                      ),
                    )
                    .toList(growable: false),
              ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Dose times',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addTime,
                  icon: const Icon(Icons.add_alarm_outlined),
                  label: const Text('Add time'),
                ),
              ],
            ),
            const Text(
              'Choose the times from your confirmed instructions. CareMate does not decide dosage or timing.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _times
                  .map(
                    (time) => InputChip(
                      avatar: const Icon(Icons.schedule, size: 18),
                      label: Text(_friendlyTime(time)),
                      onDeleted: _times.length == 1
                          ? null
                          : () => setState(() {
                              _times.remove(time);
                              _preview = null;
                            }),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('preview-schedule-button'),
              onPressed: widget.coordinator.isSaving ? null : _previewSchedule,
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Preview medication schedule'),
            ),
            if (_localError ?? widget.coordinator.errorMessage
                case final error?) ...[
              const SizedBox(height: 12),
              Text(error, style: TextStyle(color: theme.colorScheme.error)),
            ],
            if (_preview case final preview?) ...[
              const SizedBox(height: 20),
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Review before activation',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${preview.occurrences.length} dose occurrence${preview.occurrences.length == 1 ? '' : 's'} · ${_number(preview.quantityRequired)} ${preview.quantityUnit.toLowerCase()} needed',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _times.map(_friendlyTime).join(', '),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        key: const Key('activate-schedule-button'),
                        onPressed: widget.coordinator.isSaving
                            ? null
                            : _activate,
                        child: Text(
                          widget.schedule == null
                              ? 'Activate schedule'
                              : 'Save schedule changes',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  MedicationScheduleDraft get _draft => MedicationScheduleDraft(
    daysOfWeek: _recurrence == 'WEEKLY'
        ? (_daysOfWeek.toList()..sort())
        : const [],
    endDate: _openEnded ? null : _endDate,
    excludedDates: List.unmodifiable(_excludedDates),
    recurrence: _recurrence,
    startDate: _startDate,
    times: List.unmodifiable(_times),
    timezone: widget.coordinator.profile!.timezone,
  );

  Future<void> _previewSchedule() async {
    if (_recurrence == 'WEEKLY' && _daysOfWeek.isEmpty) {
      setState(() => _localError = 'Choose at least one weekday.');
      return;
    }
    setState(() => _localError = null);
    final preview = await widget.coordinator.previewSchedule(
      widget.medication.id,
      _draft,
    );
    if (mounted) setState(() => _preview = preview);
  }

  Future<void> _activate() async {
    final current = widget.schedule;
    final succeeded = current == null
        ? (await widget.coordinator.activateSchedule(
                widget.medication.id,
                _draft,
              ))?.schedule !=
              null
        : await widget.coordinator.updateSchedule(
                widget.medication.id,
                current,
                _draft,
              ) !=
              null;
    if (succeeded && mounted) Navigator.pop(context, true);
  }

  Future<void> _chooseDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      initialDate: initial,
      lastDate: DateTime.now().add(const Duration(days: 366)),
    );
    if (selected == null) return;
    setState(() {
      if (isStart) {
        _startDate = selected;
        if (_endDate.isBefore(selected)) _endDate = selected;
      } else {
        _endDate = selected;
      }
      _excludedDates.removeWhere(
        (date) =>
            date.isBefore(_startDate) ||
            (!_openEnded && date.isAfter(_endDate)),
      );
      _preview = null;
    });
  }

  Future<void> _addExcludedDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: _startDate,
      initialDate: _startDate,
      lastDate: _openEnded
          ? _startDate.add(const Duration(days: 365))
          : _endDate,
      helpText: 'Choose a date with no generated dose occurrence',
    );
    if (selected == null ||
        _excludedDates.any((date) => _sameDate(date, selected))) {
      return;
    }
    setState(() {
      _excludedDates.add(selected);
      _excludedDates.sort();
      _preview = null;
    });
  }

  Future<void> _addTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 20, minute: 0),
      helpText: 'Add a confirmed dose time',
    );
    if (selected == null) return;
    final value =
        '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
    if (_times.contains(value)) return;
    setState(() {
      _times.add(value);
      _times.sort();
      _preview = null;
    });
  }

  String _number(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);

  int _isoWeekday(DateTime value) => value.weekday;

  bool _sameDate(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  String _dateLabel(DateTime value) =>
      '${value.day}/${value.month}/${value.year}';

  String _friendlyTime(String value) {
    final parts = value.split(':').map(int.parse).toList();
    final hour = parts.first;
    final minute = parts.last;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.onPressed,
    required this.value,
  });

  final String label;
  final VoidCallback? onPressed;
  final DateTime value;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 3),
          Text(
            '${value.day}/${value.month}/${value.year}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
