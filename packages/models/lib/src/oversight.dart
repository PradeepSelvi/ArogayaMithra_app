import 'package:meta/meta.dart';

import 'enums.dart';
import 'geo.dart';

/// PRD 19 - referral KPIs for one district and day.
@immutable
class ReferralKpi {
  const ReferralKpi({
    required this.districtId,
    required this.districtName,
    required this.day,
    required this.created,
    required this.sent,
    required this.accepted,
    required this.rejected,
    required this.completed,
    required this.expired,
    required this.noShow,
    required this.emergencyEscalations,
    required this.slaBreaches,
    this.acceptanceRate,
    this.completionRate,
    this.medianAcceptMinutes,
    this.medianTurnaroundMinutes,
  });

  factory ReferralKpi.fromJson(Map<String, Object?> json) => ReferralKpi(
        districtId: json['district_id']! as String,
        districtName: json['district_name']! as String,
        day: DateTime.parse(json['day']! as String),
        created: (json['referrals_created'] as num?)?.toInt() ?? 0,
        sent: (json['referrals_sent'] as num?)?.toInt() ?? 0,
        accepted: (json['referrals_accepted'] as num?)?.toInt() ?? 0,
        rejected: (json['referrals_rejected'] as num?)?.toInt() ?? 0,
        completed: (json['referrals_completed'] as num?)?.toInt() ?? 0,
        expired: (json['referrals_expired'] as num?)?.toInt() ?? 0,
        noShow: (json['referrals_no_show'] as num?)?.toInt() ?? 0,
        emergencyEscalations:
            (json['emergency_escalations'] as num?)?.toInt() ?? 0,
        slaBreaches: (json['sla_breaches'] as num?)?.toInt() ?? 0,
        acceptanceRate: (json['acceptance_rate'] as num?)?.toDouble(),
        completionRate: (json['completion_rate'] as num?)?.toDouble(),
        medianAcceptMinutes:
            (json['median_accept_minutes'] as num?)?.toDouble(),
        medianTurnaroundMinutes:
            (json['median_turnaround_minutes'] as num?)?.toDouble(),
      );

  final String districtId;
  final String districtName;
  final DateTime day;
  final int created;
  final int sent;
  final int accepted;
  final int rejected;
  final int completed;
  final int expired;
  final int noShow;
  final int emergencyEscalations;
  final int slaBreaches;
  final double? acceptanceRate;
  final double? completionRate;
  final double? medianAcceptMinutes;
  final double? medianTurnaroundMinutes;
}

/// PRD 5.4 - one cell of the readiness heatmap.
@immutable
class FacilityReadinessSummary {
  const FacilityReadinessSummary({
    required this.facilityId,
    required this.nameEn,
    required this.type,
    required this.tier,
    required this.districtId,
    required this.districtName,
    required this.location,
    required this.readinessScore,
    required this.readinessConfidence,
    required this.doctorStatus,
    required this.medicinesStatus,
    required this.diagnosticsStatus,
    required this.bedsStatus,
    required this.band,
    required this.isStale,
    required this.openIncomingReferrals,
    this.nameLocal,
    this.checkedAt,
  });

  factory FacilityReadinessSummary.fromJson(Map<String, Object?> json) =>
      FacilityReadinessSummary(
        facilityId: json['facility_id']! as String,
        nameEn: json['name_en']! as String,
        type: FacilityType.parse(json['type'] as String?),
        tier: (json['tier'] as num?)?.toInt() ?? 1,
        districtId: json['district_id']! as String,
        districtName: json['district_name']! as String,
        location: GeoPoint(
          latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
          longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        ),
        readinessScore: (json['readiness_score'] as num?)?.toDouble() ?? 0,
        readinessConfidence:
            (json['readiness_confidence'] as num?)?.toDouble() ?? 0,
        doctorStatus: AvailabilityStatus.parse(json['doctor_status'] as String?),
        medicinesStatus:
            AvailabilityStatus.parse(json['medicines_status'] as String?),
        diagnosticsStatus:
            AvailabilityStatus.parse(json['diagnostics_status'] as String?),
        bedsStatus: AvailabilityStatus.parse(json['beds_status'] as String?),
        band: ReadinessBand.parse(json['readiness_band'] as String?),
        isStale: json['is_stale'] as bool? ?? true,
        openIncomingReferrals:
            (json['open_incoming_referrals'] as num?)?.toInt() ?? 0,
        nameLocal: json['name_local'] as String?,
        checkedAt: _dateTime(json['checked_at']),
      );

  final String facilityId;
  final String nameEn;
  final String? nameLocal;
  final FacilityType type;
  final int tier;
  final String districtId;
  final String districtName;
  final GeoPoint location;
  final double readinessScore;
  final double readinessConfidence;
  final AvailabilityStatus doctorStatus;
  final AvailabilityStatus medicinesStatus;
  final AvailabilityStatus diagnosticsStatus;
  final AvailabilityStatus bedsStatus;
  final ReadinessBand band;
  final bool isStale;
  final int openIncomingReferrals;
  final DateTime? checkedAt;

  String displayName(LanguageCode language) =>
      language == LanguageCode.tamil ? (nameLocal ?? nameEn) : nameEn;
}

/// PRD 5.4 / 18 - a live operational alert.
@immutable
class OperationalAlert {
  const OperationalAlert({
    required this.alertType,
    required this.severity,
    required this.subjectId,
    required this.subjectLabel,
    required this.raisedAt,
    this.districtId,
    this.facilityId,
    this.dueAt,
    this.details = const {},
  });

  factory OperationalAlert.fromJson(Map<String, Object?> json) =>
      OperationalAlert(
        alertType: json['alert_type']! as String,
        severity: json['severity']! as String,
        subjectId: json['subject_id']! as String,
        subjectLabel: json['subject_label']! as String,
        raisedAt: DateTime.parse(json['raised_at']! as String).toLocal(),
        districtId: json['district_id'] as String?,
        facilityId: json['facility_id'] as String?,
        dueAt: _dateTime(json['due_at']),
        details: (json['details'] as Map?)?.cast<String, Object?>() ?? const {},
      );

  /// One of: referral_sla_breach, readiness_critical, feedback_issue.
  final String alertType;

  /// critical or warning.
  final String severity;

  final String subjectId;
  final String subjectLabel;
  final DateTime raisedAt;
  final String? districtId;
  final String? facilityId;
  final DateTime? dueAt;
  final Map<String, Object?> details;

  bool get isCritical => severity == 'critical';
}

/// PRD 19 - citizen satisfaction rollup.
@immutable
class FeedbackKpi {
  const FeedbackKpi({
    required this.month,
    required this.responses,
    required this.averageRating,
    required this.detractors,
    required this.promoters,
    required this.openIssues,
    this.facilityId,
    this.facilityName,
    this.npsLike,
    this.topCategory,
  });

  factory FeedbackKpi.fromJson(Map<String, Object?> json) => FeedbackKpi(
        month: DateTime.parse(json['month']! as String),
        responses: (json['responses'] as num?)?.toInt() ?? 0,
        averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
        detractors: (json['detractors'] as num?)?.toInt() ?? 0,
        promoters: (json['promoters'] as num?)?.toInt() ?? 0,
        openIssues: (json['open_issues'] as num?)?.toInt() ?? 0,
        facilityId: json['facility_id'] as String?,
        facilityName: json['facility_name'] as String?,
        npsLike: (json['nps_like'] as num?)?.toDouble(),
        topCategory: json['top_category'] as String?,
      );

  final DateTime month;
  final int responses;
  final double averageRating;
  final int detractors;
  final int promoters;
  final int openIssues;
  final String? facilityId;
  final String? facilityName;
  final double? npsLike;
  final String? topCategory;
}

/// PRD 19 - follow-up compliance rollup.
@immutable
class FollowUpKpi {
  const FollowUpKpi({
    required this.week,
    required this.total,
    required this.completed,
    required this.missed,
    required this.pending,
    this.completionRate,
  });

  factory FollowUpKpi.fromJson(Map<String, Object?> json) => FollowUpKpi(
        week: DateTime.parse(json['week']! as String),
        total: (json['total_followups'] as num?)?.toInt() ?? 0,
        completed: (json['completed'] as num?)?.toInt() ?? 0,
        missed: (json['missed'] as num?)?.toInt() ?? 0,
        pending: (json['pending'] as num?)?.toInt() ?? 0,
        completionRate: (json['completion_rate'] as num?)?.toDouble(),
      );

  final DateTime week;
  final int total;
  final int completed;
  final int missed;
  final int pending;
  final double? completionRate;
}

DateTime? _dateTime(Object? raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  return DateTime.tryParse(raw as String)?.toLocal();
}
