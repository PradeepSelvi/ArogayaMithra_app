/// Wire-compatible mirrors of the Postgres enum types.
///
/// Every enum carries an explicit [wire] value. Parsing an unrecognised value
/// throws rather than defaulting, because silently coercing an unknown clinical
/// risk level or referral status would hide a schema drift bug.
library;

/// Thrown when the database sends an enum label this build does not know.
class UnknownEnumValueException implements Exception {
  UnknownEnumValueException(this.enumName, this.value);

  final String enumName;
  final String value;

  @override
  String toString() =>
      'Unknown $enumName value "$value". The client build is out of step with '
      'the database schema.';
}

T _parse<T>(String enumName, String? raw, Map<String, T> byWire) {
  if (raw == null) {
    throw UnknownEnumValueException(enumName, 'null');
  }
  final value = byWire[raw];
  if (value == null) {
    throw UnknownEnumValueException(enumName, raw);
  }
  return value;
}

/// PRD 4 - roles.
enum UserRole {
  citizen('citizen'),
  asha('asha'),
  anm('anm'),
  medicalOfficer('medical_officer'),
  facilityAdmin('facility_admin'),
  dho('dho'),
  stateAdmin('state_admin'),
  systemAdmin('system_admin');

  const UserRole(this.wire);
  final String wire;

  static UserRole parse(String? raw) =>
      _parse('user_role', raw, {for (final v in values) v.wire: v});

  bool get isCitizen => this == UserRole.citizen;
  bool get isFieldWorker => this == UserRole.asha || this == UserRole.anm;
  bool get isFacilityStaff =>
      this == UserRole.medicalOfficer || this == UserRole.facilityAdmin;
  bool get isOversight =>
      this == UserRole.dho ||
      this == UserRole.stateAdmin ||
      this == UserRole.systemAdmin;
}

enum AccountStatus {
  pending('pending'),
  active('active'),
  suspended('suspended'),
  disabled('disabled');

  const AccountStatus(this.wire);
  final String wire;

  static AccountStatus parse(String? raw) =>
      _parse('account_status', raw, {for (final v in values) v.wire: v});
}

enum Sex {
  male('male'),
  female('female'),
  other('other'),
  undisclosed('undisclosed');

  const Sex(this.wire);
  final String wire;

  static Sex parse(String? raw) =>
      _parse('sex', raw, {for (final v in values) v.wire: v});
}

/// PRD 3 - Tamil and English first, architecture ready for more.
enum LanguageCode {
  tamil('ta'),
  english('en'),
  hindi('hi');

  const LanguageCode(this.wire);
  final String wire;

  static LanguageCode parse(String? raw) =>
      _parse('language_code', raw, {for (final v in values) v.wire: v});

  static LanguageCode? tryParse(String? raw) {
    if (raw == null) return null;
    for (final v in values) {
      if (v.wire == raw) return v;
    }
    return null;
  }
}

enum FacilityType {
  healthSubCentre('health_sub_centre'),
  hwc('hwc'),
  phc('phc'),
  chc('chc'),
  subDistrictHospital('sub_district_hospital'),
  districtHospital('district_hospital'),
  medicalCollege('medical_college'),
  privateHospital('private_hospital'),
  diagnosticCentre('diagnostic_centre');

  const FacilityType(this.wire);
  final String wire;

  static FacilityType parse(String? raw) =>
      _parse('facility_type', raw, {for (final v in values) v.wire: v});
}

enum ResourceKind {
  doctor('doctor'),
  nurse('nurse'),
  specialist('specialist'),
  essentialMedicine('essential_medicine'),
  diagnostic('diagnostic'),
  bed('bed'),
  icuBed('icu_bed'),
  oxygen('oxygen'),
  ambulance('ambulance'),
  equipment('equipment');

  const ResourceKind(this.wire);
  final String wire;

  static ResourceKind parse(String? raw) =>
      _parse('resource_kind', raw, {for (final v in values) v.wire: v});
}

/// PRD 12.3 - readiness component state.
enum AvailabilityStatus {
  available('available'),
  limited('limited'),
  unavailable('unavailable'),
  unknown('unknown');

  const AvailabilityStatus(this.wire);
  final String wire;

  static AvailabilityStatus parse(String? raw) =>
      _parse('availability_status', raw, {for (final v in values) v.wire: v});

  /// Never present "unknown" as reassuring. PRD 12.3 requires stale or missing
  /// data to be visibly flagged rather than rendered as available.
  bool get isReassuring => this == AvailabilityStatus.available;
}

/// PRD 12.2 - referral state machine.
enum ReferralStatus {
  created('CREATED'),
  triaged('TRIAGED'),
  recommended('RECOMMENDED'),
  referralSent('REFERRAL_SENT'),
  accepted('ACCEPTED'),
  patientTravelling('PATIENT_TRAVELLING'),
  arrived('ARRIVED'),
  consultation('CONSULTATION'),
  completed('COMPLETED'),
  rejected('REJECTED'),
  cancelled('CANCELLED'),
  expired('EXPIRED'),
  noShow('NO_SHOW'),
  emergencyEscalated('EMERGENCY_ESCALATED');

  const ReferralStatus(this.wire);
  final String wire;

  static ReferralStatus parse(String? raw) =>
      _parse('referral_status', raw, {for (final v in values) v.wire: v});

  /// Progress markers for the citizen-facing tracker.
  static const List<ReferralStatus> happyPath = [
    created,
    triaged,
    recommended,
    referralSent,
    accepted,
    patientTravelling,
    arrived,
    consultation,
    completed,
  ];

  /// Terminal states, mirroring the database transition table. The database is
  /// the authority; this is a UI convenience.
  bool get isClosed => const {
        ReferralStatus.completed,
        ReferralStatus.rejected,
        ReferralStatus.cancelled,
        ReferralStatus.expired,
        ReferralStatus.noShow,
      }.contains(this);

  bool get isAwaitingFacility => this == ReferralStatus.referralSent;

  bool get isEmergency => this == ReferralStatus.emergencyEscalated;

  /// Position along [happyPath], or null for an exception state.
  ///
  /// Returning null rather than clamping matters: an expired or rejected
  /// referral has no position on the normal journey, and showing one would tell
  /// the citizen progress is happening when it is not.
  int? get progressIndex {
    final index = happyPath.indexOf(this);
    return index < 0 ? null : index;
  }
}

enum ReferralPriority {
  routine('routine'),
  urgent('urgent'),
  emergency('emergency');

  const ReferralPriority(this.wire);
  final String wire;

  static ReferralPriority parse(String? raw) =>
      _parse('referral_priority', raw, {for (final v in values) v.wire: v});
}

/// PRD 6 FR-005 - triage outcome.
enum RiskLevel {
  low('low'),
  medium('medium'),
  high('high'),
  emergency('emergency');

  const RiskLevel(this.wire);
  final String wire;

  static RiskLevel parse(String? raw) =>
      _parse('risk_level', raw, {for (final v in values) v.wire: v});

  bool get requiresImmediateAction => this == RiskLevel.emergency;
}

enum NextAction {
  selfCare('self_care'),
  visitFacility('visit_facility'),
  teleconsult('teleconsult'),
  refer('refer'),
  emergencyResponse('emergency_response');

  const NextAction(this.wire);
  final String wire;

  static NextAction parse(String? raw) =>
      _parse('next_action', raw, {for (final v in values) v.wire: v});

  /// Whether this outcome should lead the citizen into facility selection.
  bool get needsFacility => const {
        NextAction.visitFacility,
        NextAction.refer,
        NextAction.emergencyResponse,
      }.contains(this);
}

enum FollowUpStatus {
  scheduled('scheduled'),
  due('due'),
  completed('completed'),
  missed('missed'),
  cancelled('cancelled');

  const FollowUpStatus(this.wire);
  final String wire;

  static FollowUpStatus parse(String? raw) =>
      _parse('followup_status', raw, {for (final v in values) v.wire: v});

  bool get isOpen =>
      this == FollowUpStatus.scheduled || this == FollowUpStatus.due;
}

enum NotificationChannel {
  push('push'),
  sms('sms'),
  ivr('ivr'),
  inApp('in_app'),
  whatsapp('whatsapp');

  const NotificationChannel(this.wire);
  final String wire;

  static NotificationChannel parse(String? raw) =>
      _parse('notification_channel', raw, {for (final v in values) v.wire: v});
}

enum DeliveryStatus {
  queued('queued'),
  sent('sent'),
  delivered('delivered'),
  failed('failed'),
  suppressed('suppressed');

  const DeliveryStatus(this.wire);
  final String wire;

  static DeliveryStatus parse(String? raw) =>
      _parse('delivery_status', raw, {for (final v in values) v.wire: v});
}

enum AmbulanceStatus {
  requested('requested'),
  dispatched('dispatched'),
  enRoutePickup('en_route_pickup'),
  atPickup('at_pickup'),
  enRouteDestination('en_route_destination'),
  completed('completed'),
  cancelled('cancelled'),
  failed('failed');

  const AmbulanceStatus(this.wire);
  final String wire;

  static AmbulanceStatus parse(String? raw) =>
      _parse('ambulance_status', raw, {for (final v in values) v.wire: v});
}

enum TeleconsultStatus {
  requested('requested'),
  scheduled('scheduled'),
  inProgress('in_progress'),
  completed('completed'),
  cancelled('cancelled'),
  failed('failed');

  const TeleconsultStatus(this.wire);
  final String wire;

  static TeleconsultStatus parse(String? raw) =>
      _parse('teleconsult_status', raw, {for (final v in values) v.wire: v});
}

/// PRD 12.3 / 5.4 - readiness banding used by the heatmap.
enum ReadinessBand {
  good('good'),
  partial('partial'),
  critical('critical'),
  stale('stale');

  const ReadinessBand(this.wire);
  final String wire;

  static ReadinessBand parse(String? raw) =>
      _parse('readiness_band', raw, {for (final v in values) v.wire: v});
}
