import 'package:am_localization/am_localization.dart';
import 'package:am_models/am_models.dart';
import 'package:flutter/material.dart';

import '../theme/am_tokens.dart';

/// Status pill.
///
/// Always renders an icon and a text label alongside the colour. Colour alone
/// would fail for a colour-blind user and washes out in sunlight, and "medicines
/// unavailable" is not something anyone should have to infer from a hue.
class AmStatusChip extends StatelessWidget {
  const AmStatusChip({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
    this.dense = false,
    super.key,
  });

  /// Readiness component status (PRD 12.3).
  factory AmStatusChip.availability(
    AvailabilityStatus status, {
    required AmStrings strings,
    bool dense = false,
  }) {
    return switch (status) {
      AvailabilityStatus.available => AmStatusChip(
          label: strings.availabilityAvailable,
          icon: Icons.check_circle_outline,
          foreground: AmTokens.success,
          background: AmTokens.successLight,
          dense: dense,
        ),
      AvailabilityStatus.limited => AmStatusChip(
          label: strings.availabilityLimited,
          icon: Icons.error_outline,
          foreground: AmTokens.warning,
          background: AmTokens.warningLight,
          dense: dense,
        ),
      AvailabilityStatus.unavailable => AmStatusChip(
          label: strings.availabilityUnavailable,
          icon: Icons.cancel_outlined,
          foreground: AmTokens.emergency,
          background: AmTokens.emergencyLight,
          dense: dense,
        ),
      // Never green. Unreported is not the same as available.
      AvailabilityStatus.unknown => AmStatusChip(
          label: strings.availabilityUnknown,
          icon: Icons.help_outline,
          foreground: AmTokens.unknown,
          background: AmTokens.unknownLight,
          dense: dense,
        ),
    };
  }

  /// Readiness band for the heatmap (PRD 5.4).
  factory AmStatusChip.readinessBand(
    ReadinessBand band, {
    required AmStrings strings,
    bool dense = false,
  }) {
    return switch (band) {
      ReadinessBand.good => AmStatusChip(
          label: strings.readinessBandGood,
          icon: Icons.verified_outlined,
          foreground: AmTokens.success,
          background: AmTokens.successLight,
          dense: dense,
        ),
      ReadinessBand.partial => AmStatusChip(
          label: strings.readinessBandPartial,
          icon: Icons.error_outline,
          foreground: AmTokens.warning,
          background: AmTokens.warningLight,
          dense: dense,
        ),
      ReadinessBand.critical => AmStatusChip(
          label: strings.readinessBandCritical,
          icon: Icons.report_problem_outlined,
          foreground: AmTokens.emergency,
          background: AmTokens.emergencyLight,
          dense: dense,
        ),
      ReadinessBand.stale => AmStatusChip(
          label: strings.readinessBandStale,
          icon: Icons.schedule,
          foreground: AmTokens.unknown,
          background: AmTokens.unknownLight,
          dense: dense,
        ),
    };
  }

  /// Referral status, using the citizen-facing wording.
  factory AmStatusChip.referral(
    ReferralStatus status, {
    required AmStrings strings,
    bool dense = false,
  }) {
    final label = referralStatusLabel(status, strings);

    return switch (status) {
      ReferralStatus.completed => AmStatusChip(
          label: label,
          icon: Icons.task_alt,
          foreground: AmTokens.success,
          background: AmTokens.successLight,
          dense: dense,
        ),
      ReferralStatus.emergencyEscalated => AmStatusChip(
          label: label,
          icon: Icons.emergency_outlined,
          foreground: AmTokens.emergency,
          background: AmTokens.emergencyLight,
          dense: dense,
        ),
      ReferralStatus.rejected ||
      ReferralStatus.expired ||
      ReferralStatus.noShow =>
        AmStatusChip(
          label: label,
          icon: Icons.report_problem_outlined,
          foreground: AmTokens.emergency,
          background: AmTokens.emergencyLight,
          dense: dense,
        ),
      ReferralStatus.cancelled => AmStatusChip(
          label: label,
          icon: Icons.block,
          foreground: AmTokens.unknown,
          background: AmTokens.unknownLight,
          dense: dense,
        ),
      ReferralStatus.referralSent => AmStatusChip(
          label: label,
          icon: Icons.hourglass_top,
          foreground: AmTokens.warning,
          background: AmTokens.warningLight,
          dense: dense,
        ),
      _ => AmStatusChip(
          label: label,
          icon: Icons.timeline,
          foreground: AmTokens.info,
          background: AmTokens.infoLight,
          dense: dense,
        ),
    };
  }

  /// Referral priority.
  factory AmStatusChip.priority(
    ReferralPriority priority, {
    required AmStrings strings,
    bool dense = false,
  }) {
    return switch (priority) {
      ReferralPriority.emergency => AmStatusChip(
          label: strings.referralPriorityEmergency,
          icon: Icons.emergency_outlined,
          foreground: AmTokens.emergency,
          background: AmTokens.emergencyLight,
          dense: dense,
        ),
      ReferralPriority.urgent => AmStatusChip(
          label: strings.referralPriorityUrgent,
          icon: Icons.priority_high,
          foreground: AmTokens.warning,
          background: AmTokens.warningLight,
          dense: dense,
        ),
      ReferralPriority.routine => AmStatusChip(
          label: strings.referralPriorityRoutine,
          icon: Icons.schedule,
          foreground: AmTokens.unknown,
          background: AmTokens.unknownLight,
          dense: dense,
        ),
    };
  }

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;
  final bool dense;

  /// Citizen-facing wording for a referral state.
  static String referralStatusLabel(
    ReferralStatus status,
    AmStrings strings,
  ) =>
      switch (status) {
        ReferralStatus.created => strings.referralStatusCreated,
        ReferralStatus.triaged => strings.referralStatusTriaged,
        ReferralStatus.recommended => strings.referralStatusRecommended,
        ReferralStatus.referralSent => strings.referralStatusReferralSent,
        ReferralStatus.accepted => strings.referralStatusAccepted,
        ReferralStatus.patientTravelling =>
          strings.referralStatusPatientTravelling,
        ReferralStatus.arrived => strings.referralStatusArrived,
        ReferralStatus.consultation => strings.referralStatusConsultation,
        ReferralStatus.completed => strings.referralStatusCompleted,
        ReferralStatus.rejected => strings.referralStatusRejected,
        ReferralStatus.cancelled => strings.referralStatusCancelled,
        ReferralStatus.expired => strings.referralStatusExpired,
        ReferralStatus.noShow => strings.referralStatusNoShow,
        ReferralStatus.emergencyEscalated =>
          strings.referralStatusEmergencyEscalated,
      };

  /// Localised risk level label.
  static String riskLabel(RiskLevel risk, AmStrings strings) => switch (risk) {
        RiskLevel.low => strings.riskLow,
        RiskLevel.medium => strings.riskMedium,
        RiskLevel.high => strings.riskHigh,
        RiskLevel.emergency => strings.riskEmergency,
      };

  /// Localised next-action label.
  static String nextActionLabel(NextAction action, AmStrings strings) =>
      switch (action) {
        NextAction.selfCare => strings.nextActionSelfCare,
        NextAction.visitFacility => strings.nextActionVisitFacility,
        NextAction.teleconsult => strings.nextActionTeleconsult,
        NextAction.refer => strings.nextActionRefer,
        NextAction.emergencyResponse => strings.nextActionEmergencyResponse,
      };

  @override
  Widget build(BuildContext context) {
    final textStyle = dense
        ? Theme.of(context).textTheme.bodySmall
        : Theme.of(context).textTheme.labelMedium;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AmTokens.spaceSm : AmTokens.spaceMd,
        vertical: dense ? AmTokens.spaceXs : AmTokens.spaceSm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AmTokens.radiusSmall),
        border: Border.all(color: foreground.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: dense ? 14 : 18, color: foreground),
          const SizedBox(width: AmTokens.spaceXs),
          Flexible(
            child: Text(
              label,
              style: textStyle?.copyWith(color: foreground),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
