// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'am_strings.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AmStringsTa extends AmStrings {
  AmStringsTa([String locale = 'ta']) : super(locale);

  @override
  String get appName => 'ஆரோக்யமித்ரா';

  @override
  String get actionContinue => 'தொடரவும்';

  @override
  String get actionBack => 'பின்செல்';

  @override
  String get actionNext => 'அடுத்து';

  @override
  String get actionCancel => 'ரத்து செய்';

  @override
  String get actionRetry => 'மீண்டும் முயற்சிக்கவும்';

  @override
  String get actionSave => 'சேமி';

  @override
  String get actionClose => 'மூடு';

  @override
  String get actionConfirm => 'உறுதிப்படுத்து';

  @override
  String get actionSubmit => 'சமர்ப்பி';

  @override
  String get actionYes => 'ஆம்';

  @override
  String get actionNo => 'இல்லை';

  @override
  String get actionSkip => 'தவிர்';

  @override
  String get actionDone => 'முடிந்தது';

  @override
  String get actionRefresh => 'புதுப்பி';

  @override
  String get loading => 'ஏற்றுகிறது';

  @override
  String get noResults => 'இப்போது காட்ட எதுவும் இல்லை';

  @override
  String get chooseLanguage => 'உங்கள் மொழியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get languageTamil => 'தமிழ்';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get signIn => 'உள்நுழை';

  @override
  String get signOut => 'வெளியேறு';

  @override
  String get staffSignIn => 'பணியாளர் உள்நுழைவு';

  @override
  String get phoneNumber => 'கைபேசி எண்';

  @override
  String get sendOtp => 'குறியீட்டை அனுப்பு';

  @override
  String get enterOtp => 'உங்களுக்கு அனுப்பிய குறியீட்டை உள்ளிடவும்';

  @override
  String get verify => 'சரிபார்';

  @override
  String get emailAddress => 'மின்னஞ்சல் முகவரி';

  @override
  String get password => 'கடவுச்சொல்';

  @override
  String get signInHelp =>
      'உங்கள் சுகாதாரப் பதிவைப் பாதுகாப்பாக வைக்க மட்டுமே உங்கள் கைபேசி எண்ணைப் பயன்படுத்துகிறோம்.';

  @override
  String homeGreeting(String name) {
    return 'வணக்கம், $name';
  }

  @override
  String get homeNeedCare => 'எனக்கு சிகிச்சை தேவை';

  @override
  String get homeNeedCareHint =>
      'உங்கள் உடல்நிலையைச் சொல்லுங்கள், சரியான சிகிச்சையைக் கண்டுபிடிக்கிறோம்';

  @override
  String get homeEmergency => 'அவசர உதவி';

  @override
  String get homeMyReferrals => 'எனது பரிந்துரைகள்';

  @override
  String get homeNotifications => 'செய்திகள்';

  @override
  String get homeFollowUps => 'எனது பின்தொடர்தல்கள்';

  @override
  String get homeFeedback => 'கருத்து தெரிவிக்க';

  @override
  String get homeProfile => 'எனது விவரங்கள்';

  @override
  String get profileTitle => 'உங்கள் விவரங்கள்';

  @override
  String get profileWhy =>
      'உங்கள் ஆபத்து அளவை சரியாக மதிப்பிடுவதற்காக இதைக் கேட்கிறோம்.';

  @override
  String get profileName => 'முழுப் பெயர்';

  @override
  String get profileAge => 'வயது (ஆண்டுகள்)';

  @override
  String get profileSex => 'பாலினம்';

  @override
  String get sexMale => 'ஆண்';

  @override
  String get sexFemale => 'பெண்';

  @override
  String get sexOther => 'மற்றவை';

  @override
  String get sexUndisclosed => 'சொல்ல விரும்பவில்லை';

  @override
  String get profilePregnant => 'தற்போது கர்ப்பமாக உள்ளேன்';

  @override
  String get profileChronic => 'நீண்டகால நோய்கள்';

  @override
  String get chronicDiabetes => 'சர்க்கரை நோய்';

  @override
  String get chronicHypertension => 'உயர் இரத்த அழுத்தம்';

  @override
  String get chronicHeartDisease => 'இதய நோய்';

  @override
  String get chronicAsthma => 'ஆஸ்துமா';

  @override
  String get chronicKidneyDisease => 'சிறுநீரக நோய்';

  @override
  String get chronicTuberculosis => 'காசநோய்';

  @override
  String get symptomsTitle => 'உங்களுக்கு என்ன பிரச்சினை?';

  @override
  String get symptomsHint => 'பொருந்தும் அனைத்தையும் தேர்ந்தெடுக்கவும்';

  @override
  String get symptomsSearch => 'அறிகுறிகளைத் தேடுங்கள்';

  @override
  String symptomsSelected(int count) {
    return '$count தேர்ந்தெடுக்கப்பட்டது';
  }

  @override
  String get symptomsCommon => 'பொதுவானவை';

  @override
  String get symptomsAll => 'அனைத்து அறிகுறிகள்';

  @override
  String get symptomsNoneSelected =>
      'தொடர குறைந்தது ஒரு அறிகுறியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get symptomsVoiceInput => 'பேசி சொல்லுங்கள்';

  @override
  String get symptomsListening => 'கேட்கிறது';

  @override
  String get symptomsVoiceConfirm =>
      'இதை நாங்கள் கேட்டோம். தொடர்வதற்கு முன் உறுதிப்படுத்தவும்.';

  @override
  String get severityTitle => 'இப்போது எவ்வளவு கடுமையாக உள்ளது?';

  @override
  String get severityHint =>
      'இது எவ்வளவு அவசரமாக நீங்கள் பார்க்கப்படுவீர்கள் என்பதை தீர்மானிக்கிறது. உண்மையைச் சொல்லுங்கள்.';

  @override
  String get severity1 => 'மிக லேசானது';

  @override
  String get severity2 => 'லேசானது';

  @override
  String get severity3 => 'மிதமானது';

  @override
  String get severity4 => 'கடுமையானது';

  @override
  String get severity5 => 'மிகக் கடுமையானது';

  @override
  String get durationTitle => 'எவ்வளவு காலமாக இது உள்ளது?';

  @override
  String durationHours(int count) {
    return '$count மணி நேரம்';
  }

  @override
  String get durationLessThanDay => 'ஒரு நாளுக்கும் குறைவாக';

  @override
  String get durationOneToThreeDays => '1 முதல் 3 நாட்கள்';

  @override
  String get durationUpToWeek => '3 நாட்கள் முதல் ஒரு வாரம்';

  @override
  String get durationOverTwoWeeks => 'இரண்டு வாரங்களுக்கு மேல்';

  @override
  String get triageRunning => 'உங்கள் அறிகுறிகளை பரிசோதிக்கிறோம்';

  @override
  String get triageResultTitle => 'நீங்கள் என்ன செய்ய வேண்டும்';

  @override
  String get riskLow => 'குறைந்த ஆபத்து';

  @override
  String get riskMedium => 'பரிசோதனை தேவை';

  @override
  String get riskHigh => 'இன்றே சிகிச்சை தேவை';

  @override
  String get riskEmergency => 'அவசர நிலை';

  @override
  String get nextActionSelfCare => 'வீட்டிலேயே பராமரிப்பு';

  @override
  String get nextActionVisitFacility => 'சுகாதார நிலையத்திற்குச் செல்லுங்கள்';

  @override
  String get nextActionTeleconsult => 'மருத்துவரிடம் ஆன்லைனில் பேசுங்கள்';

  @override
  String get nextActionRefer => 'மருத்துவமனைக்கு பரிந்துரை பெறுங்கள்';

  @override
  String get nextActionEmergencyResponse => 'இப்போதே அவசர உதவி பெறுங்கள்';

  @override
  String get triageRedFlagsTitle => 'நாங்கள் கண்டறிந்த ஆபத்து அறிகுறிகள்';

  @override
  String triageAssessedBy(int version) {
    return 'மருத்துவ விதி தொகுப்பு பதிப்பு $version பயன்படுத்தி மதிப்பிடப்பட்டது';
  }

  @override
  String get triageFallbackWarning =>
      'உங்கள் அறிகுறிகளை சரியாகப் பொருத்த முடியவில்லை. எனவே பாதுகாப்புக்காக ஒரு மருத்துவரைப் பார்க்கச் சொல்கிறோம்.';

  @override
  String get triageNotDiagnosis =>
      'இது எங்கே செல்ல வேண்டும் என்ற வழிகாட்டல் மட்டுமே. இது நோய் கண்டறிதல் அல்ல.';

  @override
  String get triageCallEmergency => 'இப்போதே 108 ஐ அழைக்கவும்';

  @override
  String get triageFindFacility => 'மருத்துவமனையைக் கண்டுபிடி';

  @override
  String get facilitiesTitle => 'எங்கே செல்ல வேண்டும்';

  @override
  String get facilitiesSubtitle =>
      'பயண நேரம், கிடைக்கும் சேவைகள் மற்றும் தற்போதைய தயார்நிலை அடிப்படையில் வரிசைப்படுத்தப்பட்டது';

  @override
  String get facilitiesSearching =>
      'உங்கள் அருகில் உள்ள மருத்துவமனைகளைத் தேடுகிறோம்';

  @override
  String get facilitiesNoneFound =>
      'அருகில் பொருத்தமான மருத்துவமனை இல்லை. 108 ஐ அழைக்கவும் அல்லது உங்கள் ஆஷா பணியாளரைத் தொடர்பு கொள்ளவும்.';

  @override
  String facilityDistance(String km) {
    return '$km கி.மீ தூரம்';
  }

  @override
  String facilityTravelTime(int minutes) {
    return 'சுமார் $minutes நிமிடம்';
  }

  @override
  String facilityReadiness(int percent) {
    return 'தயார்நிலை $percent%';
  }

  @override
  String get facilityOpen24x7 => '24 மணி நேரம் திறந்திருக்கும்';

  @override
  String get facilityHasEmergency => 'அவசர சிகிச்சைப் பிரிவு';

  @override
  String get readinessDoctor => 'மருத்துவர்';

  @override
  String get readinessMedicines => 'மருந்துகள்';

  @override
  String get readinessDiagnostics => 'பரிசோதனைகள்';

  @override
  String get readinessBeds => 'படுக்கைகள்';

  @override
  String get availabilityAvailable => 'கிடைக்கும்';

  @override
  String get availabilityLimited => 'குறைவாக உள்ளது';

  @override
  String get availabilityUnavailable => 'கிடைக்காது';

  @override
  String get availabilityUnknown => 'தெரிவிக்கப்படவில்லை';

  @override
  String readinessStaleWarning(int hours) {
    return 'இந்த மருத்துவமனை $hours மணி நேரத்திற்கு முன்பு தகவல் அளித்தது. செல்வதற்கு முன் அழைத்துக் கேளுங்கள்.';
  }

  @override
  String get readinessNotReported =>
      'இந்த மருத்துவமனை தனது நிலையைத் தெரிவிக்கவில்லை. செல்வதற்கு முன் அழைத்துக் கேளுங்கள்.';

  @override
  String get facilityServiceGap =>
      'உங்களுக்குத் தேவையான அனைத்தும் இங்கே இருக்காமல் இருக்கலாம். முடிந்தால் முன்பே அழைத்துக் கேளுங்கள்.';

  @override
  String get facilityChoose => 'இந்த மருத்துவமனையைத் தேர்ந்தெடு';

  @override
  String get facilityDirections => 'வழி காட்டு';

  @override
  String get facilityCall => 'அழை';

  @override
  String get facilityWhyRanked => 'இந்த வரிசை ஏன்?';

  @override
  String facilityScoreBreakdown(
    int travel,
    int services,
    int wait,
    int confidence,
  ) {
    return 'பயணம் $travel%, சேவைகள் $services%, காத்திருப்பு $wait%, தகவல் நம்பகத்தன்மை $confidence%';
  }

  @override
  String get referralCreatedTitle => 'பரிந்துரை உருவாக்கப்பட்டது';

  @override
  String referralReference(String code) {
    return 'குறிப்பு எண் $code';
  }

  @override
  String get referralShowAtFacility =>
      'இந்த குறிப்பு எண்ணை மருத்துவமனையில் காட்டுங்கள்';

  @override
  String get referralsTitle => 'எனது பரிந்துரைகள்';

  @override
  String get referralsEmpty => 'இன்னும் பரிந்துரைகள் இல்லை';

  @override
  String get referralStatusCreated => 'உருவாக்கப்பட்டது';

  @override
  String get referralStatusTriaged => 'அறிகுறிகள் மதிப்பிடப்பட்டன';

  @override
  String get referralStatusRecommended => 'மருத்துவமனை பரிந்துரைக்கப்பட்டது';

  @override
  String get referralStatusReferralSent =>
      'மருத்துவமனையின் பதிலுக்கு காத்திருக்கிறோம்';

  @override
  String get referralStatusAccepted => 'மருத்துவமனை ஏற்றுக்கொண்டது';

  @override
  String get referralStatusPatientTravelling => 'வழியில் உள்ளீர்கள்';

  @override
  String get referralStatusArrived => 'வந்து சேர்ந்தீர்கள்';

  @override
  String get referralStatusConsultation => 'மருத்துவரிடம் உள்ளீர்கள்';

  @override
  String get referralStatusCompleted => 'நிறைவடைந்தது';

  @override
  String get referralStatusRejected => 'ஏற்கப்படவில்லை';

  @override
  String get referralStatusCancelled => 'ரத்து செய்யப்பட்டது';

  @override
  String get referralStatusExpired => 'காலாவதியானது';

  @override
  String get referralStatusNoShow => 'வரவில்லை';

  @override
  String get referralStatusEmergencyEscalated =>
      'அவசர உதவி ஏற்பாடு செய்யப்பட்டது';

  @override
  String get referralTimeline => 'வரலாறு';

  @override
  String referralAwaitingFacility(int minutes) {
    return 'மருத்துவமனை பதிலளிக்க $minutes நிமிடங்கள் உள்ளன';
  }

  @override
  String get referralOverdue =>
      'மருத்துவமனை நேரத்தில் பதிலளிக்கவில்லை. இது பதிவு செய்யப்பட்டுள்ளது.';

  @override
  String get referralRejectedNext =>
      'இந்த மருத்துவமனை உங்களை ஏற்க முடியவில்லை. வேறு ஒன்றைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get referralChooseAnother => 'வேறு மருத்துவமனையைத் தேர்ந்தெடு';

  @override
  String get referralImOnMyWay => 'நான் புறப்பட்டுவிட்டேன்';

  @override
  String get referralCancel => 'பரிந்துரையை ரத்து செய்';

  @override
  String get referralCancelReason => 'எதற்காக ரத்து செய்கிறீர்கள்?';

  @override
  String get referralPriorityRoutine => 'வழக்கமான';

  @override
  String get referralPriorityUrgent => 'அவசரம்';

  @override
  String get referralPriorityEmergency => 'அவசர நிலை';

  @override
  String get referralAutomatedEvent => 'கணினியால் தானாகப் புதுப்பிக்கப்பட்டது';

  @override
  String get ambulanceTitle => 'அவசர வாகன சேவை';

  @override
  String get ambulanceRequest => 'ஆம்புலன்ஸ் கோரவும்';

  @override
  String get ambulanceRequesting => 'வாகனம் கோரப்படுகிறது';

  @override
  String ambulanceEta(int minutes) {
    return 'சுமார் $minutes நிமிடத்தில் வந்துவிடும்';
  }

  @override
  String ambulanceVehicle(String number) {
    return 'வாகனம் $number';
  }

  @override
  String get ambulanceStayPut =>
      'அங்கேயே இருங்கள், கைபேசியை அருகில் வைத்திருங்கள்.';

  @override
  String get ambulanceMockNotice =>
      'செயல்விளக்க முறை: உண்மையான ஆம்புலன்ஸ் அனுப்பப்படவில்லை.';

  @override
  String get feedbackTitle => 'உங்கள் சிகிச்சை எப்படி இருந்தது?';

  @override
  String get feedbackRating => 'உங்கள் மதிப்பீடு';

  @override
  String get feedbackCategory => 'இது எதைப் பற்றியது?';

  @override
  String get feedbackComment => 'வேறு எதுவும் சொல்ல விரும்புகிறீர்களா?';

  @override
  String get feedbackThanks => 'நன்றி. உங்கள் கருத்து பதிவு செய்யப்பட்டது.';

  @override
  String get feedbackWouldRecommend =>
      'இந்த மருத்துவமனையை மற்றவர்களுக்குப் பரிந்துரைப்பீர்களா?';

  @override
  String get feedbackCategoryGeneral => 'பொது';

  @override
  String get feedbackCategoryWaitingTime => 'காத்திருப்பு நேரம்';

  @override
  String get feedbackCategoryStaffBehaviour => 'பணியாளர் நடத்தை';

  @override
  String get feedbackCategoryMedicineUnavailable => 'மருந்துகள் கிடைக்கவில்லை';

  @override
  String get feedbackCategoryDiagnosticUnavailable =>
      'பரிசோதனைகள் கிடைக்கவில்லை';

  @override
  String get feedbackCategoryCleanliness => 'தூய்மை';

  @override
  String get feedbackCategoryCost => 'செலவு';

  @override
  String get feedbackCategoryReferralProcess => 'பரிந்துரை நடைமுறை';

  @override
  String get feedbackCategoryAmbulance => 'ஆம்புலன்ஸ்';

  @override
  String get feedbackCategoryTeleconsult => 'ஆன்லைன் ஆலோசனை';

  @override
  String get feedbackCategoryOther => 'வேறு ஏதாவது';

  @override
  String get notificationsTitle => 'செய்திகள்';

  @override
  String get notificationsEmpty => 'இன்னும் செய்திகள் இல்லை';

  @override
  String notificationsUnread(int count) {
    return '$count படிக்காதவை';
  }

  @override
  String get followUpsTitle => 'பின்தொடர்தல்கள்';

  @override
  String get followUpsEmpty => 'இப்போது எதுவும் இல்லை';

  @override
  String followUpDueOn(String date) {
    return '$date அன்று செய்ய வேண்டும்';
  }

  @override
  String followUpOverdue(int days) {
    return '$days நாட்கள் தாமதம்';
  }

  @override
  String get followUpComplete => 'முடிந்ததாகக் குறி';

  @override
  String get followUpOutcome => 'என்ன நடந்தது?';

  @override
  String get consoleQueueTitle => 'வரும் பரிந்துரைகள்';

  @override
  String get consoleQueueEmpty => 'காத்திருக்கும் பரிந்துரைகள் இல்லை';

  @override
  String get consoleAccept => 'ஏற்கவும்';

  @override
  String get consoleReject => 'மறுக்கவும்';

  @override
  String get consoleRejectReason => 'மறுப்பதற்கான காரணம்';

  @override
  String get consoleRejectReasonRequired =>
      'குடிமகனை வேறு மருத்துவமனைக்கு அனுப்ப காரணம் தேவை.';

  @override
  String get consoleMarkArrived => 'நோயாளி வந்துவிட்டார்';

  @override
  String get consoleStartConsultation => 'ஆலோசனையைத் தொடங்கு';

  @override
  String get consoleComplete => 'நிறைவு செய்';

  @override
  String get consoleCompleteOutcome => 'விளைவு';

  @override
  String get consoleNoShow => 'வரவில்லை';

  @override
  String get consoleReadinessTitle => 'மருத்துவமனை தயார்நிலை';

  @override
  String get consoleReadinessSubtitle =>
      'நீங்கள் இங்கே தெரிவிப்பதே குடிமக்கள் எங்கே அனுப்பப்படுவார்கள் என்பதைத் தீர்மானிக்கிறது.';

  @override
  String get consoleUpdateResource => 'புதுப்பி';

  @override
  String get consoleOverride => 'கைமுறை மாற்றம்';

  @override
  String get consoleOverrideReason => 'மாற்றத்திற்கான காரணம்';

  @override
  String consoleLastUpdated(String ago) {
    return '$ago புதுப்பிக்கப்பட்டது';
  }

  @override
  String consoleSlaRemaining(int minutes) {
    return 'பதிலளிக்க $minutes நிமிடம்';
  }

  @override
  String get consoleSlaBreached => 'பதில் தாமதமாகிவிட்டது';

  @override
  String get dashboardTitle => 'மாவட்ட கண்காணிப்பு';

  @override
  String get dashboardReadiness => 'மருத்துவமனை தயார்நிலை';

  @override
  String get dashboardAlerts => 'எச்சரிக்கைகள்';

  @override
  String get dashboardReferrals => 'பரிந்துரைகள்';

  @override
  String get dashboardFeedback => 'குடிமக்கள் கருத்து';

  @override
  String get dashboardFollowUps => 'பின்தொடர்தல் இணக்கம்';

  @override
  String get dashboardAlertsEmpty => 'திறந்த எச்சரிக்கைகள் இல்லை';

  @override
  String get dashboardMetricCreated => 'உருவாக்கப்பட்டது';

  @override
  String get dashboardMetricAccepted => 'ஏற்கப்பட்டது';

  @override
  String get dashboardMetricCompleted => 'நிறைவடைந்தது';

  @override
  String get dashboardMetricBreaches => 'கால வரம்பு மீறல்கள்';

  @override
  String get dashboardAcceptanceRate => 'ஏற்பு விகிதம்';

  @override
  String get dashboardCompletionRate => 'நிறைவு விகிதம்';

  @override
  String get dashboardMedianTurnaround => 'இடைநிலை முடிவு நேரம்';

  @override
  String dashboardMinutes(String value) {
    return '$value நிமிடம்';
  }

  @override
  String get readinessBandGood => 'தயார்';

  @override
  String get readinessBandPartial => 'பகுதியளவு';

  @override
  String get readinessBandCritical => 'மிக மோசம்';

  @override
  String get readinessBandStale => 'தெரிவிக்கப்படவில்லை';

  @override
  String get alertReferralSlaBreach => 'பரிந்துரை பதில் தாமதம்';

  @override
  String get alertReadinessCritical => 'மருத்துவமனை தயார்நிலை மிக மோசம்';

  @override
  String get alertFeedbackIssue => 'குடிமகன் புகார் பதிவு';

  @override
  String get adviceEmergencyUnresponsive =>
      'இது ஒரு மருத்துவ அவசர நிலை. உடனே 108 ஐ அழைக்கவும். வாய் வழியாக எதையும் கொடுக்க வேண்டாம். நோயாளியை ஒரு பக்கமாகத் திருப்பிப் படுக்க வைத்து அவருடன் இருங்கள்.';

  @override
  String get adviceEmergencyBleeding =>
      'சுத்தமான துணியால் காயத்தை அழுத்திப் பிடித்துக்கொள்ளுங்கள். உடனே 108 ஐ அழைக்கவும்.';

  @override
  String get adviceEmergencyPoisoning =>
      'உடனே 108 ஐ அழைக்கவும். வாந்தி எடுக்க வைக்க முயற்சிக்க வேண்டாம். விஷப் பாட்டில் அல்லது அதன் லேபிளை எடுத்துச் செல்லுங்கள்.';

  @override
  String get adviceEmergencySnakebite =>
      'உடனே 108 ஐ அழைக்கவும். கடிபட்ட உறுப்பை அசைக்காமல் இதயத்திற்குக் கீழே வைத்திருங்கள். காயத்தை வெட்டவோ, உறிஞ்சவோ, கட்டவோ வேண்டாம். பாம்பு விஷ முறிவு மருந்து அவசரமாகத் தேவை.';

  @override
  String get adviceEmergencyStroke =>
      'உடனே 108 ஐ அழைக்கவும். அறிகுறிகள் தொடங்கிய நேரத்தைக் குறித்து வைத்திருங்கள் — சிகிச்சை அதைப் பொறுத்தது. உணவு அல்லது தண்ணீர் கொடுக்க வேண்டாம்.';

  @override
  String get adviceEmergencyChestPain =>
      'உடனே 108 ஐ அழைக்கவும். உட்கார்ந்து ஓய்வெடுங்கள்; நடக்கவோ நீங்களே வாகனம் ஓட்டவோ வேண்டாம். உடனடியாக இ.சி.ஜி தேவை.';

  @override
  String get adviceEmergencyBreathlessness =>
      'உடனே 108 ஐ அழைக்கவும். நேராக உட்கார்ந்து இறுக்கமான உடைகளைத் தளர்த்துங்கள். ஆக்சிஜன் தேவைப்படலாம்.';

  @override
  String get adviceEmergencyObstetricBleeding =>
      'உடனே 108 ஐ அழைக்கவும். இடது பக்கமாகப் படுத்துக்கொள்ளுங்கள். கர்ப்ப காலத்தில் இரத்தப்போக்கு அவசர சிகிச்சை தேவை.';

  @override
  String get adviceEmergencyLabour =>
      'பிரசவ வசதி உள்ள மருத்துவமனைக்கு இப்போதே செல்லுங்கள். வாகனம் தேவைப்பட்டால் 108 ஐ அழைக்கவும்.';

  @override
  String get adviceEmergencyFetalMovement =>
      'மகப்பேறு சிகிச்சை உள்ள மருத்துவமனைக்கு இப்போதே செல்லுங்கள். கருவின் அசைவு குறைவது உடனடியாகப் பரிசோதிக்கப்பட வேண்டும்.';

  @override
  String get adviceEmergencySickChild =>
      'குழந்தை நல சிகிச்சை உள்ள மருத்துவமனைக்கு உடனே அழைத்துச் செல்லுங்கள். வாகனத்திற்கு 108 ஐ அழைக்கவும். குழந்தையை சூடாக வைத்து, விழுங்க முடிந்தால் திரவம் கொடுத்துக்கொண்டே இருங்கள்.';

  @override
  String get adviceEmergencyTrauma =>
      'உடனே 108 ஐ அழைக்கவும். ஆபத்து இல்லாத வரை காயமடைந்தவரை அசைக்க வேண்டாம்.';

  @override
  String get adviceEmergencyBurn =>
      'தீக்காயத்தை 20 நிமிடங்கள் சுத்தமான ஓடும் தண்ணீரில் குளிர்விக்கவும். எண்ணெய், பற்பசை அல்லது பனிக்கட்டி வைக்க வேண்டாம். 108 ஐ அழைக்கவும்.';

  @override
  String get adviceEmergencyAnuria =>
      'உடனே 108 ஐ அழைக்கவும். சிறுநீர் கழிக்காமல் இருப்பது சிறுநீரகம் செயலிழப்பதைக் குறிக்கலாம்.';

  @override
  String get adviceHighAnimalBite =>
      'காயத்தை சோப்பு போட்டு ஓடும் தண்ணீரில் 15 நிமிடங்கள் கழுவி, இன்றே மருத்துவமனைக்குச் செல்லுங்கள். ரேபிஸ் தடுப்பூசி தேவை.';

  @override
  String get adviceHighHaemoptysis =>
      'இன்றே மருத்துவரைப் பாருங்கள். காசநோய் இல்லை என்பதை உறுதிப்படுத்த நெஞ்சு எக்ஸ்-ரே மற்றும் சளி பரிசோதனை தேவை.';

  @override
  String get adviceHighTbSuspect =>
      'இவ்வளவு நாட்கள் இருமல், எடை குறைவு அல்லது இரவில் வியர்வையுடன் இருந்தால் இன்றே காசநோய் பரிசோதனை தேவை. சிகிச்சை இலவசம்.';

  @override
  String get adviceHighJaundice =>
      'இன்றே மருத்துவரைப் பாருங்கள். கண் அல்லது தோல் மஞ்சளாக இருப்பதற்கான காரணம் அறிய இரத்தப் பரிசோதனை தேவை.';

  @override
  String get adviceHighBreathlessness =>
      'இன்றே மருத்துவரைப் பாருங்கள். மூச்சு மேலும் சிரமமானால் உடனே திரும்பி வரவும் அல்லது 108 ஐ அழைக்கவும்.';

  @override
  String get adviceHighChestPainYoung =>
      'இன்றே மருத்துவரைப் பார்த்து இ.சி.ஜி கேளுங்கள். வலி அதிகரித்தால், கை அல்லது தாடைக்குப் பரவினால், அல்லது வியர்வை வந்தால் 108 ஐ அழைக்கவும்.';

  @override
  String get adviceHighPersistentFever =>
      'இவ்வளவு நாட்கள் இந்த அளவு காய்ச்சல் இருந்தால், டெங்கு, மலேரியா அல்லது டைபாய்டு பரிசோதனை இன்றே தேவை.';

  @override
  String get adviceHighPregnancy =>
      'கர்ப்ப காலத்தில் ஏதேனும் புதிய அறிகுறி இருந்தால் அதே நாளில் மகப்பேறு சிகிச்சை உள்ள மருத்துவமனையில் பரிசோதிக்க வேண்டும்.';

  @override
  String get adviceHighDiabetesFever =>
      'சர்க்கரை நோய் இருந்தால் தொற்று விரைவில் மோசமாகும். இன்றே மருத்துவரைப் பாருங்கள்.';

  @override
  String get adviceHighCardiacHistory =>
      'உங்கள் இதய நோய் வரலாற்றைக் கருதி, இந்த அறிகுறிகளுக்கு இன்றே இ.சி.ஜி தேவை.';

  @override
  String get adviceMediumDehydration =>
      'ஒவ்வொரு முறை வயிற்றுப்போக்கிற்குப் பிறகும் ஓ.ஆர்.எஸ் குடிக்கவும். இன்றே மருத்துவமனைக்குச் செல்லுங்கள். திரவம் உள்ளே தங்காவிட்டால் அல்லது சிறுநீர் மிகக் குறைவாக இருந்தால் உடனே செல்லுங்கள்.';

  @override
  String get adviceMediumAbdominalPain =>
      'இன்றே மருத்துவரைப் பாருங்கள். வெறும் வயிற்றில் வலி நிவாரண மாத்திரை எடுக்க வேண்டாம். வலி கடுமையானால் அல்லது வயிறு இறுகினால் உடனே செல்லுங்கள்.';

  @override
  String get adviceMediumFebrileIllness =>
      'இன்றே மருத்துவரைப் பார்த்து, தேவைப்பட்டால் இரத்தப் பரிசோதனை செய்யுங்கள். நிறைய திரவம் குடித்து ஓய்வெடுங்கள்.';

  @override
  String get adviceMediumUti =>
      'இன்றே மருத்துவரைப் பாருங்கள். சிறுநீர் பரிசோதனை தேவை. அதுவரை நிறைய தண்ணீர் குடியுங்கள்.';

  @override
  String get adviceMediumJointPain =>
      'மருத்துவரைப் பார்த்து பரிசோதிக்கவும். மூட்டுக்கு ஓய்வு கொடுத்து கனமான பொருட்களைத் தூக்க வேண்டாம்.';

  @override
  String get adviceMediumMentalHealth =>
      'ஆலோசகர் அல்லது மருத்துவரிடம் பேசுவது உதவும். ஆன்லைன் ஆலோசனை மூலம் இதைச் செய்யலாம்; இது ரகசியமாக வைக்கப்படும்.';

  @override
  String get adviceMediumVision =>
      'கண் பரிசோதனை செய்யுங்கள். பார்வை திடீரென இழந்தால் அல்லது கண் வலி இருந்தால் உடனே செல்லுங்கள்.';

  @override
  String get adviceMediumMinorBurn =>
      '20 நிமிடங்கள் ஓடும் தண்ணீரில் குளிர்விக்கவும், சுத்தமான துணியால் தளர்வாக மூடவும், மருத்துவமனையில் கட்டுப் போடவும்.';

  @override
  String get adviceMediumMinorInjury =>
      'காயத்தைச் சுத்தம் செய்து பரிசோதிக்கவும். வீக்கம் இருந்தால் அல்லது அசைக்க முடியாவிட்டால் எக்ஸ்-ரே தேவைப்படலாம்.';

  @override
  String get adviceMediumDental =>
      'பல் மருத்துவர் அல்லது மருத்துவமனை மருத்துவரைப் பாருங்கள். வெதுவெதுப்பான உப்பு நீரில் வாய் கொப்பளிக்கவும், மிகச் சூடான அல்லது குளிர்ந்த உணவைத் தவிர்க்கவும்.';

  @override
  String get adviceLowMildFever =>
      'ஓய்வெடுங்கள், நிறைய திரவம் குடியுங்கள், பாராசிட்டமால் அறிவுரைப்படி எடுத்துக்கொள்ளுங்கள். காய்ச்சல் மூன்று நாட்களுக்கு மேல் நீடித்தால், 39C க்கு மேல் சென்றால், அல்லது மூச்சுத் திணறல், தோல் அரிப்பு அல்லது வாந்தி வந்தால் மருத்துவரைப் பாருங்கள்.';

  @override
  String get adviceLowMildCough =>
      'வெதுவெதுப்பான திரவங்கள் மற்றும் ஆவி பிடிப்பது உதவும். இருமல் இரண்டு வாரங்களுக்கு மேல் நீடித்தால், அல்லது காய்ச்சல், சளியில் இரத்தம் அல்லது மூச்சுத் திணறல் வந்தால் மருத்துவரைப் பாருங்கள்.';

  @override
  String get adviceLowMildHeadache =>
      'அமைதியான இருண்ட அறையில் ஓய்வெடுங்கள், தண்ணீர் குடியுங்கள், நேரத்திற்குச் சாப்பிடுங்கள். தலைவலி திடீரென மிகக் கடுமையாக இருந்தால், அல்லது காய்ச்சல், வாந்தி, பலவீனம் அல்லது பார்வை மாற்றத்துடன் வந்தால் மருத்துவரைப் பாருங்கள்.';

  @override
  String get adviceLowSoreThroat =>
      'வெதுவெதுப்பான உப்பு நீரில் வாய் கொப்பளிப்பதும் சூடான திரவங்களும் உதவும். விழுங்க அல்லது மூச்சு விட சிரமமாக இருந்தால், அல்லது காய்ச்சல் மூன்று நாட்களுக்கு மேல் இருந்தால் மருத்துவரைப் பாருங்கள்.';

  @override
  String get adviceLowBackPain =>
      'மெதுவாக நடமாடுங்கள், படுக்கையில் முழுநேர ஓய்வையும் கனமான வேலையையும் தவிர்க்கவும். வலி காலுக்குப் பரவினால், அல்லது மரத்துப்போதல், பலவீனம் அல்லது சிறுநீர் கழிப்பதில் சிரமம் இருந்தால் மருத்துவரைப் பாருங்கள்.';

  @override
  String get adviceLowRash =>
      'தோலைச் சுத்தமாகவும் காயவும் வைத்துக்கொள்ளுங்கள், சொறிய வேண்டாம். அரிப்பு வேகமாகப் பரவினால், கொப்புளம் வந்தால், அல்லது காய்ச்சல் அல்லது மூச்சுத் திணறலுடன் இருந்தால் மருத்துவரைப் பாருங்கள்.';

  @override
  String get adviceDefaultVisitFacility =>
      'உங்கள் அறிகுறிகளை சரியாக மதிப்பிடுவதற்கு மருத்துவரைப் பாருங்கள்.';

  @override
  String get adviceWhenToReturn =>
      'உடல்நிலை மோசமானால் உடனே திரும்பி வரவும் அல்லது 108 ஐ அழைக்கவும்.';

  @override
  String get followupDefault =>
      'நோயாளியின் நிலையைப் பரிசோதித்து விளைவைப் பதிவு செய்யுங்கள்.';

  @override
  String get followupPostReferral =>
      'நோயாளி மருத்துவமனைக்குச் சென்றாரா, பரிசோதிக்கப்பட்டாரா என்பதை உறுதிப்படுத்தி என்ன நடந்தது என்று பதிவு செய்யுங்கள்.';

  @override
  String get errorUnauthenticated => 'தொடர உள்நுழையவும்.';

  @override
  String get errorSignInFailed =>
      'உள்நுழைய முடியவில்லை. விவரங்களைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get errorSessionExpired =>
      'உங்கள் அமர்வு காலாவதியானது. மீண்டும் உள்நுழையவும்.';

  @override
  String get errorForbidden => 'இதற்கான அணுகல் உங்களுக்கு இல்லை.';

  @override
  String get errorNotPermitted => 'இதைச் செய்ய உங்களுக்கு அனுமதி இல்லை.';

  @override
  String get errorInvalidInput =>
      'நீங்கள் உள்ளிட்டதைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get errorNotFound => 'இந்தப் பதிவு கிடைக்கவில்லை.';

  @override
  String get errorAlreadyExists => 'இது ஏற்கனவே உள்ளது.';

  @override
  String get errorRelatedRecordMissing => 'இதற்குத் தேவையான ஒரு பதிவு இல்லை.';

  @override
  String get errorOffline =>
      'நீங்கள் இணையத்தில் இல்லை எனத் தெரிகிறது. உங்கள் தகவலைச் சேமித்து மீண்டும் முயற்சிக்கிறோம்.';

  @override
  String get errorUnexpected => 'ஏதோ தவறு நடந்தது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get errorActionNotAllowed => 'இந்தச் செயலுக்கு இப்போது அனுமதி இல்லை.';

  @override
  String get errorReferralTransitionIllegal =>
      'இந்தப் பரிந்துரை ஏற்கனவே அடுத்த நிலைக்குச் சென்றுவிட்டது. தற்போதைய நிலையைக் காண புதுப்பிக்கவும்.';

  @override
  String get errorReasonRequired => 'காரணத்தைக் குறிப்பிடவும்.';

  @override
  String get errorOutcomeRequired => 'விளைவைப் பதிவு செய்யவும்.';

  @override
  String get errorOverrideReasonRequired => 'கைமுறை மாற்றத்திற்கு காரணம் தேவை.';

  @override
  String get errorFacilityNotOperational =>
      'இந்த மருத்துவமனை தற்போது இயங்கவில்லை.';

  @override
  String get errorTriageUnavailable =>
      'அறிகுறி மதிப்பீடு இப்போது கிடைக்கவில்லை. உங்கள் ஆஷா பணியாளரைத் தொடர்பு கொள்ளவும், அவசரமானால் 108 ஐ அழைக்கவும்.';

  @override
  String get errorProfileMissing =>
      'உங்கள் கணக்கு இன்னும் அமைக்கப்படவில்லை. நிர்வாகியைத் தொடர்பு கொள்ளவும்.';

  @override
  String get errorNoAudioCaptured =>
      'எதுவும் கேட்கவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get errorTtsUnavailable =>
      'ஒலி வடிவ பதில் கிடைக்கவில்லை. உரை திரையில் காட்டப்படுகிறது.';

  @override
  String get errorAmbulanceRequestFailed =>
      'வாகனத்தைக் கோர முடியவில்லை. நேரடியாக 108 ஐ அழைக்கவும்.';

  @override
  String get errorStorage => 'அந்தக் கோப்பைப் பதிவேற்ற முடியவில்லை.';

  @override
  String get errorPatientDistrictUnknown =>
      'இந்த நோயாளிக்கு மாவட்டம் பதிவு செய்யப்படவில்லை; எனவே வாகனத்தைக் கோர முடியாது.';

  @override
  String get errorLocationDenied =>
      'அருகிலுள்ள மருத்துவமனைகளைக் கண்டுபிடிக்க உங்கள் இருப்பிடம் தேவை. அல்லது உங்கள் கிராமத்தைத் தேர்ந்தெடுக்கலாம்.';

  @override
  String get errorLocationUnavailable =>
      'உங்கள் இருப்பிடத்தைப் பெற முடியவில்லை. உங்கள் கிராமத்தைத் தேர்ந்தெடுக்கவும்.';
}
