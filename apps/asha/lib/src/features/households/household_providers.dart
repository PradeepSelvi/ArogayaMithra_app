import 'package:am_models/am_models.dart';
import 'package:am_networking/am_networking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Households assigned to the signed-in worker.
///
/// The set is decided by row-level security from the worker's block assignment,
/// so there is no district or block parameter to get wrong here (PRD 27).
final assignedHouseholdsProvider = FutureProvider<List<Household>>((ref) async {
  final result =
      await ref.watch(peopleRepositoryProvider).assignedHouseholds();
  return result.fold(
    onSuccess: (list) => list,
    onFailure: (failure) => throw failure,
  );
});

final householdMembersProvider =
    FutureProvider.family<List<Patient>, String>((ref, householdId) async {
  final result =
      await ref.watch(peopleRepositoryProvider).householdMembers(householdId);
  return result.fold(
    onSuccess: (list) => list,
    onFailure: (failure) => throw failure,
  );
});

/// Villages the worker can register a household in.
final workerVillagesProvider = FutureProvider<List<AdminArea>>((ref) async {
  final catalog = ref.watch(catalogRepositoryProvider);
  final districts = await catalog.districts();

  final firstDistrict = districts.valueOrNull?.firstOrNull;
  if (firstDistrict == null) return const [];

  final blocks = await catalog.blocks(districtId: firstDistrict.id);
  final villages = <AdminArea>[];

  for (final block in blocks.valueOrNull ?? const <AdminArea>[]) {
    final result = await catalog.villages(blockId: block.id);
    villages.addAll(result.valueOrNull ?? const []);
  }

  return villages;
});
