import 'package:am_localization/am_localization.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'care_journey_controller.dart';
import 'triage_result_screen.dart';

/// Severity and duration.
///
/// Both feed the rule predicates directly: `max_severity` is what keeps a
/// self-care rule from matching a serious presentation, and `min_duration_hours`
/// is what separates a new cough from a suspected TB case. Neither has a default,
/// so the user must answer.
class SeverityScreen extends ConsumerStatefulWidget {
  const SeverityScreen({super.key});

  @override
  ConsumerState<SeverityScreen> createState() => _SeverityScreenState();
}

class _SeverityScreenState extends ConsumerState<SeverityScreen> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final strings = AmStrings.of(context);
    final theme = Theme.of(context);
    final journey = ref.watch(careJourneyProvider);
    final controller = ref.read(careJourneyProvider.notifier);

    final durations = <String, int>{
      strings.durationLessThanDay: 12,
      strings.durationOneToThreeDays: 48,
      strings.durationUpToWeek: 120,
      strings.durationOverTwoWeeks: 360,
    };

    return Scaffold(
      appBar: AppBar(title: Text(strings.severityTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AmTokens.spaceMd),
          children: [
            Text(strings.severityHint, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AmTokens.spaceMd),
            AmSeveritySelector(
              value: journey.severity,
              onChanged: controller.setSeverity,
            ),
            const SizedBox(height: AmTokens.spaceXl),

            Text(strings.durationTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: AmTokens.spaceSm),
            for (final entry in durations.entries) ...[
              AmRadioTile<int>(
                label: entry.key,
                value: entry.value,
                groupValue: journey.durationHours,
                onChanged: controller.setDurationHours,
              ),
              const SizedBox(height: AmTokens.spaceSm),
            ],

            if (journey.failure != null) ...[
              const SizedBox(height: AmTokens.spaceMd),
              AmFailureBanner(failure: journey.failure!),
            ],

            const SizedBox(height: AmTokens.spaceXl),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AmTokens.spaceMd),
          child: AmBigButton(
            label: strings.actionContinue,
            icon: Icons.arrow_forward,
            isBusy: _isSubmitting || journey.isBusy,
            onPressed: journey.canRunTriage && !_isSubmitting ? _submit : null,
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final patient = ref.read(selfPatientProvider).valueOrNull;
    if (patient == null) return;

    setState(() => _isSubmitting = true);
    final assessment =
        await ref.read(careJourneyProvider.notifier).runTriage(patient);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (assessment != null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const TriageResultScreen()),
      );
    }
  }
}
