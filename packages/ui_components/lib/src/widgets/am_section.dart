import 'package:flutter/material.dart';

import '../theme/am_tokens.dart';

/// A titled card grouping related content.
class AmSection extends StatelessWidget {
  const AmSection({
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(AmTokens.spaceMd),
    super.key,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null || trailing != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          Text(title!, style: theme.textTheme.titleMedium),
                        if (subtitle != null) ...[
                          const SizedBox(height: AmTokens.spaceXs),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: AmTokens.spaceMd),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// Constrains content width on wide screens so console tables stay readable.
class AmContentFrame extends StatelessWidget {
  const AmContentFrame({
    required this.child,
    this.maxWidth = AmTokens.maxContentWidth,
    super.key,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}

/// A labelled metric for the dashboards.
class AmMetricTile extends StatelessWidget {
  const AmMetricTile({
    required this.label,
    required this.value,
    this.tone,
    this.icon,
    super.key,
  });

  final String label;
  final String value;
  final Color? tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AmTokens.spaceMd),
      decoration: BoxDecoration(
        color: AmTokens.surface,
        borderRadius: BorderRadius.circular(AmTokens.radiusMedium),
        border: Border.all(color: AmTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: tone ?? AmTokens.textSecondary),
                const SizedBox(width: AmTokens.spaceXs),
              ],
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AmTokens.spaceSm),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: tone ?? AmTokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
