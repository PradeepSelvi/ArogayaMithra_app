import 'package:am_localization/am_localization.dart';
import 'package:am_models/am_models.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screening/screening_screen.dart';
import 'household_providers.dart';

/// Household members and the screening entry point (PRD 5.2).
class HouseholdDetailScreen extends ConsumerWidget {
  const HouseholdDetailScreen({required this.household, super.key});

  final Household household;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AmStrings.of(context);
    final theme = Theme.of(context);
    final members = ref.watch(householdMembersProvider(household.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(household.headOfHousehold ?? household.code),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(householdMembersProvider(household.id)),
          child: ListView(
            padding: const EdgeInsets.all(AmTokens.spaceMd),
            children: [
              AmSection(
                title: household.code,
                subtitle: household.addressLine,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (household.contactPhone != null)
                      Text(
                        household.contactPhone!,
                        style: theme.textTheme.bodyLarge,
                      ),
                    if (household.landmark != null)
                      Text(
                        household.landmark!,
                        style: theme.textTheme.bodyMedium,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AmTokens.spaceLg),

              members.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Text(strings.errorUnexpected),
                data: (list) => Column(
                  children: [
                    for (final patient in list) ...[
                      _MemberTile(patient: patient),
                      const SizedBox(height: AmTokens.spaceSm),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AmTokens.spaceXl),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberTile extends ConsumerWidget {
  const _MemberTile({required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AmStrings.of(context);
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(AmTokens.spaceMd),
        leading: Icon(
          patient.isChild ? Icons.child_care : Icons.person_outline,
          size: 32,
        ),
        title: Text(patient.fullName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${patient.ageYears ?? '-'} · ${patient.sex.wire}',
              style: theme.textTheme.bodySmall,
            ),
            if (patient.isPregnant || patient.chronicConditions.isNotEmpty) ...[
              const SizedBox(height: AmTokens.spaceXs),
              Wrap(
                spacing: AmTokens.spaceXs,
                runSpacing: AmTokens.spaceXs,
                children: [
                  // Surfaced on the tile because both change how triage scores
                  // the same symptoms.
                  if (patient.isPregnant)
                    AmStatusChip(
                      label: strings.profilePregnant,
                      icon: Icons.pregnant_woman,
                      foreground: AmTokens.warning,
                      background: AmTokens.warningLight,
                      dense: true,
                    ),
                  for (final condition in patient.chronicConditions)
                    AmStatusChip(
                      label: condition,
                      icon: Icons.medical_information_outlined,
                      foreground: AmTokens.info,
                      background: AmTokens.infoLight,
                      dense: true,
                    ),
                ],
              ),
            ],
          ],
        ),
        trailing: FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ScreeningScreen(patient: patient),
            ),
          ),
          icon: const Icon(Icons.assignment_outlined),
          label: Text(strings.homeNeedCare),
        ),
        isThreeLine: patient.isPregnant || patient.chronicConditions.isNotEmpty,
      ),
    );
  }
}
