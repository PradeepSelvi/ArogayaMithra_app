import 'package:am_auth/am_auth.dart';
import 'package:am_localization/am_localization.dart';
import 'package:am_models/am_models.dart';
import 'package:am_networking/am_networking.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../referrals/referral_detail_screen.dart';

/// Notification inbox (PRD 13 GET /notifications, PRD 18).
///
/// The database renders each message from a template in the recipient's
/// language, so the client displays the stored text rather than re-deriving it.
class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AmStrings.of(context);
    final inbox = ref.watch(inboxStreamProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.notificationsTitle)),
      body: SafeArea(
        child: inbox.when(
          loading: () => AmLoadingView(message: strings.loading),
          error: (_, __) => AmEmptyView(message: strings.notificationsEmpty),
          data: (items) => items.isEmpty
              ? AmEmptyView(
                  message: strings.notificationsEmpty,
                  icon: Icons.notifications_none,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AmTokens.spaceMd),
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AmTokens.spaceSm),
                  itemBuilder: (context, index) =>
                      _NotificationTile(notification: items[index]),
                ),
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      color: notification.isUnread ? AmTokens.primaryLight : AmTokens.surface,
      child: ListTile(
        contentPadding: const EdgeInsets.all(AmTokens.spaceMd),
        leading: Icon(
          notification.isUnread
              ? Icons.mark_email_unread_outlined
              : Icons.mark_email_read_outlined,
          color: notification.isUnread
              ? AmTokens.primary
              : AmTokens.textSecondary,
        ),
        title: Text(notification.title, style: theme.textTheme.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AmTokens.spaceXs),
          child: Text(notification.body, style: theme.textTheme.bodyMedium),
        ),
        onTap: () => _open(context, ref),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    if (notification.isUnread) {
      await ref
          .read(engagementRepositoryProvider)
          .markRead(notification.id);
    }

    if (!context.mounted) return;

    // Notifications carry a deep-link target so a "referral accepted" message
    // lands on the referral rather than the inbox.
    final targetId = notification.targetId;
    if (notification.route == '/referrals' && targetId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ReferralDetailScreen(referralId: targetId),
        ),
      );
    }
  }
}

final inboxStreamProvider = StreamProvider<List<AppNotification>>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return Stream.value(const []);

  return ref
      .watch(engagementRepositoryProvider)
      .watchInbox(userId)
      .map((list) => list.reversed.toList(growable: false));
});
