/// ArogyaMitra location and directions.
///
/// Kept behind a small interface because the approved mapping and routing
/// provider is a deployment decision (PRD 9, PRD 29). Nothing in the app assumes
/// a particular vendor, and nothing breaks when location is unavailable: the
/// citizen can pick their village instead.
library;

export 'src/directions_launcher.dart';
export 'src/location_service.dart';
export 'src/maps_providers.dart';
