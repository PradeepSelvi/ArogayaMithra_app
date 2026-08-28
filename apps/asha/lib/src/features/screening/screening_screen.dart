import 'package:am_auth/am_auth.dart';
import 'package:am_localization/am_localization.dart';
import 'package:am_maps/am_maps.dart';
import 'package:am_models/am_models.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'referral_choice_screen.dart';
import 'screening_controller.dart';

/// Screening form for a household member (PRD 5.2, FR-004).
///
/// Symptoms, severity and duration in one scroll, because a worker standing in a
/// doorway should not be walked through four screens. Triage runs server side and
/// the outcome is shown inline before any referral is offered.
class ScreeningScreen extends ConsumerWidget {
  const ScreeningScreen({required this.patient, super.key});

  final Patient patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AmStrings.of(context);
    final theme = Theme.of(context);
    final language = ref.watch(currentLanguageProvider);
    final state = ref.watch(screeningControllerProvider(patient));
    final controller = ref.read(screeningControllerProvider(patient).notifier);
    final catalogue = ref.watch(symptomCatalogProvider);

    final durations = <String, int>{
      strings.durationLessThanDay: 12,
      strings.durationOneToThreeDays: 48,
      strings.durationUpToWeek: 120,
      strings.durationOverTwoWeeks: 360,
    };

    return Scaffold(
      appBar: AppBar(title: Text(patient.fullName)),
      body: SafeArea(
        child: catalogue.when(
          loading: () => AmLoadingView(message: strings.loading),
          error: (_, __) => AmEmptyView(message: strings.errorUnexpected),
          data: (symptoms) => ListView(
            padding: const EdgeInsets.all(AmTokens.spaceMd),
            children: [
              if (patient.isPregnant) ...[
                AmBanner.warning(message: strings.adviceHighPregnancy),
                const SizedBox(height: AmTokens.spaceMd),
              ],

              Text(strings.symptomsTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: AmTokens.spaceSm),
              for (final symptom in symptoms.where((s) => s.isCommon)) ...[
                AmChoiceTile(
                  label: symptom.label(language),
                  isSelected: state.symptomCodes.contains(symptom.code),
                  onTap: () => controller.toggleSymptom(symptom.code),
                ),
                const SizedBox(height: AmTokens.spaceSm),
              ],
              ExpansionTile(
                title: Text(strings.symptomsAll),
                tilePadding: EdgeInsets.zero,
                children: [
                  for (final symptom in symptoms.where((s) => !s.isCommon)) ...[
                    AmChoiceTile(
                      label: symptom.label(language),
                      isSelected: state.symptomCodes.contains(symptom.code),
                      onTap: () => controller.toggleSymptom(symptom.code),
                    ),
                    const SizedBox(height: AmTokens.spaceSm),
                  ],
                ],
              ),

              const SizedBox(height: AmTokens.spaceLg),
              Text(strings.severityTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: AmTokens.spaceSm),
              AmSeveritySelector(
                value: state.severity,
                onChanged: controller.setSeverity,
              ),

              const SizedBox(height: AmTokens.spaceLg),
              Text(strings.durationTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: AmTokens.spaceSm),
              for (final entry in durations.entries) ...[
                AmRadioTile<int>(
                  label: entry.key,
                  value: entry.value,
                  groupValue: state.durationHours,
                  onChanged: controller.setDurationHours,
                ),
                const SizedBox(height: AmTokens.spaceSm),
              ],

              if (state.failure != null) ...[
                const SizedBox(height: AmTokens.spaceMd),
                AmFailureBanner(failure: state.failure!),
              ],

              if (state.assessment != null) ...[
                const SizedBox(height: AmTokens.spaceLg),
                _Outcome(assessment: state.assessment!),
              ],

              const SizedBox(height: AmTokens.spaceXl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AmTokens.spaceMd),
          child: state.assessment == null
              ? AmBigButton(
                  label: strings.actionContinue,
                  icon: Icons.arrow_forward,
                  isBusy: state.isBusy,
                  onPressed: state.canSubmit && !state.isBusy
                      ? () => controller.runTriage()
                      : null,
                )
              : _NextAction(patient: patient, assessment: state.assessment!),
        ),
      ),
    );
  }
}

class _Outcome extends StatelessWidget {
  const _Outcome({required this.assessment});

  final TriageAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final strings = AmStrings.of(context);
    final theme = Theme.of(context);

    if (assessment.isEmergency) {
      return AmBanner.emergency(
        title: AmStatusChip.riskLabel(assessment.riskLevel, strings),
        message: strings.advice(assessment.adviceKey),
      );
    }

    return AmSection(
      title: AmStatusChip.riskLabel(assessment.riskLevel, strings),
      subtitle: AmStatusChip.nextActionLabel(assessment.nextAction, strings),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.advice(assessment.adviceKey),
            style: theme.textTheme.bodyLarge,
          ),
          if (assessment.usedDefaultFallback) ...[
            const SizedBox(height: AmTokens.spaceMd),
            AmBanner.warning(message: strings.triageFallbackWarning),
          ],
          const SizedBox(height: AmTokens.spaceSm),
          Text(
            strings.triageAssessedBy(assessment.ruleSetVersion),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _NextAction extends ConsumerWidget {
  const _NextAction({required this.patient, required this.assessment});

  final Patient patient;
  final TriageAssessment assessment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AmStrings.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (assessment.isEmergency) ...[
          AmBigButton.emergency(
            label: strings.triageCallEmergency,
            onPressed: () =>
                ref.read(directionsLauncherProvider).callEmergencyServices(),
          ),
          const SizedBox(height: AmTokens.spaceSm),
        ],
        if (assessment.shouldFindFacility)
          AmBigButton(
            label: strings.triageFindFacility,
            icon: Icons.location_on_outlined,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ReferralChoiceScreen(patient: patient),
              ),
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.check),
            label: Text(strings.actionDone),
          ),
      ],
    );
  }
}
