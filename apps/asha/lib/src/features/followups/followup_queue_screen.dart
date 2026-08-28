import 'package:am_core/am_core.dart';
import 'package:am_localization/am_localization.dart';
import 'package:am_models/am_models.dart';
import 'package:am_networking/am_networking.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Follow-up task queue (PRD 5.2, FR-011).
///
/// Overdue tasks are marked, because follow-up completion is a monitored KPI and
/// a worker should be able to see at a glance what is slipping (PRD 19).
class FollowUpQueueScreen extends ConsumerWidget {
  const FollowUpQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AmStrings.of(context);
    final followUps = ref.watch(myFollowUpsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myFollowUpsProvider),
      child: followUps.when(
        loading: () => AmLoadingView(message: strings.loading),
        error: (error, _) => AmFailureView(
          failure: error is Failure
              ? error
              : Failure.unexpected(detail: error.toString()),
          onRetry: () => ref.invalidate(myFollowUpsProvider),
        ),
        data: (list) => list.isEmpty
            ? AmEmptyView(
                message: strings.followUpsEmpty,
                icon: Icons.event_available_outlined,
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AmTokens.spaceMd),
                itemCount: list.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AmTokens.spaceSm),
                itemBuilder: (context, index) =>
                    _FollowUpTile(followUp: list[index]),
              ),
      ),
    );
  }
}

class _FollowUpTile extends ConsumerStatefulWidget {
  const _FollowUpTile({required this.followUp});

  final FollowUp followUp;

  @override
  ConsumerState<_FollowUpTile> createState() => _FollowUpTileState();
}

class _FollowUpTileState extends ConsumerState<_FollowUpTile> {
  bool _isBusy = false;

  @override
  Widget build(BuildContext context) {
    final strings = AmStrings.of(context);
    final theme = Theme.of(context);
    final followUp = widget.followUp;
    final overdue = followUp.daysOverdue;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AmTokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.followUpInstructions(followUp.instructionsKey),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                if (overdue > 0)
                  AmStatusChip(
                    label: strings.followUpOverdue(overdue),
                    icon: Icons.timer_off_outlined,
                    foreground: AmTokens.emergency,
                    background: AmTokens.emergencyLight,
                    dense: true,
                  ),
              ],
            ),
            const SizedBox(height: AmTokens.spaceSm),
            Text(
              strings.followUpDueOn(
                '${followUp.dueDate.day}/${followUp.dueDate.month}',
              ),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AmTokens.spaceMd),
            FilledButton.icon(
              onPressed: _isBusy ? null : _complete,
              icon: const Icon(Icons.check),
              label: Text(strings.followUpComplete),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _complete() async {
    final strings = AmStrings.of(context);
    final controller = TextEditingController();

    // An outcome is required by the database, so it is collected up front rather
    // than failing the update after the round trip.
    final outcome = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.followUpOutcome),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.actionCancel),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => FilledButton(
              onPressed: value.text.trim().isEmpty
                  ? null
                  : () => Navigator.of(context).pop(value.text.trim()),
              child: Text(strings.actionSave),
            ),
          ),
        ],
      ),
    );

    if (outcome == null || !mounted) return;

    setState(() => _isBusy = true);

    final result = await ref.read(engagementRepositoryProvider).complete(
          followUpId: widget.followUp.id,
          outcome: outcome,
        );

    if (!mounted) return;
    setState(() => _isBusy = false);

    result.fold(
      onSuccess: (_) => ref.invalidate(myFollowUpsProvider),
      onFailure: (failure) => showAmFailureSnackBar(context, failure),
    );
  }
}

final myFollowUpsProvider = FutureProvider<List<FollowUp>>((ref) async {
  final result = await ref.watch(engagementRepositoryProvider).myFollowUps();
  return result.fold(
    onSuccess: (list) => list,
    onFailure: (failure) => throw failure,
  );
});
