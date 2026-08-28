import 'package:am_core/am_core.dart';
import 'package:am_models/am_models.dart';
import 'package:url_launcher/url_launcher.dart';

/// Hands off to the device's map and dialler apps.
///
/// The directions URL comes from configuration rather than being hard-coded, so
/// a deployment can point at whichever mapping provider it is approved to use
/// (PRD 9).
class DirectionsLauncher {
  const DirectionsLauncher(this._environment);

  final AppEnvironment _environment;

  Future<Result<void>> openDirections(GeoPoint destination) async {
    final url = _environment.directionsUrlTemplate
        .replaceAll('{lat}', destination.latitude.toString())
        .replaceAll('{lon}', destination.longitude.toString());

    return _launch(Uri.parse(url), 'error.unexpected');
  }

  /// Places a call. Used for the facility number and for 108.
  Future<Result<void>> call(String phoneNumber) async {
    final sanitised = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (sanitised.isEmpty) {
      return const Err(
        Failure(
          kind: FailureKind.invalidInput,
          messageKey: 'error.invalid_input',
        ),
      );
    }

    return _launch(Uri(scheme: 'tel', path: sanitised), 'error.unexpected');
  }

  /// The national emergency number.
  Future<Result<void>> callEmergencyServices() => call('108');

  Future<Result<void>> _launch(Uri uri, String failureKey) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        return Err(
          Failure(
            kind: FailureKind.integration,
            messageKey: failureKey,
            detail: 'Nothing on this device can open $uri',
          ),
        );
      }
      return const Success(null);
    } catch (error) {
      return Err(
        Failure(
          kind: FailureKind.integration,
          messageKey: failureKey,
          detail: error.toString(),
          cause: error,
        ),
      );
    }
  }
}
