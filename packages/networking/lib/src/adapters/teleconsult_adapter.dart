import 'package:am_core/am_core.dart';
import 'package:am_models/am_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'ambulance_adapter.dart' show FailureMapperShim;

/// A teleconsultation session.
class TeleconsultSession {
  const TeleconsultSession({
    required this.id,
    required this.status,
    this.externalSessionId,
    this.joinUrl,
    this.scheduledAt,
    this.isMock = true,
  });

  final String id;
  final TeleconsultStatus status;
  final String? externalSessionId;

  /// Held only for the life of the session and never cached (PRD 14.3).
  final String? joinUrl;

  final DateTime? scheduledAt;
  final bool isMock;

  bool get isJoinable =>
      joinUrl != null &&
      (status == TeleconsultStatus.scheduled ||
          status == TeleconsultStatus.inProgress);
}

/// Teleconsultation, fronting eSanjeevani (PRD 14.3).
///
/// ArogyaMitra tracks the session lifecycle and consent; it does not duplicate
/// the external platform's clinical record.
abstract interface class TeleconsultAdapter {
  /// Creates a session for an eligible patient.
  ///
  /// [consentRecordId] is required because a teleconsultation shares health
  /// information with a clinician outside the referring facility (PRD 16).
  Future<Result<TeleconsultSession>> createSession({
    required String patientId,
    required String consentRecordId,
    String? referralId,
    String? facilityId,
  });

  Future<Result<TeleconsultSession>> status(String sessionId);

  Future<Result<void>> cancel(String sessionId, String reason);
}

/// Development adapter. Records a real session row so consent, audit and
/// utilisation analytics behave as they will in production.
final class MockTeleconsultAdapter implements TeleconsultAdapter {
  MockTeleconsultAdapter(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<TeleconsultSession>> createSession({
    required String patientId,
    required String consentRecordId,
    String? referralId,
    String? facilityId,
  }) async {
    try {
      final districtRow = await _client
          .from('patients')
          .select('district_id')
          .eq('id', patientId)
          .single();

      final scheduledAt = DateTime.now().add(const Duration(minutes: 15));

      final row = await _client
          .from('teleconsult_sessions')
          .insert({
            'patient_id': patientId,
            'district_id': districtRow['district_id'],
            'consent_record_id': consentRecordId,
            if (referralId != null) 'referral_id': referralId,
            if (facilityId != null) 'facility_id': facilityId,
            'provider_key': 'mock',
            'is_mock': true,
            'status': 'scheduled',
            'scheduled_at': scheduledAt.toUtc().toIso8601String(),
            'external_session_id':
                'MOCK-${DateTime.now().millisecondsSinceEpoch}',
            'join_url': 'https://teleconsult.invalid/session/mock',
          })
          .select()
          .single();

      return Success(_toSession(row));
    } catch (error, stackTrace) {
      return Err(const FailureMapperShim().map(error, stackTrace));
    }
  }

  @override
  Future<Result<TeleconsultSession>> status(String sessionId) async {
    try {
      final row = await _client
          .from('teleconsult_sessions')
          .select()
          .eq('id', sessionId)
          .single();
      return Success(_toSession(row));
    } catch (error, stackTrace) {
      return Err(const FailureMapperShim().map(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> cancel(String sessionId, String reason) async {
    try {
      await _client
          .from('teleconsult_sessions')
          .update({'status': 'cancelled', 'failure_reason': reason})
          .eq('id', sessionId);
      return const Success(null);
    } catch (error, stackTrace) {
      return Err(const FailureMapperShim().map(error, stackTrace));
    }
  }

  TeleconsultSession _toSession(Map<String, Object?> row) => TeleconsultSession(
        id: row['id']! as String,
        status: TeleconsultStatus.parse(row['status'] as String?),
        externalSessionId: row['external_session_id'] as String?,
        joinUrl: row['join_url'] as String?,
        scheduledAt: row['scheduled_at'] == null
            ? null
            : DateTime.parse(row['scheduled_at']! as String).toLocal(),
        isMock: row['is_mock'] as bool? ?? true,
      );
}
