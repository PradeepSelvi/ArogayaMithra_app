import 'package:flutter/material.dart';

import '../theme/am_tokens.dart';

/// Severity of an inline message.
enum AmBannerTone { emergency, warning, info, success }

/// An inline message.
///
/// Used for the things the platform must never let a user miss: an emergency
/// instruction, a stale-readiness warning before travelling, or a note that a
/// mock adapter is in use instead of a real dispatch.
class AmBanner extends StatelessWidget {
  const AmBanner({
    required this.message,
    required this.tone,
    this.title,
    this.icon,
    this.action,
    super.key,
  });

  const AmBanner.emergency({
    required this.message,
    this.title,
    this.action,
    super.key,
  })  : tone = AmBannerTone.emergency,
        icon = Icons.emergency;

  const AmBanner.warning({
    required this.message,
    this.title,
    this.action,
    super.key,
  })  : tone = AmBannerTone.warning,
        icon = Icons.warning_amber_rounded;

  const AmBanner.info({
    required this.message,
    this.title,
    this.action,
    super.key,
  })  : tone = AmBannerTone.info,
        icon = Icons.info_outline;

  final String message;
  final String? title;
  final AmBannerTone tone;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (foreground, background) = switch (tone) {
      AmBannerTone.emergency => (AmTokens.emergency, AmTokens.emergencyLight),
      AmBannerTone.warning => (AmTokens.warning, AmTokens.warningLight),
      AmBannerTone.info => (AmTokens.info, AmTokens.infoLight),
      AmBannerTone.success => (AmTokens.success, AmTokens.successLight),
    };

    return Semantics(
      liveRegion: tone == AmBannerTone.emergency,
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AmTokens.spaceMd),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AmTokens.radiusMedium),
          border: Border.all(color: foreground.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon ?? Icons.info_outline, color: foreground, size: 26),
            const SizedBox(width: AmTokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(
                      title!,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: foreground),
                    ),
                    const SizedBox(height: AmTokens.spaceXs),
                  ],
                  Text(
                    message,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: AmTokens.textPrimary),
                  ),
                  if (action != null) ...[
                    const SizedBox(height: AmTokens.spaceMd),
                    action!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
