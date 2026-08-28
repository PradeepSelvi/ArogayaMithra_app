import 'package:am_core/am_core.dart';
import 'package:am_localization/am_localization.dart';
import 'package:am_models/am_models.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import 'care_journey_controller.dart';
import 'severity_screen.dart';

/// Symptom selection (PRD 6 FR-004).
///
/// Common symptoms come first so the usual case takes two taps, with the full
/// list and a search below for everything else. Selection is by code, never free
/// text, because the rule engine rejects codes it does not know rather than
/// guessing.
class SymptomScreen extends ConsumerStatefulWidget {
  const SymptomScreen({super.key});

  @override
  ConsumerState<SymptomScreen> createState() => _SymptomScreenState();
}

class _SymptomScreenState extends ConsumerState<SymptomScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AmStrings.of(context);
    final language = ref.watch(activeLanguageProvider);
    final journey = ref.watch(careJourneyProvider);
    final catalogue = ref.watch(symptomCatalogProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.symptomsTitle)),
      body: SafeArea(
        child: catalogue.when(
          loading: () => AmLoadingView(message: strings.loading),
          error: (error, _) => AmFailureView(
            failure: error is Failure
                ? error
                : Failure.unexpected(detail: error.toString()),
            onRetry: () => ref.invalidate(symptomCatalogProvider),
          ),
          data: (symptoms) => _buildBody(
            strings: strings,
            language: language,
            symptoms: symptoms,
            selected: journey.symptomCodes,
          ),
        ),
      ),
      bottomNavigationBar: journey.symptomCodes.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AmTokens.spaceMd),
                child: AmBigButton(
                  label: strings.actionContinue,
                  subtitle: strings.symptomsSelected(journey.symptomCodes.length),
                  icon: Icons.arrow_forward,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SeverityScreen(),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildBody({
    required AmStrings strings,
    required LanguageCode language,
    required List<Symptom> symptoms,
    required Set<String> selected,
  }) {
    final isSearching = _query.trim().isNotEmpty;

    final visible = isSearching
        ? symptoms
            .where(
              (s) => s
                  .label(language)
                  .toLowerCase()
                  .contains(_query.trim().toLowerCase()),
            )
            .toList()
        : symptoms.where((s) => s.isCommon).toList();

    final others = isSearching
        ? const <Symptom>[]
        : symptoms.where((s) => !s.isCommon).toList();

    return ListView(
      padding: const EdgeInsets.all(AmTokens.spaceMd),
      children: [
        Text(strings.symptomsHint, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AmTokens.spaceMd),
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            labelText: strings.symptomsSearch,
            prefixIcon: const Icon(Icons.search),
          ),
        ),
        const SizedBox(height: AmTokens.spaceLg),

        if (!isSearching)
          Text(
            strings.symptomsCommon,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        const SizedBox(height: AmTokens.spaceSm),

        for (final symptom in visible) ...[
          AmChoiceTile(
            label: symptom.label(language),
            isSelected: selected.contains(symptom.code),
            onTap: () => ref
                .read(careJourneyProvider.notifier)
                .toggleSymptom(symptom.code),
          ),
          const SizedBox(height: AmTokens.spaceSm),
        ],

        if (others.isNotEmpty) ...[
          const SizedBox(height: AmTokens.spaceMd),
          ExpansionTile(
            title: Text(strings.symptomsAll),
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(top: AmTokens.spaceSm),
            children: [
              for (final symptom in others) ...[
                AmChoiceTile(
                  label: symptom.label(language),
                  isSelected: selected.contains(symptom.code),
                  onTap: () => ref
                      .read(careJourneyProvider.notifier)
                      .toggleSymptom(symptom.code),
                ),
                const SizedBox(height: AmTokens.spaceSm),
              ],
            ],
          ),
        ],

        if (visible.isEmpty && isSearching)
          Padding(
            padding: const EdgeInsets.only(top: AmTokens.spaceLg),
            child: Text(
              strings.noResults,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),

        const SizedBox(height: AmTokens.spaceXl),
      ],
    );
  }
}
