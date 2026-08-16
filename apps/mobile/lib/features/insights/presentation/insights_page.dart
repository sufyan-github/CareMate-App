import 'package:caremate/features/shell/presentation/segment_placeholder.dart';
import 'package:flutter/material.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SegmentPlaceholder(
      icon: Icons.insights_outlined,
      title: 'Your insights',
      description:
          'Self-reported dose outcomes and inventory trends will appear here.',
    );
  }
}
