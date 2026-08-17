import 'package:caremate/features/care/domain/care_access_gateway.dart';
import 'package:flutter/material.dart';

class InviteCaregiverPage extends StatefulWidget {
  const InviteCaregiverPage({
    required this.accessToken,
    required this.gateway,
    required this.profileId,
    super.key,
  });

  final String accessToken;
  final CareAccessGateway gateway;
  final String profileId;

  @override
  State<InviteCaregiverPage> createState() => _InviteCaregiverPageState();
}

class _InviteCaregiverPageState extends State<InviteCaregiverPage> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  bool _canViewPlan = true;
  bool _canReceiveMissedDoseAlerts = true;
  bool _canViewDoseOutcomes = false;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invite caregiver')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              const Text(
                'The recipient must accept before access starts. In this testing build, the invitation appears after they sign in to CareMate with this number; SMS delivery is not enabled.',
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('caregiver-phone-input'),
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Caregiver mobile number',
                  prefixText: '+88 ',
                ),
                validator: (value) {
                  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                  return RegExp(r'^01[3-9]\d{8}$').hasMatch(digits)
                      ? null
                      : 'Enter a valid Bangladesh mobile number';
                },
              ),
              const SizedBox(height: 22),
              Text(
                'Permissions',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _canViewPlan,
                onChanged: (value) => setState(() {
                  _canViewPlan = value ?? false;
                  if (!_canViewPlan) _canViewDoseOutcomes = false;
                }),
                title: const Text('View confirmed medication plan'),
                subtitle: const Text('Does not allow changing medicines'),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _canViewDoseOutcomes,
                onChanged: !_canViewPlan
                    ? null
                    : (value) =>
                          setState(() => _canViewDoseOutcomes = value ?? false),
                title: const Text('View reported dose outcomes'),
                subtitle: const Text(
                  'Shows confirmed, skipped, and missed app records',
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _canReceiveMissedDoseAlerts,
                onChanged: (value) => setState(
                  () => _canReceiveMissedDoseAlerts = value ?? false,
                ),
                title: const Text('Receive missed-dose alerts'),
                subtitle: const Text('Available after reminders are enabled'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('send-caregiver-invitation-button'),
                onPressed: _isSaving ? null : _submit,
                child: Text(
                  _isSaving ? 'Creating invitation…' : 'Create invitation',
                ),
              ),
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
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_canViewPlan && !_canReceiveMissedDoseAlerts) {
      setState(() => _error = 'Choose at least one caregiver permission.');
      return;
    }
    setState(() {
      _error = null;
      _isSaving = true;
    });
    try {
      await widget.gateway.createInvitation(
        accessToken: widget.accessToken,
        phoneNumber: _phone.text,
        profileId: widget.profileId,
        permissions: CarePermissions(
          canReceiveMissedDoseAlerts: _canReceiveMissedDoseAlerts,
          canViewMedicationPlan: _canViewPlan,
          canViewDoseOutcomes: _canViewDoseOutcomes,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } on CareAccessFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
