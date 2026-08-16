import 'package:caremate/features/medications/application/patient_medication_coordinator.dart';
import 'package:flutter/material.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({required this.coordinator, super.key});

  final PatientMedicationCoordinator coordinator;

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.account_circle_outlined,
                      size: 72,
                      color: colors.primary,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Set up your profile',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This name helps you and trusted caregivers identify whose medicines are shown.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      key: const Key('profile-name-input'),
                      controller: _controller,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Your name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter your name'
                          : null,
                    ),
                    if (widget.coordinator.errorMessage case final error?) ...[
                      const SizedBox(height: 12),
                      Text(error, style: TextStyle(color: colors.error)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: widget.coordinator.isSaving ? null : _submit,
                      child: widget.coordinator.isSaving
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Continue to CareMate'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Timezone: Asia/Dhaka. You can change it later in settings.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await widget.coordinator.createProfile(_controller.text.trim());
  }
}
