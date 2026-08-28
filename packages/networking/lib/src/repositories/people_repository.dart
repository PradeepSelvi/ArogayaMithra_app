import 'package:am_core/am_core.dart';
import 'package:am_models/am_models.dart';

import '../failure_mapper.dart';
import '../supabase_bootstrap.dart';

/// Profiles, households and patients.
///
/// Every read here is filtered by row-level security, so an empty result means
/// "not visible to you", not "does not exist". Callers must not present it as
/// deletion (PRD 16, 27).
final class PeopleRepository extends SupabaseRepository {
  PeopleRepository(super.client, {IdempotencyKeys? keys})
      : _keys = keys ?? IdempotencyKeys();

  final IdempotencyKeys _keys;

  /// The signed-in user's ArogyaMitra profile, including role and scope.
  Future<Result<AppUser>> currentUser() => guard(() async {
        final userId = client.auth.currentUser?.id;
        if (userId == null) {
          throw const Failure.unauthenticated();
        }

        final row = await client
            .from('app_users')
            .select()
            .eq('id', userId)
            .maybeSingle();

        if (row == null) {
          // The profile trigger should make this impossible; treat it as a
          // blocked account rather than guessing a role.
          throw const Failure(
            kind: FailureKind.forbidden,
            messageKey: 'error.profile_missing',
          );
        }

        return AppUser.fromJson(row);
      });

  Future<Result<AppUser>> updatePreferredLanguage(LanguageCode language) =>
      guard(() async {
        final userId = client.auth.currentUser?.id;
        if (userId == null) throw const Failure.unauthenticated();

        final row = await client
            .from('app_users')
            .update({'preferred_language': language.wire})
            .eq('id', userId)
            .select()
            .single();

        return AppUser.fromJson(row);
      });

  /// The patient record that represents the signed-in citizen.
  Future<Result<Patient?>> selfPatient() => guard(() async {
        final userId = client.auth.currentUser?.id;
        if (userId == null) throw const Failure.unauthenticated();

        final row = await client
            .from('patients')
            .select()
            .eq('app_user_id', userId)
            .maybeSingle();

        return row == null ? null : Patient.fromJson(row);
      });

  /// Creates the citizen's own patient record on first use.
  ///
  /// The client supplies the id so a retry after a dropped response updates the
  /// same row instead of creating a duplicate (PRD 15).
  Future<Result<Patient>> registerSelf({
    required String fullName,
    required Sex sex,
    required int ageYears,
    required LanguageCode language,
    bool isPregnant = false,
    List<String> chronicConditions = const [],
    String? contactPhone,
  }) =>
      guard(() async {
        final userId = client.auth.currentUser?.id;
        if (userId == null) throw const Failure.unauthenticated();

        final patient = Patient(
          id: _keys.newRecordId(),
          appUserId: userId,
          fullName: fullName,
          sex: sex,
          ageYears: ageYears,
          preferredLanguage: language,
          isPregnant: isPregnant,
          chronicConditions: chronicConditions,
          contactPhone: contactPhone,
        );

        final row = await client
            .from('patients')
            .upsert(patient.toInsertJson(), onConflict: 'id')
            .select()
            .single();

        return Patient.fromJson(row);
      });

  Future<Result<Patient>> updatePatient(Patient patient) => guard(() async {
        final row = await client
            .from('patients')
            .update({
              'full_name': patient.fullName,
              'sex': patient.sex.wire,
              'age_years': patient.ageYears,
              'is_pregnant': patient.isPregnant,
              'chronic_conditions': patient.chronicConditions,
              if (patient.contactPhone != null)
                'contact_phone': patient.contactPhone,
            })
            .eq('id', patient.id)
            .select()
            .single();

        return Patient.fromJson(row);
      });

  /// Households assigned to the signed-in field worker (PRD 5.2).
  Future<Result<List<Household>>> assignedHouseholds() => guard(() async {
        final rows =
            await client.from('households').select().order('code');
        return rows.map(Household.fromJson).toList(growable: false);
      });

  Future<Result<List<Patient>>> householdMembers(String householdId) =>
      guard(() async {
        final rows = await client
            .from('patients')
            .select()
            .eq('household_id', householdId)
            .order('full_name');
        return rows.map(Patient.fromJson).toList(growable: false);
      });

  /// Registers a household. Safe to call again with the same [household] after a
  /// failed sync: the id is client-generated and the write is an upsert.
  Future<Result<Household>> saveHousehold(Household household) =>
      guard(() async {
        final row = await client
            .from('households')
            .upsert(household.toInsertJson(), onConflict: 'id')
            .select()
            .single();
        return Household.fromJson(row);
      });

  Future<Result<Patient>> savePatient(Patient patient) => guard(() async {
        final row = await client
            .from('patients')
            .upsert(patient.toInsertJson(), onConflict: 'id')
            .select()
            .single();
        return Patient.fromJson(row);
      });

  /// A new client-generated id for an offline-first write.
  String newRecordId() => _keys.newRecordId();

  /// A key that makes one logical command safe to retry.
  String idempotencyKeyFor(String operation, {required String scope}) =>
      _keys.forOperation(operation, scope: scope);
}
