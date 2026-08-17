import 'package:caremate/app/design/caremate_tokens.dart';
import 'package:flutter/material.dart';

class CareMateEmptyState extends StatelessWidget {
  const CareMateEmptyState({
    required this.icon,
    required this.message,
    required this.title,
    this.actionIcon,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData? actionIcon;
  final String? actionLabel;
  final IconData icon;
  final String message;
  final VoidCallback? onAction;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(CareMateSpacing.xl),
        child: Semantics(
          container: true,
          label: '$title. $message',
          child: ExcludeSemantics(
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(CareMateRadii.large),
                  ),
                  child: Icon(icon, color: colors.onPrimaryContainer, size: 32),
                ),
                const SizedBox(height: CareMateSpacing.md),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: CareMateSpacing.xs),
                Text(message, textAlign: TextAlign.center),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: CareMateSpacing.lg),
                  FilledButton.icon(
                    onPressed: onAction,
                    icon: Icon(actionIcon ?? Icons.arrow_forward),
                    label: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
