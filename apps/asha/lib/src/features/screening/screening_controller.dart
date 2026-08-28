import 'package:am_auth/am_auth.dart';
import 'package:am_core/am_core.dart';
import 'package:am_models/am_models.dart';
import 'package:am_networking/am_networking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// Screening state for one household member.
@immutable
class ScreeningState {
  const ScreeningState({
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

  bool get canSubmit => symptomCodes.isNotEmpty && severity != null;

  ScreeningState copyWith({
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
      ScreeningState(
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

/// Screening and referral on behalf of a household member (PRD 5.2).
///
/// Every write carries an idempotency key derived from the patient and the
/// assessment. That is what makes a retried sync safe: replaying the queued
/// request returns the original referral instead of creating a second one
/// (PRD 15, PRD 27).
class ScreeningController extends FamilyNotifier<ScreeningState, Patient> {
  @override
  ScreeningState build(Patient arg) => const ScreeningState();

  Patient get patient => arg;

  void toggleSymptom(String code) {
    final next = Set<String>.from(state.symptomCodes);
    if (!next.remove(code)) next.add(code);

    state = ScreeningState(
      symptomCodes: next,
      severity: state.severity,
      durationHours: state.durationHours,
    );
  }

  void setSeverity(int value) =>
      state = state.copyWith(severity: value, clearFailure: true);

  void setDurationHours(int value) =>
      state = state.copyWith(durationHours: value, clearFailure: true);

  Future<TriageAssessment?> runTriage() async {
    if (!state.canSubmit) return null;

    state = state.copyWith(isBusy: true, clearFailure: true);

    final people = ref.read(peopleRepositoryProvider);
    final result = await ref.read(triageRepositoryProvider).run(
          TriageRequest(
            patientId: patient.id,
            symptomCodes: state.symptomCodes.toList(),
            channel: AppFlavor.fieldWorker.triageChannel,
            inputLanguage: ref.read(currentLanguageProvider),
            severity: state.severity,
            durationHours: state.durationHours,
            idempotencyKey: people.idempotencyKeyFor(
              'run_triage',
              scope: patient.id,
            ),
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

  Future<void> loadFacilities(GeoPoint origin) async {
    final assessment = state.assessment;
    if (assessment == null) return;

    state = state.copyWith(isBusy: true, clearFailure: true);

    final result =
        await ref.read(facilityRepositoryProvider).searchForAssessment(
              origin: origin,
              assessment: assessment,
            );

    state = result.fold(
      onSuccess: (candidates) =>
          state.copyWith(candidates: candidates, isBusy: false),
      onFailure: (failure) => state.copyWith(failure: failure, isBusy: false),
    );
  }

  Future<Referral?> refer(FacilityCandidate candidate, {String? reason}) async {
    final assessment = state.assessment;
    if (assessment == null) return null;

    state = state.copyWith(isBusy: true, clearFailure: true);

    final people = ref.read(peopleRepositoryProvider);
    final result =
        await ref.read(referralRepositoryProvider).createFromCandidate(
              patientId: patient.id,
              candidate: candidate,
              assessment: assessment,
              reason: reason,
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

final screeningControllerProvider =
    NotifierProvider.family<ScreeningController, ScreeningState, Patient>(
  ScreeningController.new,
);

final symptomCatalogProvider = FutureProvider<List<Symptom>>((ref) async {
  final result = await ref.watch(catalogRepositoryProvider).symptoms();
  return result.fold(
    onSuccess: (list) => list,
    onFailure: (failure) => throw failure,
  );
});
