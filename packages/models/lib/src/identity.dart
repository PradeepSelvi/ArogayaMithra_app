import 'package:meta/meta.dart';

import 'enums.dart';
import 'geo.dart';

/// The signed-in user's ArogyaMitra profile: role and authorization scope.
///
/// Role and scope are assigned by an administrator and enforced by database
/// policy. This object is a read-only projection for the UI (PRD 6 FR-002).
@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.role,
    required this.status,
    required this.preferredLanguage,
    this.phone,
    this.fullName,
    this.employeeCode,
    this.stateId,
    this.districtId,
    this.blockId,
    this.facilityId,
  });

  factory AppUser.fromJson(Map<String, Object?> json) => AppUser(
        id: json['id']! as String,
        role: UserRole.parse(json['role'] as String?),
        status: AccountStatus.parse(json['status'] as String?),
        preferredLanguage:
            LanguageCode.parse(json['preferred_language'] as String?),
        phone: json['phone'] as String?,
        fullName: json['full_name'] as String?,
        employeeCode: json['employee_code'] as String?,
        stateId: json['state_id'] as String?,
        districtId: json['district_id'] as String?,
        blockId: json['block_id'] as String?,
        facilityId: json['facility_id'] as String?,
      );

  final String id;
  final UserRole role;
  final AccountStatus status;
  final LanguageCode preferredLanguage;
  final String? phone;
  final String? fullName;
  final String? employeeCode;
  final String? stateId;
  final String? districtId;
  final String? blockId;
  final String? facilityId;

  bool get isActive => status == AccountStatus.active;

  /// A facility role is unusable without a facility assignment. Surfacing this
  /// as a blocked state is better than showing an empty console.
  bool get hasUsableScope => switch (role) {
        UserRole.citizen || UserRole.systemAdmin => true,
        UserRole.medicalOfficer || UserRole.facilityAdmin => facilityId != null,
        UserRole.asha || UserRole.anm => blockId != null || districtId != null,
        UserRole.dho => districtId != null,
        UserRole.stateAdmin => stateId != null || districtId != null,
      };
}

/// PRD 11 - Household.
@immutable
class Household {
  const Household({
    required this.id,
    required this.code,
    required this.villageId,
    required this.districtId,
    required this.memberCount,
    this.blockId,
    this.addressLine,
    this.landmark,
    this.headOfHousehold,
    this.contactPhone,
    this.geoPoint,
    this.assignedWorkerId,
    this.clientCreatedAt,
    this.syncedAt,
  });

  factory Household.fromJson(Map<String, Object?> json) => Household(
        id: json['id']! as String,
        code: json['code']! as String,
        villageId: json['village_id']! as String,
        districtId: json['district_id']! as String,
        memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
        blockId: json['block_id'] as String?,
        addressLine: json['address_line'] as String?,
        landmark: json['landmark'] as String?,
        headOfHousehold: json['head_of_household'] as String?,
        contactPhone: json['contact_phone'] as String?,
        assignedWorkerId: json['assigned_worker_id'] as String?,
        clientCreatedAt: _dateTime(json['client_created_at']),
        syncedAt: _dateTime(json['synced_at']),
      );

  final String id;
  final String code;
  final String villageId;
  final String districtId;
  final int memberCount;
  final String? blockId;
  final String? addressLine;
  final String? landmark;
  final String? headOfHousehold;
  final String? contactPhone;
  final GeoPoint? geoPoint;
  final String? assignedWorkerId;
  final DateTime? clientCreatedAt;
  final DateTime? syncedAt;

  /// True while this household exists only on the device (PRD 15).
  bool get isPendingSync => syncedAt == null;

  Map<String, Object?> toInsertJson() => {
        'id': id,
        'code': code,
        'village_id': villageId,
        if (addressLine != null) 'address_line': addressLine,
        if (landmark != null) 'landmark': landmark,
        if (headOfHousehold != null) 'head_of_household': headOfHousehold,
        if (contactPhone != null) 'contact_phone': contactPhone,
        if (assignedWorkerId != null) 'assigned_worker_id': assignedWorkerId,
        'client_created_at':
            (clientCreatedAt ?? DateTime.now().toUtc()).toIso8601String(),
      };
}

/// PRD 11 - Patient. Holds operational demographics and the risk context triage
/// needs. Clinical records stay in the source systems (PRD 3.2).
@immutable
class Patient {
  const Patient({
    required this.id,
    required this.fullName,
    required this.sex,
    required this.preferredLanguage,
    this.householdId,
    this.appUserId,
    this.ageYears,
    this.dateOfBirth,
    this.contactPhone,
    this.villageId,
    this.districtId,
    this.abhaAddress,
    this.abhaNumberLast4,
    this.isPregnant = false,
    this.chronicConditions = const [],
    this.allergies = const [],
  });

  factory Patient.fromJson(Map<String, Object?> json) => Patient(
        id: json['id']! as String,
        fullName: json['full_name']! as String,
        sex: Sex.parse(json['sex'] as String?),
        preferredLanguage:
            LanguageCode.parse(json['preferred_language'] as String?),
        householdId: json['household_id'] as String?,
        appUserId: json['app_user_id'] as String?,
        ageYears: (json['age_years'] as num?)?.toInt(),
        dateOfBirth: _dateTime(json['date_of_birth']),
        contactPhone: json['contact_phone'] as String?,
        villageId: json['village_id'] as String?,
        districtId: json['district_id'] as String?,
        abhaAddress: json['abha_address'] as String?,
        abhaNumberLast4: json['abha_number_last4'] as String?,
        isPregnant: json['is_pregnant'] as bool? ?? false,
        chronicConditions: _stringList(json['chronic_conditions']),
        allergies: _stringList(json['allergies']),
      );

  final String id;
  final String fullName;
  final Sex sex;
  final LanguageCode preferredLanguage;
  final String? householdId;
  final String? appUserId;
  final int? ageYears;
  final DateTime? dateOfBirth;
  final String? contactPhone;
  final String? villageId;
  final String? districtId;
  final String? abhaAddress;
  final String? abhaNumberLast4;
  final bool isPregnant;
  final List<String> chronicConditions;
  final List<String> allergies;

  bool get isChild => (ageYears ?? 99) < 5;

  /// Displayed instead of the full ABHA number so the identifier is never shown
  /// in full on screen (PRD 16).
  String? get maskedAbha =>
      abhaNumberLast4 == null ? null : 'XXXX XXXX XXXX $abhaNumberLast4';

  Map<String, Object?> toInsertJson() => {
        'id': id,
        'full_name': fullName,
        'sex': sex.wire,
        'preferred_language': preferredLanguage.wire,
        if (householdId != null) 'household_id': householdId,
        if (appUserId != null) 'app_user_id': appUserId,
        if (ageYears != null) 'age_years': ageYears,
        if (dateOfBirth != null)
          'date_of_birth': dateOfBirth!.toIso8601String().split('T').first,
        if (contactPhone != null) 'contact_phone': contactPhone,
        'is_pregnant': isPregnant,
        'chronic_conditions': chronicConditions,
        'allergies': allergies,
        'client_created_at': DateTime.now().toUtc().toIso8601String(),
      };

  Patient copyWith({
    String? fullName,
    Sex? sex,
    int? ageYears,
    bool? isPregnant,
    List<String>? chronicConditions,
    String? contactPhone,
  }) =>
      Patient(
        id: id,
        fullName: fullName ?? this.fullName,
        sex: sex ?? this.sex,
        preferredLanguage: preferredLanguage,
        householdId: householdId,
        appUserId: appUserId,
        ageYears: ageYears ?? this.ageYears,
        dateOfBirth: dateOfBirth,
        contactPhone: contactPhone ?? this.contactPhone,
        villageId: villageId,
        districtId: districtId,
        abhaAddress: abhaAddress,
        abhaNumberLast4: abhaNumberLast4,
        isPregnant: isPregnant ?? this.isPregnant,
        chronicConditions: chronicConditions ?? this.chronicConditions,
        allergies: allergies,
      );
}

DateTime? _dateTime(Object? raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  return DateTime.tryParse(raw as String)?.toLocal();
}

List<String> _stringList(Object? raw) {
  if (raw is List) {
    return raw.map((e) => e.toString()).toList(growable: false);
  }
  return const [];
}
