import 'package:am_core/am_core.dart';
import 'package:am_models/am_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'directions_launcher.dart';
import 'location_service.dart';

/// Runtime configuration, overridden by each app in `main()`.
final mapsEnvironmentProvider = Provider<AppEnvironment>((ref) {
  throw UnimplementedError('Override mapsEnvironmentProvider in main().');
});

final locationServiceProvider = Provider<LocationService>(
  (ref) => const GeolocatorLocationService(),
);

final directionsLauncherProvider = Provider<DirectionsLauncher>(
  (ref) => DirectionsLauncher(ref.watch(mapsEnvironmentProvider)),
);

/// The device position, if the user allows it.
///
/// Resolves to a [Result] rather than throwing so the UI can offer the
/// village-picker fallback in the same build (PRD 17 accessibility).
final currentPositionProvider = FutureProvider<Result<GeoPoint>>(
  (ref) => ref.watch(locationServiceProvider).currentPosition(),
);
