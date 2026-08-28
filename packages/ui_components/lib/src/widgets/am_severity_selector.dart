import 'package:am_localization/am_localization.dart';
import 'package:flutter/material.dart';

import '../theme/am_tokens.dart';

/// Self-reported severity, 1 to 5.
///
/// Severity is what separates a self-care outcome from an escalation in the
/// triage rules, so the control is explicit and unavoidable rather than a slider
/// with a hidden default. Each step carries a word, not just a number.
class AmSeveritySelector extends StatelessWidget {
  const AmSeveritySelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final int? value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AmStrings.of(context);
    final labels = <int, String>{
      1: strings.severity1,
      2: strings.severity2,
      3: strings.severity3,
      4: strings.severity4,
      5: strings.severity5,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in labels.entries) ...[
          _SeverityOption(
            level: entry.key,
            label: entry.value,
            isSelected: value == entry.key,
            onTap: () => onChanged(entry.key),
          ),
          if (entry.key != labels.length)
            const SizedBox(height: AmTokens.spaceSm),
        ],
      ],
    );
  }
}

class _SeverityOption extends StatelessWidget {
  const _SeverityOption({
    required this.level,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final int level;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Severity 4 and 5 shade toward the emergency palette so the user sees that
    // these answers carry weight before they pick one.
    final tone = switch (level) {
      1 || 2 => AmTokens.success,
      3 => AmTokens.warning,
      _ => AmTokens.emergency,
    };

    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: isSelected,
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: isSelected ? tone.withValues(alpha: 0.12) : AmTokens.surface,
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
                  color: isSelected ? tone : AmTokens.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tone,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$level',
                      style: theme.textTheme.labelLarge
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: AmTokens.spaceMd),
                  Expanded(
                    child: Text(label, style: theme.textTheme.bodyLarge),
                  ),
                  if (isSelected) Icon(Icons.check_circle, color: tone),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
