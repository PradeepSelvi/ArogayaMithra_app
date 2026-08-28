import 'package:flutter/material.dart';

import '../theme/am_tokens.dart';

/// A large primary action for the citizen and field apps.
///
/// Sized well above the minimum touch target and always paired with an icon, so
/// it stays usable for someone who cannot read the label.
class AmBigButton extends StatelessWidget {
  const AmBigButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.subtitle,
    this.isEmergency = false,
    this.isBusy = false,
    super.key,
  });

  /// The emergency action.
  ///
  /// Visually separated from every other action, because PRD 16 requires urgent
  /// action to be unmistakable next to general information.
  const AmBigButton.emergency({
    required this.label,
    required this.onPressed,
    this.subtitle,
    this.isBusy = false,
    super.key,
  })  : icon = Icons.emergency,
        isEmergency = true;

  final String label;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isEmergency;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = isEmergency ? AmTokens.emergency : AmTokens.primary;
    final isEnabled = onPressed != null && !isBusy;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: subtitle == null ? label : '$label. $subtitle',
      child: ExcludeSemantics(
        child: Material(
          color: isEnabled ? background : AmTokens.border,
          borderRadius: BorderRadius.circular(AmTokens.radiusLarge),
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            borderRadius: BorderRadius.circular(AmTokens.radiusLarge),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: AmTokens.largeTouchTarget,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AmTokens.spaceLg,
                vertical: AmTokens.spaceMd,
              ),
              child: Row(
                children: [
                  if (isBusy)
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  else
                    Icon(icon, size: 32, color: Colors.white),
                  const SizedBox(width: AmTokens.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: AmTokens.spaceXs),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
