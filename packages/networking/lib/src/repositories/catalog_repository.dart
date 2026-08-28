import 'package:am_core/am_core.dart';
import 'package:am_models/am_models.dart';

import '../failure_mapper.dart';
import '../supabase_bootstrap.dart';

/// Reference data: symptoms, services, geography and the referral transition
/// table. All of it is slow-moving, so it is cached for the session and is the
/// first thing an offline-capable app should prefetch (PRD 15).
final class CatalogRepository extends SupabaseRepository {
  CatalogRepository(super.client);

  List<Symptom>? _symptoms;
  List<HealthService>? _services;
  List<ReferralTransition>? _transitions;

  /// Structured symptom vocabulary (PRD 6 FR-004).
  Future<Result<List<Symptom>>> symptoms() async {
    final cached = _symptoms;
    if (cached != null) return Success(cached);

    return guard(() async {
      final rows = await client
          .from('symptom_catalog')
          .select()
          .order('display_order');

      final parsed = rows.map(Symptom.fromJson).toList(growable: false);
      _symptoms = parsed;
      return parsed;
    });
  }

  /// Symptoms shown in the citizen quick-pick grid.
  Future<Result<List<Symptom>>> commonSymptoms() async {
    final all = await symptoms();
    return all.map(
      (list) => list.where((s) => s.isCommon).toList(growable: false),
    );
  }

  Future<Result<List<HealthService>>> services() async {
    final cached = _services;
    if (cached != null) return Success(cached);

    return guard(() async {
      final rows =
          await client.from('service_catalog').select().order('min_tier');
      final parsed = rows.map(HealthService.fromJson).toList(growable: false);
      _services = parsed;
      return parsed;
    });
  }

  /// The legal referral transitions, so a console can offer exactly the actions
  /// the database will accept for the signed-in role (PRD 12.2).
  Future<Result<List<ReferralTransition>>> referralTransitions() async {
    final cached = _transitions;
    if (cached != null) return Success(cached);

    return guard(() async {
      final rows = await client.from('referral_transitions').select();
      final parsed =
          rows.map(ReferralTransition.fromJson).toList(growable: false);
      _transitions = parsed;
      return parsed;
    });
  }

  /// Transitions available from [from] for [role].
  Future<Result<List<ReferralTransition>>> allowedTransitions({
    required ReferralStatus from,
    required UserRole role,
  }) async {
    final all = await referralTransitions();
    return all.map(
      (list) => list
          .where((t) => t.fromStatus == from && t.isAllowedFor(role))
          .toList(growable: false),
    );
  }

  Future<Result<List<AdminArea>>> districts() => guard(() async {
        final rows =
            await client.from('districts').select().order('name_en');
        return rows
            .map((r) => AdminArea.fromJson(r, parentKey: 'state_id'))
            .toList(growable: false);
      });

  Future<Result<List<AdminArea>>> blocks({required String districtId}) =>
      guard(() async {
        final rows = await client
            .from('blocks')
            .select()
            .eq('district_id', districtId)
            .order('name_en');
        return rows
            .map((r) => AdminArea.fromJson(r, parentKey: 'district_id'))
            .toList(growable: false);
      });

  Future<Result<List<AdminArea>>> villages({required String blockId}) =>
      guard(() async {
        final rows = await client
            .from('villages')
            .select()
            .eq('block_id', blockId)
            .order('name_en');
        return rows
            .map((r) => AdminArea.fromJson(r, parentKey: 'block_id'))
            .toList(growable: false);
      });

  /// Drops cached reference data, e.g. after a language or scope change.
  void invalidate() {
    _symptoms = null;
    _services = null;
    _transitions = null;
  }
}
