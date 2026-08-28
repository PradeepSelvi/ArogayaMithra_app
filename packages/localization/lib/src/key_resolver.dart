import 'generated/am_strings.dart';

/// Resolves the string keys the database sends into localised text.
///
/// The database stores keys, not sentences: `advice_key` on a triage rule,
/// `instructions_key` on a follow-up, and `messageKey` on a mapped failure.
/// Keeping the lookup in one place means an unmapped key is a single visible
/// bug rather than a blank screen, and it satisfies PRD 17 (no hard-coded
/// user-facing strings) without the database holding translations.
extension AmKeyResolver on AmStrings {
  /// Clinical advice for a triage outcome.
  ///
  /// Returns null when the build does not know the key, which happens if the
  /// clinical team publishes a new rule before the app is updated. Callers must
  /// fall back to [adviceDefaultVisitFacility] rather than showing nothing,
  /// because silently dropping advice is a safety problem.
  String? adviceOrNull(String key) => switch (key) {
        'advice.emergency.unresponsive' => adviceEmergencyUnresponsive,
        'advice.emergency.bleeding' => adviceEmergencyBleeding,
        'advice.emergency.poisoning' => adviceEmergencyPoisoning,
        'advice.emergency.snakebite' => adviceEmergencySnakebite,
        'advice.emergency.stroke' => adviceEmergencyStroke,
        'advice.emergency.chest_pain' => adviceEmergencyChestPain,
        'advice.emergency.breathlessness' => adviceEmergencyBreathlessness,
        'advice.emergency.obstetric_bleeding' =>
          adviceEmergencyObstetricBleeding,
        'advice.emergency.labour' => adviceEmergencyLabour,
        'advice.emergency.fetal_movement' => adviceEmergencyFetalMovement,
        'advice.emergency.sick_child' => adviceEmergencySickChild,
        'advice.emergency.trauma' => adviceEmergencyTrauma,
        'advice.emergency.burn' => adviceEmergencyBurn,
        'advice.emergency.anuria' => adviceEmergencyAnuria,
        'advice.high.animal_bite' => adviceHighAnimalBite,
        'advice.high.haemoptysis' => adviceHighHaemoptysis,
        'advice.high.tb_suspect' => adviceHighTbSuspect,
        'advice.high.jaundice' => adviceHighJaundice,
        'advice.high.breathlessness' => adviceHighBreathlessness,
        'advice.high.chest_pain_young' => adviceHighChestPainYoung,
        'advice.high.persistent_fever' => adviceHighPersistentFever,
        'advice.high.pregnancy' => adviceHighPregnancy,
        'advice.high.diabetes_fever' => adviceHighDiabetesFever,
        'advice.high.cardiac_history' => adviceHighCardiacHistory,
        'advice.medium.dehydration' => adviceMediumDehydration,
        'advice.medium.abdominal_pain' => adviceMediumAbdominalPain,
        'advice.medium.febrile_illness' => adviceMediumFebrileIllness,
        'advice.medium.uti' => adviceMediumUti,
        'advice.medium.joint_pain' => adviceMediumJointPain,
        'advice.medium.mental_health' => adviceMediumMentalHealth,
        'advice.medium.vision' => adviceMediumVision,
        'advice.medium.minor_burn' => adviceMediumMinorBurn,
        'advice.medium.minor_injury' => adviceMediumMinorInjury,
        'advice.medium.dental' => adviceMediumDental,
        'advice.low.mild_fever' => adviceLowMildFever,
        'advice.low.mild_cough' => adviceLowMildCough,
        'advice.low.mild_headache' => adviceLowMildHeadache,
        'advice.low.sore_throat' => adviceLowSoreThroat,
        'advice.low.back_pain' => adviceLowBackPain,
        'advice.low.rash' => adviceLowRash,
        'advice.default_visit_facility' => adviceDefaultVisitFacility,
        _ => null,
      };

  /// Advice text with a safe fallback.
  String advice(String key) => adviceOrNull(key) ?? adviceDefaultVisitFacility;

  /// True when the advice key is not known to this build. Callers surface this
  /// so the user is told the guidance may be incomplete rather than being shown
  /// generic text as though it were specific.
  bool isUnknownAdviceKey(String key) => adviceOrNull(key) == null;

  /// Follow-up task instructions.
  String followUpInstructions(String key) => switch (key) {
        'followup.post_referral' => followupPostReferral,
        _ => followupDefault,
      };

  /// Message for a mapped failure.
  String failureMessage(String key) => switch (key) {
        'error.unauthenticated' => errorUnauthenticated,
        'error.sign_in_failed' => errorSignInFailed,
        'error.session_expired' => errorSessionExpired,
        'error.forbidden' => errorForbidden,
        'error.not_permitted' => errorNotPermitted,
        'error.invalid_input' => errorInvalidInput,
        'error.not_found' => errorNotFound,
        'error.already_exists' => errorAlreadyExists,
        'error.related_record_missing' => errorRelatedRecordMissing,
        'error.offline' => errorOffline,
        'error.action_not_allowed' => errorActionNotAllowed,
        'error.referral_transition_illegal' => errorReferralTransitionIllegal,
        'error.reason_required' => errorReasonRequired,
        'error.outcome_required' => errorOutcomeRequired,
        'error.override_reason_required' => errorOverrideReasonRequired,
        'error.facility_not_operational' => errorFacilityNotOperational,
        'error.triage_unavailable' => errorTriageUnavailable,
        'error.profile_missing' => errorProfileMissing,
        'error.no_audio_captured' => errorNoAudioCaptured,
        'error.tts_unavailable' => errorTtsUnavailable,
        'error.ambulance_request_failed' => errorAmbulanceRequestFailed,
        'error.storage' => errorStorage,
        'error.patient_district_unknown' => errorPatientDistrictUnknown,
        'error.location_denied' => errorLocationDenied,
        'error.location_unavailable' => errorLocationUnavailable,
        _ => errorUnexpected,
      };
}
