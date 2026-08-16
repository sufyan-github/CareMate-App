import 'package:flutter/material.dart';

class MorePage extends StatelessWidget {
  const MorePage({required this.onLogout, super.key});

  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text(
          'Settings and support',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        const Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.translate),
                title: Text('Language'),
                subtitle: Text('বাংলা and English'),
                trailing: Icon(Icons.chevron_right),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.devices_outlined),
                title: Text('Devices and sessions'),
                subtitle: Text('Review where you are signed in'),
                trailing: Icon(Icons.chevron_right),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.shield_outlined),
                title: Text('Privacy and security'),
                trailing: Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout),
          label: const Text('Sign out of this device'),
        ),
      ],
    );
  }
}
