/// ArogyaMitra data layer.
///
/// Everything the apps read or write goes through a repository here. External
/// systems (Bhashini, ambulance dispatch, teleconsultation) sit behind adapter
/// interfaces with mock implementations, so the core workflow keeps working when
/// an integration is unavailable or not yet authorised (PRD 8.1, 14, 27).
library;

export 'src/adapters/ambulance_adapter.dart';
export 'src/adapters/language_adapter.dart';
export 'src/adapters/teleconsult_adapter.dart';
export 'src/failure_mapper.dart';
export 'src/providers.dart';
export 'src/repositories/catalog_repository.dart';
export 'src/repositories/engagement_repository.dart';
export 'src/repositories/facility_repository.dart';
export 'src/repositories/oversight_repository.dart';
export 'src/repositories/people_repository.dart';
export 'src/repositories/referral_repository.dart';
export 'src/repositories/triage_repository.dart';
export 'src/supabase_bootstrap.dart';
