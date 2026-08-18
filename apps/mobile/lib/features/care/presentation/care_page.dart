import 'dart:async';

import 'package:caremate/app/preferences/caremate_preferences.dart';
import 'package:caremate/features/care/domain/care_access_gateway.dart';
import 'package:caremate/features/care/domain/caregiver_alert_notifier.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CarePage extends StatefulWidget {
  const CarePage({
    required this.accessToken,
    required this.canManage,
    required this.canReceiveMissedDoseAlerts,
    required this.competitionDemo,
    required this.gateway,
    required this.isActive,
    required this.missedDoseGraceMinutes,
    required this.notifier,
    required this.onInvite,
    required this.patientDisplayName,
    required this.profileId,
    required this.profileVersion,
    super.key,
  });

  final String accessToken;
  final bool canManage;
  final bool canReceiveMissedDoseAlerts;
  final bool competitionDemo;
  final CareAccessGateway gateway;
  final bool isActive;
  final int missedDoseGraceMinutes;
  final CaregiverAlertNotifier notifier;
  final Future<bool> Function() onInvite;
  final String patientDisplayName;
  final String profileId;
  final int profileVersion;

  @override
  State<CarePage> createState() => _CarePageState();
}

class _CarePageState extends State<CarePage> {
  List<CareInvitation> _invitations = const [];
  List<CaregiverAlert> _alerts = const [];
  final Set<String> _notifiedAlertIds = {};
  Timer? _pollTimer;
  bool _loading = false;
  String? _error;
  late int _graceMinutes;
  late int _profileVersion;

  @override
  void initState() {
    super.initState();
    _graceMinutes = widget.missedDoseGraceMinutes;
    _profileVersion = widget.profileVersion;
    unawaited(widget.notifier.initialize());
    _syncActivity();
  }

  @override
  void didUpdateWidget(CarePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profileId != oldWidget.profileId) {
      _alerts = const [];
      _invitations = const [];
      _notifiedAlertIds.clear();
      _graceMinutes = widget.missedDoseGraceMinutes;
      _profileVersion = widget.profileVersion;
    }
    if (widget.isActive != oldWidget.isActive ||
        widget.canManage != oldWidget.canManage ||
        widget.canReceiveMissedDoseAlerts !=
            oldWidget.canReceiveMissedDoseAlerts) {
      _syncActivity();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = CareMateStrings.of(context);
    final activeInvitations = _invitations
        .where(
          (invitation) =>
              invitation.status == 'PENDING' || invitation.status == 'ACCEPTED',
        )
        .toList(growable: false);

    return SafeArea(
      top: false,
      child: RefreshIndicator(
        onRefresh: widget.canManage ? _loadInvitations : _loadAlerts,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(
              copy.pick('Care circle', 'সহায়তার বৃত্ত'),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              widget.canManage
                  ? copy.pick(
                      'Share only the information you choose with a trusted caregiver.',
                      'বিশ্বস্ত সহায়তাকারীর সঙ্গে শুধু আপনার বেছে নেওয়া তথ্য শেয়ার করুন।',
                    )
                  : copy.pick(
                      'Private, consent-based updates from ${widget.patientDisplayName}.',
                      '${widget.patientDisplayName}-এর সম্মতিভিত্তিক ব্যক্তিগত আপডেট।',
                    ),
            ),
            const SizedBox(height: 20),
            if (widget.canManage) ...[
              _GraceWindowCard(
                minutes: _graceMinutes,
                onChanged: _loading ? null : _updateGrace,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _invite,
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: Text(
                  copy.pick('Invite caregiver', 'সহায়তাকারীকে আমন্ত্রণ'),
                ),
              ),
              if (widget.competitionDemo) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: const Key('simulate-missed-dose-button'),
                  onPressed: _loading ? null : _simulateMiss,
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Demo: simulate a missed dose now'),
                ),
              ],
            ],
            const SizedBox(height: 20),
            if (!widget.canManage && !widget.canReceiveMissedDoseAlerts)
              _CareStateCard(
                icon: Icons.notifications_off_outlined,
                title: 'No alert permission',
                message:
                    '${widget.patientDisplayName} has not shared missed-dose alerts with this account.',
              )
            else if (_loading &&
                (widget.canManage ? _invitations.isEmpty : _alerts.isEmpty))
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error case final message?)
              _CareStateCard(
                icon: Icons.cloud_off_outlined,
                title: widget.canManage
                    ? 'Could not load care circle'
                    : 'Could not refresh caregiver alerts',
                message: message,
                action: TextButton(
                  onPressed: widget.canManage ? _loadInvitations : _loadAlerts,
                  child: const Text('Try again'),
                ),
              )
            else if (!widget.canManage && _alerts.isEmpty)
              const _CareStateCard(
                icon: Icons.notifications_none_outlined,
                title: 'No missed-dose alerts',
                message:
                    'CareMate checks every 30 seconds while this screen is open. Pull down to refresh now.',
              )
            else if (!widget.canManage) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Caregiver alerts',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh alerts',
                    onPressed: _loading ? null : _loadAlerts,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final alert in _alerts)
                _CaregiverAlertCard(
                  alert: alert,
                  onAcknowledge: () => _acknowledge(alert),
                  onCall: () => _callPatient(alert),
                ),
            ] else if (activeInvitations.isEmpty)
              const _CareStateCard(
                icon: Icons.people_outline,
                title: 'No caregivers connected',
                message:
                    'An invitation must be accepted before anyone can see your information. You can revoke access later.',
              )
            else ...[
              Text(
                'Caregivers and invitations',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              for (final invitation in activeInvitations)
                _InvitationCard(
                  invitation: invitation,
                  onRevoke: () => _revoke(invitation),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _syncActivity() {
    _pollTimer?.cancel();
    if (!widget.isActive) return;
    if (widget.canManage) {
      unawaited(_loadInvitations());
      return;
    }
    if (!widget.canReceiveMissedDoseAlerts) return;
    unawaited(_loadAlerts());
    _pollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(_loadAlerts(silent: true)),
    );
  }

  Future<void> _loadInvitations() async {
    if (_loading) return;
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final invitations = await widget.gateway.listForProfile(
        accessToken: widget.accessToken,
        profileId: widget.profileId,
      );
      if (mounted) setState(() => _invitations = invitations);
    } on CareAccessFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadAlerts({bool silent = false}) async {
    if (_loading) return;
    if (!silent) {
      setState(() {
        _error = null;
        _loading = true;
      });
    } else {
      _loading = true;
    }
    try {
      final alerts = await widget.gateway.listAlerts(
        accessToken: widget.accessToken,
        profileId: widget.profileId,
      );
      for (final alert in alerts) {
        if (alert.status == 'ACTIVE' && _notifiedAlertIds.add(alert.id)) {
          await widget.notifier.show(alert);
        }
      }
      if (mounted) {
        setState(() {
          _alerts = alerts;
          _error = null;
        });
      }
    } on CareAccessFailure catch (failure) {
      if (mounted && !silent) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _invite() async {
    if (await widget.onInvite()) await _loadInvitations();
  }

  Future<void> _acknowledge(CaregiverAlert alert) async {
    try {
      await widget.gateway.acknowledgeAlert(
        accessToken: widget.accessToken,
        alertId: alert.id,
      );
      await _loadAlerts();
    } on CareAccessFailure catch (failure) {
      _showFailure(failure.message);
    }
  }

  Future<void> _callPatient(CaregiverAlert alert) async {
    final launched = await launchUrl(
      Uri(scheme: 'tel', path: alert.callPhoneE164),
    );
    if (!launched) _showFailure('This device could not open the phone app.');
  }

  Future<void> _updateGrace(int minutes) async {
    final previous = _graceMinutes;
    setState(() => _graceMinutes = minutes);
    try {
      _profileVersion = await widget.gateway.updateMissedDoseGrace(
        accessToken: widget.accessToken,
        expectedVersion: _profileVersion,
        minutes: minutes,
        profileId: widget.profileId,
      );
    } on CareAccessFailure catch (failure) {
      if (mounted) setState(() => _graceMinutes = previous);
      _showFailure(failure.message);
    }
  }

  Future<void> _simulateMiss() async {
    try {
      await widget.gateway.simulateMiss(
        accessToken: widget.accessToken,
        minutesLate: _graceMinutes + 1,
        profileId: widget.profileId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Synthetic miss created. The caregiver phone checks within 30 seconds while Care is open.',
          ),
        ),
      );
    } on CareAccessFailure catch (failure) {
      _showFailure(failure.message);
    }
  }

  Future<void> _revoke(CareInvitation invitation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke caregiver access?'),
        content: Text(
          invitation.status == 'ACCEPTED'
              ? '${invitation.inviteePhoneMasked} will immediately lose access to the shared information and new alerts.'
              : 'The pending invitation for ${invitation.inviteePhoneMasked} will be cancelled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            key: const Key('confirm-revoke-caregiver-button'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.gateway.revoke(
        accessToken: widget.accessToken,
        invitationId: invitation.id,
      );
      await _loadInvitations();
    } on CareAccessFailure catch (failure) {
      _showFailure(failure.message);
    }
  }

  void _showFailure(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _GraceWindowCard extends StatelessWidget {
  const _GraceWindowCard({required this.minutes, required this.onChanged});

  final int minutes;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Missed-dose grace window',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text('An alert is created only after this time passes.'),
              ],
            ),
          ),
          DropdownButton<int>(
            key: const Key('missed-dose-grace-setting'),
            value: minutes,
            onChanged: onChanged == null
                ? null
                : (value) {
                    if (value != null) onChanged!(value);
                  },
            items: const [15, 30, 45, 60]
                .map(
                  (value) =>
                      DropdownMenuItem(value: value, child: Text('$value min')),
                )
                .toList(growable: false),
          ),
        ],
      ),
    ),
  );
}

class _CaregiverAlertCard extends StatelessWidget {
  const _CaregiverAlertCard({
    required this.alert,
    required this.onAcknowledge,
    required this.onCall,
  });

  final CaregiverAlert alert;
  final VoidCallback onAcknowledge;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final resolved = alert.status == 'RESOLVED';
    final acknowledged = alert.status == 'ACKNOWLEDGED';
    final medicine = alert.medicationName;
    final title = medicine == null
        ? 'A scheduled dose was missed'
        : '$medicine dose was missed';
    final state = resolved
        ? 'Resolved — taken ${alert.resolvedMinutesLate ?? 0} minutes late'
        : acknowledged
        ? 'Acknowledged by you'
        : 'Needs attention';
    final colors = Theme.of(context).colorScheme;
    return Card(
      key: Key('caregiver-alert-${alert.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  resolved ? Icons.check_circle_outline : Icons.warning_amber,
                  color: resolved ? colors.primary : colors.error,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${alert.patientDisplayName} • ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(alert.plannedAt.toLocal()))}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(state, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!resolved && !acknowledged)
                  FilledButton.icon(
                    key: Key('acknowledge-alert-${alert.id}'),
                    onPressed: onAcknowledge,
                    icon: const Icon(Icons.done),
                    label: const Text('Acknowledge'),
                  ),
                OutlinedButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.call_outlined),
                  label: const Text('Call patient'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({required this.invitation, required this.onRevoke});

  final CareInvitation invitation;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final copy = CareMateStrings.of(context);
    final accepted = invitation.status == 'ACCEPTED';
    final permissions = <String>[
      if (invitation.permissions.canViewMedicationPlan)
        copy.pick('View medication plan', 'ওষুধের পরিকল্পনা দেখা'),
      if (invitation.permissions.canReceiveMissedDoseAlerts)
        copy.pick('Missed-dose alerts', 'মিস ডোজের সতর্কতা'),
      if (invitation.permissions.canViewDoseOutcomes)
        copy.pick('View dose outcomes', 'ডোজের ফল দেখা'),
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Icon(
                    accepted ? Icons.person : Icons.hourglass_top_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invitation.inviteePhoneMasked,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        accepted
                            ? copy.pick('Access accepted', 'অনুমতি গৃহীত')
                            : copy.pick(
                                'Waiting for acceptance',
                                'গ্রহণের অপেক্ষায়',
                              ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onRevoke,
                  child: Text(copy.pick('Revoke', 'অনুমতি বাতিল')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(permissions.join(' • ')),
            if (!accepted) ...[
              const SizedBox(height: 8),
              Text(
                copy.pick(
                  'Demo delivery: the caregiver sees this after signing in with the invited number. No SMS is sent.',
                  'ডেমো ডেলিভারি: আমন্ত্রিত নম্বর দিয়ে সাইন ইন করলে সহায়তাকারী এটি দেখবেন। কোনো SMS পাঠানো হয় না।',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CareStateCard extends StatelessWidget {
  const _CareStateCard({
    required this.icon,
    required this.message,
    required this.title,
    this.action,
  });

  final Widget? action;
  final IconData icon;
  final String message;
  final String title;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          if (action case final value?) ...[const SizedBox(height: 10), value],
        ],
      ),
    ),
  );
}
