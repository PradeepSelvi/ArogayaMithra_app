import 'package:am_core/am_core.dart';
import 'package:am_localization/am_localization.dart';
import 'package:am_maps/am_maps.dart';
import 'package:am_models/am_models.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../referrals/referral_detail_screen.dart';
import '../triage/care_journey_controller.dart';

/// Ranked facilities for the current assessment (PRD 7.6-7.9, FR-007, FR-008).
///
/// Each card shows the readiness components and, when relevant, a warning that
/// the data is stale or the facility cannot deliver every required service. A
/// citizen deciding whether to travel needs those caveats more than they need a
/// tidy list (PRD 12.3).
class FacilityListScreen extends ConsumerStatefulWidget {
  const FacilityListScreen({super.key});

  @override
  ConsumerState<FacilityListScreen> createState() => _FacilityListScreenState();
}

class _FacilityListScreenState extends ConsumerState<FacilityListScreen> {
  Failure? _locationFailure;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final position = await ref.read(locationServiceProvider).currentPosition();

    await position.fold(
      onSuccess: (origin) async {
        setState(() => _locationFailure = null);
        await ref.read(careJourneyProvider.notifier).loadFacilities(origin);
      },
      onFailure: (failure) async {
        // Falling back to the district centroid keeps the journey moving when a
        // rural GPS fix fails or the user declines the permission. The banner
        // tells them the ranking is approximate.
        setState(() => _locationFailure = failure);
        await ref
            .read(careJourneyProvider.notifier)
            .loadFacilities(_districtFallback);
      },
    );
  }

  /// Tiruvannamalai district centre, matching the seeded deployment.
  static const _districtFallback =
      GeoPoint(latitude: 12.2253, longitude: 79.0747);

  @override
  Widget build(BuildContext context) {
    final strings = AmStrings.of(context);
    final journey = ref.watch(careJourneyProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.facilitiesTitle)),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (journey.isBusy && journey.candidates.isEmpty) {
              return AmLoadingView(message: strings.facilitiesSearching);
            }

            if (journey.failure != null && journey.candidates.isEmpty) {
              return AmFailureView(
                failure: journey.failure!,
                onRetry: _load,
              );
            }

            if (journey.candidates.isEmpty) {
              return AmEmptyView(
                message: strings.facilitiesNoneFound,
                icon: Icons.location_off_outlined,
                action: FilledButton.icon(
                  onPressed: () =>
                      ref.read(directionsLauncherProvider).callEmergencyServices(),
                  icon: const Icon(Icons.call),
                  label: Text(strings.triageCallEmergency),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AmTokens.spaceMd),
              itemCount: journey.candidates.length + 1,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AmTokens.spaceMd),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.facilitiesSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (_locationFailure != null) ...[
                        const SizedBox(height: AmTokens.spaceMd),
                        AmFailureBanner(
                          failure: _locationFailure!,
                          onRetry: _load,
                        ),
                      ],
                    ],
                  );
                }

                return _FacilityCard(
                  candidate: journey.candidates[index - 1],
                  isRecommended: index == 1,
                  onChoose: () => _choose(journey.candidates[index - 1]),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _choose(FacilityCandidate candidate) async {
    final patient = ref.read(selfPatientProvider).valueOrNull;
    if (patient == null) return;

    final referral = await ref.read(careJourneyProvider.notifier).chooseFacility(
          patient: patient,
          candidate: candidate,
        );

    if (!mounted) return;

    if (referral == null) {
      final failure = ref.read(careJourneyProvider).failure;
      if (failure != null) showAmFailureSnackBar(context, failure);
      return;
    }

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ReferralDetailScreen(referralId: referral.id),
      ),
    );
  }
}

class _FacilityCard extends ConsumerWidget {
  const _FacilityCard({
    required this.candidate,
    required this.isRecommended,
    required this.onChoose,
  });

  final FacilityCandidate candidate;
  final bool isRecommended;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AmStrings.of(context);
    final theme = Theme.of(context);
    final language = ref.watch(activeLanguageProvider);
    final facility = candidate.facility;

    return AmSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  facility.displayName(language),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (isRecommended)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AmTokens.spaceSm,
                    vertical: AmTokens.spaceXs,
                  ),
                  decoration: BoxDecoration(
                    color: AmTokens.primaryLight,
                    borderRadius: BorderRadius.circular(AmTokens.radiusSmall),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: AmTokens.primary,
                      ),
                      const SizedBox(width: AmTokens.spaceXs),
                      Text(
                        '1',
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: AmTokens.primary),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AmTokens.spaceSm),

          Wrap(
            spacing: AmTokens.spaceMd,
            runSpacing: AmTokens.spaceXs,
            children: [
              _Meta(
                icon: Icons.directions_walk,
                label: strings.facilityDistance(
                  candidate.distanceKm.toStringAsFixed(1),
                ),
              ),
              _Meta(
                icon: Icons.schedule,
                label: strings.facilityTravelTime(
                  candidate.travelTimeMinutes.round(),
                ),
              ),
              if (facility.is24x7)
                _Meta(icon: Icons.access_time, label: strings.facilityOpen24x7),
              if (facility.hasEmergencyDepartment)
                _Meta(
                  icon: Icons.emergency_outlined,
                  label: strings.facilityHasEmergency,
                ),
            ],
          ),

          const SizedBox(height: AmTokens.spaceMd),
          AmReadinessView(readiness: candidate.readiness),

          if (candidate.hasServiceGap) ...[
            const SizedBox(height: AmTokens.spaceMd),
            AmBanner.warning(message: strings.facilityServiceGap),
          ],

          const SizedBox(height: AmTokens.spaceMd),
          ExpansionTile(
            title: Text(
              strings.facilityWhyRanked,
              style: theme.textTheme.labelMedium,
            ),
            tilePadding: EdgeInsets.zero,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  strings.facilityScoreBreakdown(
                    _percent(candidate.scoreComponents, 'travel'),
                    (candidate.serviceMatch * 100).round(),
                    (candidate.waitScore * 100).round(),
                    (candidate.readiness.confidence * 100).round(),
                  ),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),

          const SizedBox(height: AmTokens.spaceMd),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onChoose,
                  icon: const Icon(Icons.check),
                  label: Text(strings.facilityChoose),
                ),
              ),
              const SizedBox(width: AmTokens.spaceSm),
              IconButton.outlined(
                tooltip: strings.facilityDirections,
                onPressed: () => ref
                    .read(directionsLauncherProvider)
                    .openDirections(facility.location),
                icon: const Icon(Icons.directions),
              ),
              if (facility.callablePhone != null) ...[
                const SizedBox(width: AmTokens.spaceSm),
                IconButton.outlined(
                  tooltip: strings.facilityCall,
                  onPressed: () => ref
                      .read(directionsLauncherProvider)
                      .call(facility.callablePhone!),
                  icon: const Icon(Icons.call),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  int _percent(Map<String, Object?> components, String key) {
    final entry = components[key];
    if (entry is Map) {
      final value = entry['value'];
      if (value is num) return (value * 100).round();
    }
    return 0;
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AmTokens.textSecondary),
          const SizedBox(width: AmTokens.spaceXs),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}
