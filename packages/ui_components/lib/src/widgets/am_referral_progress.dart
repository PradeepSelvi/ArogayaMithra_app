import 'package:am_localization/am_localization.dart';
import 'package:am_models/am_models.dart';
import 'package:flutter/material.dart';

import '../theme/am_tokens.dart';
import 'am_status_chip.dart';

/// Citizen-facing referral tracker.
///
/// Exception states (rejected, cancelled, expired, no-show, emergency) are not
/// forced onto the linear path: showing "step 4 of 9" for a rejected referral
/// would imply progress that is not happening. Those states get an explicit
/// status chip instead.
class AmReferralProgress extends StatelessWidget {
  const AmReferralProgress({required this.status, super.key});

  final ReferralStatus status;

  /// Steps shown to the citizen. The database tracks finer detail; this is the
  /// journey as the person experiences it.
  static const _visibleSteps = <ReferralStatus>[
    ReferralStatus.referralSent,
    ReferralStatus.accepted,
    ReferralStatus.patientTravelling,
    ReferralStatus.arrived,
    ReferralStatus.completed,
  ];

  @override
  Widget build(BuildContext context) {
    final strings = AmStrings.of(context);

    final currentIndex = status.progressIndex;
    if (currentIndex == null || status.isClosed && status != ReferralStatus.completed) {
      return AmStatusChip.referral(status, strings: strings);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _visibleSteps.length; i++)
          _Step(
            label: AmStatusChip.referralStatusLabel(_visibleSteps[i], strings),
            isDone: _isReached(_visibleSteps[i]),
            isCurrent: _isCurrent(_visibleSteps[i]),
            isLast: i == _visibleSteps.length - 1,
          ),
      ],
    );
  }

  bool _isReached(ReferralStatus step) {
    final stepIndex = ReferralStatus.happyPath.indexOf(step);
    final currentIndex = status.progressIndex ?? -1;
    return currentIndex >= stepIndex;
  }

  bool _isCurrent(ReferralStatus step) {
    // Consultation is folded into "arrived" for the citizen view.
    if (status == ReferralStatus.consultation) {
      return step == ReferralStatus.arrived;
    }
    if (status == ReferralStatus.recommended ||
        status == ReferralStatus.triaged ||
        status == ReferralStatus.created) {
      return step == ReferralStatus.referralSent;
    }
    return step == status;
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
  });

  final String label;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = isDone ? AmTokens.primary : AmTokens.border;

    return Semantics(
      label: label,
      value: isDone ? 'done' : 'pending',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDone ? AmTokens.primary : AmTokens.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: tone, width: 2),
                  ),
                  child: isDone
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Container(width: 2, height: 28, color: tone),
              ],
            ),
            const SizedBox(width: AmTokens.spaceMd),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2, bottom: AmTokens.spaceMd),
                child: Text(
                  label,
                  style: isCurrent
                      ? theme.textTheme.titleMedium
                      : theme.textTheme.bodyLarge?.copyWith(
                          color: isDone
                              ? AmTokens.textPrimary
                              : AmTokens.textSecondary,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
