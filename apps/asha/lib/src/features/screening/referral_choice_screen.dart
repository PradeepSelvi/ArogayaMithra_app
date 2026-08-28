import 'package:am_auth/am_auth.dart';
import 'package:am_localization/am_localization.dart';
import 'package:am_maps/am_maps.dart';
import 'package:am_models/am_models.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screening_controller.dart';

/// Facility choice and referral creation by a field worker (PRD 5.2, FR-009).
class ReferralChoiceScreen extends ConsumerStatefulWidget {
  const ReferralChoiceScreen({required this.patient, super.key});

  final Patient patient;

  @override
  ConsumerState<ReferralChoiceScreen> createState() =>
      _ReferralChoiceScreenState();
}

class _ReferralChoiceScreenState extends ConsumerState<ReferralChoiceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final controller =
        ref.read(screeningControllerProvider(widget.patient).notifier);
    final position = await ref.read(locationServiceProvider).currentPosition();

    // The worker's own position is the right origin: they are standing at the
    // household. When location is unavailable the district centre keeps the
    // ranking usable rather than blocking the referral.
    await controller.loadFacilities(
      position.valueOrNull ??
          const GeoPoint(latitude: 12.2253, longitude: 79.0747),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AmStrings.of(context);
    final language = ref.watch(currentLanguageProvider);
    final state = ref.watch(screeningControllerProvider(widget.patient));

    return Scaffold(
      appBar: AppBar(title: Text(strings.facilitiesTitle)),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (state.isBusy && state.candidates.isEmpty) {
              return AmLoadingView(message: strings.facilitiesSearching);
            }

            if (state.candidates.isEmpty) {
              return AmEmptyView(
                message: strings.facilitiesNoneFound,
                icon: Icons.location_off_outlined,
                action: FilledButton.icon(
                  onPressed: () => ref
                      .read(directionsLauncherProvider)
                      .callEmergencyServices(),
                  icon: const Icon(Icons.call),
                  label: Text(strings.triageCallEmergency),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AmTokens.spaceMd),
              itemCount: state.candidates.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AmTokens.spaceMd),
              itemBuilder: (context, index) {
                final candidate = state.candidates[index];

                return AmSection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate.facility.displayName(language),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AmTokens.spaceXs),
                      Text(
                        '${strings.facilityDistance(
                          candidate.distanceKm.toStringAsFixed(1),
                        )} · ${strings.facilityTravelTime(
                          candidate.travelTimeMinutes.round(),
                        )}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AmTokens.spaceMd),
                      AmReadinessView(readiness: candidate.readiness),
                      if (candidate.hasServiceGap) ...[
                        const SizedBox(height: AmTokens.spaceMd),
                        AmBanner.warning(message: strings.facilityServiceGap),
                      ],
                      const SizedBox(height: AmTokens.spaceMd),
                      FilledButton.icon(
                        onPressed:
                            state.isBusy ? null : () => _refer(candidate),
                        icon: const Icon(Icons.send_outlined),
                        label: Text(strings.facilityChoose),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _refer(FacilityCandidate candidate) async {
    final referral = await ref
        .read(screeningControllerProvider(widget.patient).notifier)
        .refer(candidate);

    if (!mounted) return;

    final strings = AmStrings.of(context);

    if (referral == null) {
      final failure =
          ref.read(screeningControllerProvider(widget.patient)).failure;
      if (failure != null) showAmFailureSnackBar(context, failure);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.referralReference(referral.referenceCode))),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
