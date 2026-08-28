import 'package:am_core/am_core.dart';
import 'package:am_models/am_models.dart';

import '../failure_mapper.dart';
import '../supabase_bootstrap.dart';

/// District and state analytics (PRD 5.4, 19).
///
/// Every source here is an aggregate view that filters by the caller's district
/// scope inside the database. Oversight roles have no row access to patient
/// records, so these are the only numbers they can see (PRD 16).
final class OversightRepository extends SupabaseRepository {
  OversightRepository(super.client);

  /// Referral funnel and turnaround by day.
  Future<Result<List<ReferralKpi>>> referralKpis({
    DateTime? since,
    String? districtId,
  }) =>
      guard(() async {
        var query = client.from('kpi_referral_daily').select();

        if (since != null) {
          query = query.gte('day', since.toIso8601String().split('T').first);
        }
        if (districtId != null) {
          query = query.eq('district_id', districtId);
        }

        final rows = await query.order('day', ascending: false);
        return rows.map(ReferralKpi.fromJson).toList(growable: false);
      });

  /// Readiness heatmap cells.
  Future<Result<List<FacilityReadinessSummary>>> readinessHeatmap({
    String? districtId,
  }) =>
      guard(() async {
        var query = client.from('kpi_facility_readiness').select();
        if (districtId != null) {
          query = query.eq('district_id', districtId);
        }
        final rows = await query.order('readiness_score');
        return rows
            .map(FacilityReadinessSummary.fromJson)
            .toList(growable: false);
      });

  /// Live alert feed: SLA breaches, critical or stale readiness, open issues.
  Future<Result<List<OperationalAlert>>> alerts({String? districtId}) =>
      guard(() async {
        var query = client.from('operational_alerts').select();
        if (districtId != null) {
          query = query.eq('district_id', districtId);
        }
        final rows = await query.order('raised_at', ascending: false);
        return rows.map(OperationalAlert.fromJson).toList(growable: false);
      });

  Future<Result<List<FeedbackKpi>>> feedbackKpis({String? districtId}) =>
      guard(() async {
        var query = client.from('kpi_feedback_summary').select();
        if (districtId != null) {
          query = query.eq('district_id', districtId);
        }
        final rows = await query.order('month', ascending: false);
        return rows.map(FeedbackKpi.fromJson).toList(growable: false);
      });

  Future<Result<List<FollowUpKpi>>> followUpKpis({String? districtId}) =>
      guard(() async {
        var query = client.from('kpi_followup_compliance').select();
        if (districtId != null) {
          query = query.eq('district_id', districtId);
        }
        final rows = await query.order('week', ascending: false);
        return rows.map(FollowUpKpi.fromJson).toList(growable: false);
      });

  /// Triage risk mix, used to sanity-check that red flags are firing as expected
  /// (PRD 20 model monitoring).
  Future<Result<List<Map<String, Object?>>>> triageKpis({
    String? districtId,
  }) =>
      guard(() async {
        var query = client.from('kpi_triage_daily').select();
        if (districtId != null) {
          query = query.eq('district_id', districtId);
        }
        final rows = await query.order('day', ascending: false);
        return rows.cast<Map<String, Object?>>().toList(growable: false);
      });
}
