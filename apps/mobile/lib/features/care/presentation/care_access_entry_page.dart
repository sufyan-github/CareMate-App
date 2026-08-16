import 'package:caremate/features/care/domain/care_access_gateway.dart';
import 'package:caremate/features/medications/application/patient_medication_coordinator.dart';
import 'package:caremate/features/medications/presentation/profile_setup_page.dart';
import 'package:flutter/material.dart';

class CareAccessEntryPage extends StatefulWidget {
  const CareAccessEntryPage({
    required this.accessToken,
    required this.coordinator,
    required this.gateway,
    super.key,
  });

  final String accessToken;
  final PatientMedicationCoordinator coordinator;
  final CareAccessGateway gateway;

  @override
  State<CareAccessEntryPage> createState() => _CareAccessEntryPageState();
}

class _CareAccessEntryPageState extends State<CareAccessEntryPage> {
  List<CareInvitation> _incoming = const [];
  bool _loading = true;
  bool _showProfileSetup = false;
  String? _busyId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_showProfileSetup ||
        (!_loading && _incoming.isEmpty && _error == null)) {
      return ProfileSetupPage(coordinator: widget.coordinator);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Care invitations')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'You have been invited to help',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Review the permissions before accepting. You receive read-only access and the patient can revoke it at any time.',
                  ),
                  if (_error case final message?) ...[
                    const SizedBox(height: 12),
                    Text(
                      message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  for (final invitation in _incoming)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              invitation.patientDisplayName,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            if (invitation.permissions.canViewMedicationPlan)
                              const Text('• View confirmed medication plan'),
                            if (invitation
                                .permissions
                                .canReceiveMissedDoseAlerts)
                              const Text('• Receive missed-dose alerts'),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: _busyId == null
                                      ? () => _decline(invitation)
                                      : null,
                                  child: const Text('Decline'),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  key: const Key(
                                    'accept-caregiver-invitation-button',
                                  ),
                                  onPressed: _busyId == null
                                      ? () => _accept(invitation)
                                      : null,
                                  child: Text(
                                    _busyId == invitation.id
                                        ? 'Accepting…'
                                        : 'Accept',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() => _showProfileSetup = true),
                    child: const Text('Set up my own medication profile'),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _load() async {
    try {
      final invitations = await widget.gateway.listIncoming(
        accessToken: widget.accessToken,
      );
      if (mounted) setState(() => _incoming = invitations);
    } on CareAccessFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _accept(CareInvitation invitation) async {
    setState(() {
      _busyId = invitation.id;
      _error = null;
    });
    try {
      await widget.gateway.accept(
        accessToken: widget.accessToken,
        invitationId: invitation.id,
      );
      await widget.coordinator.initialize();
      if (widget.coordinator.status == PatientMedicationStatus.needsProfile) {
        await _load();
      }
    } on CareAccessFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _decline(CareInvitation invitation) async {
    setState(() {
      _busyId = invitation.id;
      _error = null;
    });
    try {
      await widget.gateway.decline(
        accessToken: widget.accessToken,
        invitationId: invitation.id,
      );
      await _load();
    } on CareAccessFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }
}
