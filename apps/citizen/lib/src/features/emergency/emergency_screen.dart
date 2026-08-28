import 'package:am_core/am_core.dart';
import 'package:am_localization/am_localization.dart';
import 'package:am_maps/am_maps.dart';
import 'package:am_networking/am_networking.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../triage/care_journey_controller.dart';

/// The emergency shortcut (PRD 5.1, FR-021).
///
/// Calling 108 is the primary action and is available immediately, before any
/// form or lookup. Requesting transport through the platform is secondary,
/// because a phone call works when the app, the network or the dispatch
/// integration does not.
class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen> {
  bool _isRequesting = false;
  AmbulanceDispatch? _dispatch;
  Failure? _failure;

  @override
  Widget build(BuildContext context) {
    final strings = AmStrings.of(context);
    final environment = ref.watch(appEnvironmentProvider);
    final patient = ref.watch(selfPatientProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(strings.ambulanceTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AmTokens.spaceMd),
          children: [
            AmBanner.emergency(message: strings.ambulanceStayPut),
            const SizedBox(height: AmTokens.spaceLg),

            AmBigButton.emergency(
              label: strings.triageCallEmergency,
              onPressed: () =>
                  ref.read(directionsLauncherProvider).callEmergencyServices(),
            ),
            const SizedBox(height: AmTokens.spaceLg),

            if (environment.usesMockAdapters) ...[
              // PRD 14.4: never let a demonstration build imply that a real
              // ambulance is on the way.
              AmBanner.warning(message: strings.ambulanceMockNotice),
              const SizedBox(height: AmTokens.spaceMd),
            ],

            if (_failure != null) ...[
              AmFailureBanner(failure: _failure!),
              const SizedBox(height: AmTokens.spaceMd),
            ],

            if (_dispatch != null)
              _DispatchStatus(dispatch: _dispatch!)
            else
              AmBigButton(
                label: strings.ambulanceRequest,
                icon: Icons.local_shipping_outlined,
                isBusy: _isRequesting,
                onPressed: patient == null || _isRequesting
                    ? null
                    : () => _request(patient.id, patient.contactPhone),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _request(String patientId, String? phone) async {
    setState(() {
      _isRequesting = true;
      _failure = null;
    });

    final position = await ref.read(locationServiceProvider).currentPosition();

    final pickup = position.valueOrNull;
    if (pickup == null) {
      setState(() {
        _isRequesting = false;
        _failure = position.failureOrNull;
      });
      return;
    }

    final result = await ref.read(ambulanceAdapterProvider).requestDispatch(
          patientId: patientId,
          pickup: pickup,
          contactPhone: phone ?? '',
        );

    if (!mounted) return;

    setState(() {
      _isRequesting = false;
      _dispatch = result.valueOrNull;
      _failure = result.failureOrNull;
    });
  }
}

class _DispatchStatus extends StatelessWidget {
  const _DispatchStatus({required this.dispatch});

  final AmbulanceDispatch dispatch;

  @override
  Widget build(BuildContext context) {
    final strings = AmStrings.of(context);

    return AmSection(
      title: strings.ambulanceTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dispatch.status.wire,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (dispatch.etaMinutes != null) ...[
            const SizedBox(height: AmTokens.spaceSm),
            Text(strings.ambulanceEta(dispatch.etaMinutes!)),
          ],
          if (dispatch.vehicleNumber != null) ...[
            const SizedBox(height: AmTokens.spaceXs),
            Text(strings.ambulanceVehicle(dispatch.vehicleNumber!)),
          ],
        ],
      ),
    );
  }
}
