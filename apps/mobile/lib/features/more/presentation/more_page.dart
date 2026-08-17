import 'package:caremate/app/preferences/caremate_preferences.dart';
import 'package:caremate/features/more/presentation/devices_page.dart';
import 'package:caremate/features/more/presentation/language_page.dart';
import 'package:caremate/features/more/presentation/privacy_security_page.dart';
import 'package:caremate/features/more/domain/account_settings_gateway.dart';
import 'package:flutter/material.dart';

class MorePage extends StatelessWidget {
  const MorePage({
    required this.accessToken,
    required this.gateway,
    required this.onLogout,
    super.key,
  });

  final String accessToken;
  final AccountSettingsGateway gateway;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final copy = CareMateStrings.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text(
          copy.pick('Settings and support', 'সেটিংস ও সহায়তা'),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                key: const Key('language-settings-tile'),
                leading: const Icon(Icons.translate),
                title: Text(copy.pick('Language', 'ভাষা')),
                subtitle: const Text('বাংলা and English'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => LanguagePage(
                      accessToken: accessToken,
                      gateway: gateway,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                key: const Key('devices-settings-tile'),
                leading: const Icon(Icons.devices_outlined),
                title: Text(copy.pick('Devices and sessions', 'ডিভাইস ও সেশন')),
                subtitle: Text(
                  copy.pick(
                    'Review where you are signed in',
                    'কোথায় সাইন ইন করা আছে দেখুন',
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => DevicesPage(
                      accessToken: accessToken,
                      gateway: gateway,
                      onLogout: onLogout,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                key: const Key('privacy-settings-tile'),
                leading: const Icon(Icons.shield_outlined),
                title: Text(
                  copy.pick('Privacy and security', 'গোপনীয়তা ও নিরাপত্তা'),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => PrivacySecurityPage(
                      accessToken: accessToken,
                      gateway: gateway,
                      onLogout: onLogout,
                    ),
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
          label: Text(
            copy.pick('Sign out of this device', 'এই ডিভাইস থেকে সাইন আউট'),
          ),
        ),
      ],
    );
  }
}
