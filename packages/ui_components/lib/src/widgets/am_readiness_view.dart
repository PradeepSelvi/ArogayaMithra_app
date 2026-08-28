import 'package:am_localization/am_localization.dart';
import 'package:am_models/am_models.dart';
import 'package:flutter/material.dart';

import '../theme/am_tokens.dart';
import 'am_banner.dart';
import 'am_status_chip.dart';

/// Component-level readiness for a facility.
///
/// PRD 12.3 requires component detail, a timestamp and a visible stale flag.
/// This widget refuses to summarise readiness into a single reassuring number:
/// the citizen sees whether a doctor, medicines, tests and beds are each
/// available, because "70% ready" is meaningless when the missing 30% is the
/// doctor.
class AmReadinessView extends StatelessWidget {
  const AmReadinessView({
    required this.readiness,
    this.showStaleWarning = true,
    this.dense = false,
    super.key,
  });

  final FacilityReadiness readiness;
  final bool showStaleWarning;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final strings = AmStrings.of(context);

    final components = <(String, AvailabilityStatus)>[
      (strings.readinessDoctor, readiness.doctorStatus),
      (strings.readinessMedicines, readiness.medicinesStatus),
      (strings.readinessDiagnostics, readiness.diagnosticsStatus),
      (strings.readinessBeds, readiness.bedsStatus),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AmTokens.spaceSm,
          runSpacing: AmTokens.spaceSm,
          children: [
            for (final (label, status) in components)
              _ComponentPill(
                label: label,
                status: status,
                strings: strings,
                dense: dense,
              ),
          ],
        ),
        if (showStaleWarning && _warning(strings) != null) ...[
          const SizedBox(height: AmTokens.spaceMd),
          AmBanner.warning(message: _warning(strings)!),
        ],
      ],
    );
  }

  /// The warning a citizen needs before setting out.
  String? _warning(AmStrings strings) {
    if (readiness.checkedAt == null) {
      return strings.readinessNotReported;
    }
    if (readiness.isStale) {
      final hours = DateTime.now().difference(readiness.checkedAt!).inHours;
      return strings.readinessStaleWarning(hours);
    }
    return null;
  }
}

class _ComponentPill extends StatelessWidget {
  const _ComponentPill({
    required this.label,
    required this.status,
    required this.strings,
    required this.dense,
  });

  final String label;
  final AvailabilityStatus status;
  final AmStrings strings;
  final bool dense;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$label: ${_statusLabel()}',
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AmTokens.spaceXs),
              AmStatusChip.availability(status, strings: strings, dense: dense),
            ],
          ),
        ),
      );

  String _statusLabel() => switch (status) {
        AvailabilityStatus.available => strings.availabilityAvailable,
        AvailabilityStatus.limited => strings.availabilityLimited,
        AvailabilityStatus.unavailable => strings.availabilityUnavailable,
        AvailabilityStatus.unknown => strings.availabilityUnknown,
      };
}
