import 'package:am_core/am_core.dart';
import 'package:am_models/am_models.dart';
import 'package:geolocator/geolocator.dart';

/// Device positioning.
abstract interface class LocationService {
  /// The current position, or a failure explaining why it is unavailable.
  ///
  /// Never throws for a denied permission: refusing to share location is a
  /// legitimate choice, and facility search must still work from a chosen
  /// village (PRD 5.1).
  Future<Result<GeoPoint>> currentPosition();

  /// Whether the user has already granted permission.
  Future<bool> hasPermission();
}

final class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<bool> hasPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Future<Result<GeoPoint>> currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const Err(
          Failure(
            kind: FailureKind.invalidInput,
            messageKey: 'error.location_unavailable',
            detail: 'Location services are switched off.',
          ),
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const Err(
          Failure(
            kind: FailureKind.forbidden,
            messageKey: 'error.location_denied',
          ),
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          // A rural GPS fix can be slow; the fallback is choosing a village, so
          // waiting forever is worse than giving up and offering that.
          timeLimit: Duration(seconds: 12),
        ),
      );

      return Success(
        GeoPoint(latitude: position.latitude, longitude: position.longitude),
      );
    } catch (error) {
      return Err(
        Failure(
          kind: FailureKind.invalidInput,
          messageKey: 'error.location_unavailable',
          detail: error.toString(),
          cause: error,
        ),
      );
    }
  }
}
