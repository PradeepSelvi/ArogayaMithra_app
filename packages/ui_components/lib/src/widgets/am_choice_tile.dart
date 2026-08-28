import 'package:flutter/material.dart';

import '../theme/am_tokens.dart';

/// A large multi-select tile, used for the symptom grid and condition pickers.
class AmChoiceTile extends StatelessWidget {
  const AmChoiceTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.subtitle,
    super.key,
  });

  final String label;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: isSelected ? AmTokens.primaryLight : AmTokens.surface,
          borderRadius: BorderRadius.circular(AmTokens.radiusMedium),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AmTokens.radiusMedium),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: AmTokens.minTouchTarget,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AmTokens.spaceMd,
                vertical: AmTokens.spaceSm,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AmTokens.radiusMedium),
                border: Border.all(
                  color: isSelected ? AmTokens.primary : AmTokens.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: isSelected ? AmTokens.primary : AmTokens.textSecondary,
                    size: 26,
                  ),
                  const SizedBox(width: AmTokens.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label, style: theme.textTheme.bodyLarge),
                        if (subtitle != null)
                          Text(subtitle!, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single-select row, used for sex, language and category pickers.
class AmRadioTile<T> extends StatelessWidget {
  const AmRadioTile({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.subtitle,
    super.key,
  });

  final String label;
  final String? subtitle;
  final T value;
  final T? groupValue;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = value == groupValue;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: isSelected,
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: isSelected ? AmTokens.primaryLight : AmTokens.surface,
          borderRadius: BorderRadius.circular(AmTokens.radiusMedium),
          child: InkWell(
            onTap: () => onChanged(value),
            borderRadius: BorderRadius.circular(AmTokens.radiusMedium),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: AmTokens.minTouchTarget,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AmTokens.spaceMd,
                vertical: AmTokens.spaceSm,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AmTokens.radiusMedium),
                border: Border.all(
                  color: isSelected ? AmTokens.primary : AmTokens.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color:
                        isSelected ? AmTokens.primary : AmTokens.textSecondary,
                    size: 26,
                  ),
                  const SizedBox(width: AmTokens.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label, style: theme.textTheme.bodyLarge),
                        if (subtitle != null)
                          Text(subtitle!, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
