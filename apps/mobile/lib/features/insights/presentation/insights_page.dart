import 'dart:async';

import 'package:caremate/features/insights/domain/insights_gateway.dart';
import 'package:caremate/features/insights/domain/insights_models.dart';
import 'package:caremate/features/medications/application/patient_medication_coordinator.dart';
import 'package:flutter/material.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({
    required this.coordinator,
    required this.gateway,
    required this.isActive,
    super.key,
  });

  final PatientMedicationCoordinator coordinator;
  final InsightsGateway gateway;
  final bool isActive;

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  AdherenceIndicator? _indicator;
  List<InventoryPositionSummary> _inventory = const [];
  String? _error;
  bool _loading = false;
  int _periodDays = 7;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant InsightsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) unawaited(_load());
  }

  @override
  Widget build(BuildContext context) {
    final medicationCount = widget.coordinator.medications.length;
    return SafeArea(
      top: false,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          key: const Key('insights-scroll-view'),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Your insights',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh insights',
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 7, label: Text('7 days')),
                ButtonSegment(value: 30, label: Text('30 days')),
              ],
              selected: {_periodDays},
              onSelectionChanged: _loading
                  ? null
                  : (selection) {
                      setState(() => _periodDays = selection.single);
                      unawaited(_load());
                    },
            ),
            if (_loading && _indicator == null) ...[
              const SizedBox(height: 48),
              const Center(child: CircularProgressIndicator()),
            ] else ...[
              if (_error != null) ...[
                const SizedBox(height: 16),
                _ErrorCard(message: _error!, onRetry: _load),
              ],
              const SizedBox(height: 16),
              _MedicationOverviewCard(medicationCount: medicationCount),
              const SizedBox(height: 16),
              if (_indicator case final indicator?)
                _IndicatorCard(indicator: indicator)
              else if (_error == null)
                const _EmptyIndicatorCard(),
              const SizedBox(height: 24),
              Text(
                'Estimated stock',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Stock changes are kept as an auditable ledger. Confirmed doses reduce the estimate once.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              if (_inventory.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.inventory_2_outlined),
                    title: Text('No medicine stock to show'),
                    subtitle: Text(
                      'Add a medicine first, then record its opening quantity.',
                    ),
                  ),
                )
              else
                ..._inventory.map(
                  (position) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _InventoryCard(
                      key: ValueKey('inventory-${position.id}'),
                      position: position,
                      onAdjust: () => _showAdjustment(position),
                      onThreshold: () => _showThreshold(position),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _load() async {
    if (_loading || widget.coordinator.profile == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final today = DateTime.now();
    final to = DateTime(today.year, today.month, today.day);
    final from = to.subtract(Duration(days: _periodDays - 1));
    try {
      final token = await widget.coordinator.accessTokenForRequest();
      final profileId = widget.coordinator.profile!.id;
      final results = await Future.wait<Object>([
        widget.gateway.getIndicator(
          accessToken: token,
          from: from,
          profileId: profileId,
          to: to,
        ),
        widget.gateway.listInventory(accessToken: token, profileId: profileId),
      ]);
      if (!mounted) return;
      setState(() {
        _indicator = results[0] as AdherenceIndicator;
        _inventory = results[1] as List<InventoryPositionSummary>;
      });
    } on InsightsFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } on Object {
      if (mounted) {
        setState(() => _error = 'Could not load insights. Try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showAdjustment(InventoryPositionSummary position) async {
    final quantity = TextEditingController();
    var reason = position.adjustments.isEmpty ? 'OPENING' : 'RESTOCK';
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            position.adjustments.isEmpty ? 'Set opening stock' : 'Adjust stock',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('stock-quantity-input'),
                controller: quantity,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Quantity (${position.quantityUnit})',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: reason,
                decoration: const InputDecoration(labelText: 'Reason'),
                items: const [
                  DropdownMenuItem(value: 'OPENING', child: Text('Opening')),
                  DropdownMenuItem(value: 'RESTOCK', child: Text('Restock')),
                  DropdownMenuItem(
                    value: 'CORRECTION',
                    child: Text('Correction'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => reason = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('save-stock-adjustment-button'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (submitted != true || !mounted) return;
    final delta = double.tryParse(quantity.text.trim());
    if (delta == null || delta == 0) {
      _message('Enter a stock change greater or less than zero.');
      return;
    }
    await _mutate(() async {
      final updated = await widget.gateway.createStockAdjustment(
        accessToken: await widget.coordinator.accessTokenForRequest(),
        delta: delta,
        positionId: position.id,
        quantityUnit: position.quantityUnit,
        reason: reason,
      );
      _replacePosition(updated);
      _message('Estimated stock updated.');
    });
  }

  Future<void> _showThreshold(InventoryPositionSummary position) async {
    final threshold = TextEditingController(
      text: _quantity(position.lowStockThreshold),
    );
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Low-stock threshold'),
        content: TextField(
          key: const Key('low-stock-threshold-input'),
          controller: threshold,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Alert at or below (${position.quantityUnit})',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('save-low-stock-threshold-button'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (submitted != true || !mounted) return;
    final value = double.tryParse(threshold.text.trim());
    if (value == null || value < 0) {
      _message('Enter a threshold of zero or more.');
      return;
    }
    await _mutate(() async {
      final updated = await widget.gateway.updateLowStockThreshold(
        accessToken: await widget.coordinator.accessTokenForRequest(),
        expectedVersion: position.version,
        lowStockThreshold: value,
        positionId: position.id,
      );
      _replacePosition(updated);
      _message('Low-stock threshold updated.');
    });
  }

  Future<void> _mutate(Future<void> Function() operation) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await operation();
    } on InsightsFailure catch (failure) {
      _message(failure.message);
    } on Object {
      _message('Could not update estimated stock. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _replacePosition(InventoryPositionSummary updated) {
    if (!mounted) return;
    setState(() {
      _inventory = _inventory
          .map((position) => position.id == updated.id ? updated : position)
          .toList(growable: false);
    });
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MedicationOverviewCard extends StatelessWidget {
  const _MedicationOverviewCard({required this.medicationCount});

  final int medicationCount;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(
            Icons.medication_outlined,
            color: Theme.of(context).colorScheme.primary,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medication overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$medicationCount active ${medicationCount == 1 ? 'medicine' : 'medicines'} recorded',
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _IndicatorCard extends StatelessWidget {
  const _IndicatorCard({required this.indicator});

  final AdherenceIndicator indicator;

  @override
  Widget build(BuildContext context) {
    final percentage = indicator.percentage;
    final score = percentage == null
        ? '—'
        : '${percentage.toStringAsFixed(percentage % 1 == 0 ? 0 : 1)}%';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App-based adherence indicator',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              score,
              key: const Key('adherence-percentage'),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              indicator.denominator == 0
                  ? 'No completed planned doses in this period'
                  : '${indicator.numerator} of ${indicator.denominator} completed planned doses were self-reported as confirmed',
            ),
            const Divider(height: 28),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _OutcomeChip(
                  label: 'On time',
                  value: indicator.counts.onTimeConfirmed,
                ),
                _OutcomeChip(
                  label: 'Late',
                  value: indicator.counts.lateConfirmed,
                ),
                _OutcomeChip(label: 'Skipped', value: indicator.counts.skipped),
                _OutcomeChip(label: 'Missed', value: indicator.counts.missed),
                _OutcomeChip(
                  label: 'Unresolved',
                  value: indicator.counts.unresolved,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${indicator.timezone} • ${_date(indicator.from)} to ${_date(indicator.to)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              indicator.disclaimer,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _date(DateTime value) =>
      '${value.day}/${value.month}/${value.year}';
}

class _OutcomeChip extends StatelessWidget {
  const _OutcomeChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Chip(label: Text('$label $value'));
}

class _EmptyIndicatorCard extends StatelessWidget {
  const _EmptyIndicatorCard();

  @override
  Widget build(BuildContext context) => const Card(
    child: ListTile(
      leading: Icon(Icons.event_available_outlined),
      title: Text('No dose outcomes in this period'),
      subtitle: Text(
        'An app-based indicator appears after planned doses have confirmed, skipped, or missed outcomes.',
      ),
    ),
  );
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({
    required this.onAdjust,
    required this.onThreshold,
    required this.position,
    super.key,
  });

  final VoidCallback onAdjust;
  final VoidCallback onThreshold;
  final InventoryPositionSummary position;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final days = position.estimatedDaysRemaining;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  position.isLowStock
                      ? Icons.warning_amber_rounded
                      : Icons.inventory_2_outlined,
                  color: position.isLowStock ? colors.error : colors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    position.medicationName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (position.isLowStock)
                  Chip(
                    avatar: const Icon(Icons.warning_amber_rounded, size: 18),
                    label: const Text('Low stock'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${_quantity(position.estimatedQuantity)} ${position.quantityUnit}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              days == null
                  ? 'No run-out date within the current schedule forecast'
                  : 'Estimated $days ${days == 1 ? 'day' : 'days'} remaining',
            ),
            Text(
              'Low-stock threshold: ${_quantity(position.lowStockThreshold)} ${position.quantityUnit}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  key: Key('adjust-stock-${position.id}'),
                  onPressed: onAdjust,
                  icon: const Icon(Icons.add_box_outlined),
                  label: Text(
                    position.adjustments.isEmpty
                        ? 'Set opening stock'
                        : 'Adjust stock',
                  ),
                ),
                TextButton(
                  key: Key('threshold-${position.id}'),
                  onPressed: onThreshold,
                  child: const Text('Set low-stock alert'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: ListTile(
      leading: const Icon(Icons.cloud_off_outlined),
      title: Text(message),
      trailing: TextButton(onPressed: onRetry, child: const Text('Retry')),
    ),
  );
}

String _quantity(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);
