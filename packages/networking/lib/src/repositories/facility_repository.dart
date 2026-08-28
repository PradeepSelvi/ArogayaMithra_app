import 'package:am_core/am_core.dart';
import 'package:am_models/am_models.dart';

import '../failure_mapper.dart';
import '../supabase_bootstrap.dart';

/// Facility discovery and readiness publishing.
final class FacilityRepository extends SupabaseRepository {
  FacilityRepository(super.client);

  /// Ranked candidates for a referral (PRD FR-007, FR-008).
  ///
  /// Ranking happens server side so the weights are versioned configuration
  /// rather than app logic, and so every client sees the same recommendation
  /// (PRD 12.1).
  Future<Result<List<FacilityCandidate>>> search({
    required GeoPoint origin,
    List<String> requiredServices = const [],
    int minTier = 1,
    int? radiusMetres,
    bool emergencyOnly = false,
    int limit = 10,
  }) =>
      guard(() async {
        final rows = await client.rpc<List<dynamic>>(
          'search_facilities',
          params: {
            'p_lat': origin.latitude,
            'p_lon': origin.longitude,
            'p_required_services': requiredServices,
            'p_min_tier': minTier,
            'p_radius_m': radiusMetres,
            'p_emergency_only': emergencyOnly,
            'p_limit': limit,
          },
        );

        return rows
            .cast<Map<String, Object?>>()
            .map(FacilityCandidate.fromJson)
            .toList(growable: false);
      });

  /// Candidates for a triage outcome, honouring the services and tier the rule
  /// set asked for.
  Future<Result<List<FacilityCandidate>>> searchForAssessment({
    required GeoPoint origin,
    required TriageAssessment assessment,
    int? radiusMetres,
    int limit = 10,
  }) =>
      search(
        origin: origin,
        requiredServices: assessment.requiredServices,
        minTier: assessment.minFacilityTier,
        radiusMetres: radiusMetres,
        emergencyOnly: assessment.isEmergency,
        limit: limit,
      );

  Future<Result<Facility>> byId(String facilityId) => guard(() async {
        final row = await client
            .from('facilities')
            .select(
              'id, hfr_id, name_en, name_local, type, tier, district_id, '
              'address, contact_phone, emergency_phone, is_24x7, '
              'has_emergency_department, is_operational',
            )
            .eq('id', facilityId)
            .single();

        // `facilities.location` is a geography column, so coordinates come from
        // the readiness view which already projects lat/lon.
        final coords = await client
            .from('kpi_facility_readiness')
            .select('latitude, longitude')
            .eq('facility_id', facilityId)
            .maybeSingle();

        return Facility.fromJson({...row, ...?coords});
      });

  /// Current readiness for one facility (PRD 13 GET /facilities/{id}/readiness).
  Future<Result<FacilityReadiness>> readiness(String facilityId) =>
      guard(() async {
        final row = await client
            .from('facility_readiness_current')
            .select()
            .eq('facility_id', facilityId)
            .single();
        return FacilityReadiness.fromJson(row);
      });

  /// Tracked resources for the facility console (PRD 5.3).
  Future<Result<List<FacilityResource>>> resources(String facilityId) =>
      guard(() async {
        final rows = await client
            .from('facility_resources')
            .select()
            .eq('facility_id', facilityId)
            .order('kind')
            .order('label_en');
        return rows.map(FacilityResource.fromJson).toList(growable: false);
      });

  /// Publishes a resource status.
  ///
  /// A manual override must carry a reason; the database rejects it otherwise,
  /// so the argument is required here rather than optional (PRD 12.3).
  Future<Result<FacilityResource>> updateResource({
    required String resourceId,
    required AvailabilityStatus status,
    int? quantity,
    bool isManualOverride = false,
    String? overrideReason,
  }) =>
      guard(() async {
        if (isManualOverride &&
            (overrideReason == null || overrideReason.trim().isEmpty)) {
          throw const Failure(
            kind: FailureKind.invalidInput,
            messageKey: 'error.override_reason_required',
          );
        }

        final row = await client
            .from('facility_resources')
            .update({
              'status': status.wire,
              if (quantity != null) 'quantity': quantity,
              'is_manual_override': isManualOverride,
              'override_reason': isManualOverride ? overrideReason : null,
            })
            .eq('id', resourceId)
            .select()
            .single();

        return FacilityResource.fromJson(row);
      });

  /// Forces a readiness recomputation and returns the new snapshot.
  Future<Result<FacilityReadiness>> refreshReadiness(String facilityId) =>
      guard(() async {
        final row = await client.rpc<Map<String, Object?>>(
          'refresh_facility_readiness',
          params: {'p_facility_id': facilityId},
        );

        return FacilityReadiness.fromJson({
          'readiness_score': row['score'],
          'readiness_confidence': row['confidence'],
          'doctor_status': row['doctor_status'],
          'medicines_status': row['medicines_status'],
          'diagnostics_status': row['diagnostics_status'],
          'beds_status': row['beds_status'],
          'checked_at': row['checked_at'],
          'is_stale': false,
        });
      });

  /// Services a facility offers and their current status.
  Future<Result<Map<String, AvailabilityStatus>>> serviceStatuses(
    String facilityId,
  ) =>
      guard(() async {
        final rows = await client
            .from('facility_services')
            .select('service_code, status')
            .eq('facility_id', facilityId);

        return {
          for (final row in rows)
            row['service_code']! as String:
                AvailabilityStatus.parse(row['status'] as String?),
        };
      });
}
