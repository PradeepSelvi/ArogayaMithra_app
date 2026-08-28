import 'package:am_auth/am_auth.dart';
import 'package:am_models/am_models.dart';
import 'package:am_networking/am_networking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every provider here reads an aggregate view. The district filter is applied
/// inside the database as well, so passing a district id is a convenience rather
/// than the security boundary (PRD 16, 27).
final _districtId = Provider<String?>(
  (ref) => ref.watch(currentDistrictIdProvider),
);

final referralKpiProvider = FutureProvider<List<ReferralKpi>>((ref) async {
  final result = await ref.watch(oversightRepositoryProvider).referralKpis(
        districtId: ref.watch(_districtId),
        since: DateTime.now().subtract(const Duration(days: 30)),
      );
  return result.fold(
    onSuccess: (list) => list,
    onFailure: (failure) => throw failure,
  );
});

final readinessHeatmapProvider =
    FutureProvider<List<FacilityReadinessSummary>>((ref) async {
  final result = await ref.watch(oversightRepositoryProvider).readinessHeatmap(
        districtId: ref.watch(_districtId),
      );
  return result.fold(
    onSuccess: (list) => list,
    onFailure: (failure) => throw failure,
  );
});

final alertsProvider = FutureProvider<List<OperationalAlert>>((ref) async {
  final result = await ref.watch(oversightRepositoryProvider).alerts(
        districtId: ref.watch(_districtId),
      );
  return result.fold(
    onSuccess: (list) => list,
    onFailure: (failure) => throw failure,
  );
});

final feedbackKpiProvider = FutureProvider<List<FeedbackKpi>>((ref) async {
  final result = await ref.watch(oversightRepositoryProvider).feedbackKpis(
        districtId: ref.watch(_districtId),
      );
  return result.fold(
    onSuccess: (list) => list,
    onFailure: (failure) => throw failure,
  );
});

final followUpKpiProvider = FutureProvider<List<FollowUpKpi>>((ref) async {
  final result = await ref.watch(oversightRepositoryProvider).followUpKpis(
        districtId: ref.watch(_districtId),
      );
  return result.fold(
    onSuccess: (list) => list,
    onFailure: (failure) => throw failure,
  );
});

/// Roll-up of the last 30 days, for the headline metrics.
final referralTotalsProvider = Provider<ReferralTotals>((ref) {
  final kpis = ref.watch(referralKpiProvider).valueOrNull ?? const [];

  var created = 0;
  var sent = 0;
  var accepted = 0;
  var completed = 0;
  var breaches = 0;
  final turnarounds = <double>[];

  for (final kpi in kpis) {
    created += kpi.created;
    sent += kpi.sent;
    accepted += kpi.accepted;
    completed += kpi.completed;
    breaches += kpi.slaBreaches;
    final median = kpi.medianTurnaroundMinutes;
    if (median != null) turnarounds.add(median);
  }

  // Median of daily medians rather than a mean, so one quiet day with a single
  // slow referral does not distort the headline figure.
  turnarounds.sort();
  final medianTurnaround = turnarounds.isEmpty
      ? null
      : turnarounds[turnarounds.length ~/ 2];

  return ReferralTotals(
    created: created,
    sent: sent,
    accepted: accepted,
    completed: completed,
    slaBreaches: breaches,
    medianTurnaroundMinutes: medianTurnaround,
  );
});

class ReferralTotals {
  const ReferralTotals({
    required this.created,
    required this.sent,
    required this.accepted,
    required this.completed,
    required this.slaBreaches,
    this.medianTurnaroundMinutes,
  });

  final int created;
  final int sent;
  final int accepted;
  final int completed;
  final int slaBreaches;
  final double? medianTurnaroundMinutes;

  double? get acceptanceRate => sent == 0 ? null : accepted / sent;
  double? get completionRate => created == 0 ? null : completed / created;
}
