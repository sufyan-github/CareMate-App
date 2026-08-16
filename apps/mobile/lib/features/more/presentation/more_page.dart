import 'package:caremate/features/shell/presentation/segment_placeholder.dart';
import 'package:flutter/material.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SegmentPlaceholder(
      icon: Icons.settings_outlined,
      title: 'Settings and support',
      description:
          'Manage language, accessibility, privacy, subscription, and help.',
    );
  }
}
