import 'package:flutter/material.dart';

class InviteCaregiverPage extends StatefulWidget {
  const InviteCaregiverPage({super.key});

  @override
  State<InviteCaregiverPage> createState() => _InviteCaregiverPageState();
}

class _InviteCaregiverPageState extends State<InviteCaregiverPage> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  bool _canViewPlan = true;
  bool _canReceiveMissedDoseAlerts = true;

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
                'The recipient must accept before access starts. CareMate will show exactly which permissions you grant.',
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
                onChanged: (value) =>
                    setState(() => _canViewPlan = value ?? false),
                title: const Text('View confirmed medication plan'),
                subtitle: const Text('Does not allow changing medicines'),
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
                onPressed: _submit,
                child: const Text('Send invitation'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Caregiver delivery and acceptance will be enabled with the Care Access backend module.',
        ),
      ),
    );
  }
}
