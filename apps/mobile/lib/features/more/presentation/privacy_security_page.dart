import 'package:caremate/features/more/domain/account_settings_gateway.dart';
import 'package:flutter/material.dart';

class PrivacySecurityPage extends StatefulWidget {
  const PrivacySecurityPage({
    required this.accessToken,
    required this.gateway,
    required this.onLogout,
    super.key,
  });

  final String accessToken;
  final AccountSettingsGateway gateway;
  final Future<void> Function() onLogout;

  @override
  State<PrivacySecurityPage> createState() => _PrivacySecurityPageState();
}

class _PrivacySecurityPageState extends State<PrivacySecurityPage> {
  AccountPreferences? _preferences;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final preferences = _preferences;
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy and security')),
      body: SafeArea(
        child: preferences == null && _error == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Your privacy controls',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_error case final message?) ...[
                    const SizedBox(height: 12),
                    Text(
                      message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _load,
                      child: const Text('Try again'),
                    ),
                  ],
                  if (preferences != null) ...[
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: preferences.showMedicineOnLockScreen,
                      onChanged: _saving
                          ? null
                          : (value) => _update(showMedicineOnLockScreen: value),
                      title: const Text('Show medicine details on lock screen'),
                      subtitle: const Text(
                        'Off keeps future reminder text private by default.',
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: preferences.allowAnalytics,
                      onChanged: _saving
                          ? null
                          : (value) => _update(allowAnalytics: value),
                      title: const Text('Share optional usage analytics'),
                      subtitle: const Text(
                        'Medical details and prescription images are never included.',
                      ),
                    ),
                  ],
                  if (_saving) const LinearProgressIndicator(),
                  const Divider(height: 32),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.lock_outline),
                    title: Text('Secure session storage'),
                    subtitle: Text(
                      'Refresh credentials are stored using Android secure storage.',
                    ),
                  ),
                  const Divider(height: 32),
                  Text(
                    'Account deletion',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'A deletion request immediately signs out every device and revokes caregiver access. Data removal then follows the published retention process.',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const Key('request-account-deletion-button'),
                    onPressed: _requestDeletion,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Request account deletion'),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final preferences = await widget.gateway.getPreferences(
        widget.accessToken,
      );
      if (mounted) setState(() => _preferences = preferences);
    } on AccountSettingsFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    }
  }

  Future<void> _update({
    bool? allowAnalytics,
    bool? showMedicineOnLockScreen,
  }) async {
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      final updated = await widget.gateway.updatePreferences(
        accessToken: widget.accessToken,
        allowAnalytics: allowAnalytics,
        showMedicineOnLockScreen: showMedicineOnLockScreen,
      );
      if (mounted) setState(() => _preferences = updated);
    } on AccountSettingsFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _requestDeletion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _DeletionConfirmationDialog(),
    );
    if (confirmed != true) return;
    try {
      await widget.gateway.requestAccountDeletion(widget.accessToken);
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      await widget.onLogout();
    } on AccountSettingsFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    }
  }
}

class _DeletionConfirmationDialog extends StatefulWidget {
  const _DeletionConfirmationDialog();

  @override
  State<_DeletionConfirmationDialog> createState() =>
      _DeletionConfirmationDialogState();
}

class _DeletionConfirmationDialogState
    extends State<_DeletionConfirmationDialog> {
  final _controller = TextEditingController();
  bool _matches = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Request account deletion?'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This signs out all devices and revokes sharing immediately. Type DELETE to confirm.',
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('account-deletion-confirmation-input'),
            controller: _controller,
            autocorrect: false,
            onChanged: (value) => setState(() => _matches = value == 'DELETE'),
            decoration: const InputDecoration(labelText: 'DELETE'),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('confirm-account-deletion-button'),
        onPressed: _matches ? () => Navigator.pop(context, true) : null,
        child: const Text('Request deletion'),
      ),
    ],
  );
}
