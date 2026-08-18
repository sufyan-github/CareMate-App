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
              SwitchListTile(
                key: const Key('simple-mode-setting'),
                secondary: const Icon(Icons.visibility_outlined),
                value: CareMatePreferencesScope.of(context).simpleMode,
                onChanged: (enabled) => _setSimpleMode(context, enabled),
                title: Text(copy.pick('Simple Mode', 'বড় মোড')),
                subtitle: Text(
                  copy.pick(
                    'One dose at a time with large pictures and actions',
                    'বড় ছবি ও বোতামে একবারে একটি ডোজ দেখুন',
                  ),
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                key: const Key('voice-prompts-setting'),
                secondary: const Icon(Icons.volume_up_outlined),
                value: CareMatePreferencesScope.of(context).voicePromptsEnabled,
                onChanged: (enabled) => _setVoicePrompts(context, enabled),
                title: Text(copy.pick('Bangla voice', 'বাংলা কণ্ঠ')),
                subtitle: Text(
                  copy.pick(
                    'Read the selected dose aloud on this phone',
                    'এই ফোনে নির্বাচিত ডোজটি শুনুন',
                  ),
                ),
              ),
            ],
          ),
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

  Future<void> _setSimpleMode(BuildContext context, bool enabled) async {
    final preferences = CareMatePreferencesScope.of(context);
    final accountSave = gateway.updatePreferences(
      accessToken: accessToken,
      simpleMode: enabled,
    );
    await preferences.setSimpleMode(enabled);
    try {
      final saved = await accountSave;
      await preferences.setSimpleMode(saved.simpleMode);
    } on AccountSettingsFailure catch (failure) {
      await preferences.setSimpleMode(!enabled);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _setVoicePrompts(BuildContext context, bool enabled) async {
    final preferences = CareMatePreferencesScope.of(context);
    final accountSave = gateway.updatePreferences(
      accessToken: accessToken,
      voicePromptsEnabled: enabled,
    );
    await preferences.setVoicePromptsEnabled(enabled);
    try {
      final saved = await accountSave;
      await preferences.setVoicePromptsEnabled(saved.voicePromptsEnabled);
    } on AccountSettingsFailure catch (failure) {
      await preferences.setVoicePromptsEnabled(!enabled);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }
}
