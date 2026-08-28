import 'package:am_core/am_core.dart';
import 'package:am_models/am_models.dart';

import '../failure_mapper.dart';
import '../supabase_bootstrap.dart';

/// Follow-ups, feedback and the notification inbox.
final class EngagementRepository extends SupabaseRepository {
  EngagementRepository(super.client);

  // ----- Follow-ups (PRD FR-011) -------------------------------------------

  /// The signed-in worker's task queue, soonest due first.
  Future<Result<List<FollowUp>>> myFollowUps({bool openOnly = true}) =>
      guard(() async {
        var query = client.from('followups').select();
        if (openOnly) {
          query = query.inFilter('status', const ['scheduled', 'due']);
        }
        final rows = await query.order('due_date');
        return rows.map(FollowUp.fromJson).toList(growable: false);
      });

  Future<Result<List<FollowUp>>> forPatient(String patientId) =>
      guard(() async {
        final rows = await client
            .from('followups')
            .select()
            .eq('patient_id', patientId)
            .order('due_date', ascending: false);
        return rows.map(FollowUp.fromJson).toList(growable: false);
      });

  /// Closes a follow-up. The database requires an outcome for a completed task,
  /// so it is a required argument here.
  Future<Result<FollowUp>> complete({
    required String followUpId,
    required String outcome,
    String? notes,
  }) =>
      guard(() async {
        if (outcome.trim().isEmpty) {
          throw const Failure(
            kind: FailureKind.invalidInput,
            messageKey: 'error.outcome_required',
          );
        }

        final row = await client
            .from('followups')
            .update({
              'status': 'completed',
              'outcome': outcome.trim(),
              if (notes != null) 'notes': notes,
            })
            .eq('id', followUpId)
            .select()
            .single();

        return FollowUp.fromJson(row);
      });

  Future<Result<FollowUp>> schedule({
    required String patientId,
    required DateTime dueDate,
    String taskType = 'custom',
    String instructionsKey = 'followup.default',
    String? referralId,
    String? assigneeId,
    String? notes,
  }) =>
      guard(() async {
        final row = await client
            .from('followups')
            .insert({
              'patient_id': patientId,
              'due_date': dueDate.toIso8601String().split('T').first,
              'task_type': taskType,
              'instructions_key': instructionsKey,
              if (referralId != null) 'referral_id': referralId,
              if (assigneeId != null) 'assignee_id': assigneeId,
              if (notes != null) 'notes': notes,
              'client_created_at': DateTime.now().toUtc().toIso8601String(),
            })
            .select()
            .single();

        return FollowUp.fromJson(row);
      });

  // ----- Feedback (PRD FR-012) ---------------------------------------------

  Future<Result<Feedback>> submitFeedback(FeedbackDraft draft) =>
      guard(() async {
        final row = await client
            .from('feedback')
            .insert(draft.toInsertJson())
            .select()
            .single();
        return Feedback.fromJson(row);
      });

  /// Feedback the signed-in user may see: their own, or their facility's.
  Future<Result<List<Feedback>>> visibleFeedback({int limit = 50}) =>
      guard(() async {
        final rows = await client
            .from('feedback')
            .select()
            .order('created_at', ascending: false)
            .limit(limit);
        return rows.map(Feedback.fromJson).toList(growable: false);
      });

  /// Records how a facility or district resolved an issue.
  Future<Result<Feedback>> resolveFeedback({
    required String feedbackId,
    required String resolutionNote,
  }) =>
      guard(() async {
        final row = await client
            .from('feedback')
            .update({
              'status': 'actioned',
              'resolution_note': resolutionNote,
            })
            .eq('id', feedbackId)
            .select()
            .single();
        return Feedback.fromJson(row);
      });

  // ----- Notifications (PRD FR-014, 18) ------------------------------------

  Future<Result<List<AppNotification>>> inbox({int limit = 50}) =>
      guard(() async {
        final rows = await client
            .from('notifications')
            .select()
            .order('queued_at', ascending: false)
            .limit(limit);
        return rows.map(AppNotification.fromJson).toList(growable: false);
      });

  Future<Result<AppNotification>> markRead(String notificationId) =>
      guard(() async {
        final row = await client.rpc<Map<String, Object?>>(
          'mark_notification_read',
          params: {'p_notification_id': notificationId},
        );
        return AppNotification.fromJson(row);
      });

  /// Live inbox. Realtime respects RLS, so only the recipient's rows arrive.
  Stream<List<AppNotification>> watchInbox(String userId) => client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('recipient_id', userId)
      .order('queued_at')
      .map(
        (rows) => rows.map(AppNotification.fromJson).toList(growable: false),
      );

  Stream<int> watchUnreadCount(String userId) =>
      watchInbox(userId).map((list) => list.where((n) => n.isUnread).length);
}
