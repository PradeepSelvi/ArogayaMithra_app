import 'package:meta/meta.dart';

import 'enums.dart';

/// PRD 11 - Referral.
///
/// [status] is authoritative on the server: the database rejects any transition
/// that is not in its transition table, so the client never decides what is
/// legal, only what to offer (PRD 12.2, FR-010).
@immutable
class Referral {
  const Referral({
    required this.id,
    required this.referenceCode,
    required this.patientId,
    required this.districtId,
    required this.priority,
    required this.status,
    required this.requiredServices,
    required this.createdAt,
    this.destinationFacilityId,
    this.sourceFacilityId,
    this.triageAssessmentId,
    this.riskLevel,
    this.reason,
    this.clinicalNotes,
    this.scoreSnapshot,
    this.slaDueAt,
    this.expiresAt,
    this.slaBreached = false,
    this.sentAt,
    this.acceptedAt,
    this.arrivedAt,
    this.consultationAt,
    this.closedAt,
    this.rejectionReason,
    this.cancellationReason,
    this.outcome,
    this.assignedWorkerId,
  });

  factory Referral.fromJson(Map<String, Object?> json) => Referral(
        id: json['id']! as String,
        referenceCode: json['reference_code']! as String,
        patientId: json['patient_id']! as String,
        districtId: json['district_id']! as String,
        priority: ReferralPriority.parse(json['priority'] as String?),
        status: ReferralStatus.parse(json['status'] as String?),
        requiredServices: _stringList(json['required_services']),
        createdAt: DateTime.parse(json['created_at']! as String).toLocal(),
        destinationFacilityId: json['destination_facility_id'] as String?,
        sourceFacilityId: json['source_facility_id'] as String?,
        triageAssessmentId: json['triage_assessment_id'] as String?,
        riskLevel: json['risk_level'] == null
            ? null
            : RiskLevel.parse(json['risk_level'] as String?),
        reason: json['reason'] as String?,
        clinicalNotes: json['clinical_notes'] as String?,
        scoreSnapshot:
            (json['score_snapshot'] as Map?)?.cast<String, Object?>(),
        slaDueAt: _dateTime(json['sla_due_at']),
        expiresAt: _dateTime(json['expires_at']),
        slaBreached: json['sla_breached'] as bool? ?? false,
        sentAt: _dateTime(json['sent_at']),
        acceptedAt: _dateTime(json['accepted_at']),
        arrivedAt: _dateTime(json['arrived_at']),
        consultationAt: _dateTime(json['consultation_at']),
        closedAt: _dateTime(json['closed_at']),
        rejectionReason: json['rejection_reason'] as String?,
        cancellationReason: json['cancellation_reason'] as String?,
        outcome: json['outcome'] as String?,
        assignedWorkerId: json['assigned_worker_id'] as String?,
      );

  final String id;

  /// Human-readable code the citizen quotes at the facility, e.g. RF-2026-0A3C91.
  final String referenceCode;

  final String patientId;
  final String districtId;
  final ReferralPriority priority;
  final ReferralStatus status;
  final List<String> requiredServices;
  final DateTime createdAt;
  final String? destinationFacilityId;
  final String? sourceFacilityId;
  final String? triageAssessmentId;
  final RiskLevel? riskLevel;
  final String? reason;
  final String? clinicalNotes;

  /// Why this facility was chosen, captured at decision time (PRD 12.1).
  final Map<String, Object?>? scoreSnapshot;

  final DateTime? slaDueAt;
  final DateTime? expiresAt;
  final bool slaBreached;
  final DateTime? sentAt;
  final DateTime? acceptedAt;
  final DateTime? arrivedAt;
  final DateTime? consultationAt;
  final DateTime? closedAt;
  final String? rejectionReason;
  final String? cancellationReason;
  final String? outcome;
  final String? assignedWorkerId;

  bool get isOpen => !status.isClosed;
  bool get isEmergency => priority == ReferralPriority.emergency;

  /// Time left for the destination facility to respond. Negative once breached.
  Duration? get timeToSla => slaDueAt?.difference(DateTime.now());

  bool get isOverdue =>
      slaBreached ||
      (status.isAwaitingFacility &&
          slaDueAt != null &&
          slaDueAt!.isBefore(DateTime.now()));

  /// Index into [ReferralStatus.happyPath] for the citizen progress tracker.
  /// Null for exception states, which are shown differently.
  int? get progressIndex => status.progressIndex;
}

/// PRD 11 ReferralEvent - one immutable entry in the referral timeline.
@immutable
class ReferralEvent {
  const ReferralEvent({
    required this.id,
    required this.referralId,
    required this.eventType,
    required this.occurredAt,
    this.fromStatus,
    this.toStatus,
    this.reason,
    this.actorRole,
    this.metadata = const {},
  });

  factory ReferralEvent.fromJson(Map<String, Object?> json) => ReferralEvent(
        id: (json['id'] as num).toInt(),
        referralId: json['referral_id']! as String,
        eventType: json['event_type']! as String,
        occurredAt: DateTime.parse(json['occurred_at']! as String).toLocal(),
        fromStatus: json['from_status'] == null
            ? null
            : ReferralStatus.parse(json['from_status'] as String?),
        toStatus: json['to_status'] == null
            ? null
            : ReferralStatus.parse(json['to_status'] as String?),
        reason: json['reason'] as String?,
        actorRole: json['actor_role'] == null
            ? null
            : UserRole.parse(json['actor_role'] as String?),
        metadata: (json['metadata'] as Map?)?.cast<String, Object?>() ?? const {},
      );

  final int id;
  final String referralId;
  final String eventType;
  final DateTime occurredAt;
  final ReferralStatus? fromStatus;
  final ReferralStatus? toStatus;
  final String? reason;

  /// Null when the change was made by scheduled automation, such as the SLA
  /// expiry sweep.
  final UserRole? actorRole;

  final Map<String, Object?> metadata;

  bool get isAutomated => actorRole == null;
}

/// A legal transition, read from the database so the UI offers exactly the
/// actions the server will accept (PRD 12.2).
@immutable
class ReferralTransition {
  const ReferralTransition({
    required this.fromStatus,
    required this.toStatus,
    required this.allowedRoles,
    required this.requiresReason,
    this.description,
  });

  factory ReferralTransition.fromJson(Map<String, Object?> json) =>
      ReferralTransition(
        fromStatus: ReferralStatus.parse(json['from_status'] as String?),
        toStatus: ReferralStatus.parse(json['to_status'] as String?),
        allowedRoles: _stringList(json['allowed_roles'])
            .map(UserRole.parse)
            .toList(growable: false),
        requiresReason: json['requires_reason'] as bool? ?? false,
        description: json['description'] as String?,
      );

  final ReferralStatus fromStatus;
  final ReferralStatus toStatus;

  /// Empty means any authenticated role in scope may perform it.
  final List<UserRole> allowedRoles;

  final bool requiresReason;
  final String? description;

  bool isAllowedFor(UserRole role) =>
      allowedRoles.isEmpty || allowedRoles.contains(role);
}

DateTime? _dateTime(Object? raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  return DateTime.tryParse(raw as String)?.toLocal();
}

List<String> _stringList(Object? raw) {
  if (raw is List) return raw.map((e) => e.toString()).toList(growable: false);
  return const [];
}
