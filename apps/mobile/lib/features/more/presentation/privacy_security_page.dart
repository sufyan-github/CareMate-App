import 'package:flutter/material.dart';

class PrivacySecurityPage extends StatefulWidget {
  const PrivacySecurityPage({super.key});

  @override
  State<PrivacySecurityPage> createState() => _PrivacySecurityPageState();
}

class _PrivacySecurityPageState extends State<PrivacySecurityPage> {
  bool _showMedicineOnLockScreen = false;
  bool _allowAnalytics = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy and security')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Your privacy controls',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _showMedicineOnLockScreen,
              onChanged: (value) =>
                  setState(() => _showMedicineOnLockScreen = value),
              title: const Text('Show medicine details on lock screen'),
              subtitle: const Text(
                'Off keeps reminder text private by default.',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _allowAnalytics,
              onChanged: (value) => setState(() => _allowAnalytics = value),
              title: const Text('Share optional usage analytics'),
              subtitle: const Text(
                'Medical details and prescription images are never included.',
              ),
            ),
            const Divider(height: 32),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.lock_outline),
              title: Text('Secure session storage'),
              subtitle: Text(
                'Refresh credentials are stored using Android secure storage.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
