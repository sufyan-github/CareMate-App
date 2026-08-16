import 'package:flutter/material.dart';

class CarePage extends StatelessWidget {
  const CarePage({required this.onInvite, super.key});

  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            'Care circle',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Share only the information you choose with a trusted caregiver.',
          ),
          const SizedBox(height: 28),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No caregivers connected',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'An invitation must be accepted before anyone can see your information. You can revoke access later.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onInvite,
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('Invite caregiver'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
