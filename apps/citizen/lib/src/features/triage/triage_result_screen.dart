import 'package:am_localization/am_localization.dart';
import 'package:am_maps/am_maps.dart';
import 'package:am_models/am_models.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../facilities/facility_list_screen.dart';
import 'care_journey_controller.dart';

/// Triage outcome and what to do next (PRD 7.4, FR-005, FR-006).
///
/// Three rules govern this screen:
///   * An emergency outcome leads with the call action and the emergency advice.
///     Nothing else competes with it (PRD 16).
///   * The advice text is the clinically authored string for the matched rule,
///     resolved from a key. It is never generated (PRD 20).
///   * The rule set version is shown, so a past decision can be explained.
class TriageResultScreen extends ConsumerWidget {
  const TriageResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AmStrings.of(context);
    final theme = Theme.of(context);
    final assessment = ref.watch(careJourneyProvider).assessment;

    if (assessment == null) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.triageResultTitle)),
        body: AmEmptyView(message: strings.noResults),
      );
    }

    final isEmergency = assessment.isEmergency;

    return Scaffold(
      appBar: AppBar(title: Text(strings.triageResultTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AmTokens.spaceMd),
          children: [
            _RiskHeader(assessment: assessment),
            const SizedBox(height: AmTokens.spaceLg),

            if (isEmergency)
              AmBanner.emergency(
                title: strings.riskEmergency,
                message: strings.advice(assessment.adviceKey),
              )
            else
              AmSection(
                title: AmStatusChip.nextActionLabel(
                  assessment.nextAction,
                  strings,
                ),
                child: Text(
                  strings.advice(assessment.adviceKey),
                  style: theme.textTheme.bodyLarge,
                ),
              ),

            // The clinical team can publish a rule before the app ships its
            // translation. Saying so is safer than showing generic advice as
            // though it were specific to the matched rule.
            if (strings.isUnknownAdviceKey(assessment.adviceKey)) ...[
              const SizedBox(height: AmTokens.spaceMd),
              AmBanner.warning(message: strings.adviceWhenToReturn),
            ],

            if (assessment.usedDefaultFallback) ...[
              const SizedBox(height: AmTokens.spaceMd),
              AmBanner.warning(message: strings.triageFallbackWarning),
            ],

            if (assessment.hasRedFlags) ...[
              const SizedBox(height: AmTokens.spaceMd),
              AmSection(
                title: strings.triageRedFlagsTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final flag in assessment.redFlags)
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: AmTokens.spaceXs),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.flag_outlined,
                              size: 18,
                              color: AmTokens.emergency,
                            ),
                            const SizedBox(width: AmTokens.spaceSm),
                            Expanded(
                              child: Text(
                                flag,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AmTokens.spaceMd),
            AmBanner.info(message: strings.triageNotDiagnosis),

            const SizedBox(height: AmTokens.spaceSm),
            Text(
              strings.triageAssessedBy(assessment.ruleSetVersion),
              style: theme.textTheme.bodySmall,
            ),

            const SizedBox(height: AmTokens.spaceXl),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AmTokens.spaceMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isEmergency) ...[
                AmBigButton.emergency(
                  label: strings.triageCallEmergency,
                  onPressed: () => ref
                      .read(directionsLauncherProvider)
                      .callEmergencyServices(),
                ),
                const SizedBox(height: AmTokens.spaceSm),
              ],
              if (assessment.shouldFindFacility)
                AmBigButton(
                  label: strings.triageFindFacility,
                  icon: Icons.location_on_outlined,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const FacilityListScreen(),
                    ),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context)
                      .popUntil((route) => route.isFirst),
                  icon: const Icon(Icons.home_outlined),
                  label: Text(strings.actionDone),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RiskHeader extends StatelessWidget {
  const _RiskHeader({required this.assessment});

  final TriageAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final strings = AmStrings.of(context);
    final theme = Theme.of(context);

    final (tone, background, icon) = switch (assessment.riskLevel) {
      RiskLevel.emergency => (
          AmTokens.emergency,
          AmTokens.emergencyLight,
          Icons.emergency,
        ),
      RiskLevel.high => (
          AmTokens.warning,
          AmTokens.warningLight,
          Icons.priority_high,
        ),
      RiskLevel.medium => (AmTokens.info, AmTokens.infoLight, Icons.info_outline),
      RiskLevel.low => (
          AmTokens.success,
          AmTokens.successLight,
          Icons.check_circle_outline,
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AmTokens.spaceLg),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AmTokens.radiusLarge),
        // ignore: deprecated_member_use
        border: Border.all(color: Color.fromRGBO(tone.red, tone.green, tone.blue, 0.4)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: tone),
          const SizedBox(height: AmTokens.spaceSm),
          Text(
            AmStatusChip.riskLabel(assessment.riskLevel, strings),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(color: tone),
          ),
          const SizedBox(height: AmTokens.spaceXs),
          Text(
            AmStatusChip.nextActionLabel(assessment.nextAction, strings),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
