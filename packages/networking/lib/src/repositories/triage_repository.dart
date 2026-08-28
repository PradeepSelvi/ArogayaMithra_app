import 'package:am_core/am_core.dart';
import 'package:am_models/am_models.dart';

import '../failure_mapper.dart';
import '../supabase_bootstrap.dart';

/// Triage.
///
/// The rules run in the database, not here. That is deliberate: the engine must
/// be deterministic, versioned and identical for every channel, and an app
/// build must never be able to change a clinical outcome (PRD 16, 20).
final class TriageRepository extends SupabaseRepository {
  TriageRepository(super.client);

  /// Runs triage and returns the assessment.
  ///
  /// Supply [TriageRequest.idempotencyKey] for captures made offline so a
  /// replayed sync returns the original assessment rather than creating a second
  /// one (PRD 15).
  Future<Result<TriageAssessment>> run(TriageRequest request) =>
      guard(() async {
        final row = await client.rpc<Map<String, Object?>>(
          'run_triage',
          params: request.toRpcParams(),
        );
        return TriageAssessment.fromJson(row);
      });

  /// Assessment history for a patient, newest first.
  Future<Result<List<TriageAssessment>>> history(
    String patientId, {
    int limit = 20,
  }) =>
      guard(() async {
        final rows = await client
            .from('triage_assessments')
            .select()
            .eq('patient_id', patientId)
            .order('created_at', ascending: false)
            .limit(limit);
        return rows.map(TriageAssessment.fromJson).toList(growable: false);
      });

  Future<Result<TriageAssessment?>> latestFor(String patientId) async {
    final result = await history(patientId, limit: 1);
    return result.map((list) => list.isEmpty ? null : list.first);
  }
}
