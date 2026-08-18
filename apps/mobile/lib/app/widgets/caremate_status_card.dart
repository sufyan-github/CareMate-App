import 'package:caremate/app/design/caremate_tokens.dart';
import 'package:flutter/material.dart';

enum CareMateStatusTone { info, success, warning, error, offline }

class CareMateStatusCard extends StatelessWidget {
  const CareMateStatusCard({
    required this.message,
    required this.title,
    this.actionKey,
    this.actionLabel,
    this.icon,
    this.liveRegion = false,
    this.onAction,
    this.prominentAction = false,
    this.tone = CareMateStatusTone.info,
    super.key,
  });

  final Key? actionKey;
  final String? actionLabel;
  final IconData? icon;
  final bool liveRegion;
  final String message;
  final VoidCallback? onAction;
  final bool prominentAction;
  final String title;
  final CareMateStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = _palette(Theme.of(context).colorScheme);
    return Semantics(
      container: true,
      liveRegion: liveRegion,
      label: '$title. $message',
      child: Card(
        color: palette.background,
        child: Padding(
          padding: const EdgeInsets.all(CareMateSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: CareMateLayout.minTouchTarget,
                  height: CareMateLayout.minTouchTarget,
                  decoration: BoxDecoration(
                    color: palette.iconBackground,
                    borderRadius: BorderRadius.circular(CareMateRadii.medium),
                  ),
                  child: Icon(icon ?? _defaultIcon, color: palette.foreground),
                ),
              ),
              const SizedBox(width: CareMateSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: palette.foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: CareMateSpacing.xxs),
                    ExcludeSemantics(
                      child: Text(
                        message,
                        style: TextStyle(color: palette.foreground),
                      ),
                    ),
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(height: CareMateSpacing.sm),
                      if (prominentAction)
                        FilledButton(
                          key: actionKey,
                          onPressed: onAction,
                          child: Text(actionLabel!),
                        )
                      else
                        OutlinedButton(
                          key: actionKey,
                          onPressed: onAction,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: palette.foreground,
                            side: BorderSide(color: palette.foreground),
                          ),
                          child: Text(actionLabel!),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _defaultIcon => switch (tone) {
    CareMateStatusTone.info => Icons.info_outline,
    CareMateStatusTone.success => Icons.check_circle_outline,
    CareMateStatusTone.warning => Icons.warning_amber_rounded,
    CareMateStatusTone.error => Icons.error_outline,
    CareMateStatusTone.offline => Icons.cloud_off_outlined,
  };

  _StatusPalette _palette(ColorScheme colors) => switch (tone) {
    CareMateStatusTone.info => _StatusPalette(
      background: colors.secondaryContainer,
      foreground: colors.onSecondaryContainer,
      iconBackground: colors.secondary.withValues(alpha: 0.14),
    ),
    CareMateStatusTone.success => _StatusPalette(
      background: colors.primaryContainer,
      foreground: colors.onPrimaryContainer,
      iconBackground: colors.primary.withValues(alpha: 0.14),
    ),
    CareMateStatusTone.warning => _StatusPalette(
      background: colors.tertiaryContainer,
      foreground: colors.onTertiaryContainer,
      iconBackground: colors.tertiary.withValues(alpha: 0.14),
    ),
    CareMateStatusTone.error => _StatusPalette(
      background: colors.errorContainer,
      foreground: colors.onErrorContainer,
      iconBackground: colors.error.withValues(alpha: 0.14),
    ),
    CareMateStatusTone.offline => _StatusPalette(
      background: colors.surfaceContainerHighest,
      foreground: colors.onSurface,
      iconBackground: colors.onSurface.withValues(alpha: 0.10),
    ),
  };
}

class _StatusPalette {
  const _StatusPalette({
    required this.background,
    required this.foreground,
    required this.iconBackground,
  });

  final Color background;
  final Color foreground;
  final Color iconBackground;
}
