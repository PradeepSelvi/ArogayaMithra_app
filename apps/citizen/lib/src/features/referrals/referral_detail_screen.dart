import 'package:am_core/am_core.dart';
import 'package:am_localization/am_localization.dart';
import 'package:am_models/am_models.dart';
import 'package:am_networking/am_networking.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../feedback/feedback_screen.dart';

/// Live referral status for the citizen (PRD 7.12, 7.13).
///
/// Subscribes to the row rather than polling, so a facility acceptance appears
/// without the user pulling to refresh. Realtime honours row-level security, so
/// only referrals this citizen may read ever arrive.
class ReferralDetailScreen extends ConsumerWidget {
  const ReferralDetailScreen({required this.referralId, super.key});

  final String referralId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AmStrings.of(context);
    final referral = ref.watch(referralStreamProvider(referralId));

    return Scaffold(
      appBar: AppBar(title: Text(strings.referralsTitle)),
      body: SafeArea(
        child: referral.when(
          loading: () => AmLoadingView(message: strings.loading),
          error: (error, _) => AmFailureView(
            failure: error is Failure
                ? error
                : Failure.unexpected(detail: error.toString()),
          ),
          data: (value) => value == null
              ? AmEmptyView(message: strings.referralsEmpty)
              : _Body(referral: value),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.referral});

  final Referral referral;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AmStrings.of(context);
    final theme = Theme.of(context);
    final timeline = ref.watch(referralTimelineProvider(referral.id));

    return ListView(
      padding: const EdgeInsets.all(AmTokens.spaceMd),
      children: [
        AmSection(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.referralReference(referral.referenceCode),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  AmStatusChip.priority(referral.priority, strings: strings),
                ],
              ),
              const SizedBox(height: AmTokens.spaceXs),
              Text(
                strings.referralShowAtFacility,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AmTokens.spaceMd),

        if (referral.status.isEmergency)
          AmBanner.emergency(message: strings.ambulanceStayPut)
        else if (referral.isOverdue)
          AmBanner.warning(message: strings.referralOverdue)
        else if (referral.status.isAwaitingFacility && referral.timeToSla != null)
          AmBanner.info(
            message: strings.referralAwaitingFacility(
              referral.timeToSla!.inMinutes.clamp(0, 999),
            ),
          )
        else if (referral.status == ReferralStatus.rejected)
          AmBanner.warning(message: strings.referralRejectedNext),

        const SizedBox(height: AmTokens.spaceMd),
        AmSection(
          title: strings.referralsTitle,
          child: AmReferralProgress(status: referral.status),
        ),

        const SizedBox(height: AmTokens.spaceMd),
        AmSection(
          title: strings.referralTimeline,
          child: timeline.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AmTokens.spaceMd),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Text(
              strings.errorUnexpected,
              style: theme.textTheme.bodyMedium,
            ),
            data: (events) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final event in events)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AmTokens.spaceSm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          event.isAutomated ? Icons.settings : Icons.person,
                          size: 16,
                          color: AmTokens.textSecondary,
                        ),
                        const SizedBox(width: AmTokens.spaceSm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.toStatus == null
                                    ? event.eventType
                                    : AmStatusChip.referralStatusLabel(
                                        event.toStatus!,
                                        strings,
                                      ),
                                style: theme.textTheme.bodyLarge,
                              ),
                              Text(
                                _formatTime(event.occurredAt),
                                style: theme.textTheme.bodySmall,
                              ),
                              if (event.reason != null)
                                Text(
                                  event.reason!,
                                  style: theme.textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AmTokens.spaceLg),
        ..._actions(context, ref, strings),
        const SizedBox(height: AmTokens.spaceXl),
      ],
    );
  }

  /// Offers only the actions a citizen can legitimately take. Anything else is
  /// refused by the database state machine, so showing it would be a dead end.
  List<Widget> _actions(
    BuildContext context,
    WidgetRef ref,
    AmStrings strings,
  ) {
    final widgets = <Widget>[];

    if (referral.status == ReferralStatus.accepted) {
      widgets.add(
        AmBigButton(
          label: strings.referralImOnMyWay,
          icon: Icons.directions_walk,
          onPressed: () => _advance(
            context,
            ref,
            ReferralStatus.patientTravelling,
          ),
        ),
      );
    }

    if (referral.status == ReferralStatus.completed) {
      widgets.add(
        AmBigButton(
          label: strings.homeFeedback,
          icon: Icons.rate_review_outlined,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => FeedbackScreen(
                referralId: referral.id,
                facilityId: referral.destinationFacilityId,
                patientId: referral.patientId,
              ),
            ),
          ),
        ),
      );
    }

    if (referral.isOpen && !referral.status.isEmergency) {
      widgets
        ..add(const SizedBox(height: AmTokens.spaceSm))
        ..add(
          OutlinedButton.icon(
            onPressed: () => _cancel(context, ref, strings),
            icon: const Icon(Icons.close),
            label: Text(strings.referralCancel),
          ),
        );
    }

    return widgets;
  }

  Future<void> _advance(
    BuildContext context,
    WidgetRef ref,
    ReferralStatus to,
  ) async {
    final result =
        await ref.read(referralRepositoryProvider).advance(referral.id, to);

    if (!context.mounted) return;
    result.fold(
      onSuccess: (_) {},
      onFailure: (failure) => showAmFailureSnackBar(context, failure),
    );
  }

  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    AmStrings strings,
  ) async {
    final reason = await _promptForReason(
      context,
      title: strings.referralCancelReason,
      confirmLabel: strings.actionConfirm,
      cancelLabel: strings.actionCancel,
    );

    if (reason == null || !context.mounted) return;

    final result =
        await ref.read(referralRepositoryProvider).cancel(referral.id, reason);

    if (!context.mounted) return;
    result.fold(
      onSuccess: (_) => Navigator.of(context).pop(),
      onFailure: (failure) => showAmFailureSnackBar(context, failure),
    );
  }

  static String _formatTime(DateTime time) =>
      '${time.day.toString().padLeft(2, '0')}/'
      '${time.month.toString().padLeft(2, '0')} '
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
}

/// Asks for a free-text reason. The database rejects a blank one, so the confirm
/// button stays disabled until something is typed.
Future<String?> _promptForReason(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  required String cancelLabel,
}) {
  final controller = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 3,
        minLines: 2,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(cancelLabel),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => FilledButton(
            onPressed: value.text.trim().isEmpty
                ? null
                : () => Navigator.of(context).pop(value.text.trim()),
            child: Text(confirmLabel),
          ),
        ),
      ],
    ),
  );
}

/// Live referral row.
final referralStreamProvider =
    StreamProvider.family<Referral?, String>((ref, referralId) {
  return ref.watch(referralRepositoryProvider).watchReferral(referralId);
});

/// Referral timeline, refreshed whenever the referral row changes.
final referralTimelineProvider =
    FutureProvider.family<List<ReferralEvent>, String>((ref, referralId) async {
  ref.watch(referralStreamProvider(referralId));

  final result =
      await ref.watch(referralRepositoryProvider).timeline(referralId);
  return result.fold(
    onSuccess: (events) => events,
    onFailure: (failure) => throw failure,
  );
});
