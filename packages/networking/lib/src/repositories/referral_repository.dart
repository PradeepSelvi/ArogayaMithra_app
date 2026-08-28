import 'package:am_core/am_core.dart';
import 'package:am_models/am_models.dart';

import '../failure_mapper.dart';
import '../supabase_bootstrap.dart';

/// Referral lifecycle.
///
/// Nothing here decides whether a transition is legal. The database owns the
/// state machine and refuses anything outside its transition table, so these
/// methods are thin, auditable commands (PRD 12.2, FR-010).
final class ReferralRepository extends SupabaseRepository {
  ReferralRepository(super.client);

  /// Creates a referral and advances it to REFERRAL_SENT, or to
  /// EMERGENCY_ESCALATED when triage found a red flag (PRD FR-006).
  ///
  /// Pass [idempotencyKey] for writes queued offline.
  Future<Result<Referral>> create({
    required String patientId,
    required String destinationFacilityId,
    String? triageAssessmentId,
    ReferralPriority? priority,
    String? reason,
    String? clinicalNotes,
    String? sourceFacilityId,
    Map<String, Object?>? scoreSnapshot,
    int? scoreConfigVersion,
    DateTime? clientCreatedAt,
    String? idempotencyKey,
  }) =>
      guard(() async {
        final row = await client.rpc<Map<String, Object?>>(
          'create_referral',
          params: {
            'p_patient_id': patientId,
            'p_destination_facility_id': destinationFacilityId,
            'p_triage_assessment_id': triageAssessmentId,
            'p_priority': priority?.wire,
            'p_reason': reason,
            'p_clinical_notes': clinicalNotes,
            'p_source_facility_id': sourceFacilityId,
            'p_score_snapshot': scoreSnapshot,
            'p_score_config_version': scoreConfigVersion,
            'p_client_created_at': clientCreatedAt?.toUtc().toIso8601String(),
            'p_idempotency_key': idempotencyKey,
          },
        );
        return Referral.fromJson(row);
      });

  /// Creates a referral straight from a chosen candidate, preserving the score
  /// breakdown that justified the choice (PRD 12.1).
  Future<Result<Referral>> createFromCandidate({
    required String patientId,
    required FacilityCandidate candidate,
    required TriageAssessment assessment,
    String? reason,
    String? idempotencyKey,
  }) =>
      create(
        patientId: patientId,
        destinationFacilityId: candidate.facility.id,
        triageAssessmentId: assessment.id,
        reason: reason,
        scoreSnapshot: candidate.toScoreSnapshot(),
        scoreConfigVersion: candidate.scoreConfigVersion,
        idempotencyKey: idempotencyKey,
      );

  Future<Result<Referral>> accept(String referralId, {String? note}) =>
      guard(() async {
        final row = await client.rpc<Map<String, Object?>>(
          'accept_referral',
          params: {'p_referral_id': referralId, 'p_note': note},
        );
        return Referral.fromJson(row);
      });

  /// Rejects a referral. A reason is mandatory and enforced by the database.
  Future<Result<Referral>> reject(String referralId, String reason) =>
      guard(() async {
        final row = await client.rpc<Map<String, Object?>>(
          'reject_referral',
          params: {'p_referral_id': referralId, 'p_reason': reason},
        );
        return Referral.fromJson(row);
      });

  /// Moves a referral one legal step. Use the transition table to decide what to
  /// offer; this call will be refused otherwise.
  Future<Result<Referral>> advance(
    String referralId,
    ReferralStatus to, {
    String? reason,
    String? outcome,
  }) =>
      guard(() async {
        final row = await client.rpc<Map<String, Object?>>(
          'advance_referral',
          params: {
            'p_referral_id': referralId,
            'p_to': to.wire,
            'p_reason': reason,
            'p_outcome': outcome,
          },
        );
        return Referral.fromJson(row);
      });

  Future<Result<Referral>> cancel(String referralId, String reason) =>
      guard(() async {
        final row = await client.rpc<Map<String, Object?>>(
          'cancel_referral',
          params: {'p_referral_id': referralId, 'p_reason': reason},
        );
        return Referral.fromJson(row);
      });

  /// Raises a referral to the emergency pathway (PRD FR-006).
  Future<Result<Referral>> escalate(String referralId, {String? reason}) =>
      guard(() async {
        final row = await client.rpc<Map<String, Object?>>(
          'escalate_referral',
          params: {'p_referral_id': referralId, 'p_reason': reason},
        );
        return Referral.fromJson(row);
      });

  /// Sends a rejected referral to a different facility (PRD 7.11).
  Future<Result<Referral>> reroute({
    required String referralId,
    required FacilityCandidate candidate,
  }) =>
      guard(() async {
        final row = await client.rpc<Map<String, Object?>>(
          'reroute_referral',
          params: {
            'p_referral_id': referralId,
            'p_destination_facility_id': candidate.facility.id,
            'p_score_snapshot': candidate.toScoreSnapshot(),
          },
        );
        return Referral.fromJson(row);
      });

  Future<Result<Referral>> byId(String referralId) => guard(() async {
        final row =
            await client.from('referrals').select().eq('id', referralId).single();
        return Referral.fromJson(row);
      });

  /// Referrals visible to the signed-in user, newest first. RLS decides the set.
  Future<Result<List<Referral>>> visible({int limit = 50}) => guard(() async {
        final rows = await client
            .from('referrals')
            .select()
            .order('created_at', ascending: false)
            .limit(limit);
        return rows.map(Referral.fromJson).toList(growable: false);
      });

  Future<Result<List<Referral>>> forPatient(String patientId) =>
      guard(() async {
        final rows = await client
            .from('referrals')
            .select()
            .eq('patient_id', patientId)
            .order('created_at', ascending: false);
        return rows.map(Referral.fromJson).toList(growable: false);
      });

  /// The facility's incoming queue (PRD 5.3).
  ///
  /// Emergencies first, then the referrals closest to breaching their SLA.
  Future<Result<List<Referral>>> incomingQueue({
    required String facilityId,
    bool openOnly = true,
  }) =>
      guard(() async {
        var query = client
            .from('referrals')
            .select()
            .eq('destination_facility_id', facilityId);

        if (openOnly) {
          query = query.inFilter('status', const [
            'REFERRAL_SENT',
            'ACCEPTED',
            'PATIENT_TRAVELLING',
            'ARRIVED',
            'CONSULTATION',
            'EMERGENCY_ESCALATED',
          ]);
        }

        final rows = await query
            .order('priority', ascending: false)
            .order('sla_due_at');

        return rows.map(Referral.fromJson).toList(growable: false);
      });

  /// Immutable referral timeline (PRD 13 GET /referrals/{id}/events).
  Future<Result<List<ReferralEvent>>> timeline(String referralId) =>
      guard(() async {
        final rows = await client
            .from('referral_timeline')
            .select()
            .eq('referral_id', referralId)
            .order('occurred_at');
        return rows.map(ReferralEvent.fromJson).toList(growable: false);
      });

  /// Live updates for a facility queue or a citizen's referral.
  ///
  /// Realtime respects RLS, so a subscriber only receives rows they may read.
  Stream<List<Referral>> watchIncomingQueue(String facilityId) => client
      .from('referrals')
      .stream(primaryKey: ['id'])
      .eq('destination_facility_id', facilityId)
      .map(
        (rows) => rows
            .map(Referral.fromJson)
            .where((r) => r.isOpen)
            .toList(growable: false),
      );

  Stream<Referral?> watchReferral(String referralId) => client
      .from('referrals')
      .stream(primaryKey: ['id'])
      .eq('id', referralId)
      .map((rows) => rows.isEmpty ? null : Referral.fromJson(rows.first));
}
