import 'package:caremate/features/care/domain/care_access_gateway.dart';
import 'package:flutter/material.dart';

class CarePage extends StatefulWidget {
  const CarePage({
    required this.accessToken,
    required this.canManage,
    required this.gateway,
    required this.isActive,
    required this.onInvite,
    required this.profileId,
    required this.patientDisplayName,
    super.key,
  });

  final String accessToken;
  final bool canManage;
  final CareAccessGateway gateway;
  final bool isActive;
  final Future<bool> Function() onInvite;
  final String profileId;
  final String patientDisplayName;

  @override
  State<CarePage> createState() => _CarePageState();
}

class _CarePageState extends State<CarePage> {
  List<CareInvitation> _invitations = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.isActive && widget.canManage) _load();
  }

  @override
  void didUpdateWidget(CarePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && widget.canManage && !oldWidget.isActive) _load();
  }

  @override
  Widget build(BuildContext context) {
    final active = _invitations
        .where(
          (invitation) =>
              invitation.status == 'PENDING' || invitation.status == 'ACCEPTED',
        )
        .toList(growable: false);

    return SafeArea(
      top: false,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(
              'Care circle',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share only the information you choose with a trusted caregiver.',
            ),
            const SizedBox(height: 20),
            if (widget.canManage)
              FilledButton.icon(
                onPressed: _invite,
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text('Invite caregiver'),
              ),
            const SizedBox(height: 20),
            if (!widget.canManage)
              _CareStateCard(
                icon: Icons.volunteer_activism_outlined,
                title: 'Caring for ${widget.patientDisplayName}',
                message:
                    'Your access is read-only. The patient can change permissions or revoke access at any time.',
              )
            else if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error case final message?)
              _CareStateCard(
                icon: Icons.cloud_off_outlined,
                title: 'Could not load care circle',
                message: message,
                action: TextButton(
                  onPressed: _load,
                  child: const Text('Try again'),
                ),
              )
            else if (active.isEmpty)
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
              for (final invitation in active)
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

  Future<void> _load() async {
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

  Future<void> _invite() async {
    if (await widget.onInvite()) await _load();
  }

  Future<void> _revoke(CareInvitation invitation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke caregiver access?'),
        content: Text(
          invitation.status == 'ACCEPTED'
              ? '${invitation.inviteePhoneMasked} will immediately lose access to the shared information.'
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
      await _load();
    } on CareAccessFailure catch (failure) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }
}

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({required this.invitation, required this.onRevoke});

  final CareInvitation invitation;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final accepted = invitation.status == 'ACCEPTED';
    final permissions = <String>[
      if (invitation.permissions.canViewMedicationPlan) 'View medication plan',
      if (invitation.permissions.canReceiveMissedDoseAlerts)
        'Missed-dose alerts',
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
                        accepted ? 'Access accepted' : 'Waiting for acceptance',
                      ),
                    ],
                  ),
                ),
                TextButton(onPressed: onRevoke, child: const Text('Revoke')),
              ],
            ),
            const SizedBox(height: 12),
            Text(permissions.join(' • ')),
            if (!accepted) ...[
              const SizedBox(height: 8),
              const Text(
                'The caregiver sees this invitation after signing in with the invited number.',
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
