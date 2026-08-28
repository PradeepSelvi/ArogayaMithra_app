import 'package:am_auth/am_auth.dart';
import 'package:am_core/am_core.dart';
import 'package:am_models/am_models.dart';
import 'package:am_networking/am_networking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// The citizen's own patient record, created on first use.
final selfPatientProvider = FutureProvider<Patient?>((ref) async {
  // Re-resolves whenever the session changes, so a different user on a shared
  // handset never sees the previous person's record.
  ref.watch(currentUserProvider);
  final result = await ref.watch(peopleRepositoryProvider).selfPatient();
  return result.fold(onSuccess: (p) => p, onFailure: (_) => null);
});

/// One pass through the care journey: symptoms, triage, facility, referral.
@immutable
class CareJourneyState {
  const CareJourneyState({
    this.symptomCodes = const {},
    this.severity,
    this.durationHours,
    this.assessment,
    this.candidates = const [],
    this.referral,
    this.failure,
    this.isBusy = false,
  });

  final Set<String> symptomCodes;
  final int? severity;
  final int? durationHours;
  final TriageAssessment? assessment;
  final List<FacilityCandidate> candidates;
  final Referral? referral;
  final Failure? failure;
  final bool isBusy;

  bool get canRunTriage => symptomCodes.isNotEmpty && severity != null;

  CareJourneyState copyWith({
    Set<String>? symptomCodes,
    int? severity,
    int? durationHours,
    TriageAssessment? assessment,
    List<FacilityCandidate>? candidates,
    Referral? referral,
    Failure? failure,
    bool? isBusy,
    bool clearFailure = false,
  }) =>
      CareJourneyState(
        symptomCodes: symptomCodes ?? this.symptomCodes,
        severity: severity ?? this.severity,
        durationHours: durationHours ?? this.durationHours,
        assessment: assessment ?? this.assessment,
        candidates: candidates ?? this.candidates,
        referral: referral ?? this.referral,
        failure: clearFailure ? null : (failure ?? this.failure),
        isBusy: isBusy ?? this.isBusy,
      );
}

/// Drives the journey in PRD 7 and PRD 23.
///
/// The controller holds *inputs and results*, never clinical decisions. Risk
/// level, next action and facility ranking all come back from the server, so an
/// app update can never change a triage outcome (PRD 20).
class CareJourneyController extends Notifier<CareJourneyState> {
  @override
  CareJourneyState build() => const CareJourneyState();

  void toggleSymptom(String code) {
    final next = Set<String>.from(state.symptomCodes);
    if (!next.remove(code)) next.add(code);

    // Changing the symptoms invalidates everything downstream. Keeping a stale
    // assessment on screen after the inputs changed would be misleading.
    state = CareJourneyState(
      symptomCodes: next,
      severity: state.severity,
      durationHours: state.durationHours,
    );
  }

  void setSeverity(int severity) =>
      state = state.copyWith(severity: severity, clearFailure: true);

  void setDurationHours(int hours) =>
      state = state.copyWith(durationHours: hours, clearFailure: true);

  void reset() => state = const CareJourneyState();

  /// Runs triage for [patient].
  Future<TriageAssessment?> runTriage(Patient patient) async {
    if (!state.canRunTriage) return null;

    state = state.copyWith(isBusy: true, clearFailure: true);

    final language = ref.read(currentLanguageProvider);
    final result = await ref.read(triageRepositoryProvider).run(
          TriageRequest(
            patientId: patient.id,
            symptomCodes: state.symptomCodes.toList(),
            channel: AppFlavor.citizen.triageChannel,
            inputLanguage: language,
            severity: state.severity,
            durationHours: state.durationHours,
          ),
        );

    return result.fold(
      onSuccess: (assessment) {
        state = state.copyWith(assessment: assessment, isBusy: false);
        return assessment;
      },
      onFailure: (failure) {
        state = state.copyWith(failure: failure, isBusy: false);
        return null;
      },
    );
  }

  /// Loads ranked facilities for the current assessment.
  Future<void> loadFacilities(GeoPoint origin) async {
    final assessment = state.assessment;
    if (assessment == null) return;

    state = state.copyWith(isBusy: true, clearFailure: true);

    final result = await ref.read(facilityRepositoryProvider).searchForAssessment(
          origin: origin,
          assessment: assessment,
        );

    state = result.fold(
      onSuccess: (candidates) =>
          state.copyWith(candidates: candidates, isBusy: false),
      onFailure: (failure) => state.copyWith(failure: failure, isBusy: false),
    );
  }

  /// Creates the referral for a chosen facility.
  ///
  /// The score breakdown is sent with it so the reason this facility was
  /// recommended is recorded at decision time (PRD 12.1).
  Future<Referral?> chooseFacility({
    required Patient patient,
    required FacilityCandidate candidate,
    String? reason,
  }) async {
    final assessment = state.assessment;
    if (assessment == null) return null;

    state = state.copyWith(isBusy: true, clearFailure: true);

    final people = ref.read(peopleRepositoryProvider);
    final result = await ref.read(referralRepositoryProvider).createFromCandidate(
          patientId: patient.id,
          candidate: candidate,
          assessment: assessment,
          reason: reason,
          // Guards against a double tap or a retried request creating two
          // referrals for the same decision (PRD 15, PRD 27).
          idempotencyKey: people.idempotencyKeyFor(
            'create_referral',
            scope: '${assessment.id}:${candidate.facility.id}',
          ),
        );

    return result.fold(
      onSuccess: (referral) {
        state = state.copyWith(referral: referral, isBusy: false);
        return referral;
      },
      onFailure: (failure) {
        state = state.copyWith(failure: failure, isBusy: false);
        return null;
      },
    );
  }
}

final careJourneyProvider =
    NotifierProvider<CareJourneyController, CareJourneyState>(
  CareJourneyController.new,
);

/// The symptom catalogue, localised by the UI.
final symptomCatalogProvider = FutureProvider<List<Symptom>>((ref) async {
  final result = await ref.watch(catalogRepositoryProvider).symptoms();
  return result.fold(
    onSuccess: (list) => list,
    onFailure: (failure) => throw failure,
  );
});
