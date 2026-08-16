import 'package:caremate/features/shell/presentation/segment_placeholder.dart';
import 'package:flutter/material.dart';

class CarePage extends StatelessWidget {
  const CarePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SegmentPlaceholder(
      icon: Icons.people_outline,
      title: 'Care circle',
      description:
          'Invite a trusted caregiver and choose exactly what they can see.',
    );
  }
}
