import 'package:meta/meta.dart';

import 'enums.dart';

/// A structured symptom the citizen or worker can select (PRD 6 FR-004).
///
/// Free text is deliberately not part of the triage input: the rule engine
/// matches codes, and an unmatched code is rejected server side rather than
/// silently dropped.
@immutable
class Symptom {
  const Symptom({
    required this.code,
    required this.nameEn,
    required this.nameTa,
    required this.bodySystem,
    required this.isCommon,
    required this.displayOrder,
    this.iconKey,
  });

  factory Symptom.fromJson(Map<String, Object?> json) => Symptom(
        code: json['code']! as String,
        nameEn: json['name_en']! as String,
        nameTa: json['name_ta']! as String,
        bodySystem: json['body_system']! as String,
        isCommon: json['is_common'] as bool? ?? false,
        displayOrder: (json['display_order'] as num?)?.toInt() ?? 100,
        iconKey: json['icon_key'] as String?,
      );

  final String code;
  final String nameEn;
  final String nameTa;
  final String bodySystem;

  /// Shown in the quick-pick grid for low-literacy users (PRD 17).
  final bool isCommon;
  final int displayOrder;
  final String? iconKey;

  String label(LanguageCode language) =>
      language == LanguageCode.tamil ? nameTa : nameEn;
}

/// Input for `run_triage`.
@immutable
class TriageRequest {
  const TriageRequest({
    required this.patientId,
    required this.symptomCodes,
    required this.channel,
    required this.inputLanguage,
    this.severity,
    this.durationHours,
    this.answers = const {},
    this.idempotencyKey,
  });

  final String patientId;
  final List<String> symptomCodes;

  /// PRD 19 - lets analytics segment by entry point.
  final String channel;
  final LanguageCode inputLanguage;

  /// Self-reported 1..5. Severity is what separates self-care from escalation,
  /// so the UI must always collect it.
  final int? severity;

  final int? durationHours;
  final Map<String, Object?> answers;

  /// Set for offline captures so a replayed sync reuses the same assessment
  /// (PRD 15).
  final String? idempotencyKey;

  Map<String, Object?> toRpcParams() => {
        'p_patient_id': patientId,
        'p_symptoms': symptomCodes,
        'p_severity': severity,
        'p_duration_hours': durationHours,
        'p_channel': channel,
        'p_input_language': inputLanguage.wire,
        'p_answers': answers,
        if (idempotencyKey != null) 'p_idempotency_key': idempotencyKey,
      };
}

/// PRD 11 TriageAssessment - the outcome, plus everything needed to explain it.
@immutable
class TriageAssessment {
  const TriageAssessment({
    required this.id,
    required this.patientId,
    required this.symptomCodes,
    required this.riskLevel,
    required this.nextAction,
    required this.redFlags,
    required this.requiredServices,
    required this.minFacilityTier,
    required this.adviceKey,
    required this.ruleSetVersion,
    required this.usedDefaultFallback,
    required this.createdAt,
    this.matchedRuleCode,
    this.severity,
    this.durationHours,
    this.aiAssisted = false,
  });

  factory TriageAssessment.fromJson(Map<String, Object?> json) =>
      TriageAssessment(
        id: json['id']! as String,
        patientId: json['patient_id']! as String,
        symptomCodes: _stringList(json['symptoms']),
        riskLevel: RiskLevel.parse(json['risk_level'] as String?),
        nextAction: NextAction.parse(json['next_action'] as String?),
        redFlags: _stringList(json['red_flags']),
        requiredServices: _stringList(json['required_services']),
        minFacilityTier: (json['min_facility_tier'] as num?)?.toInt() ?? 1,
        adviceKey: json['advice_key']! as String,
        ruleSetVersion: (json['rule_set_version'] as num).toInt(),
        usedDefaultFallback: json['used_default_fallback'] as bool? ?? false,
        createdAt:
            DateTime.parse(json['created_at']! as String).toLocal(),
        matchedRuleCode: json['matched_rule_code'] as String?,
        severity: (json['severity'] as num?)?.toInt(),
        durationHours: (json['duration_hours'] as num?)?.toInt(),
        aiAssisted: json['ai_assisted'] as bool? ?? false,
      );

  final String id;
  final String patientId;
  final List<String> symptomCodes;
  final RiskLevel riskLevel;
  final NextAction nextAction;

  /// Codes of every red-flag rule that fired.
  final List<String> redFlags;

  /// Services the destination facility must offer. Feeds facility scoring.
  final List<String> requiredServices;

  final int minFacilityTier;

  /// Localisation key for the advice text. Advice is never free-form generated
  /// (PRD 20).
  final String adviceKey;

  /// Version of the clinically approved rule set that produced this outcome.
  final int ruleSetVersion;

  /// True when no rule matched and the engine fell back to its safe default.
  /// The UI says the assessment could not be completed precisely and still
  /// routes the person to a clinician.
  final bool usedDefaultFallback;

  final DateTime createdAt;
  final String? matchedRuleCode;
  final int? severity;
  final int? durationHours;
  final bool aiAssisted;

  bool get isEmergency => riskLevel == RiskLevel.emergency;
  bool get hasRedFlags => redFlags.isNotEmpty;

  /// Whether this assessment should lead into facility selection.
  bool get shouldFindFacility => nextAction.needsFacility;

  /// Priority a referral created from this assessment will take.
  ReferralPriority get impliedPriority => switch (riskLevel) {
        RiskLevel.emergency => ReferralPriority.emergency,
        RiskLevel.high => ReferralPriority.urgent,
        RiskLevel.medium || RiskLevel.low => ReferralPriority.routine,
      };
}

List<String> _stringList(Object? raw) {
  if (raw is List) return raw.map((e) => e.toString()).toList(growable: false);
  return const [];
}
