import 'package:caremate/features/medications/application/patient_medication_coordinator.dart';
import 'package:caremate/features/medications/domain/patient_medication_models.dart';
import 'package:flutter/material.dart';

Future<void> showMedicationForm(
  BuildContext context, {
  required PatientMedicationCoordinator coordinator,
  String initialName = '',
  String? sourceText,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _MedicationForm(
      coordinator: coordinator,
      initialName: initialName,
      sourceText: sourceText,
    ),
  );
}

class MedicationsPage extends StatelessWidget {
  const MedicationsPage({required this.coordinator, super.key});

  final PatientMedicationCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: coordinator,
      builder: (context, _) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Your medicines',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () =>
                        showMedicationForm(context, coordinator: coordinator),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (coordinator.medications.isEmpty)
                Expanded(
                  child: _EmptyState(
                    onAdd: () =>
                        showMedicationForm(context, coordinator: coordinator),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: coordinator.medications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final medication = coordinator.medications[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: const CircleAvatar(
                            child: Icon(Icons.medication_outlined),
                          ),
                          title: Text(
                            medication.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${medication.strengthLabel}\n${medication.quantityLabel}',
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.medication_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 18),
            Text(
              'Add your first medicine',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the label exactly as you know it. CareMate does not change or prescribe your medicine.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add medicine'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicationForm extends StatefulWidget {
  const _MedicationForm({
    required this.coordinator,
    required this.initialName,
    this.sourceText,
  });

  final PatientMedicationCoordinator coordinator;
  final String initialName;
  final String? sourceText;

  @override
  State<_MedicationForm> createState() => _MedicationFormState();
}

class _MedicationFormState extends State<_MedicationForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  final _strength = TextEditingController();
  final _strengthUnit = TextEditingController(text: 'mg');
  final _quantity = TextEditingController(text: '1');
  String _form = 'TABLET';
  String _meal = 'UNSPECIFIED';

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _name.dispose();
    _strength.dispose();
    _strengthUnit.dispose();
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add medicine',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Copy the details from your medicine label or prescription.',
              ),
              if (widget.sourceText != null) ...[
                const SizedBox(height: 12),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'This form was prefilled from an unverified OCR draft. Check every value before saving.',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('medication-name-input'),
                controller: _name,
                decoration: const InputDecoration(labelText: 'Medicine name'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter the medicine name'
                    : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _strength,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Strength'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _strengthUnit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _form,
                decoration: const InputDecoration(labelText: 'Form'),
                items: const [
                  DropdownMenuItem(value: 'TABLET', child: Text('Tablet')),
                  DropdownMenuItem(value: 'CAPSULE', child: Text('Capsule')),
                  DropdownMenuItem(value: 'SYRUP', child: Text('Syrup')),
                  DropdownMenuItem(value: 'DROPS', child: Text('Drops')),
                  DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                ],
                onChanged: (value) => _form = value ?? _form,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _quantity,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Quantity per dose',
                ),
                validator: (value) {
                  final quantity = double.tryParse(value ?? '');
                  return quantity == null || quantity <= 0
                      ? 'Enter a valid quantity'
                      : null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _meal,
                decoration: const InputDecoration(labelText: 'Meal relation'),
                items: const [
                  DropdownMenuItem(
                    value: 'UNSPECIFIED',
                    child: Text('Not specified'),
                  ),
                  DropdownMenuItem(value: 'BEFORE', child: Text('Before food')),
                  DropdownMenuItem(value: 'WITH', child: Text('With food')),
                  DropdownMenuItem(value: 'AFTER', child: Text('After food')),
                ],
                onChanged: (value) => _meal = value ?? _meal,
              ),
              if (widget.coordinator.errorMessage case final error?) ...[
                const SizedBox(height: 12),
                Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 22),
              FilledButton(
                key: const Key('save-medication-button'),
                onPressed: widget.coordinator.isSaving ? null : _save,
                child: const Text('Save medicine'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final saved = await widget.coordinator.createMedication(
      MedicationDraft(
        displayName: _name.text.trim(),
        form: _form,
        mealRelation: _meal,
        quantityUnit: _form == 'SYRUP' ? 'ML' : _form,
        quantityValue: double.parse(_quantity.text),
        route: 'ORAL',
        sourceText: widget.sourceText,
        strengthUnit: _strength.text.trim().isEmpty
            ? null
            : _strengthUnit.text.trim(),
        strengthValue: double.tryParse(_strength.text),
      ),
    );
    if (saved && mounted) Navigator.pop(context);
  }
}
