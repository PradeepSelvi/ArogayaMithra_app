import 'package:am_auth/am_auth.dart';
import 'package:am_localization/am_localization.dart';
import 'package:am_models/am_models.dart';
import 'package:am_networking/am_networking.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Readiness publishing (PRD 5.3, FR-013, 12.3).
///
/// The subtitle is not decoration: what an officer records here changes where
/// citizens are sent. Each row shows how old the reading is, because a stale
/// "available" is worse than an honest "not reported".
class ReadinessScreen extends ConsumerWidget {
  const ReadinessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AmStrings.of(context);
    final facilityId = ref.watch(currentFacilityIdProvider);

    if (facilityId == null) {
      return AmEmptyView(message: strings.errorProfileMissing);
    }

    final resources = ref.watch(facilityResourcesProvider(facilityId));
    final readiness = ref.watch(facilityReadinessProvider(facilityId));

    return AmContentFrame(
      child: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(facilityResourcesProvider(facilityId))
            ..invalidate(facilityReadinessProvider(facilityId));
        },
        child: ListView(
          padding: const EdgeInsets.all(AmTokens.spaceMd),
          children: [
            AmSection(
              title: strings.consoleReadinessTitle,
              subtitle: strings.consoleReadinessSubtitle,
              child: readiness.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Text(strings.errorUnexpected),
                data: (value) => AmReadinessView(readiness: value),
              ),
            ),
            const SizedBox(height: AmTokens.spaceLg),

            resources.when(
              loading: () => AmLoadingView(message: strings.loading),
              error: (_, __) => AmEmptyView(message: strings.errorUnexpected),
              data: (list) => Column(
                children: [
                  for (final resource in list) ...[
                    _ResourceRow(resource: resource, facilityId: facilityId),
                    const SizedBox(height: AmTokens.spaceSm),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AmTokens.spaceXl),
          ],
        ),
      ),
    );
  }
}

class _ResourceRow extends ConsumerStatefulWidget {
  const _ResourceRow({required this.resource, required this.facilityId});

  final FacilityResource resource;
  final String facilityId;

  @override
  ConsumerState<_ResourceRow> createState() => _ResourceRowState();
}

class _ResourceRowState extends ConsumerState<_ResourceRow> {
  bool _isBusy = false;

  @override
  Widget build(BuildContext context) {
    final strings = AmStrings.of(context);
    final theme = Theme.of(context);
    final language = ref.watch(currentLanguageProvider);
    final resource = widget.resource;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AmTokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.label(language),
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        _ageLabel(strings, resource),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (resource.capacity != null)
                  Text(
                    '${resource.quantity ?? 0} / ${resource.capacity}',
                    style: theme.textTheme.titleMedium,
                  ),
              ],
            ),
            const SizedBox(height: AmTokens.spaceMd),
            Wrap(
              spacing: AmTokens.spaceSm,
              runSpacing: AmTokens.spaceSm,
              children: [
                for (final status in const [
                  AvailabilityStatus.available,
                  AvailabilityStatus.limited,
                  AvailabilityStatus.unavailable,
                ])
                  ChoiceChip(
                    selected: resource.status == status,
                    onSelected: _isBusy ? null : (_) => _update(status),
                    label: Text(_statusLabel(status, strings)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(AvailabilityStatus status, AmStrings strings) =>
      switch (status) {
        AvailabilityStatus.available => strings.availabilityAvailable,
        AvailabilityStatus.limited => strings.availabilityLimited,
        AvailabilityStatus.unavailable => strings.availabilityUnavailable,
        AvailabilityStatus.unknown => strings.availabilityUnknown,
      };

  String _ageLabel(AmStrings strings, FacilityResource resource) {
    final age = resource.age;
    if (age == null) return strings.availabilityUnknown;

    final ago = age.inHours >= 1
        ? '${age.inHours}h'
        : '${age.inMinutes.clamp(0, 59)}m';
    return strings.consoleLastUpdated(ago);
  }

  Future<void> _update(AvailabilityStatus status) async {
    setState(() => _isBusy = true);

    final result = await ref.read(facilityRepositoryProvider).updateResource(
          resourceId: widget.resource.id,
          status: status,
        );

    if (!mounted) return;
    setState(() => _isBusy = false);

    result.fold(
      onSuccess: (_) {
        // Readiness is recomputed by a database trigger, so both views are
        // refreshed rather than patched locally.
        ref
          ..invalidate(facilityResourcesProvider(widget.facilityId))
          ..invalidate(facilityReadinessProvider(widget.facilityId));
      },
      onFailure: (failure) => showAmFailureSnackBar(context, failure),
    );
  }
}

final facilityResourcesProvider =
    FutureProvider.family<List<FacilityResource>, String>((ref, facilityId) async {
  final result =
      await ref.watch(facilityRepositoryProvider).resources(facilityId);
  return result.fold(
    onSuccess: (list) => list,
    onFailure: (failure) => throw failure,
  );
});

final facilityReadinessProvider =
    FutureProvider.family<FacilityReadiness, String>((ref, facilityId) async {
  final result =
      await ref.watch(facilityRepositoryProvider).readiness(facilityId);
  return result.fold(
    onSuccess: (value) => value,
    onFailure: (failure) => throw failure,
  );
});
