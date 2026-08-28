// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'am_strings.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AmStringsEn extends AmStrings {
  AmStringsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'ArogyaMitra';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionBack => 'Back';

  @override
  String get actionNext => 'Next';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionRetry => 'Try again';

  @override
  String get actionSave => 'Save';

  @override
  String get actionClose => 'Close';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionSubmit => 'Submit';

  @override
  String get actionYes => 'Yes';

  @override
  String get actionNo => 'No';

  @override
  String get actionSkip => 'Skip';

  @override
  String get actionDone => 'Done';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String get loading => 'Loading';

  @override
  String get noResults => 'Nothing to show yet';

  @override
  String get chooseLanguage => 'Choose your language';

  @override
  String get languageTamil => 'தமிழ்';

  @override
  String get languageEnglish => 'English';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get staffSignIn => 'Staff sign in';

  @override
  String get phoneNumber => 'Mobile number';

  @override
  String get sendOtp => 'Send code';

  @override
  String get enterOtp => 'Enter the code we sent you';

  @override
  String get verify => 'Verify';

  @override
  String get emailAddress => 'Email address';

  @override
  String get password => 'Password';

  @override
  String get signInHelp =>
      'We use your mobile number only to keep your care record safe.';

  @override
  String homeGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get homeNeedCare => 'I need care';

  @override
  String get homeNeedCareHint =>
      'Tell us how you feel and we will find the right care';

  @override
  String get homeEmergency => 'Emergency help';

  @override
  String get homeMyReferrals => 'My referrals';

  @override
  String get homeNotifications => 'Messages';

  @override
  String get homeFollowUps => 'My follow-ups';

  @override
  String get homeFeedback => 'Give feedback';

  @override
  String get homeProfile => 'My details';

  @override
  String get profileTitle => 'Your details';

  @override
  String get profileWhy =>
      'We ask this so triage can judge your risk correctly.';

  @override
  String get profileName => 'Full name';

  @override
  String get profileAge => 'Age in years';

  @override
  String get profileSex => 'Sex';

  @override
  String get sexMale => 'Male';

  @override
  String get sexFemale => 'Female';

  @override
  String get sexOther => 'Other';

  @override
  String get sexUndisclosed => 'Prefer not to say';

  @override
  String get profilePregnant => 'Currently pregnant';

  @override
  String get profileChronic => 'Long-term conditions';

  @override
  String get chronicDiabetes => 'Diabetes';

  @override
  String get chronicHypertension => 'High blood pressure';

  @override
  String get chronicHeartDisease => 'Heart disease';

  @override
  String get chronicAsthma => 'Asthma';

  @override
  String get chronicKidneyDisease => 'Kidney disease';

  @override
  String get chronicTuberculosis => 'Tuberculosis';

  @override
  String get symptomsTitle => 'What is troubling you?';

  @override
  String get symptomsHint => 'Choose everything that applies';

  @override
  String get symptomsSearch => 'Search symptoms';

  @override
  String symptomsSelected(int count) {
    return '$count selected';
  }

  @override
  String get symptomsCommon => 'Common';

  @override
  String get symptomsAll => 'All symptoms';

  @override
  String get symptomsNoneSelected => 'Choose at least one symptom to continue';

  @override
  String get symptomsVoiceInput => 'Speak instead';

  @override
  String get symptomsListening => 'Listening';

  @override
  String get symptomsVoiceConfirm =>
      'We heard this. Please confirm before we continue.';

  @override
  String get severityTitle => 'How bad is it right now?';

  @override
  String get severityHint =>
      'This decides how urgently you are seen, so please be honest.';

  @override
  String get severity1 => 'Very mild';

  @override
  String get severity2 => 'Mild';

  @override
  String get severity3 => 'Moderate';

  @override
  String get severity4 => 'Severe';

  @override
  String get severity5 => 'Very severe';

  @override
  String get durationTitle => 'How long has this been going on?';

  @override
  String durationHours(int count) {
    return '$count hours';
  }

  @override
  String get durationLessThanDay => 'Less than a day';

  @override
  String get durationOneToThreeDays => '1 to 3 days';

  @override
  String get durationUpToWeek => '3 days to a week';

  @override
  String get durationOverTwoWeeks => 'More than two weeks';

  @override
  String get triageRunning => 'Checking your symptoms';

  @override
  String get triageResultTitle => 'What you should do';

  @override
  String get riskLow => 'Low risk';

  @override
  String get riskMedium => 'Needs a check-up';

  @override
  String get riskHigh => 'Needs care today';

  @override
  String get riskEmergency => 'Emergency';

  @override
  String get nextActionSelfCare => 'Care at home';

  @override
  String get nextActionVisitFacility => 'Visit a health facility';

  @override
  String get nextActionTeleconsult => 'Talk to a doctor online';

  @override
  String get nextActionRefer => 'Get referred to a facility';

  @override
  String get nextActionEmergencyResponse => 'Get emergency help now';

  @override
  String get triageRedFlagsTitle => 'Warning signs we found';

  @override
  String triageAssessedBy(int version) {
    return 'Assessed using clinical rule set v$version';
  }

  @override
  String get triageFallbackWarning =>
      'We could not match your symptoms exactly, so we are asking you to see a clinician to be safe.';

  @override
  String get triageNotDiagnosis =>
      'This is guidance on where to go. It is not a diagnosis.';

  @override
  String get triageCallEmergency => 'Call 108 now';

  @override
  String get triageFindFacility => 'Find a facility';

  @override
  String get facilitiesTitle => 'Where to go';

  @override
  String get facilitiesSubtitle =>
      'Ranked by travel time, available services and current readiness';

  @override
  String get facilitiesSearching => 'Finding facilities near you';

  @override
  String get facilitiesNoneFound =>
      'No suitable facility found within range. Please call 108 or your ASHA worker.';

  @override
  String facilityDistance(String km) {
    return '$km km away';
  }

  @override
  String facilityTravelTime(int minutes) {
    return 'about $minutes min';
  }

  @override
  String facilityReadiness(int percent) {
    return 'Readiness $percent%';
  }

  @override
  String get facilityOpen24x7 => 'Open 24 hours';

  @override
  String get facilityHasEmergency => 'Emergency department';

  @override
  String get readinessDoctor => 'Doctor';

  @override
  String get readinessMedicines => 'Medicines';

  @override
  String get readinessDiagnostics => 'Tests';

  @override
  String get readinessBeds => 'Beds';

  @override
  String get availabilityAvailable => 'Available';

  @override
  String get availabilityLimited => 'Limited';

  @override
  String get availabilityUnavailable => 'Not available';

  @override
  String get availabilityUnknown => 'Not reported';

  @override
  String readinessStaleWarning(int hours) {
    return 'This facility last updated $hours hours ago. Please call before travelling.';
  }

  @override
  String get readinessNotReported =>
      'This facility has not reported its status. Please call before travelling.';

  @override
  String get facilityServiceGap =>
      'This facility may not offer everything you need. Call ahead if you can.';

  @override
  String get facilityChoose => 'Choose this facility';

  @override
  String get facilityDirections => 'Directions';

  @override
  String get facilityCall => 'Call';

  @override
  String get facilityWhyRanked => 'Why this order?';

  @override
  String facilityScoreBreakdown(
    int travel,
    int services,
    int wait,
    int confidence,
  ) {
    return 'Travel $travel%, services $services%, wait $wait%, data confidence $confidence%';
  }

  @override
  String get referralCreatedTitle => 'Referral created';

  @override
  String referralReference(String code) {
    return 'Reference $code';
  }

  @override
  String get referralShowAtFacility => 'Show this reference at the facility';

  @override
  String get referralsTitle => 'My referrals';

  @override
  String get referralsEmpty => 'You have no referrals yet';

  @override
  String get referralStatusCreated => 'Created';

  @override
  String get referralStatusTriaged => 'Symptoms assessed';

  @override
  String get referralStatusRecommended => 'Facility suggested';

  @override
  String get referralStatusReferralSent => 'Waiting for the facility';

  @override
  String get referralStatusAccepted => 'Facility accepted';

  @override
  String get referralStatusPatientTravelling => 'On the way';

  @override
  String get referralStatusArrived => 'Arrived';

  @override
  String get referralStatusConsultation => 'With the doctor';

  @override
  String get referralStatusCompleted => 'Completed';

  @override
  String get referralStatusRejected => 'Not accepted';

  @override
  String get referralStatusCancelled => 'Cancelled';

  @override
  String get referralStatusExpired => 'Expired';

  @override
  String get referralStatusNoShow => 'Did not attend';

  @override
  String get referralStatusEmergencyEscalated => 'Emergency help arranged';

  @override
  String get referralTimeline => 'History';

  @override
  String referralAwaitingFacility(int minutes) {
    return 'The facility has $minutes minutes to respond';
  }

  @override
  String get referralOverdue =>
      'The facility has not responded in time. This has been flagged.';

  @override
  String get referralRejectedNext =>
      'This facility could not take you. Choose another.';

  @override
  String get referralChooseAnother => 'Choose another facility';

  @override
  String get referralImOnMyWay => 'I am on my way';

  @override
  String get referralCancel => 'Cancel referral';

  @override
  String get referralCancelReason => 'Why are you cancelling?';

  @override
  String get referralPriorityRoutine => 'Routine';

  @override
  String get referralPriorityUrgent => 'Urgent';

  @override
  String get referralPriorityEmergency => 'Emergency';

  @override
  String get referralAutomatedEvent => 'Updated automatically by the system';

  @override
  String get ambulanceTitle => 'Emergency transport';

  @override
  String get ambulanceRequest => 'Request an ambulance';

  @override
  String get ambulanceRequesting => 'Requesting transport';

  @override
  String ambulanceEta(int minutes) {
    return 'Arriving in about $minutes min';
  }

  @override
  String ambulanceVehicle(String number) {
    return 'Vehicle $number';
  }

  @override
  String get ambulanceStayPut =>
      'Stay where you are and keep your phone nearby.';

  @override
  String get ambulanceMockNotice =>
      'Demonstration mode: no real ambulance has been dispatched.';

  @override
  String get feedbackTitle => 'How was your care?';

  @override
  String get feedbackRating => 'Your rating';

  @override
  String get feedbackCategory => 'What is this about?';

  @override
  String get feedbackComment => 'Anything else you want to tell us?';

  @override
  String get feedbackThanks => 'Thank you. Your feedback has been recorded.';

  @override
  String get feedbackWouldRecommend => 'Would you recommend this facility?';

  @override
  String get feedbackCategoryGeneral => 'General';

  @override
  String get feedbackCategoryWaitingTime => 'Waiting time';

  @override
  String get feedbackCategoryStaffBehaviour => 'Staff behaviour';

  @override
  String get feedbackCategoryMedicineUnavailable => 'Medicines not available';

  @override
  String get feedbackCategoryDiagnosticUnavailable => 'Tests not available';

  @override
  String get feedbackCategoryCleanliness => 'Cleanliness';

  @override
  String get feedbackCategoryCost => 'Cost';

  @override
  String get feedbackCategoryReferralProcess => 'Referral process';

  @override
  String get feedbackCategoryAmbulance => 'Ambulance';

  @override
  String get feedbackCategoryTeleconsult => 'Online consultation';

  @override
  String get feedbackCategoryOther => 'Something else';

  @override
  String get notificationsTitle => 'Messages';

  @override
  String get notificationsEmpty => 'No messages yet';

  @override
  String notificationsUnread(int count) {
    return '$count unread';
  }

  @override
  String get followUpsTitle => 'Follow-ups';

  @override
  String get followUpsEmpty => 'Nothing due';

  @override
  String followUpDueOn(String date) {
    return 'Due $date';
  }

  @override
  String followUpOverdue(int days) {
    return '$days days overdue';
  }

  @override
  String get followUpComplete => 'Mark done';

  @override
  String get followUpOutcome => 'What happened?';

  @override
  String get consoleQueueTitle => 'Incoming referrals';

  @override
  String get consoleQueueEmpty => 'No referrals waiting';

  @override
  String get consoleAccept => 'Accept';

  @override
  String get consoleReject => 'Decline';

  @override
  String get consoleRejectReason => 'Reason for declining';

  @override
  String get consoleRejectReasonRequired =>
      'A reason is required so the citizen can be re-routed.';

  @override
  String get consoleMarkArrived => 'Patient arrived';

  @override
  String get consoleStartConsultation => 'Start consultation';

  @override
  String get consoleComplete => 'Complete';

  @override
  String get consoleCompleteOutcome => 'Outcome';

  @override
  String get consoleNoShow => 'Did not attend';

  @override
  String get consoleReadinessTitle => 'Facility readiness';

  @override
  String get consoleReadinessSubtitle =>
      'What you publish here decides where citizens are sent.';

  @override
  String get consoleUpdateResource => 'Update';

  @override
  String get consoleOverride => 'Manual override';

  @override
  String get consoleOverrideReason => 'Reason for the override';

  @override
  String consoleLastUpdated(String ago) {
    return 'Updated $ago';
  }

  @override
  String consoleSlaRemaining(int minutes) {
    return '$minutes min to respond';
  }

  @override
  String get consoleSlaBreached => 'Response overdue';

  @override
  String get dashboardTitle => 'District dashboard';

  @override
  String get dashboardReadiness => 'Facility readiness';

  @override
  String get dashboardAlerts => 'Alerts';

  @override
  String get dashboardReferrals => 'Referrals';

  @override
  String get dashboardFeedback => 'Citizen feedback';

  @override
  String get dashboardFollowUps => 'Follow-up compliance';

  @override
  String get dashboardAlertsEmpty => 'No open alerts';

  @override
  String get dashboardMetricCreated => 'Created';

  @override
  String get dashboardMetricAccepted => 'Accepted';

  @override
  String get dashboardMetricCompleted => 'Completed';

  @override
  String get dashboardMetricBreaches => 'SLA breaches';

  @override
  String get dashboardAcceptanceRate => 'Acceptance rate';

  @override
  String get dashboardCompletionRate => 'Completion rate';

  @override
  String get dashboardMedianTurnaround => 'Median turnaround';

  @override
  String dashboardMinutes(String value) {
    return '$value min';
  }

  @override
  String get readinessBandGood => 'Ready';

  @override
  String get readinessBandPartial => 'Partial';

  @override
  String get readinessBandCritical => 'Critical';

  @override
  String get readinessBandStale => 'Not reported';

  @override
  String get alertReferralSlaBreach => 'Referral response overdue';

  @override
  String get alertReadinessCritical => 'Facility readiness critical';

  @override
  String get alertFeedbackIssue => 'Citizen issue reported';

  @override
  String get adviceEmergencyUnresponsive =>
      'This is a medical emergency. Call 108 immediately. Do not give anything by mouth. Turn the person on their side and stay with them.';

  @override
  String get adviceEmergencyBleeding =>
      'Press firmly on the wound with a clean cloth and keep pressing. Call 108 immediately.';

  @override
  String get adviceEmergencyPoisoning =>
      'Call 108 immediately. Do not try to make the person vomit. Take the container or label with you.';

  @override
  String get adviceEmergencySnakebite =>
      'Call 108 immediately. Keep the bitten limb still and below heart level. Do not cut, suck or tie the wound. Anti-snake venom is needed urgently.';

  @override
  String get adviceEmergencyStroke =>
      'Call 108 immediately. Note the time symptoms started, as treatment depends on it. Do not give food or water.';

  @override
  String get adviceEmergencyChestPain =>
      'Call 108 immediately. Sit and rest, do not walk or drive yourself. This needs an ECG straight away.';

  @override
  String get adviceEmergencyBreathlessness =>
      'Call 108 immediately. Sit upright and loosen tight clothing. Oxygen may be needed.';

  @override
  String get adviceEmergencyObstetricBleeding =>
      'Call 108 immediately. Lie down on your left side. Bleeding in pregnancy needs urgent care.';

  @override
  String get adviceEmergencyLabour =>
      'Go to a facility with delivery services now. Call 108 for transport if needed.';

  @override
  String get adviceEmergencyFetalMovement =>
      'Go to a facility with obstetric care now. Reduced baby movement needs to be checked urgently.';

  @override
  String get adviceEmergencySickChild =>
      'Take the child to a facility with paediatric care immediately. Call 108 for transport. Keep the child warm and keep offering fluids if they can swallow.';

  @override
  String get adviceEmergencyTrauma =>
      'Call 108 immediately. Do not move the injured person unless they are in danger.';

  @override
  String get adviceEmergencyBurn =>
      'Cool the burn under clean running water for 20 minutes. Do not apply oil, toothpaste or ice. Call 108.';

  @override
  String get adviceEmergencyAnuria =>
      'Call 108 immediately. Passing almost no urine can mean the kidneys are failing.';

  @override
  String get adviceHighAnimalBite =>
      'Wash the wound with soap under running water for 15 minutes and go to a facility today. You need rabies vaccination.';

  @override
  String get adviceHighHaemoptysis =>
      'See a doctor today. You need a chest X-ray and a sputum test to rule out tuberculosis.';

  @override
  String get adviceHighTbSuspect =>
      'A cough this long with weight loss or night sweats needs a TB test today. Treatment is free.';

  @override
  String get adviceHighJaundice =>
      'See a doctor today. Yellow eyes or skin needs blood tests to find the cause.';

  @override
  String get adviceHighBreathlessness =>
      'See a doctor today. Go back or call 108 straight away if breathing gets worse.';

  @override
  String get adviceHighChestPainYoung =>
      'See a doctor today and ask for an ECG. Call 108 if the pain worsens, spreads to your arm or jaw, or you start sweating.';

  @override
  String get adviceHighPersistentFever =>
      'Fever this high for this long needs blood tests today to check for dengue, malaria or typhoid.';

  @override
  String get adviceHighPregnancy =>
      'Any new symptom in pregnancy should be checked the same day at a facility with obstetric care.';

  @override
  String get adviceHighDiabetesFever =>
      'With diabetes, an infection can worsen quickly. See a doctor today.';

  @override
  String get adviceHighCardiacHistory =>
      'With your heart history, these symptoms need an ECG today.';

  @override
  String get adviceMediumDehydration =>
      'Drink ORS after every loose stool. Go to a facility today, and sooner if you cannot keep fluids down or pass very little urine.';

  @override
  String get adviceMediumAbdominalPain =>
      'See a clinician today. Do not take painkillers on an empty stomach. Go straight away if the pain becomes severe or your abdomen feels hard.';

  @override
  String get adviceMediumFebrileIllness =>
      'See a clinician today for a check-up and blood tests if needed. Drink plenty of fluids and rest.';

  @override
  String get adviceMediumUti =>
      'See a clinician today. A urine test is needed. Drink plenty of water in the meantime.';

  @override
  String get adviceMediumJointPain =>
      'See a clinician for an assessment. Rest the joint and avoid heavy lifting.';

  @override
  String get adviceMediumMentalHealth =>
      'Talking to a counsellor or doctor helps. You can do this by online consultation, and it is confidential.';

  @override
  String get adviceMediumVision =>
      'Get your eyes checked. Go sooner if vision loss is sudden or you have eye pain.';

  @override
  String get adviceMediumMinorBurn =>
      'Cool under running water for 20 minutes, cover loosely with a clean cloth, and get it dressed at a facility.';

  @override
  String get adviceMediumMinorInjury =>
      'Get the injury cleaned and checked. An X-ray may be needed if there is swelling or you cannot move it.';

  @override
  String get adviceMediumDental =>
      'See a dentist or the facility doctor. Rinse with warm salt water and avoid very hot or cold food.';

  @override
  String get adviceLowMildFever =>
      'Rest, drink plenty of fluids and use paracetamol as directed. See a clinician if the fever lasts more than three days, goes above 39C, or you develop breathlessness, a rash or vomiting.';

  @override
  String get adviceLowMildCough =>
      'Warm fluids and steam inhalation help. See a clinician if the cough lasts more than two weeks, or you get fever, blood in your sputum or breathlessness.';

  @override
  String get adviceLowMildHeadache =>
      'Rest in a quiet, dark room, drink water and eat regularly. See a clinician if the headache is sudden and severe, or comes with fever, vomiting, weakness or vision changes.';

  @override
  String get adviceLowSoreThroat =>
      'Warm salt water gargles and warm fluids help. See a clinician if you have difficulty swallowing or breathing, or a fever lasting more than three days.';

  @override
  String get adviceLowBackPain =>
      'Keep moving gently, avoid bed rest and avoid heavy lifting. See a clinician if the pain spreads down your leg, or you have numbness, weakness or trouble passing urine.';

  @override
  String get adviceLowRash =>
      'Keep the skin clean and dry and avoid scratching. See a clinician if the rash spreads quickly, blisters, or comes with fever or breathlessness.';

  @override
  String get adviceDefaultVisitFacility =>
      'Please see a clinician so your symptoms can be assessed properly.';

  @override
  String get adviceWhenToReturn =>
      'Come back or call 108 straight away if you get worse.';

  @override
  String get followupDefault =>
      'Check how the patient is doing and record the outcome.';

  @override
  String get followupPostReferral =>
      'Confirm the patient reached the facility, was seen, and record what happened.';

  @override
  String get errorUnauthenticated => 'Please sign in to continue.';

  @override
  String get errorSignInFailed =>
      'We could not sign you in. Please check the details and try again.';

  @override
  String get errorSessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get errorForbidden => 'You do not have access to this.';

  @override
  String get errorNotPermitted => 'You do not have permission to do this.';

  @override
  String get errorInvalidInput =>
      'Please check what you entered and try again.';

  @override
  String get errorNotFound => 'We could not find this record.';

  @override
  String get errorAlreadyExists => 'This already exists.';

  @override
  String get errorRelatedRecordMissing =>
      'Something this depends on is missing.';

  @override
  String get errorOffline =>
      'You appear to be offline. We will keep your work and try again.';

  @override
  String get errorUnexpected => 'Something went wrong. Please try again.';

  @override
  String get errorActionNotAllowed => 'This action is not allowed right now.';

  @override
  String get errorReferralTransitionIllegal =>
      'This referral has already moved on. Refresh to see its current state.';

  @override
  String get errorReasonRequired => 'Please give a reason.';

  @override
  String get errorOutcomeRequired => 'Please record the outcome.';

  @override
  String get errorOverrideReasonRequired => 'A manual override needs a reason.';

  @override
  String get errorFacilityNotOperational =>
      'This facility is not currently operating.';

  @override
  String get errorTriageUnavailable =>
      'Symptom assessment is unavailable right now. Please contact your ASHA worker or call 108 if this is urgent.';

  @override
  String get errorProfileMissing =>
      'Your account is not set up yet. Please contact your administrator.';

  @override
  String get errorNoAudioCaptured =>
      'We did not hear anything. Please try again.';

  @override
  String get errorTtsUnavailable =>
      'Spoken output is unavailable. The text is shown on screen.';

  @override
  String get errorAmbulanceRequestFailed =>
      'We could not request transport. Please call 108 directly.';

  @override
  String get errorStorage => 'We could not upload that file.';

  @override
  String get errorPatientDistrictUnknown =>
      'This patient has no district recorded, so transport cannot be requested.';

  @override
  String get errorLocationDenied =>
      'We need your location to find nearby facilities. You can also pick your village instead.';

  @override
  String get errorLocationUnavailable =>
      'We could not get your location. Please pick your village instead.';
}
