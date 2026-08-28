import 'package:am_core/am_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'adapters/ambulance_adapter.dart';
import 'adapters/language_adapter.dart';
import 'adapters/teleconsult_adapter.dart';
import 'repositories/catalog_repository.dart';
import 'repositories/engagement_repository.dart';
import 'repositories/facility_repository.dart';
import 'repositories/oversight_repository.dart';
import 'repositories/people_repository.dart';
import 'repositories/referral_repository.dart';
import 'repositories/triage_repository.dart';

/// Runtime configuration. Overridden in `main()` after bootstrapping.
final appEnvironmentProvider = Provider<AppEnvironment>((ref) {
  throw UnimplementedError(
    'Override appEnvironmentProvider in main() with AppEnvironment.fromDartDefines().',
  );
});

/// The initialised Supabase client.
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

// ---------------------------------------------------------------------------
// Repositories
// ---------------------------------------------------------------------------

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(ref.watch(supabaseClientProvider)),
);

final peopleRepositoryProvider = Provider<PeopleRepository>(
  (ref) => PeopleRepository(ref.watch(supabaseClientProvider)),
);

final triageRepositoryProvider = Provider<TriageRepository>(
  (ref) => TriageRepository(ref.watch(supabaseClientProvider)),
);

final facilityRepositoryProvider = Provider<FacilityRepository>(
  (ref) => FacilityRepository(ref.watch(supabaseClientProvider)),
);

final referralRepositoryProvider = Provider<ReferralRepository>(
  (ref) => ReferralRepository(ref.watch(supabaseClientProvider)),
);

final engagementRepositoryProvider = Provider<EngagementRepository>(
  (ref) => EngagementRepository(ref.watch(supabaseClientProvider)),
);

final oversightRepositoryProvider = Provider<OversightRepository>(
  (ref) => OversightRepository(ref.watch(supabaseClientProvider)),
);

// ---------------------------------------------------------------------------
// Integration adapters
//
// Each is resolved through a provider so a deployment can substitute the
// authorised production adapter without touching a single call site
// (PRD 14, PRD 27).
// ---------------------------------------------------------------------------

final ambulanceAdapterProvider = Provider<AmbulanceAdapter>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  final client = ref.watch(supabaseClientProvider);

  if (environment.usesMockAdapters) {
    return MockAmbulanceAdapter(client);
  }

  // A production build must be wired to an authorised state or operator
  // interface. Failing loudly is safer than silently mocking an emergency
  // dispatch (PRD 14.4).
  throw StateError(
    'No authorised ambulance adapter is configured for '
    '${environment.target.name}. Emergency dispatch would silently do nothing.',
  );
});

final languageAdapterProvider = Provider<LanguageAdapter>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  if (environment.usesMockAdapters) {
    return const MockLanguageAdapter();
  }
  throw StateError(
    'No Bhashini adapter is configured for ${environment.target.name}.',
  );
});

final teleconsultAdapterProvider = Provider<TeleconsultAdapter>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  final client = ref.watch(supabaseClientProvider);

  if (environment.usesMockAdapters) {
    return MockTeleconsultAdapter(client);
  }
  throw StateError(
    'No teleconsultation adapter is configured for ${environment.target.name}.',
  );
});
