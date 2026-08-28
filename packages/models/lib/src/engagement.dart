import 'package:meta/meta.dart';

import 'enums.dart';

/// PRD 11 FollowUp - a task in the ASHA/ANM queue (PRD 5.2, FR-011).
@immutable
class FollowUp {
  const FollowUp({
    required this.id,
    required this.patientId,
    required this.districtId,
    required this.taskType,
    required this.instructionsKey,
    required this.dueDate,
    required this.status,
    this.referralId,
    this.assigneeId,
    this.notes,
    this.outcome,
    this.completedAt,
  });

  factory FollowUp.fromJson(Map<String, Object?> json) => FollowUp(
        id: json['id']! as String,
        patientId: json['patient_id']! as String,
        districtId: json['district_id']! as String,
        taskType: json['task_type']! as String,
        instructionsKey: json['instructions_key']! as String,
        dueDate: DateTime.parse(json['due_date']! as String),
        status: FollowUpStatus.parse(json['status'] as String?),
        referralId: json['referral_id'] as String?,
        assigneeId: json['assignee_id'] as String?,
        notes: json['notes'] as String?,
        outcome: json['outcome'] as String?,
        completedAt: _dateTime(json['completed_at']),
      );

  final String id;
  final String patientId;
  final String districtId;
  final String taskType;

  /// Localisation key for the instruction text (PRD 17).
  final String instructionsKey;

  final DateTime dueDate;
  final FollowUpStatus status;
  final String? referralId;
  final String? assigneeId;
  final String? notes;
  final String? outcome;
  final DateTime? completedAt;

  bool get isOpen => status.isOpen;

  /// Days overdue, or 0 when not yet due.
  int get daysOverdue {
    final today = DateTime.now();
    final diff = DateTime(today.year, today.month, today.day)
        .difference(DateTime(dueDate.year, dueDate.month, dueDate.day))
        .inDays;
    return diff > 0 ? diff : 0;
  }
}

/// Categories a citizen can pick when reporting an issue (PRD FR-012).
///
/// Supply-side categories are routed to the facility and the DHO as alerts.
enum FeedbackCategory {
  general('general'),
  waitingTime('waiting_time'),
  staffBehaviour('staff_behaviour'),
  medicineUnavailable('medicine_unavailable'),
  diagnosticUnavailable('diagnostic_unavailable'),
  cleanliness('cleanliness'),
  cost('cost'),
  referralProcess('referral_process'),
  ambulance('ambulance'),
  teleconsult('teleconsult'),
  other('other');

  const FeedbackCategory(this.wire);
  final String wire;

  static FeedbackCategory parse(String? raw) {
    for (final v in values) {
      if (v.wire == raw) return v;
    }
    return FeedbackCategory.general;
  }

  /// Categories that raise an operational alert regardless of rating.
  bool get isServiceGap => const {
        FeedbackCategory.medicineUnavailable,
        FeedbackCategory.diagnosticUnavailable,
        FeedbackCategory.ambulance,
      }.contains(this);
}

/// PRD 11 - Feedback.
@immutable
class Feedback {
  const Feedback({
    required this.id,
    required this.rating,
    required this.category,
    required this.status,
    required this.createdAt,
    this.patientId,
    this.facilityId,
    this.referralId,
    this.comment,
    this.wouldRecommend,
    this.resolutionNote,
  });

  factory Feedback.fromJson(Map<String, Object?> json) => Feedback(
        id: json['id']! as String,
        rating: (json['rating'] as num).toInt(),
        category: FeedbackCategory.parse(json['category'] as String?),
        status: json['status']! as String,
        createdAt: DateTime.parse(json['created_at']! as String).toLocal(),
        patientId: json['patient_id'] as String?,
        facilityId: json['facility_id'] as String?,
        referralId: json['referral_id'] as String?,
        comment: json['comment'] as String?,
        wouldRecommend: json['would_recommend'] as bool?,
        resolutionNote: json['resolution_note'] as String?,
      );

  final String id;

  /// 1..5.
  final int rating;

  final FeedbackCategory category;
  final String status;
  final DateTime createdAt;
  final String? patientId;
  final String? facilityId;
  final String? referralId;
  final String? comment;
  final bool? wouldRecommend;
  final String? resolutionNote;

  bool get isUnresolved => status == 'new' || status == 'triaged';
}

/// A draft submission, before the server assigns an id.
@immutable
class FeedbackDraft {
  const FeedbackDraft({
    required this.rating,
    required this.category,
    required this.language,
    this.patientId,
    this.facilityId,
    this.referralId,
    this.comment,
    this.wouldRecommend,
  });

  final int rating;
  final FeedbackCategory category;
  final LanguageCode language;
  final String? patientId;
  final String? facilityId;
  final String? referralId;
  final String? comment;
  final bool? wouldRecommend;

  Map<String, Object?> toInsertJson() => {
        'rating': rating,
        'category': category.wire,
        'language': language.wire,
        if (patientId != null) 'patient_id': patientId,
        if (facilityId != null) 'facility_id': facilityId,
        if (referralId != null) 'referral_id': referralId,
        if (comment != null && comment!.trim().isNotEmpty)
          'comment': comment!.trim(),
        if (wouldRecommend != null) 'would_recommend': wouldRecommend,
      };
}

/// PRD 11 - Notification. Content is already localised by the database from a
/// template, so the client renders it as-is.
@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.channel,
    required this.language,
    required this.status,
    required this.queuedAt,
    this.templateKey,
    this.action = const {},
    this.readAt,
  });

  factory AppNotification.fromJson(Map<String, Object?> json) =>
      AppNotification(
        id: json['id']! as String,
        title: json['title']! as String,
        body: json['body']! as String,
        channel: NotificationChannel.parse(json['channel'] as String?),
        language: LanguageCode.parse(json['language'] as String?),
        status: DeliveryStatus.parse(json['status'] as String?),
        queuedAt: DateTime.parse(json['queued_at']! as String).toLocal(),
        templateKey: json['template_key'] as String?,
        action: (json['action'] as Map?)?.cast<String, Object?>() ?? const {},
        readAt: _dateTime(json['read_at']),
      );

  final String id;
  final String title;
  final String body;
  final NotificationChannel channel;
  final LanguageCode language;
  final DeliveryStatus status;
  final DateTime queuedAt;
  final String? templateKey;

  /// Deep-link target, e.g. {"route": "/referrals", "id": "..."}.
  final Map<String, Object?> action;

  final DateTime? readAt;

  bool get isUnread => readAt == null;

  String? get route => action['route'] as String?;
  String? get targetId => action['id'] as String?;
}

DateTime? _dateTime(Object? raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  return DateTime.tryParse(raw as String)?.toLocal();
}
