import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'am_strings_en.dart';
import 'am_strings_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AmStrings
/// returned by `AmStrings.of(context)`.
///
/// Applications need to include `AmStrings.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/am_strings.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AmStrings.localizationsDelegates,
///   supportedLocales: AmStrings.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AmStrings.supportedLocales
/// property.
abstract class AmStrings {
  AmStrings(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AmStrings of(BuildContext context) {
    return Localizations.of<AmStrings>(context, AmStrings)!;
  }

  static const LocalizationsDelegate<AmStrings> delegate = _AmStringsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ta'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'ArogyaMitra'**
  String get appName;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionRetry;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get actionConfirm;

  /// No description provided for @actionSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get actionSubmit;

  /// No description provided for @actionYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get actionYes;

  /// No description provided for @actionNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get actionNo;

  /// No description provided for @actionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get actionSkip;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get actionRefresh;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show yet'**
  String get noResults;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// No description provided for @languageTamil.
  ///
  /// In en, this message translates to:
  /// **'தமிழ்'**
  String get languageTamil;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @staffSignIn.
  ///
  /// In en, this message translates to:
  /// **'Staff sign in'**
  String get staffSignIn;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get phoneNumber;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendOtp;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter the code we sent you'**
  String get enterOtp;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signInHelp.
  ///
  /// In en, this message translates to:
  /// **'We use your mobile number only to keep your care record safe.'**
  String get signInHelp;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String homeGreeting(String name);

  /// No description provided for @homeNeedCare.
  ///
  /// In en, this message translates to:
  /// **'I need care'**
  String get homeNeedCare;

  /// No description provided for @homeNeedCareHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us how you feel and we will find the right care'**
  String get homeNeedCareHint;

  /// No description provided for @homeEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency help'**
  String get homeEmergency;

  /// No description provided for @homeMyReferrals.
  ///
  /// In en, this message translates to:
  /// **'My referrals'**
  String get homeMyReferrals;

  /// No description provided for @homeNotifications.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get homeNotifications;

  /// No description provided for @homeFollowUps.
  ///
  /// In en, this message translates to:
  /// **'My follow-ups'**
  String get homeFollowUps;

  /// No description provided for @homeFeedback.
  ///
  /// In en, this message translates to:
  /// **'Give feedback'**
  String get homeFeedback;

  /// No description provided for @homeProfile.
  ///
  /// In en, this message translates to:
  /// **'My details'**
  String get homeProfile;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Your details'**
  String get profileTitle;

  /// No description provided for @profileWhy.
  ///
  /// In en, this message translates to:
  /// **'We ask this so triage can judge your risk correctly.'**
  String get profileWhy;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get profileName;

  /// No description provided for @profileAge.
  ///
  /// In en, this message translates to:
  /// **'Age in years'**
  String get profileAge;

  /// No description provided for @profileSex.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get profileSex;

  /// No description provided for @sexMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get sexMale;

  /// No description provided for @sexFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get sexFemale;

  /// No description provided for @sexOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get sexOther;

  /// No description provided for @sexUndisclosed.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get sexUndisclosed;

  /// No description provided for @profilePregnant.
  ///
  /// In en, this message translates to:
  /// **'Currently pregnant'**
  String get profilePregnant;

  /// No description provided for @profileChronic.
  ///
  /// In en, this message translates to:
  /// **'Long-term conditions'**
  String get profileChronic;

  /// No description provided for @chronicDiabetes.
  ///
  /// In en, this message translates to:
  /// **'Diabetes'**
  String get chronicDiabetes;

  /// No description provided for @chronicHypertension.
  ///
  /// In en, this message translates to:
  /// **'High blood pressure'**
  String get chronicHypertension;

  /// No description provided for @chronicHeartDisease.
  ///
  /// In en, this message translates to:
  /// **'Heart disease'**
  String get chronicHeartDisease;

  /// No description provided for @chronicAsthma.
  ///
  /// In en, this message translates to:
  /// **'Asthma'**
  String get chronicAsthma;

  /// No description provided for @chronicKidneyDisease.
  ///
  /// In en, this message translates to:
  /// **'Kidney disease'**
  String get chronicKidneyDisease;

  /// No description provided for @chronicTuberculosis.
  ///
  /// In en, this message translates to:
  /// **'Tuberculosis'**
  String get chronicTuberculosis;

  /// No description provided for @symptomsTitle.
  ///
  /// In en, this message translates to:
  /// **'What is troubling you?'**
  String get symptomsTitle;

  /// No description provided for @symptomsHint.
  ///
  /// In en, this message translates to:
  /// **'Choose everything that applies'**
  String get symptomsHint;

  /// No description provided for @symptomsSearch.
  ///
  /// In en, this message translates to:
  /// **'Search symptoms'**
  String get symptomsSearch;

  /// No description provided for @symptomsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String symptomsSelected(int count);

  /// No description provided for @symptomsCommon.
  ///
  /// In en, this message translates to:
  /// **'Common'**
  String get symptomsCommon;

  /// No description provided for @symptomsAll.
  ///
  /// In en, this message translates to:
  /// **'All symptoms'**
  String get symptomsAll;

  /// No description provided for @symptomsNoneSelected.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one symptom to continue'**
  String get symptomsNoneSelected;

  /// No description provided for @symptomsVoiceInput.
  ///
  /// In en, this message translates to:
  /// **'Speak instead'**
  String get symptomsVoiceInput;

  /// No description provided for @symptomsListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get symptomsListening;

  /// No description provided for @symptomsVoiceConfirm.
  ///
  /// In en, this message translates to:
  /// **'We heard this. Please confirm before we continue.'**
  String get symptomsVoiceConfirm;

  /// No description provided for @severityTitle.
  ///
  /// In en, this message translates to:
  /// **'How bad is it right now?'**
  String get severityTitle;

  /// No description provided for @severityHint.
  ///
  /// In en, this message translates to:
  /// **'This decides how urgently you are seen, so please be honest.'**
  String get severityHint;

  /// No description provided for @severity1.
  ///
  /// In en, this message translates to:
  /// **'Very mild'**
  String get severity1;

  /// No description provided for @severity2.
  ///
  /// In en, this message translates to:
  /// **'Mild'**
  String get severity2;

  /// No description provided for @severity3.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get severity3;

  /// No description provided for @severity4.
  ///
  /// In en, this message translates to:
  /// **'Severe'**
  String get severity4;

  /// No description provided for @severity5.
  ///
  /// In en, this message translates to:
  /// **'Very severe'**
  String get severity5;

  /// No description provided for @durationTitle.
  ///
  /// In en, this message translates to:
  /// **'How long has this been going on?'**
  String get durationTitle;

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'{count} hours'**
  String durationHours(int count);

  /// No description provided for @durationLessThanDay.
  ///
  /// In en, this message translates to:
  /// **'Less than a day'**
  String get durationLessThanDay;

  /// No description provided for @durationOneToThreeDays.
  ///
  /// In en, this message translates to:
  /// **'1 to 3 days'**
  String get durationOneToThreeDays;

  /// No description provided for @durationUpToWeek.
  ///
  /// In en, this message translates to:
  /// **'3 days to a week'**
  String get durationUpToWeek;

  /// No description provided for @durationOverTwoWeeks.
  ///
  /// In en, this message translates to:
  /// **'More than two weeks'**
  String get durationOverTwoWeeks;

  /// No description provided for @triageRunning.
  ///
  /// In en, this message translates to:
  /// **'Checking your symptoms'**
  String get triageRunning;

  /// No description provided for @triageResultTitle.
  ///
  /// In en, this message translates to:
  /// **'What you should do'**
  String get triageResultTitle;

  /// No description provided for @riskLow.
  ///
  /// In en, this message translates to:
  /// **'Low risk'**
  String get riskLow;

  /// No description provided for @riskMedium.
  ///
  /// In en, this message translates to:
  /// **'Needs a check-up'**
  String get riskMedium;

  /// No description provided for @riskHigh.
  ///
  /// In en, this message translates to:
  /// **'Needs care today'**
  String get riskHigh;

  /// No description provided for @riskEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get riskEmergency;

  /// No description provided for @nextActionSelfCare.
  ///
  /// In en, this message translates to:
  /// **'Care at home'**
  String get nextActionSelfCare;

  /// No description provided for @nextActionVisitFacility.
  ///
  /// In en, this message translates to:
  /// **'Visit a health facility'**
  String get nextActionVisitFacility;

  /// No description provided for @nextActionTeleconsult.
  ///
  /// In en, this message translates to:
  /// **'Talk to a doctor online'**
  String get nextActionTeleconsult;

  /// No description provided for @nextActionRefer.
  ///
  /// In en, this message translates to:
  /// **'Get referred to a facility'**
  String get nextActionRefer;

  /// No description provided for @nextActionEmergencyResponse.
  ///
  /// In en, this message translates to:
  /// **'Get emergency help now'**
  String get nextActionEmergencyResponse;

  /// No description provided for @triageRedFlagsTitle.
  ///
  /// In en, this message translates to:
  /// **'Warning signs we found'**
  String get triageRedFlagsTitle;

  /// No description provided for @triageAssessedBy.
  ///
  /// In en, this message translates to:
  /// **'Assessed using clinical rule set v{version}'**
  String triageAssessedBy(int version);

  /// No description provided for @triageFallbackWarning.
  ///
  /// In en, this message translates to:
  /// **'We could not match your symptoms exactly, so we are asking you to see a clinician to be safe.'**
  String get triageFallbackWarning;

  /// No description provided for @triageNotDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'This is guidance on where to go. It is not a diagnosis.'**
  String get triageNotDiagnosis;

  /// No description provided for @triageCallEmergency.
  ///
  /// In en, this message translates to:
  /// **'Call 108 now'**
  String get triageCallEmergency;

  /// No description provided for @triageFindFacility.
  ///
  /// In en, this message translates to:
  /// **'Find a facility'**
  String get triageFindFacility;

  /// No description provided for @facilitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Where to go'**
  String get facilitiesTitle;

  /// No description provided for @facilitiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ranked by travel time, available services and current readiness'**
  String get facilitiesSubtitle;

  /// No description provided for @facilitiesSearching.
  ///
  /// In en, this message translates to:
  /// **'Finding facilities near you'**
  String get facilitiesSearching;

  /// No description provided for @facilitiesNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No suitable facility found within range. Please call 108 or your ASHA worker.'**
  String get facilitiesNoneFound;

  /// No description provided for @facilityDistance.
  ///
  /// In en, this message translates to:
  /// **'{km} km away'**
  String facilityDistance(String km);

  /// No description provided for @facilityTravelTime.
  ///
  /// In en, this message translates to:
  /// **'about {minutes} min'**
  String facilityTravelTime(int minutes);

  /// No description provided for @facilityReadiness.
  ///
  /// In en, this message translates to:
  /// **'Readiness {percent}%'**
  String facilityReadiness(int percent);

  /// No description provided for @facilityOpen24x7.
  ///
  /// In en, this message translates to:
  /// **'Open 24 hours'**
  String get facilityOpen24x7;

  /// No description provided for @facilityHasEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency department'**
  String get facilityHasEmergency;

  /// No description provided for @readinessDoctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get readinessDoctor;

  /// No description provided for @readinessMedicines.
  ///
  /// In en, this message translates to:
  /// **'Medicines'**
  String get readinessMedicines;

  /// No description provided for @readinessDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Tests'**
  String get readinessDiagnostics;

  /// No description provided for @readinessBeds.
  ///
  /// In en, this message translates to:
  /// **'Beds'**
  String get readinessBeds;

  /// No description provided for @availabilityAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availabilityAvailable;

  /// No description provided for @availabilityLimited.
  ///
  /// In en, this message translates to:
  /// **'Limited'**
  String get availabilityLimited;

  /// No description provided for @availabilityUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get availabilityUnavailable;

  /// No description provided for @availabilityUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not reported'**
  String get availabilityUnknown;

  /// No description provided for @readinessStaleWarning.
  ///
  /// In en, this message translates to:
  /// **'This facility last updated {hours} hours ago. Please call before travelling.'**
  String readinessStaleWarning(int hours);

  /// No description provided for @readinessNotReported.
  ///
  /// In en, this message translates to:
  /// **'This facility has not reported its status. Please call before travelling.'**
  String get readinessNotReported;

  /// No description provided for @facilityServiceGap.
  ///
  /// In en, this message translates to:
  /// **'This facility may not offer everything you need. Call ahead if you can.'**
  String get facilityServiceGap;

  /// No description provided for @facilityChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose this facility'**
  String get facilityChoose;

  /// No description provided for @facilityDirections.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get facilityDirections;

  /// No description provided for @facilityCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get facilityCall;

  /// No description provided for @facilityWhyRanked.
  ///
  /// In en, this message translates to:
  /// **'Why this order?'**
  String get facilityWhyRanked;

  /// No description provided for @facilityScoreBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Travel {travel}%, services {services}%, wait {wait}%, data confidence {confidence}%'**
  String facilityScoreBreakdown(
    int travel,
    int services,
    int wait,
    int confidence,
  );

  /// No description provided for @referralCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Referral created'**
  String get referralCreatedTitle;

  /// No description provided for @referralReference.
  ///
  /// In en, this message translates to:
  /// **'Reference {code}'**
  String referralReference(String code);

  /// No description provided for @referralShowAtFacility.
  ///
  /// In en, this message translates to:
  /// **'Show this reference at the facility'**
  String get referralShowAtFacility;

  /// No description provided for @referralsTitle.
  ///
  /// In en, this message translates to:
  /// **'My referrals'**
  String get referralsTitle;

  /// No description provided for @referralsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have no referrals yet'**
  String get referralsEmpty;

  /// No description provided for @referralStatusCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get referralStatusCreated;

  /// No description provided for @referralStatusTriaged.
  ///
  /// In en, this message translates to:
  /// **'Symptoms assessed'**
  String get referralStatusTriaged;

  /// No description provided for @referralStatusRecommended.
  ///
  /// In en, this message translates to:
  /// **'Facility suggested'**
  String get referralStatusRecommended;

  /// No description provided for @referralStatusReferralSent.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the facility'**
  String get referralStatusReferralSent;

  /// No description provided for @referralStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Facility accepted'**
  String get referralStatusAccepted;

  /// No description provided for @referralStatusPatientTravelling.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get referralStatusPatientTravelling;

  /// No description provided for @referralStatusArrived.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get referralStatusArrived;

  /// No description provided for @referralStatusConsultation.
  ///
  /// In en, this message translates to:
  /// **'With the doctor'**
  String get referralStatusConsultation;

  /// No description provided for @referralStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get referralStatusCompleted;

  /// No description provided for @referralStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Not accepted'**
  String get referralStatusRejected;

  /// No description provided for @referralStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get referralStatusCancelled;

  /// No description provided for @referralStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get referralStatusExpired;

  /// No description provided for @referralStatusNoShow.
  ///
  /// In en, this message translates to:
  /// **'Did not attend'**
  String get referralStatusNoShow;

  /// No description provided for @referralStatusEmergencyEscalated.
  ///
  /// In en, this message translates to:
  /// **'Emergency help arranged'**
  String get referralStatusEmergencyEscalated;

  /// No description provided for @referralTimeline.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get referralTimeline;

  /// No description provided for @referralAwaitingFacility.
  ///
  /// In en, this message translates to:
  /// **'The facility has {minutes} minutes to respond'**
  String referralAwaitingFacility(int minutes);

  /// No description provided for @referralOverdue.
  ///
  /// In en, this message translates to:
  /// **'The facility has not responded in time. This has been flagged.'**
  String get referralOverdue;

  /// No description provided for @referralRejectedNext.
  ///
  /// In en, this message translates to:
  /// **'This facility could not take you. Choose another.'**
  String get referralRejectedNext;

  /// No description provided for @referralChooseAnother.
  ///
  /// In en, this message translates to:
  /// **'Choose another facility'**
  String get referralChooseAnother;

  /// No description provided for @referralImOnMyWay.
  ///
  /// In en, this message translates to:
  /// **'I am on my way'**
  String get referralImOnMyWay;

  /// No description provided for @referralCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel referral'**
  String get referralCancel;

  /// No description provided for @referralCancelReason.
  ///
  /// In en, this message translates to:
  /// **'Why are you cancelling?'**
  String get referralCancelReason;

  /// No description provided for @referralPriorityRoutine.
  ///
  /// In en, this message translates to:
  /// **'Routine'**
  String get referralPriorityRoutine;

  /// No description provided for @referralPriorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get referralPriorityUrgent;

  /// No description provided for @referralPriorityEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get referralPriorityEmergency;

  /// No description provided for @referralAutomatedEvent.
  ///
  /// In en, this message translates to:
  /// **'Updated automatically by the system'**
  String get referralAutomatedEvent;

  /// No description provided for @ambulanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency transport'**
  String get ambulanceTitle;

  /// No description provided for @ambulanceRequest.
  ///
  /// In en, this message translates to:
  /// **'Request an ambulance'**
  String get ambulanceRequest;

  /// No description provided for @ambulanceRequesting.
  ///
  /// In en, this message translates to:
  /// **'Requesting transport'**
  String get ambulanceRequesting;

  /// No description provided for @ambulanceEta.
  ///
  /// In en, this message translates to:
  /// **'Arriving in about {minutes} min'**
  String ambulanceEta(int minutes);

  /// No description provided for @ambulanceVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle {number}'**
  String ambulanceVehicle(String number);

  /// No description provided for @ambulanceStayPut.
  ///
  /// In en, this message translates to:
  /// **'Stay where you are and keep your phone nearby.'**
  String get ambulanceStayPut;

  /// No description provided for @ambulanceMockNotice.
  ///
  /// In en, this message translates to:
  /// **'Demonstration mode: no real ambulance has been dispatched.'**
  String get ambulanceMockNotice;

  /// No description provided for @feedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'How was your care?'**
  String get feedbackTitle;

  /// No description provided for @feedbackRating.
  ///
  /// In en, this message translates to:
  /// **'Your rating'**
  String get feedbackRating;

  /// No description provided for @feedbackCategory.
  ///
  /// In en, this message translates to:
  /// **'What is this about?'**
  String get feedbackCategory;

  /// No description provided for @feedbackComment.
  ///
  /// In en, this message translates to:
  /// **'Anything else you want to tell us?'**
  String get feedbackComment;

  /// No description provided for @feedbackThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you. Your feedback has been recorded.'**
  String get feedbackThanks;

  /// No description provided for @feedbackWouldRecommend.
  ///
  /// In en, this message translates to:
  /// **'Would you recommend this facility?'**
  String get feedbackWouldRecommend;

  /// No description provided for @feedbackCategoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get feedbackCategoryGeneral;

  /// No description provided for @feedbackCategoryWaitingTime.
  ///
  /// In en, this message translates to:
  /// **'Waiting time'**
  String get feedbackCategoryWaitingTime;

  /// No description provided for @feedbackCategoryStaffBehaviour.
  ///
  /// In en, this message translates to:
  /// **'Staff behaviour'**
  String get feedbackCategoryStaffBehaviour;

  /// No description provided for @feedbackCategoryMedicineUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Medicines not available'**
  String get feedbackCategoryMedicineUnavailable;

  /// No description provided for @feedbackCategoryDiagnosticUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Tests not available'**
  String get feedbackCategoryDiagnosticUnavailable;

  /// No description provided for @feedbackCategoryCleanliness.
  ///
  /// In en, this message translates to:
  /// **'Cleanliness'**
  String get feedbackCategoryCleanliness;

  /// No description provided for @feedbackCategoryCost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get feedbackCategoryCost;

  /// No description provided for @feedbackCategoryReferralProcess.
  ///
  /// In en, this message translates to:
  /// **'Referral process'**
  String get feedbackCategoryReferralProcess;

  /// No description provided for @feedbackCategoryAmbulance.
  ///
  /// In en, this message translates to:
  /// **'Ambulance'**
  String get feedbackCategoryAmbulance;

  /// No description provided for @feedbackCategoryTeleconsult.
  ///
  /// In en, this message translates to:
  /// **'Online consultation'**
  String get feedbackCategoryTeleconsult;

  /// No description provided for @feedbackCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get feedbackCategoryOther;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get notificationsEmpty;

  /// No description provided for @notificationsUnread.
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String notificationsUnread(int count);

  /// No description provided for @followUpsTitle.
  ///
  /// In en, this message translates to:
  /// **'Follow-ups'**
  String get followUpsTitle;

  /// No description provided for @followUpsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing due'**
  String get followUpsEmpty;

  /// No description provided for @followUpDueOn.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String followUpDueOn(String date);

  /// No description provided for @followUpOverdue.
  ///
  /// In en, this message translates to:
  /// **'{days} days overdue'**
  String followUpOverdue(int days);

  /// No description provided for @followUpComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark done'**
  String get followUpComplete;

  /// No description provided for @followUpOutcome.
  ///
  /// In en, this message translates to:
  /// **'What happened?'**
  String get followUpOutcome;

  /// No description provided for @consoleQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Incoming referrals'**
  String get consoleQueueTitle;

  /// No description provided for @consoleQueueEmpty.
  ///
  /// In en, this message translates to:
  /// **'No referrals waiting'**
  String get consoleQueueEmpty;

  /// No description provided for @consoleAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get consoleAccept;

  /// No description provided for @consoleReject.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get consoleReject;

  /// No description provided for @consoleRejectReason.
  ///
  /// In en, this message translates to:
  /// **'Reason for declining'**
  String get consoleRejectReason;

  /// No description provided for @consoleRejectReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'A reason is required so the citizen can be re-routed.'**
  String get consoleRejectReasonRequired;

  /// No description provided for @consoleMarkArrived.
  ///
  /// In en, this message translates to:
  /// **'Patient arrived'**
  String get consoleMarkArrived;

  /// No description provided for @consoleStartConsultation.
  ///
  /// In en, this message translates to:
  /// **'Start consultation'**
  String get consoleStartConsultation;

  /// No description provided for @consoleComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get consoleComplete;

  /// No description provided for @consoleCompleteOutcome.
  ///
  /// In en, this message translates to:
  /// **'Outcome'**
  String get consoleCompleteOutcome;

  /// No description provided for @consoleNoShow.
  ///
  /// In en, this message translates to:
  /// **'Did not attend'**
  String get consoleNoShow;

  /// No description provided for @consoleReadinessTitle.
  ///
  /// In en, this message translates to:
  /// **'Facility readiness'**
  String get consoleReadinessTitle;

  /// No description provided for @consoleReadinessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What you publish here decides where citizens are sent.'**
  String get consoleReadinessSubtitle;

  /// No description provided for @consoleUpdateResource.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get consoleUpdateResource;

  /// No description provided for @consoleOverride.
  ///
  /// In en, this message translates to:
  /// **'Manual override'**
  String get consoleOverride;

  /// No description provided for @consoleOverrideReason.
  ///
  /// In en, this message translates to:
  /// **'Reason for the override'**
  String get consoleOverrideReason;

  /// No description provided for @consoleLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {ago}'**
  String consoleLastUpdated(String ago);

  /// No description provided for @consoleSlaRemaining.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min to respond'**
  String consoleSlaRemaining(int minutes);

  /// No description provided for @consoleSlaBreached.
  ///
  /// In en, this message translates to:
  /// **'Response overdue'**
  String get consoleSlaBreached;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'District dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardReadiness.
  ///
  /// In en, this message translates to:
  /// **'Facility readiness'**
  String get dashboardReadiness;

  /// No description provided for @dashboardAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get dashboardAlerts;

  /// No description provided for @dashboardReferrals.
  ///
  /// In en, this message translates to:
  /// **'Referrals'**
  String get dashboardReferrals;

  /// No description provided for @dashboardFeedback.
  ///
  /// In en, this message translates to:
  /// **'Citizen feedback'**
  String get dashboardFeedback;

  /// No description provided for @dashboardFollowUps.
  ///
  /// In en, this message translates to:
  /// **'Follow-up compliance'**
  String get dashboardFollowUps;

  /// No description provided for @dashboardAlertsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No open alerts'**
  String get dashboardAlertsEmpty;

  /// No description provided for @dashboardMetricCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get dashboardMetricCreated;

  /// No description provided for @dashboardMetricAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get dashboardMetricAccepted;

  /// No description provided for @dashboardMetricCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get dashboardMetricCompleted;

  /// No description provided for @dashboardMetricBreaches.
  ///
  /// In en, this message translates to:
  /// **'SLA breaches'**
  String get dashboardMetricBreaches;

  /// No description provided for @dashboardAcceptanceRate.
  ///
  /// In en, this message translates to:
  /// **'Acceptance rate'**
  String get dashboardAcceptanceRate;

  /// No description provided for @dashboardCompletionRate.
  ///
  /// In en, this message translates to:
  /// **'Completion rate'**
  String get dashboardCompletionRate;

  /// No description provided for @dashboardMedianTurnaround.
  ///
  /// In en, this message translates to:
  /// **'Median turnaround'**
  String get dashboardMedianTurnaround;

  /// No description provided for @dashboardMinutes.
  ///
  /// In en, this message translates to:
  /// **'{value} min'**
  String dashboardMinutes(String value);

  /// No description provided for @readinessBandGood.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get readinessBandGood;

  /// No description provided for @readinessBandPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get readinessBandPartial;

  /// No description provided for @readinessBandCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get readinessBandCritical;

  /// No description provided for @readinessBandStale.
  ///
  /// In en, this message translates to:
  /// **'Not reported'**
  String get readinessBandStale;

  /// No description provided for @alertReferralSlaBreach.
  ///
  /// In en, this message translates to:
  /// **'Referral response overdue'**
  String get alertReferralSlaBreach;

  /// No description provided for @alertReadinessCritical.
  ///
  /// In en, this message translates to:
  /// **'Facility readiness critical'**
  String get alertReadinessCritical;

  /// No description provided for @alertFeedbackIssue.
  ///
  /// In en, this message translates to:
  /// **'Citizen issue reported'**
  String get alertFeedbackIssue;

  /// No description provided for @adviceEmergencyUnresponsive.
  ///
  /// In en, this message translates to:
  /// **'This is a medical emergency. Call 108 immediately. Do not give anything by mouth. Turn the person on their side and stay with them.'**
  String get adviceEmergencyUnresponsive;

  /// No description provided for @adviceEmergencyBleeding.
  ///
  /// In en, this message translates to:
  /// **'Press firmly on the wound with a clean cloth and keep pressing. Call 108 immediately.'**
  String get adviceEmergencyBleeding;

  /// No description provided for @adviceEmergencyPoisoning.
  ///
  /// In en, this message translates to:
  /// **'Call 108 immediately. Do not try to make the person vomit. Take the container or label with you.'**
  String get adviceEmergencyPoisoning;

  /// No description provided for @adviceEmergencySnakebite.
  ///
  /// In en, this message translates to:
  /// **'Call 108 immediately. Keep the bitten limb still and below heart level. Do not cut, suck or tie the wound. Anti-snake venom is needed urgently.'**
  String get adviceEmergencySnakebite;

  /// No description provided for @adviceEmergencyStroke.
  ///
  /// In en, this message translates to:
  /// **'Call 108 immediately. Note the time symptoms started, as treatment depends on it. Do not give food or water.'**
  String get adviceEmergencyStroke;

  /// No description provided for @adviceEmergencyChestPain.
  ///
  /// In en, this message translates to:
  /// **'Call 108 immediately. Sit and rest, do not walk or drive yourself. This needs an ECG straight away.'**
  String get adviceEmergencyChestPain;

  /// No description provided for @adviceEmergencyBreathlessness.
  ///
  /// In en, this message translates to:
  /// **'Call 108 immediately. Sit upright and loosen tight clothing. Oxygen may be needed.'**
  String get adviceEmergencyBreathlessness;

  /// No description provided for @adviceEmergencyObstetricBleeding.
  ///
  /// In en, this message translates to:
  /// **'Call 108 immediately. Lie down on your left side. Bleeding in pregnancy needs urgent care.'**
  String get adviceEmergencyObstetricBleeding;

  /// No description provided for @adviceEmergencyLabour.
  ///
  /// In en, this message translates to:
  /// **'Go to a facility with delivery services now. Call 108 for transport if needed.'**
  String get adviceEmergencyLabour;

  /// No description provided for @adviceEmergencyFetalMovement.
  ///
  /// In en, this message translates to:
  /// **'Go to a facility with obstetric care now. Reduced baby movement needs to be checked urgently.'**
  String get adviceEmergencyFetalMovement;

  /// No description provided for @adviceEmergencySickChild.
  ///
  /// In en, this message translates to:
  /// **'Take the child to a facility with paediatric care immediately. Call 108 for transport. Keep the child warm and keep offering fluids if they can swallow.'**
  String get adviceEmergencySickChild;

  /// No description provided for @adviceEmergencyTrauma.
  ///
  /// In en, this message translates to:
  /// **'Call 108 immediately. Do not move the injured person unless they are in danger.'**
  String get adviceEmergencyTrauma;

  /// No description provided for @adviceEmergencyBurn.
  ///
  /// In en, this message translates to:
  /// **'Cool the burn under clean running water for 20 minutes. Do not apply oil, toothpaste or ice. Call 108.'**
  String get adviceEmergencyBurn;

  /// No description provided for @adviceEmergencyAnuria.
  ///
  /// In en, this message translates to:
  /// **'Call 108 immediately. Passing almost no urine can mean the kidneys are failing.'**
  String get adviceEmergencyAnuria;

  /// No description provided for @adviceHighAnimalBite.
  ///
  /// In en, this message translates to:
  /// **'Wash the wound with soap under running water for 15 minutes and go to a facility today. You need rabies vaccination.'**
  String get adviceHighAnimalBite;

  /// No description provided for @adviceHighHaemoptysis.
  ///
  /// In en, this message translates to:
  /// **'See a doctor today. You need a chest X-ray and a sputum test to rule out tuberculosis.'**
  String get adviceHighHaemoptysis;

  /// No description provided for @adviceHighTbSuspect.
  ///
  /// In en, this message translates to:
  /// **'A cough this long with weight loss or night sweats needs a TB test today. Treatment is free.'**
  String get adviceHighTbSuspect;

  /// No description provided for @adviceHighJaundice.
  ///
  /// In en, this message translates to:
  /// **'See a doctor today. Yellow eyes or skin needs blood tests to find the cause.'**
  String get adviceHighJaundice;

  /// No description provided for @adviceHighBreathlessness.
  ///
  /// In en, this message translates to:
  /// **'See a doctor today. Go back or call 108 straight away if breathing gets worse.'**
  String get adviceHighBreathlessness;

  /// No description provided for @adviceHighChestPainYoung.
  ///
  /// In en, this message translates to:
  /// **'See a doctor today and ask for an ECG. Call 108 if the pain worsens, spreads to your arm or jaw, or you start sweating.'**
  String get adviceHighChestPainYoung;

  /// No description provided for @adviceHighPersistentFever.
  ///
  /// In en, this message translates to:
  /// **'Fever this high for this long needs blood tests today to check for dengue, malaria or typhoid.'**
  String get adviceHighPersistentFever;

  /// No description provided for @adviceHighPregnancy.
  ///
  /// In en, this message translates to:
  /// **'Any new symptom in pregnancy should be checked the same day at a facility with obstetric care.'**
  String get adviceHighPregnancy;

  /// No description provided for @adviceHighDiabetesFever.
  ///
  /// In en, this message translates to:
  /// **'With diabetes, an infection can worsen quickly. See a doctor today.'**
  String get adviceHighDiabetesFever;

  /// No description provided for @adviceHighCardiacHistory.
  ///
  /// In en, this message translates to:
  /// **'With your heart history, these symptoms need an ECG today.'**
  String get adviceHighCardiacHistory;

  /// No description provided for @adviceMediumDehydration.
  ///
  /// In en, this message translates to:
  /// **'Drink ORS after every loose stool. Go to a facility today, and sooner if you cannot keep fluids down or pass very little urine.'**
  String get adviceMediumDehydration;

  /// No description provided for @adviceMediumAbdominalPain.
  ///
  /// In en, this message translates to:
  /// **'See a clinician today. Do not take painkillers on an empty stomach. Go straight away if the pain becomes severe or your abdomen feels hard.'**
  String get adviceMediumAbdominalPain;

  /// No description provided for @adviceMediumFebrileIllness.
  ///
  /// In en, this message translates to:
  /// **'See a clinician today for a check-up and blood tests if needed. Drink plenty of fluids and rest.'**
  String get adviceMediumFebrileIllness;

  /// No description provided for @adviceMediumUti.
  ///
  /// In en, this message translates to:
  /// **'See a clinician today. A urine test is needed. Drink plenty of water in the meantime.'**
  String get adviceMediumUti;

  /// No description provided for @adviceMediumJointPain.
  ///
  /// In en, this message translates to:
  /// **'See a clinician for an assessment. Rest the joint and avoid heavy lifting.'**
  String get adviceMediumJointPain;

  /// No description provided for @adviceMediumMentalHealth.
  ///
  /// In en, this message translates to:
  /// **'Talking to a counsellor or doctor helps. You can do this by online consultation, and it is confidential.'**
  String get adviceMediumMentalHealth;

  /// No description provided for @adviceMediumVision.
  ///
  /// In en, this message translates to:
  /// **'Get your eyes checked. Go sooner if vision loss is sudden or you have eye pain.'**
  String get adviceMediumVision;

  /// No description provided for @adviceMediumMinorBurn.
  ///
  /// In en, this message translates to:
  /// **'Cool under running water for 20 minutes, cover loosely with a clean cloth, and get it dressed at a facility.'**
  String get adviceMediumMinorBurn;

  /// No description provided for @adviceMediumMinorInjury.
  ///
  /// In en, this message translates to:
  /// **'Get the injury cleaned and checked. An X-ray may be needed if there is swelling or you cannot move it.'**
  String get adviceMediumMinorInjury;

  /// No description provided for @adviceMediumDental.
  ///
  /// In en, this message translates to:
  /// **'See a dentist or the facility doctor. Rinse with warm salt water and avoid very hot or cold food.'**
  String get adviceMediumDental;

  /// No description provided for @adviceLowMildFever.
  ///
  /// In en, this message translates to:
  /// **'Rest, drink plenty of fluids and use paracetamol as directed. See a clinician if the fever lasts more than three days, goes above 39C, or you develop breathlessness, a rash or vomiting.'**
  String get adviceLowMildFever;

  /// No description provided for @adviceLowMildCough.
  ///
  /// In en, this message translates to:
  /// **'Warm fluids and steam inhalation help. See a clinician if the cough lasts more than two weeks, or you get fever, blood in your sputum or breathlessness.'**
  String get adviceLowMildCough;

  /// No description provided for @adviceLowMildHeadache.
  ///
  /// In en, this message translates to:
  /// **'Rest in a quiet, dark room, drink water and eat regularly. See a clinician if the headache is sudden and severe, or comes with fever, vomiting, weakness or vision changes.'**
  String get adviceLowMildHeadache;

  /// No description provided for @adviceLowSoreThroat.
  ///
  /// In en, this message translates to:
  /// **'Warm salt water gargles and warm fluids help. See a clinician if you have difficulty swallowing or breathing, or a fever lasting more than three days.'**
  String get adviceLowSoreThroat;

  /// No description provided for @adviceLowBackPain.
  ///
  /// In en, this message translates to:
  /// **'Keep moving gently, avoid bed rest and avoid heavy lifting. See a clinician if the pain spreads down your leg, or you have numbness, weakness or trouble passing urine.'**
  String get adviceLowBackPain;

  /// No description provided for @adviceLowRash.
  ///
  /// In en, this message translates to:
  /// **'Keep the skin clean and dry and avoid scratching. See a clinician if the rash spreads quickly, blisters, or comes with fever or breathlessness.'**
  String get adviceLowRash;

  /// No description provided for @adviceDefaultVisitFacility.
  ///
  /// In en, this message translates to:
  /// **'Please see a clinician so your symptoms can be assessed properly.'**
  String get adviceDefaultVisitFacility;

  /// No description provided for @adviceWhenToReturn.
  ///
  /// In en, this message translates to:
  /// **'Come back or call 108 straight away if you get worse.'**
  String get adviceWhenToReturn;

  /// No description provided for @followupDefault.
  ///
  /// In en, this message translates to:
  /// **'Check how the patient is doing and record the outcome.'**
  String get followupDefault;

  /// No description provided for @followupPostReferral.
  ///
  /// In en, this message translates to:
  /// **'Confirm the patient reached the facility, was seen, and record what happened.'**
  String get followupPostReferral;

  /// No description provided for @errorUnauthenticated.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to continue.'**
  String get errorUnauthenticated;

  /// No description provided for @errorSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not sign you in. Please check the details and try again.'**
  String get errorSignInFailed;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get errorSessionExpired;

  /// No description provided for @errorForbidden.
  ///
  /// In en, this message translates to:
  /// **'You do not have access to this.'**
  String get errorForbidden;

  /// No description provided for @errorNotPermitted.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to do this.'**
  String get errorNotPermitted;

  /// No description provided for @errorInvalidInput.
  ///
  /// In en, this message translates to:
  /// **'Please check what you entered and try again.'**
  String get errorInvalidInput;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'We could not find this record.'**
  String get errorNotFound;

  /// No description provided for @errorAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'This already exists.'**
  String get errorAlreadyExists;

  /// No description provided for @errorRelatedRecordMissing.
  ///
  /// In en, this message translates to:
  /// **'Something this depends on is missing.'**
  String get errorRelatedRecordMissing;

  /// No description provided for @errorOffline.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline. We will keep your work and try again.'**
  String get errorOffline;

  /// No description provided for @errorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnexpected;

  /// No description provided for @errorActionNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This action is not allowed right now.'**
  String get errorActionNotAllowed;

  /// No description provided for @errorReferralTransitionIllegal.
  ///
  /// In en, this message translates to:
  /// **'This referral has already moved on. Refresh to see its current state.'**
  String get errorReferralTransitionIllegal;

  /// No description provided for @errorReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Please give a reason.'**
  String get errorReasonRequired;

  /// No description provided for @errorOutcomeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please record the outcome.'**
  String get errorOutcomeRequired;

  /// No description provided for @errorOverrideReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'A manual override needs a reason.'**
  String get errorOverrideReasonRequired;

  /// No description provided for @errorFacilityNotOperational.
  ///
  /// In en, this message translates to:
  /// **'This facility is not currently operating.'**
  String get errorFacilityNotOperational;

  /// No description provided for @errorTriageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Symptom assessment is unavailable right now. Please contact your ASHA worker or call 108 if this is urgent.'**
  String get errorTriageUnavailable;

  /// No description provided for @errorProfileMissing.
  ///
  /// In en, this message translates to:
  /// **'Your account is not set up yet. Please contact your administrator.'**
  String get errorProfileMissing;

  /// No description provided for @errorNoAudioCaptured.
  ///
  /// In en, this message translates to:
  /// **'We did not hear anything. Please try again.'**
  String get errorNoAudioCaptured;

  /// No description provided for @errorTtsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Spoken output is unavailable. The text is shown on screen.'**
  String get errorTtsUnavailable;

  /// No description provided for @errorAmbulanceRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not request transport. Please call 108 directly.'**
  String get errorAmbulanceRequestFailed;

  /// No description provided for @errorStorage.
  ///
  /// In en, this message translates to:
  /// **'We could not upload that file.'**
  String get errorStorage;

  /// No description provided for @errorPatientDistrictUnknown.
  ///
  /// In en, this message translates to:
  /// **'This patient has no district recorded, so transport cannot be requested.'**
  String get errorPatientDistrictUnknown;

  /// No description provided for @errorLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'We need your location to find nearby facilities. You can also pick your village instead.'**
  String get errorLocationDenied;

  /// No description provided for @errorLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'We could not get your location. Please pick your village instead.'**
  String get errorLocationUnavailable;
}

class _AmStringsDelegate extends LocalizationsDelegate<AmStrings> {
  const _AmStringsDelegate();

  @override
  Future<AmStrings> load(Locale locale) {
    return SynchronousFuture<AmStrings>(lookupAmStrings(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AmStringsDelegate old) => false;
}

AmStrings lookupAmStrings(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AmStringsEn();
    case 'ta':
      return AmStringsTa();
  }

  throw FlutterError(
    'AmStrings.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
