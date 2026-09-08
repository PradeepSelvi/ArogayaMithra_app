// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'am_strings.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AmStringsHi extends AmStrings {
  AmStringsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'आरोग्यमित्र';

  @override
  String get actionContinue => 'जारी रखें';

  @override
  String get actionBack => 'वापस';

  @override
  String get actionNext => 'अगला';

  @override
  String get actionCancel => 'रद्द करें';

  @override
  String get actionRetry => 'फिर से कोशिश करें';

  @override
  String get actionSave => 'सहेजें';

  @override
  String get actionClose => 'बंद करें';

  @override
  String get actionConfirm => 'पुष्टि करें';

  @override
  String get actionSubmit => 'जमा करें';

  @override
  String get actionYes => 'हाँ';

  @override
  String get actionNo => 'नहीं';

  @override
  String get actionSkip => 'छोड़ें';

  @override
  String get actionDone => 'पूर्ण';

  @override
  String get actionRefresh => 'ताज़ा करें';

  @override
  String get loading => 'लोड हो रहा है';

  @override
  String get noResults => 'अभी दिखाने के लिए कुछ नहीं है';

  @override
  String get chooseLanguage => 'अपनी भाषा चुनें';

  @override
  String get languageTamil => 'தமிழ்';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get signIn => 'साइन इन करें';

  @override
  String get signOut => 'साइन आउट करें';

  @override
  String get staffSignIn => 'कर्मचारी साइन इन';

  @override
  String get phoneNumber => 'मोबाइल नंबर';

  @override
  String get sendOtp => 'कोड भेजें';

  @override
  String get enterOtp => 'आपको भेजा गया कोड दर्ज करें';

  @override
  String get verify => 'सत्यापित करें';

  @override
  String get emailAddress => 'ईमेल पता';

  @override
  String get password => 'पासवर्ड';

  @override
  String get signInHelp =>
      'हम आपका मोबाइल नंबर केवल आपके स्वास्थ्य रिकॉर्ड को सुरक्षित रखने के लिए उपयोग करते हैं।';

  @override
  String homeGreeting(String name) {
    return 'नमस्ते, $name';
  }

  @override
  String get homeNeedCare => 'मुझे इलाज चाहिए';

  @override
  String get homeNeedCareHint =>
      'हमें बताएं कि आपको कैसा महसूस हो रहा है, हम सही इलाज खोजेंगे';

  @override
  String get homeEmergency => 'आपातकालीन सहायता';

  @override
  String get homeMyReferrals => 'मेरे रेफ़रल';

  @override
  String get homeNotifications => 'संदेश';

  @override
  String get homeFollowUps => 'मेरी फॉलो-अप';

  @override
  String get homeFeedback => 'प्रतिक्रिया दें';

  @override
  String get homeProfile => 'मेरी जानकारी';

  @override
  String get profileTitle => 'आपकी जानकारी';

  @override
  String get profileWhy =>
      'हम यह इसलिए पूछते हैं ताकि जांच सही ढंग से आपके जोखिम का आकलन कर सके।';

  @override
  String get profileName => 'पूरा नाम';

  @override
  String get profileAge => 'आयु (वर्षों में)';

  @override
  String get profileSex => 'लिंग';

  @override
  String get sexMale => 'पुरुष';

  @override
  String get sexFemale => 'महिला';

  @override
  String get sexOther => 'अन्य';

  @override
  String get sexUndisclosed => 'बताना नहीं चाहते';

  @override
  String get profilePregnant => 'वर्तमान में गर्भवती';

  @override
  String get profileChronic => 'दीर्घकालिक बीमारियाँ';

  @override
  String get chronicDiabetes => 'मधुमेह';

  @override
  String get chronicHypertension => 'उच्च रक्तचाप';

  @override
  String get chronicHeartDisease => 'हृदय रोग';

  @override
  String get chronicAsthma => 'दमा';

  @override
  String get chronicKidneyDisease => 'गुर्दे की बीमारी';

  @override
  String get chronicTuberculosis => 'क्षय रोग (टीबी)';

  @override
  String get symptomsTitle => 'आपको क्या तकलीफ़ है?';

  @override
  String get symptomsHint => 'जो भी लागू हो उसे चुनें';

  @override
  String get symptomsSearch => 'लक्षण खोजें';

  @override
  String symptomsSelected(int count) {
    return '$count चयनित';
  }

  @override
  String get symptomsCommon => 'सामान्य';

  @override
  String get symptomsAll => 'सभी लक्षण';

  @override
  String get symptomsNoneSelected => 'जारी रखने के लिए कम से कम एक लक्षण चुनें';

  @override
  String get symptomsVoiceInput => 'इसके बजाय बोलें';

  @override
  String get symptomsListening => 'सुन रहा है';

  @override
  String get symptomsVoiceConfirm =>
      'हमने यह सुना है। जारी रखने से पहले कृपया पुष्टि करें।';

  @override
  String get severityTitle => 'अभी यह कितना गंभीर है?';

  @override
  String get severityHint =>
      'इससे तय होता है कि आपको कितनी जल्दी देखा जाएगा, इसलिए कृपया सही बताएं।';

  @override
  String get severity1 => 'बहुत हल्का';

  @override
  String get severity2 => 'हल्का';

  @override
  String get severity3 => 'मध्यम';

  @override
  String get severity4 => 'गंभीर';

  @override
  String get severity5 => 'बहुत गंभीर';

  @override
  String get durationTitle => 'यह कब से हो रहा है?';

  @override
  String durationHours(int count) {
    return '$count घंटे';
  }

  @override
  String get durationLessThanDay => 'एक दिन से कम';

  @override
  String get durationOneToThreeDays => '1 से 3 दिन';

  @override
  String get durationUpToWeek => '3 दिन से एक सप्ताह';

  @override
  String get durationOverTwoWeeks => 'दो सप्ताह से अधिक';

  @override
  String get triageRunning => 'आपके लक्षणों की जांच हो रही है';

  @override
  String get triageResultTitle => 'आपको क्या करना चाहिए';

  @override
  String get riskLow => 'कम जोखिम';

  @override
  String get riskMedium => 'जांच की आवश्यकता है';

  @override
  String get riskHigh => 'आज ही इलाज ज़रूरी है';

  @override
  String get riskEmergency => 'आपातकाल';

  @override
  String get nextActionSelfCare => 'घर पर देखभाल';

  @override
  String get nextActionVisitFacility => 'स्वास्थ्य केंद्र जाएं';

  @override
  String get nextActionTeleconsult => 'ऑनलाइन डॉक्टर से बात करें';

  @override
  String get nextActionRefer => 'किसी केंद्र के लिए रेफ़र करवाएं';

  @override
  String get nextActionEmergencyResponse => 'अभी आपातकालीन सहायता लें';

  @override
  String get triageRedFlagsTitle => 'मिले चेतावनी संकेत';

  @override
  String triageAssessedBy(int version) {
    return 'क्लिनिकल नियम सेट v$version का उपयोग करके आकलन किया गया';
  }

  @override
  String get triageFallbackWarning =>
      'हम आपके लक्षणों का सटीक मिलान नहीं कर सके, इसलिए सुरक्षा के लिए हम आपसे चिकित्सक से मिलने का अनुरोध कर रहे हैं।';

  @override
  String get triageNotDiagnosis =>
      'यह कहाँ जाना है इसका मार्गदर्शन है। यह निदान नहीं है।';

  @override
  String get triageCallEmergency => 'अभी 108 पर कॉल करें';

  @override
  String get triageFindFacility => 'स्वास्थ्य केंद्र खोजें';

  @override
  String get facilitiesTitle => 'कहाँ जाएं';

  @override
  String get facilitiesSubtitle =>
      'यात्रा समय, उपलब्ध सेवाओं और वर्तमान तैयारी के अनुसार क्रमबद्ध';

  @override
  String get facilitiesSearching =>
      'आपके पास के स्वास्थ्य केंद्र खोजे जा रहे हैं';

  @override
  String get facilitiesNoneFound =>
      'इस दायरे में कोई उपयुक्त केंद्र नहीं मिला। कृपया 108 या अपनी आशा कार्यकर्ता को कॉल करें।';

  @override
  String facilityDistance(String km) {
    return '$km किमी दूर';
  }

  @override
  String facilityTravelTime(int minutes) {
    return 'लगभग $minutes मिनट';
  }

  @override
  String facilityReadiness(int percent) {
    return 'तैयारी $percent%';
  }

  @override
  String get facilityOpen24x7 => '24 घंटे खुला';

  @override
  String get facilityHasEmergency => 'आपातकालीन विभाग';

  @override
  String get readinessDoctor => 'डॉक्टर';

  @override
  String get readinessMedicines => 'दवाइयाँ';

  @override
  String get readinessDiagnostics => 'जांच';

  @override
  String get readinessBeds => 'बिस्तर';

  @override
  String get availabilityAvailable => 'उपलब्ध';

  @override
  String get availabilityLimited => 'सीमित';

  @override
  String get availabilityUnavailable => 'उपलब्ध नहीं';

  @override
  String get availabilityUnknown => 'रिपोर्ट नहीं की गई';

  @override
  String readinessStaleWarning(int hours) {
    return 'इस केंद्र ने $hours घंटे पहले अंतिम बार अपडेट किया था। यात्रा से पहले कृपया कॉल करें।';
  }

  @override
  String get readinessNotReported =>
      'इस केंद्र ने अपनी स्थिति रिपोर्ट नहीं की है। यात्रा से पहले कृपया कॉल करें।';

  @override
  String get facilityServiceGap =>
      'हो सकता है यह केंद्र आपकी सभी आवश्यकताएं पूरी न करे। यदि संभव हो तो पहले से कॉल करें।';

  @override
  String get facilityChoose => 'यह केंद्र चुनें';

  @override
  String get facilityDirections => 'दिशा-निर्देश';

  @override
  String get facilityCall => 'कॉल करें';

  @override
  String get facilityWhyRanked => 'यह क्रम क्यों?';

  @override
  String facilityScoreBreakdown(
    int travel,
    int services,
    int wait,
    int confidence,
  ) {
    return 'यात्रा $travel%, सेवाएं $services%, प्रतीक्षा $wait%, डेटा विश्वसनीयता $confidence%';
  }

  @override
  String get referralCreatedTitle => 'रेफ़रल बनाया गया';

  @override
  String referralReference(String code) {
    return 'संदर्भ $code';
  }

  @override
  String get referralShowAtFacility => 'यह संदर्भ केंद्र पर दिखाएं';

  @override
  String get referralsTitle => 'मेरे रेफ़रल';

  @override
  String get referralsEmpty => 'अभी तक आपका कोई रेफ़रल नहीं है';

  @override
  String get referralStatusCreated => 'बनाया गया';

  @override
  String get referralStatusTriaged => 'लक्षणों का आकलन हुआ';

  @override
  String get referralStatusRecommended => 'केंद्र सुझाया गया';

  @override
  String get referralStatusReferralSent => 'केंद्र की प्रतीक्षा में';

  @override
  String get referralStatusAccepted => 'केंद्र ने स्वीकार किया';

  @override
  String get referralStatusPatientTravelling => 'रास्ते में';

  @override
  String get referralStatusArrived => 'पहुँच गए';

  @override
  String get referralStatusConsultation => 'डॉक्टर के साथ';

  @override
  String get referralStatusCompleted => 'पूर्ण';

  @override
  String get referralStatusRejected => 'स्वीकार नहीं किया गया';

  @override
  String get referralStatusCancelled => 'रद्द किया गया';

  @override
  String get referralStatusExpired => 'समाप्त हो गया';

  @override
  String get referralStatusNoShow => 'उपस्थित नहीं हुए';

  @override
  String get referralStatusEmergencyEscalated =>
      'आपातकालीन सहायता की व्यवस्था हुई';

  @override
  String get referralTimeline => 'इतिहास';

  @override
  String referralAwaitingFacility(int minutes) {
    return 'केंद्र के पास जवाब देने के लिए $minutes मिनट हैं';
  }

  @override
  String get referralOverdue =>
      'केंद्र ने समय पर जवाब नहीं दिया। इसे चिह्नित कर दिया गया है।';

  @override
  String get referralRejectedNext => 'यह केंद्र आपको नहीं ले सका। दूसरा चुनें।';

  @override
  String get referralChooseAnother => 'दूसरा केंद्र चुनें';

  @override
  String get referralImOnMyWay => 'मैं रास्ते में हूँ';

  @override
  String get referralCancel => 'रेफ़रल रद्द करें';

  @override
  String get referralCancelReason => 'आप क्यों रद्द कर रहे हैं?';

  @override
  String get referralPriorityRoutine => 'सामान्य';

  @override
  String get referralPriorityUrgent => 'तत्काल';

  @override
  String get referralPriorityEmergency => 'आपातकाल';

  @override
  String get referralAutomatedEvent => 'सिस्टम द्वारा स्वतः अपडेट किया गया';

  @override
  String get ambulanceTitle => 'आपातकालीन परिवहन';

  @override
  String get ambulanceRequest => 'एम्बुलेंस का अनुरोध करें';

  @override
  String get ambulanceRequesting => 'परिवहन का अनुरोध हो रहा है';

  @override
  String ambulanceEta(int minutes) {
    return 'लगभग $minutes मिनट में पहुँचेगी';
  }

  @override
  String ambulanceVehicle(String number) {
    return 'वाहन $number';
  }

  @override
  String get ambulanceStayPut => 'जहाँ हैं वहीं रहें और अपना फ़ोन पास रखें।';

  @override
  String get ambulanceMockNotice =>
      'प्रदर्शन मोड: कोई वास्तविक एम्बुलेंस नहीं भेजी गई है।';

  @override
  String get feedbackTitle => 'आपकी देखभाल कैसी रही?';

  @override
  String get feedbackRating => 'आपकी रेटिंग';

  @override
  String get feedbackCategory => 'यह किस बारे में है?';

  @override
  String get feedbackComment => 'और कुछ जो आप हमें बताना चाहते हैं?';

  @override
  String get feedbackThanks => 'धन्यवाद। आपकी प्रतिक्रिया दर्ज कर ली गई है।';

  @override
  String get feedbackWouldRecommend => 'क्या आप इस केंद्र की सिफ़ारिश करेंगे?';

  @override
  String get feedbackCategoryGeneral => 'सामान्य';

  @override
  String get feedbackCategoryWaitingTime => 'प्रतीक्षा समय';

  @override
  String get feedbackCategoryStaffBehaviour => 'कर्मचारी का व्यवहार';

  @override
  String get feedbackCategoryMedicineUnavailable => 'दवाइयाँ उपलब्ध नहीं';

  @override
  String get feedbackCategoryDiagnosticUnavailable => 'जांच उपलब्ध नहीं';

  @override
  String get feedbackCategoryCleanliness => 'स्वच्छता';

  @override
  String get feedbackCategoryCost => 'लागत';

  @override
  String get feedbackCategoryReferralProcess => 'रेफ़रल प्रक्रिया';

  @override
  String get feedbackCategoryAmbulance => 'एम्बुलेंस';

  @override
  String get feedbackCategoryTeleconsult => 'ऑनलाइन परामर्श';

  @override
  String get feedbackCategoryOther => 'कुछ और';

  @override
  String get notificationsTitle => 'संदेश';

  @override
  String get notificationsEmpty => 'अभी तक कोई संदेश नहीं';

  @override
  String notificationsUnread(int count) {
    return '$count अपठित';
  }

  @override
  String get followUpsTitle => 'फॉलो-अप';

  @override
  String get followUpsEmpty => 'कुछ भी बाकी नहीं';

  @override
  String followUpDueOn(String date) {
    return '$date को नियत';
  }

  @override
  String followUpOverdue(int days) {
    return '$days दिन देर हो गई';
  }

  @override
  String get followUpComplete => 'पूर्ण चिह्नित करें';

  @override
  String get followUpOutcome => 'क्या हुआ?';

  @override
  String get consoleQueueTitle => 'आने वाले रेफ़रल';

  @override
  String get consoleQueueEmpty => 'कोई रेफ़रल प्रतीक्षारत नहीं';

  @override
  String get consoleAccept => 'स्वीकार करें';

  @override
  String get consoleReject => 'अस्वीकार करें';

  @override
  String get consoleRejectReason => 'अस्वीकार करने का कारण';

  @override
  String get consoleRejectReasonRequired =>
      'कारण आवश्यक है ताकि नागरिक को फिर से भेजा जा सके।';

  @override
  String get consoleMarkArrived => 'मरीज़ पहुँच गया';

  @override
  String get consoleStartConsultation => 'परामर्श शुरू करें';

  @override
  String get consoleComplete => 'पूर्ण करें';

  @override
  String get consoleCompleteOutcome => 'परिणाम';

  @override
  String get consoleNoShow => 'उपस्थित नहीं हुआ';

  @override
  String get consoleReadinessTitle => 'केंद्र की तैयारी';

  @override
  String get consoleReadinessSubtitle =>
      'आप यहाँ जो प्रकाशित करते हैं वही तय करता है कि नागरिकों को कहाँ भेजा जाता है।';

  @override
  String get consoleUpdateResource => 'अपडेट करें';

  @override
  String get consoleOverride => 'मैनुअल ओवरराइड';

  @override
  String get consoleOverrideReason => 'ओवरराइड का कारण';

  @override
  String consoleLastUpdated(String ago) {
    return '$ago अपडेट किया गया';
  }

  @override
  String consoleSlaRemaining(int minutes) {
    return 'जवाब देने के लिए $minutes मिनट';
  }

  @override
  String get consoleSlaBreached => 'जवाब देने में देरी';

  @override
  String get dashboardTitle => 'जिला डैशबोर्ड';

  @override
  String get dashboardReadiness => 'केंद्र की तैयारी';

  @override
  String get dashboardAlerts => 'चेतावनियाँ';

  @override
  String get dashboardReferrals => 'रेफ़रल';

  @override
  String get dashboardFeedback => 'नागरिक प्रतिक्रिया';

  @override
  String get dashboardFollowUps => 'फॉलो-अप अनुपालन';

  @override
  String get dashboardAlertsEmpty => 'कोई खुली चेतावनी नहीं';

  @override
  String get dashboardMetricCreated => 'बनाया गया';

  @override
  String get dashboardMetricAccepted => 'स्वीकृत';

  @override
  String get dashboardMetricCompleted => 'पूर्ण';

  @override
  String get dashboardMetricBreaches => 'SLA उल्लंघन';

  @override
  String get dashboardAcceptanceRate => 'स्वीकृति दर';

  @override
  String get dashboardCompletionRate => 'पूर्णता दर';

  @override
  String get dashboardMedianTurnaround => 'औसत निपटान समय';

  @override
  String dashboardMinutes(String value) {
    return '$value मिनट';
  }

  @override
  String get readinessBandGood => 'तैयार';

  @override
  String get readinessBandPartial => 'आंशिक';

  @override
  String get readinessBandCritical => 'गंभीर';

  @override
  String get readinessBandStale => 'रिपोर्ट नहीं की गई';

  @override
  String get alertReferralSlaBreach => 'रेफ़रल जवाब में देरी';

  @override
  String get alertReadinessCritical => 'केंद्र की तैयारी गंभीर स्थिति में';

  @override
  String get alertFeedbackIssue => 'नागरिक ने समस्या दर्ज की';

  @override
  String get adviceEmergencyUnresponsive =>
      'यह एक चिकित्सा आपातकाल है। तुरंत 108 पर कॉल करें। मुँह से कुछ भी न दें। व्यक्ति को करवट पर लिटाएं और उनके साथ रहें।';

  @override
  String get adviceEmergencyBleeding =>
      'घाव पर साफ़ कपड़े से मज़बूती से दबाव डालें और दबाते रहें। तुरंत 108 पर कॉल करें।';

  @override
  String get adviceEmergencyPoisoning =>
      'तुरंत 108 पर कॉल करें। व्यक्ति को उल्टी कराने की कोशिश न करें। कंटेनर या लेबल अपने साथ ले जाएं।';

  @override
  String get adviceEmergencySnakebite =>
      'तुरंत 108 पर कॉल करें। काटे गए अंग को स्थिर रखें और हृदय के स्तर से नीचे रखें। घाव को काटें, चूसें या बांधें नहीं। एंटी-स्नेक वेनम की तत्काल आवश्यकता है।';

  @override
  String get adviceEmergencyStroke =>
      'तुरंत 108 पर कॉल करें। लक्षण शुरू होने का समय नोट करें, क्योंकि उपचार इस पर निर्भर करता है। भोजन या पानी न दें।';

  @override
  String get adviceEmergencyChestPain =>
      'तुरंत 108 पर कॉल करें। बैठें और आराम करें, खुद चलें या गाड़ी न चलाएं। इसके लिए तुरंत ईसीजी की आवश्यकता है।';

  @override
  String get adviceEmergencyBreathlessness =>
      'तुरंत 108 पर कॉल करें। सीधे बैठें और तंग कपड़े ढीले करें। ऑक्सीजन की आवश्यकता हो सकती है।';

  @override
  String get adviceEmergencyObstetricBleeding =>
      'तुरंत 108 पर कॉल करें। अपनी बाईं करवट लेट जाएं। गर्भावस्था में रक्तस्राव के लिए तत्काल देखभाल आवश्यक है।';

  @override
  String get adviceEmergencyLabour =>
      'अभी प्रसव सेवाओं वाले केंद्र जाएं। यदि आवश्यक हो तो परिवहन के लिए 108 पर कॉल करें।';

  @override
  String get adviceEmergencyFetalMovement =>
      'अभी प्रसूति देखभाल वाले केंद्र जाएं। शिशु की गतिविधि में कमी की तुरंत जांच होनी चाहिए।';

  @override
  String get adviceEmergencySickChild =>
      'बच्चे को तुरंत बाल चिकित्सा सुविधा वाले केंद्र ले जाएं। परिवहन के लिए 108 पर कॉल करें। बच्चे को गर्म रखें और यदि वह निगल सकता है तो तरल पदार्थ देते रहें।';

  @override
  String get adviceEmergencyTrauma =>
      'तुरंत 108 पर कॉल करें। घायल व्यक्ति को तब तक न हिलाएं जब तक वे खतरे में न हों।';

  @override
  String get adviceEmergencyBurn =>
      'जले हुए स्थान को 20 मिनट तक साफ़ बहते पानी के नीचे ठंडा करें। तेल, टूथपेस्ट या बर्फ़ न लगाएं। 108 पर कॉल करें।';

  @override
  String get adviceEmergencyAnuria =>
      'तुरंत 108 पर कॉल करें। लगभग बिल्कुल पेशाब न आना गुर्दे के फेल होने का संकेत हो सकता है।';

  @override
  String get adviceHighAnimalBite =>
      'घाव को साबुन और बहते पानी से 15 मिनट तक धोएं और आज ही केंद्र जाएं। आपको रेबीज़ का टीका चाहिए।';

  @override
  String get adviceHighHaemoptysis =>
      'आज ही डॉक्टर से मिलें। क्षय रोग (टीबी) को रद्द करने के लिए आपको छाती का एक्स-रे और थूक की जांच चाहिए।';

  @override
  String get adviceHighTbSuspect =>
      'इतने लंबे समय से खांसी के साथ वज़न कम होना या रात में पसीना आना, आज ही टीबी जांच की आवश्यकता है। उपचार निःशुल्क है।';

  @override
  String get adviceHighJaundice =>
      'आज ही डॉक्टर से मिलें। आँखों या त्वचा का पीला होना, कारण जानने के लिए रक्त जांच आवश्यक है।';

  @override
  String get adviceHighBreathlessness =>
      'आज ही डॉक्टर से मिलें। सांस लेने में और तकलीफ़ होने पर तुरंत वापस जाएं या 108 पर कॉल करें।';

  @override
  String get adviceHighChestPainYoung =>
      'आज ही डॉक्टर से मिलें और ईसीजी के लिए कहें। यदि दर्द बढ़े, बांह या जबड़े तक फैले, या पसीना आने लगे तो 108 पर कॉल करें।';

  @override
  String get adviceHighPersistentFever =>
      'इतने लंबे समय तक इतना तेज़ बुखार होने पर डेंगू, मलेरिया या टाइफ़ाइड की जांच के लिए आज ही रक्त जांच आवश्यक है।';

  @override
  String get adviceHighPregnancy =>
      'गर्भावस्था में किसी भी नए लक्षण की उसी दिन प्रसूति देखभाल वाले केंद्र में जांच होनी चाहिए।';

  @override
  String get adviceHighDiabetesFever =>
      'मधुमेह के साथ, संक्रमण जल्दी बिगड़ सकता है। आज ही डॉक्टर से मिलें।';

  @override
  String get adviceHighCardiacHistory =>
      'आपके हृदय के इतिहास के साथ, इन लक्षणों के लिए आज ही ईसीजी आवश्यक है।';

  @override
  String get adviceMediumDehydration =>
      'हर पतले दस्त के बाद ORS पिएं। आज ही केंद्र जाएं, और जल्दी जाएं यदि आप तरल पदार्थ नहीं रख पा रहे या बहुत कम पेशाब आ रहा है।';

  @override
  String get adviceMediumAbdominalPain =>
      'आज ही चिकित्सक से मिलें। खाली पेट दर्दनिवारक न लें। यदि दर्द गंभीर हो जाए या पेट सख्त महसूस हो तो तुरंत जाएं।';

  @override
  String get adviceMediumFebrileIllness =>
      'आज ही जांच और आवश्यकता पड़ने पर रक्त जांच के लिए चिकित्सक से मिलें। पर्याप्त तरल पदार्थ पिएं और आराम करें।';

  @override
  String get adviceMediumUti =>
      'आज ही चिकित्सक से मिलें। पेशाब की जांच आवश्यक है। इस बीच पर्याप्त पानी पिएं।';

  @override
  String get adviceMediumJointPain =>
      'आकलन के लिए चिकित्सक से मिलें। जोड़ को आराम दें और भारी सामान उठाने से बचें।';

  @override
  String get adviceMediumMentalHealth =>
      'किसी परामर्शदाता या डॉक्टर से बात करना मदद करता है। आप यह ऑनलाइन परामर्श से कर सकते हैं, और यह गोपनीय है।';

  @override
  String get adviceMediumVision =>
      'अपनी आँखों की जांच कराएं। यदि दृष्टि अचानक कम हो या आँख में दर्द हो तो जल्दी जाएं।';

  @override
  String get adviceMediumMinorBurn =>
      '20 मिनट तक बहते पानी के नीचे ठंडा करें, साफ़ कपड़े से ढीला ढकें, और केंद्र में इसकी ड्रेसिंग कराएं।';

  @override
  String get adviceMediumMinorInjury =>
      'चोट को साफ़ करवाकर जांच कराएं। यदि सूजन हो या आप इसे हिला न सकें तो एक्स-रे की आवश्यकता हो सकती है।';

  @override
  String get adviceMediumDental =>
      'दंत चिकित्सक या केंद्र के डॉक्टर से मिलें। गुनगुने नमक के पानी से कुल्ला करें और बहुत गर्म या ठंडा भोजन न लें।';

  @override
  String get adviceLowMildFever =>
      'आराम करें, पर्याप्त तरल पदार्थ पिएं और निर्देशानुसार पैरासिटामोल लें। यदि बुखार तीन दिन से अधिक रहे, 39C से ऊपर जाए, या सांस फूलना, चकत्ते या उल्टी हो तो चिकित्सक से मिलें।';

  @override
  String get adviceLowMildCough =>
      'गर्म तरल पदार्थ और भाप लेना मदद करता है। यदि खांसी दो सप्ताह से अधिक रहे, या बुखार, थूक में खून या सांस फूलना हो तो चिकित्सक से मिलें।';

  @override
  String get adviceLowMildHeadache =>
      'शांत, अंधेरे कमरे में आराम करें, पानी पिएं और नियमित भोजन करें। यदि सिरदर्द अचानक और गंभीर हो, या बुखार, उल्टी, कमज़ोरी या दृष्टि में बदलाव के साथ हो तो चिकित्सक से मिलें।';

  @override
  String get adviceLowSoreThroat =>
      'गुनगुने नमक के पानी से गरारे और गर्म तरल पदार्थ मदद करते हैं। यदि निगलने या सांस लेने में कठिनाई हो, या बुखार तीन दिन से अधिक रहे तो चिकित्सक से मिलें।';

  @override
  String get adviceLowBackPain =>
      'धीरे-धीरे चलते रहें, बिस्तर पर आराम और भारी सामान उठाने से बचें। यदि दर्द पैर तक फैले, या सुन्नपन, कमज़ोरी या पेशाब करने में परेशानी हो तो चिकित्सक से मिलें।';

  @override
  String get adviceLowRash =>
      'त्वचा को साफ़ और सूखा रखें और खुजलाने से बचें। यदि चकत्ते तेज़ी से फैलें, फफोले पड़ें, या बुखार या सांस फूलने के साथ हों तो चिकित्सक से मिलें।';

  @override
  String get adviceDefaultVisitFacility =>
      'कृपया चिकित्सक से मिलें ताकि आपके लक्षणों का सही आकलन हो सके।';

  @override
  String get adviceWhenToReturn =>
      'यदि हालत बिगड़े तो तुरंत वापस आएं या 108 पर कॉल करें।';

  @override
  String get followupDefault =>
      'मरीज़ कैसा कर रहा है यह जांचें और परिणाम दर्ज करें।';

  @override
  String get followupPostReferral =>
      'पुष्टि करें कि मरीज़ केंद्र पहुँचा, उसे देखा गया, और जो हुआ उसे दर्ज करें।';

  @override
  String get errorUnauthenticated => 'जारी रखने के लिए कृपया साइन इन करें।';

  @override
  String get errorSignInFailed =>
      'हम आपको साइन इन नहीं कर सके। कृपया विवरण जांचें और फिर से कोशिश करें।';

  @override
  String get errorSessionExpired =>
      'आपका सत्र समाप्त हो गया है। कृपया फिर से साइन इन करें।';

  @override
  String get errorForbidden => 'आपके पास इसकी पहुँच नहीं है।';

  @override
  String get errorNotPermitted => 'आपके पास यह करने की अनुमति नहीं है।';

  @override
  String get errorInvalidInput =>
      'कृपया जो दर्ज किया है उसे जांचें और फिर से कोशिश करें।';

  @override
  String get errorNotFound => 'हमें यह रिकॉर्ड नहीं मिला।';

  @override
  String get errorAlreadyExists => 'यह पहले से मौजूद है।';

  @override
  String get errorRelatedRecordMissing => 'इस पर निर्भर कुछ गायब है।';

  @override
  String get errorOffline =>
      'लगता है आप ऑफ़लाइन हैं। हम आपका काम सुरक्षित रखेंगे और फिर से कोशिश करेंगे।';

  @override
  String get errorUnexpected => 'कुछ गलत हो गया। कृपया फिर से कोशिश करें।';

  @override
  String get errorActionNotAllowed => 'यह कार्रवाई अभी अनुमत नहीं है।';

  @override
  String get errorReferralTransitionIllegal =>
      'यह रेफ़रल पहले ही आगे बढ़ चुका है। वर्तमान स्थिति देखने के लिए रीफ़्रेश करें।';

  @override
  String get errorReasonRequired => 'कृपया एक कारण दें।';

  @override
  String get errorOutcomeRequired => 'कृपया परिणाम दर्ज करें।';

  @override
  String get errorOverrideReasonRequired =>
      'मैनुअल ओवरराइड के लिए एक कारण आवश्यक है।';

  @override
  String get errorFacilityNotOperational =>
      'यह केंद्र वर्तमान में संचालित नहीं है।';

  @override
  String get errorTriageUnavailable =>
      'लक्षण आकलन अभी उपलब्ध नहीं है। कृपया अपनी आशा कार्यकर्ता से संपर्क करें या यदि यह तत्काल है तो 108 पर कॉल करें।';

  @override
  String get errorProfileMissing =>
      'आपका खाता अभी तक सेट नहीं है। कृपया अपने प्रशासक से संपर्क करें।';

  @override
  String get errorNoAudioCaptured =>
      'हमें कुछ भी सुनाई नहीं दिया। कृपया फिर से कोशिश करें।';

  @override
  String get errorTtsUnavailable =>
      'बोला गया आउटपुट उपलब्ध नहीं है। पाठ स्क्रीन पर दिखाया गया है।';

  @override
  String get errorAmbulanceRequestFailed =>
      'हम परिवहन का अनुरोध नहीं कर सके। कृपया सीधे 108 पर कॉल करें।';

  @override
  String get errorStorage => 'हम वह फ़ाइल अपलोड नहीं कर सके।';

  @override
  String get errorPatientDistrictUnknown =>
      'इस मरीज़ का कोई जिला दर्ज नहीं है, इसलिए परिवहन का अनुरोध नहीं किया जा सकता।';

  @override
  String get errorLocationDenied =>
      'आस-पास के केंद्र खोजने के लिए हमें आपके स्थान की आवश्यकता है। आप अपना गाँव भी चुन सकते हैं।';

  @override
  String get errorLocationUnavailable =>
      'हम आपका स्थान नहीं पा सके। कृपया इसके बजाय अपना गाँव चुनें।';
}
