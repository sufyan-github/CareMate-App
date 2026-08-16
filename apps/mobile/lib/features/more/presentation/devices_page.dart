import 'package:flutter/material.dart';

class DevicesPage extends StatelessWidget {
  const DevicesPage({required this.onLogout, super.key});

  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signed-in devices')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Card(
              child: ListTile(
                leading: CircleAvatar(child: Icon(Icons.phone_android)),
                title: Text('This device'),
                subtitle: Text('Current CareMate session'),
                trailing: Chip(label: Text('Active')),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await onLogout();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign out this device'),
            ),
          ],
        ),
      ),
    );
  }
}
