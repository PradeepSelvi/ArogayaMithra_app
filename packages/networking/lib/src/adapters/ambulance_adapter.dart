import 'dart:async';

import 'package:am_core/am_core.dart';
import 'package:am_models/am_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result of an ambulance dispatch request.
class AmbulanceDispatch {
  const AmbulanceDispatch({
    required this.requestId,
    required this.status,
    this.externalReference,
    this.vehicleNumber,
    this.crewContact,
    this.etaMinutes,
    this.isMock = true,
  });

  final String requestId;
  final AmbulanceStatus status;
  final String? externalReference;
  final String? vehicleNumber;
  final String? crewContact;
  final int? etaMinutes;

  /// True while the request was served by a mock adapter (PRD 14.4, 23).
  final bool isMock;
}

/// Provider-agnostic ambulance dispatch.
///
/// There is no universal 108 API: the interface and authorisation are specific
/// to each state or operator, so the contract lives here and the transport is
/// swapped per deployment (PRD 14.4).
abstract interface class AmbulanceAdapter {
  /// Requests transport. Returns a tracked request the citizen can follow.
  Future<Result<AmbulanceDispatch>> requestDispatch({
    required String patientId,
    required GeoPoint pickup,
    required String contactPhone,
    String? referralId,
    String? destinationFacilityId,
    String? pickupAddress,
  });

  /// Current status of a request.
  Future<Result<AmbulanceDispatch>> status(String requestId);

  /// Live status updates for the citizen tracker.
  Stream<AmbulanceDispatch> watch(String requestId);

  Future<Result<void>> cancel(String requestId, String reason);
}

/// Development adapter.
///
/// Writes a real `ambulance_requests` row so the referral timeline, audit trail
/// and DHO response analytics all behave exactly as they will in production,
/// then simulates dispatch progress. Replacing this with an authorised provider
/// adapter requires no change to the calling workflow (PRD 27).
final class MockAmbulanceAdapter implements AmbulanceAdapter {
  MockAmbulanceAdapter(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<AmbulanceDispatch>> requestDispatch({
    required String patientId,
    required GeoPoint pickup,
    required String contactPhone,
    String? referralId,
    String? destinationFacilityId,
    String? pickupAddress,
  }) async {
    try {
      final districtId = await _resolveDistrict(patientId);

      final row = await _client
          .from('ambulance_requests')
          .insert({
            'patient_id': patientId,
            'district_id': districtId,
            'contact_phone': contactPhone,
            'pickup_point': 'POINT(${pickup.longitude} ${pickup.latitude})',
            if (pickupAddress != null) 'pickup_address': pickupAddress,
            if (referralId != null) 'referral_id': referralId,
            if (destinationFacilityId != null)
              'destination_facility_id': destinationFacilityId,
            'provider_key': 'mock',
            'is_mock': true,
            'status': 'requested',
          })
          .select()
          .single();

      return Success(_toDispatch(row));
    } catch (error, stackTrace) {
      return Err(const FailureMapperShim().map(error, stackTrace));
    }
  }

  @override
  Future<Result<AmbulanceDispatch>> status(String requestId) async {
    try {
      final row = await _client
          .from('ambulance_requests')
          .select()
          .eq('id', requestId)
          .single();
      return Success(_toDispatch(row));
    } catch (error, stackTrace) {
      return Err(const FailureMapperShim().map(error, stackTrace));
    }
  }

  @override
  Stream<AmbulanceDispatch> watch(String requestId) => _client
      .from('ambulance_requests')
      .stream(primaryKey: ['id'])
      .eq('id', requestId)
      .map((rows) => _toDispatch(rows.first));

  @override
  Future<Result<void>> cancel(String requestId, String reason) async {
    try {
      await _client
          .from('ambulance_requests')
          .update({'status': 'cancelled', 'cancellation_reason': reason})
          .eq('id', requestId);
      return const Success(null);
    } catch (error, stackTrace) {
      return Err(const FailureMapperShim().map(error, stackTrace));
    }
  }

  /// Advances the mock through its lifecycle, for demonstrations and tests.
  Future<void> simulateProgress(
    String requestId, {
    Duration step = const Duration(seconds: 5),
  }) async {
    const sequence = [
      AmbulanceStatus.dispatched,
      AmbulanceStatus.enRoutePickup,
      AmbulanceStatus.atPickup,
      AmbulanceStatus.enRouteDestination,
      AmbulanceStatus.completed,
    ];

    var eta = 18;
    for (final status in sequence) {
      await Future<void>.delayed(step);
      eta = (eta - 4).clamp(0, 60);
      await _client.from('ambulance_requests').update({
        'status': status.wire,
        'eta_minutes': eta,
        'vehicle_number': 'TN-25-AM-1042',
        'crew_contact': '9840000108',
        if (status == AmbulanceStatus.atPickup)
          'at_pickup_at': DateTime.now().toUtc().toIso8601String(),
        if (status == AmbulanceStatus.completed)
          'completed_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', requestId);
    }
  }

  Future<String> _resolveDistrict(String patientId) async {
    final row = await _client
        .from('patients')
        .select('district_id')
        .eq('id', patientId)
        .single();

    final districtId = row['district_id'] as String?;
    if (districtId == null) {
      throw const Failure(
        kind: FailureKind.invalidInput,
        messageKey: 'error.patient_district_unknown',
      );
    }
    return districtId;
  }

  AmbulanceDispatch _toDispatch(Map<String, Object?> row) => AmbulanceDispatch(
        requestId: row['id']! as String,
        status: AmbulanceStatus.parse(row['status'] as String?),
        externalReference: row['external_reference'] as String?,
        vehicleNumber: row['vehicle_number'] as String?,
        crewContact: row['crew_contact'] as String?,
        etaMinutes: (row['eta_minutes'] as num?)?.toInt(),
        isMock: row['is_mock'] as bool? ?? true,
      );
}

/// Small indirection so adapters can map errors without importing the
/// repository layer, keeping the dependency direction one-way.
class FailureMapperShim {
  const FailureMapperShim();

  Failure map(Object error, [StackTrace? stackTrace]) {
    if (error is Failure) return error;
    if (error is PostgrestException) {
      return Failure(
        kind: error.code == '42501'
            ? FailureKind.forbidden
            : FailureKind.integration,
        messageKey: 'error.ambulance_request_failed',
        detail: error.message,
        code: error.code,
        cause: error,
        isRetryable: true,
      );
    }
    return Failure(
      kind: FailureKind.integration,
      messageKey: 'error.ambulance_request_failed',
      detail: error.toString(),
      cause: error,
      isRetryable: true,
    );
  }
}
