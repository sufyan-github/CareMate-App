import 'package:caremate/features/medications/application/patient_medication_coordinator.dart';
import 'package:caremate/features/medications/domain/patient_medication_models.dart';
import 'package:caremate/features/medications/presentation/schedule_setup_page.dart';
import 'package:flutter/material.dart';

class ScheduleManagePage extends StatefulWidget {
  const ScheduleManagePage({
    required this.coordinator,
    required this.medication,
    required this.schedule,
    super.key,
  });

  final PatientMedicationCoordinator coordinator;
  final MedicationSummary medication;
  final MedicationScheduleSummary schedule;

  @override
  State<ScheduleManagePage> createState() => _ScheduleManagePageState();
}

class _ScheduleManagePageState extends State<ScheduleManagePage> {
  late MedicationScheduleSummary _schedule;

  @override
  void initState() {
    super.initState();
    _schedule = widget.schedule;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.coordinator,
      builder: (context, _) => _buildPage(context),
    );
  }

  Widget _buildPage(BuildContext context) {
    final paused = _schedule.status == 'PAUSED';
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Manage medication schedule')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.medication.displayName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Chip(
                          avatar: Icon(
                            paused ? Icons.pause_circle : Icons.check_circle,
                            size: 18,
                          ),
                          label: Text(paused ? 'Paused' : 'Active'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _schedule.times.map(_friendlyTime).join(', '),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(_frequencyLabel(_schedule)),
                    const SizedBox(height: 3),
                    Text(
                      _schedule.endDate == null
                          ? 'Starts ${_date(_schedule.startDate)} · no end date · ${_schedule.timezone}'
                          : '${_date(_schedule.startDate)} to ${_date(_schedule.endDate!)} · ${_schedule.timezone}',
                    ),
                    if (_schedule.excludedDates.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        '${_schedule.excludedDates.length} skipped date${_schedule.excludedDates.length == 1 ? '' : 's'}',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (!paused)
              FilledButton.icon(
                onPressed: widget.coordinator.isSaving ? null : _edit,
                icon: const Icon(Icons.edit_calendar_outlined),
                label: const Text('Change dates or times'),
              ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: Key(
                paused ? 'resume-schedule-button' : 'pause-schedule-button',
              ),
              onPressed: widget.coordinator.isSaving
                  ? null
                  : () => _command(
                      paused ? ScheduleAction.resume : ScheduleAction.pause,
                    ),
              icon: Icon(paused ? Icons.play_arrow : Icons.pause),
              label: Text(paused ? 'Resume schedule' : 'Pause schedule'),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              key: const Key('end-schedule-button'),
              onPressed: widget.coordinator.isSaving ? null : _confirmEnd,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('End schedule'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
            if (widget.coordinator.errorMessage case final error?) ...[
              const SizedBox(height: 12),
              Text(error, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 14),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Schedule changes replace eligible future dose occurrences only. Past dose history is preserved.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => ScheduleSetupPage(
          coordinator: widget.coordinator,
          medication: widget.medication,
          schedule: _schedule,
        ),
      ),
    );
    if (changed == true && mounted) {
      final updated = widget.coordinator.medications
          .firstWhere((item) => item.id == widget.medication.id)
          .activeSchedule;
      if (updated != null) setState(() => _schedule = updated);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Schedule changes saved')));
    }
  }

  Future<void> _command(ScheduleAction action) async {
    final updated = await widget.coordinator.commandSchedule(
      widget.medication.id,
      _schedule,
      action,
    );
    if (updated != null && mounted) setState(() => _schedule = updated);
  }

  Future<void> _confirmEnd() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End this schedule?'),
        content: const Text(
          'Eligible future dose occurrences will be cancelled. Your past dose history will remain available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep schedule'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End schedule'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ended = await widget.coordinator.commandSchedule(
      widget.medication.id,
      _schedule,
      ScheduleAction.end,
    );
    if (ended != null && mounted) Navigator.pop(context, 'ended');
  }

  String _date(DateTime value) => '${value.day}/${value.month}/${value.year}';

  String _friendlyTime(String value) {
    final parts = value.split(':').map(int.parse).toList();
    final hour = parts.first;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${parts.last.toString().padLeft(2, '0')} $period';
  }

  String _frequencyLabel(MedicationScheduleSummary schedule) {
    if (schedule.recurrence != 'WEEKLY') return 'Every day';
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return schedule.daysOfWeek.map((day) => labels[day - 1]).join(', ');
  }
}
