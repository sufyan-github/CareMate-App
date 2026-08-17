import 'package:caremate/features/more/domain/account_settings_gateway.dart';
import 'package:flutter/material.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({
    required this.accessToken,
    required this.gateway,
    required this.onLogout,
    super.key,
  });

  final String accessToken;
  final AccountSettingsGateway gateway;
  final Future<void> Function() onLogout;

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  List<DeviceSession>? _sessions;
  String? _busyId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signed-in devices')),
      body: SafeArea(
        child: _sessions == null && _error == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_error case final message?) ...[
                      Text(
                        message,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _load,
                        child: const Text('Try again'),
                      ),
                    ],
                    for (final session in _sessions ?? const <DeviceSession>[])
                      Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          leading: const CircleAvatar(
                            child: Icon(Icons.phone_android),
                          ),
                          title: Text(session.deviceName),
                          subtitle: Text(
                            '${session.platform} • CareMate ${session.appVersion}\nLast active ${_lastSeen(session.lastSeenAt)}',
                          ),
                          isThreeLine: true,
                          trailing: session.status == 'REVOKED'
                              ? const Chip(label: Text('Signed out'))
                              : session.current
                              ? const Chip(label: Text('This device'))
                              : TextButton(
                                  onPressed: _busyId == null
                                      ? () => _revoke(session)
                                      : null,
                                  child: Text(
                                    _busyId == session.id
                                        ? 'Signing out…'
                                        : 'Sign out',
                                  ),
                                ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _signOutCurrent,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign out this device'),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.tonalIcon(
                      key: const Key('sign-out-all-devices-button'),
                      onPressed: _signOutAll,
                      icon: const Icon(Icons.phonelink_erase_outlined),
                      label: const Text('Sign out all devices'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final sessions = await widget.gateway.listSessions(widget.accessToken);
      if (mounted) setState(() => _sessions = sessions);
    } on AccountSettingsFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    }
  }

  Future<void> _revoke(DeviceSession session) async {
    setState(() => _busyId = session.id);
    try {
      await widget.gateway.revokeSession(
        accessToken: widget.accessToken,
        sessionId: session.id,
      );
      await _load();
    } on AccountSettingsFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _signOutCurrent() async {
    Navigator.pop(context);
    await widget.onLogout();
  }

  Future<void> _signOutAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out all devices?'),
        content: const Text(
          'Every CareMate session, including this device, will need a new verification code.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-sign-out-all-button'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out all'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.gateway.logoutAll(widget.accessToken);
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      await widget.onLogout();
    } on AccountSettingsFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    }
  }

  String _lastSeen(DateTime value) {
    final local = value.toLocal();
    final date =
        '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}
