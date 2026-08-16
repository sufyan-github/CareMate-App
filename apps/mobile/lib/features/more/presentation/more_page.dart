import 'package:caremate/features/more/presentation/devices_page.dart';
import 'package:caremate/features/more/presentation/language_page.dart';
import 'package:caremate/features/more/presentation/privacy_security_page.dart';
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
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.translate),
                title: const Text('Language'),
                subtitle: const Text('বাংলা and English'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const LanguagePage()),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.devices_outlined),
                title: const Text('Devices and sessions'),
                subtitle: const Text('Review where you are signed in'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => DevicesPage(onLogout: onLogout),
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: const Text('Privacy and security'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const PrivacySecurityPage(),
                  ),
                ),
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
