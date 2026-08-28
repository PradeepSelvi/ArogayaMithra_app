import 'package:meta/meta.dart';

import 'enums.dart';
import 'geo.dart';

/// A service the platform can require of a facility (PRD 12.3).
@immutable
class HealthService {
  const HealthService({
    required this.code,
    required this.nameEn,
    required this.nameTa,
    required this.category,
    required this.minTier,
    required this.isEmergencyService,
  });

  factory HealthService.fromJson(Map<String, Object?> json) => HealthService(
        code: json['code']! as String,
        nameEn: json['name_en']! as String,
        nameTa: json['name_ta']! as String,
        category: json['category']! as String,
        minTier: (json['min_tier'] as num?)?.toInt() ?? 1,
        isEmergencyService: json['is_emergency_service'] as bool? ?? false,
      );

  final String code;
  final String nameEn;
  final String nameTa;
  final String category;
  final int minTier;
  final bool isEmergencyService;

  String label(LanguageCode language) =>
      language == LanguageCode.tamil ? nameTa : nameEn;
}

/// A readiness component with the timestamp that makes staleness visible.
@immutable
class ReadinessComponent {
  const ReadinessComponent({
    required this.status,
    required this.weight,
  });

  final AvailabilityStatus status;
  final double weight;
}

/// PRD 11 ReadinessCheck / PRD 12.3.
///
/// [confidence] and [isStale] exist so the UI can never present unverified data
/// as a firm promise of care.
@immutable
class FacilityReadiness {
  const FacilityReadiness({
    required this.score,
    required this.confidence,
    required this.doctorStatus,
    required this.medicinesStatus,
    required this.diagnosticsStatus,
    required this.bedsStatus,
    required this.isStale,
    this.checkedAt,
  });

  factory FacilityReadiness.fromJson(Map<String, Object?> json) =>
      FacilityReadiness(
        score: (json['readiness_score'] as num?)?.toDouble() ?? 0,
        confidence: (json['readiness_confidence'] as num?)?.toDouble() ?? 0,
        doctorStatus: AvailabilityStatus.parse(json['doctor_status'] as String?),
        medicinesStatus:
            AvailabilityStatus.parse(json['medicines_status'] as String?),
        diagnosticsStatus:
            AvailabilityStatus.parse(json['diagnostics_status'] as String?),
        bedsStatus: AvailabilityStatus.parse(json['beds_status'] as String?),
        isStale: json['is_stale'] as bool? ?? true,
        checkedAt: _dateTime(json['checked_at']),
      );

  /// 0..1 weighted readiness.
  final double score;

  /// 0..1 how much of the input was explicitly set and fresh.
  final double confidence;

  final AvailabilityStatus doctorStatus;
  final AvailabilityStatus medicinesStatus;
  final AvailabilityStatus diagnosticsStatus;
  final AvailabilityStatus bedsStatus;
  final bool isStale;
  final DateTime? checkedAt;

  ReadinessBand get band {
    if (isStale) return ReadinessBand.stale;
    if (score >= 0.75) return ReadinessBand.good;
    if (score >= 0.45) return ReadinessBand.partial;
    return ReadinessBand.critical;
  }

  /// Whether the citizen should be warned before travelling.
  bool get needsCaution =>
      isStale ||
      confidence < 0.5 ||
      doctorStatus != AvailabilityStatus.available;
}

/// PRD 11 - Facility.
@immutable
class Facility {
  const Facility({
    required this.id,
    required this.nameEn,
    required this.type,
    required this.tier,
    required this.districtId,
    required this.location,
    required this.is24x7,
    required this.hasEmergencyDepartment,
    this.nameLocal,
    this.hfrId,
    this.address,
    this.contactPhone,
    this.emergencyPhone,
    this.isOperational = true,
  });

  factory Facility.fromJson(Map<String, Object?> json) => Facility(
        id: (json['id'] ?? json['facility_id'])! as String,
        nameEn: json['name_en']! as String,
        type: FacilityType.parse(json['type'] as String?),
        tier: (json['tier'] as num?)?.toInt() ?? 1,
        districtId: json['district_id']! as String,
        location: GeoPoint(
          latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
          longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        ),
        is24x7: json['is_24x7'] as bool? ?? false,
        hasEmergencyDepartment:
            json['has_emergency_department'] as bool? ?? false,
        nameLocal: json['name_local'] as String?,
        hfrId: json['hfr_id'] as String?,
        address: json['address'] as String?,
        contactPhone: json['contact_phone'] as String?,
        emergencyPhone: json['emergency_phone'] as String?,
        isOperational: json['is_operational'] as bool? ?? true,
      );

  final String id;
  final String nameEn;
  final String? nameLocal;
  final FacilityType type;
  final int tier;
  final String districtId;
  final GeoPoint location;
  final bool is24x7;
  final bool hasEmergencyDepartment;
  final String? hfrId;
  final String? address;
  final String? contactPhone;
  final String? emergencyPhone;
  final bool isOperational;

  String displayName(LanguageCode language) =>
      language == LanguageCode.tamil ? (nameLocal ?? nameEn) : nameEn;

  /// Number to call for this facility, preferring the emergency line.
  String? get callablePhone => emergencyPhone ?? contactPhone;
}

/// A ranked search result from `search_facilities`.
///
/// Carries the per-factor breakdown so the recommendation can be explained to
/// the citizen rather than presented as an opaque score (PRD 12.1).
@immutable
class FacilityCandidate {
  const FacilityCandidate({
    required this.facility,
    required this.readiness,
    required this.distanceMetres,
    required this.travelTimeMinutes,
    required this.serviceMatch,
    required this.waitScore,
    required this.score,
    required this.scoreComponents,
    this.scoreConfigVersion,
  });

  factory FacilityCandidate.fromJson(Map<String, Object?> json) =>
      FacilityCandidate(
        facility: Facility.fromJson(json),
        readiness: FacilityReadiness.fromJson(json),
        distanceMetres: (json['distance_m'] as num?)?.toDouble() ?? 0,
        travelTimeMinutes: (json['travel_time_min'] as num?)?.toDouble() ?? 0,
        serviceMatch: (json['service_match'] as num?)?.toDouble() ?? 0,
        waitScore: (json['wait_score'] as num?)?.toDouble() ?? 0,
        score: (json['facility_score'] as num?)?.toDouble() ?? 0,
        scoreComponents:
            (json['score_components'] as Map?)?.cast<String, Object?>() ??
                const {},
        scoreConfigVersion: (json['score_config_version'] as num?)?.toInt(),
      );

  final Facility facility;
  final FacilityReadiness readiness;
  final double distanceMetres;
  final double travelTimeMinutes;

  /// 0..1 share of the required services this facility can deliver now.
  final double serviceMatch;

  /// 0..1 inverse of expected wait.
  final double waitScore;

  /// 0..1 overall configurable score.
  final double score;

  final Map<String, Object?> scoreComponents;
  final int? scoreConfigVersion;

  double get distanceKm => distanceMetres / 1000;

  /// True when this facility cannot deliver everything triage asked for. The UI
  /// must say so rather than hiding the gap.
  bool get hasServiceGap => serviceMatch < 1.0;

  /// Snapshot persisted on the referral so the decision stays explainable after
  /// readiness has moved on.
  Map<String, Object?> toScoreSnapshot() => {
        'facility_score': score,
        'distance_m': distanceMetres,
        'travel_time_min': travelTimeMinutes,
        'service_match': serviceMatch,
        'wait_score': waitScore,
        'readiness_score': readiness.score,
        'readiness_confidence': readiness.confidence,
        'is_stale': readiness.isStale,
        'components': scoreComponents,
      };
}

/// A single tracked resource inside a facility (PRD 11 FacilityResource).
@immutable
class FacilityResource {
  const FacilityResource({
    required this.id,
    required this.facilityId,
    required this.kind,
    required this.itemCode,
    required this.labelEn,
    required this.status,
    this.labelTa,
    this.quantity,
    this.capacity,
    this.isManualOverride = false,
    this.overrideReason,
    this.updatedAt,
  });

  factory FacilityResource.fromJson(Map<String, Object?> json) =>
      FacilityResource(
        id: json['id']! as String,
        facilityId: json['facility_id']! as String,
        kind: ResourceKind.parse(json['kind'] as String?),
        itemCode: json['item_code']! as String,
        labelEn: json['label_en']! as String,
        status: AvailabilityStatus.parse(json['status'] as String?),
        labelTa: json['label_ta'] as String?,
        quantity: (json['quantity'] as num?)?.toInt(),
        capacity: (json['capacity'] as num?)?.toInt(),
        isManualOverride: json['is_manual_override'] as bool? ?? false,
        overrideReason: json['override_reason'] as String?,
        updatedAt: _dateTime(json['updated_at']),
      );

  final String id;
  final String facilityId;
  final ResourceKind kind;
  final String itemCode;
  final String labelEn;
  final String? labelTa;
  final AvailabilityStatus status;
  final int? quantity;
  final int? capacity;
  final bool isManualOverride;
  final String? overrideReason;
  final DateTime? updatedAt;

  String label(LanguageCode language) =>
      language == LanguageCode.tamil ? (labelTa ?? labelEn) : labelEn;

  /// Age of this reading. The console flags anything the citizen would be
  /// misled by (PRD 12.3).
  Duration? get age =>
      updatedAt == null ? null : DateTime.now().difference(updatedAt!);
}

DateTime? _dateTime(Object? raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  return DateTime.tryParse(raw as String)?.toLocal();
}
