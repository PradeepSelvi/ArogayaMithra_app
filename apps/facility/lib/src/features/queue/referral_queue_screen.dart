import 'package:am_auth/am_auth.dart';
import 'package:am_core/am_core.dart';
import 'package:am_localization/am_localization.dart';
import 'package:am_models/am_models.dart';
import 'package:am_networking/am_networking.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Incoming referral queue (PRD 5.3, FR-009).
///
/// Ordered by urgency then by time left on the acceptance SLA, so the referral
/// closest to breaching is the one in front of the officer. Realtime keeps it
/// current without a refresh, which matters when the SLA is ten minutes.
class ReferralQueueScreen extends ConsumerWidget {
  const ReferralQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AmStrings.of(context);
    final queue = ref.watch(referralQueueProvider);

    return AmContentFrame(
      child: queue.when(
        loading: () => AmLoadingView(message: strings.loading),
        error: (_, __) => AmEmptyView(message: strings.consoleQueueEmpty),
        data: (referrals) => referrals.isEmpty
            ? AmEmptyView(
                message: strings.consoleQueueEmpty,
                icon: Icons.inbox_outlined,
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AmTokens.spaceMd),
                itemCount: referrals.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AmTokens.spaceMd),
                itemBuilder: (context, index) =>
                    _QueueCard(referral: referrals[index]),
              ),
      ),
    );
  }
}

class _QueueCard extends ConsumerStatefulWidget {
  const _QueueCard({required this.referral});

  final Referral referral;

  @override
  ConsumerState<_QueueCard> createState() => _QueueCardState();
}

class _QueueCardState extends ConsumerState<_QueueCard> {
  bool _isBusy = false;

  @override
  Widget build(BuildContext context) {
    final strings = AmStrings.of(context);
    final theme = Theme.of(context);
    final referral = widget.referral;
    final role = ref.watch(currentRoleProvider);
    final transitions = ref.watch(
      allowedTransitionsProvider((status: referral.status, role: role)),
    );

    return AmSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  referral.referenceCode,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              AmStatusChip.priority(referral.priority, strings: strings),
              const SizedBox(width: AmTokens.spaceSm),
              AmStatusChip.referral(referral.status, strings: strings),
            ],
          ),
          const SizedBox(height: AmTokens.spaceSm),

          // The SLA clock, stated plainly. PRD 18 makes a breach an alert for the
          // officer and the DHO, so it should not be a surprise.
          if (referral.isOverdue)
            AmBanner.warning(message: strings.consoleSlaBreached)
          else if (referral.status.isAwaitingFacility &&
              referral.timeToSla != null)
            Text(
              strings.consoleSlaRemaining(
                referral.timeToSla!.inMinutes.clamp(0, 999),
              ),
              style: theme.textTheme.bodyMedium,
            ),

          if (referral.reason != null) ...[
            const SizedBox(height: AmTokens.spaceSm),
            Text(referral.reason!, style: theme.textTheme.bodyLarge),
          ],

          if (referral.requiredServices.isNotEmpty) ...[
            const SizedBox(height: AmTokens.spaceSm),
            Wrap(
              spacing: AmTokens.spaceSm,
              runSpacing: AmTokens.spaceXs,
              children: [
                for (final service in referral.requiredServices)
                  Chip(
                    label: Text(service),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],

          const SizedBox(height: AmTokens.spaceMd),
          _Actions(
            referral: referral,
            transitions: transitions.valueOrNull ?? const [],
            isBusy: _isBusy,
            onAccept: () => _run(() => ref
                .read(referralRepositoryProvider)
                .accept(referral.id)),
            onReject: () => _reject(strings),
            onAdvance: (to) => _run(
              () => ref.read(referralRepositoryProvider).advance(referral.id, to),
            ),
            onComplete: () => _complete(strings),
          ),
        ],
      ),
    );
  }

  Future<void> _run(Future<Result<Referral>> Function() action) async {
    setState(() => _isBusy = true);
    final result = await action();
    if (!mounted) return;
    setState(() => _isBusy = false);

    // Repositories return Result, so a refusal from the state machine surfaces
    // as a message rather than an exception. The realtime subscription picks up
    // the new state, so there is nothing to do on success.
    result.fold(
      onSuccess: (_) {},
      onFailure: (failure) => showAmFailureSnackBar(context, failure),
    );
  }

  Future<void> _reject(AmStrings strings) async {
    final reason = await _promptForText(
      context,
      title: strings.consoleRejectReason,
      helper: strings.consoleRejectReasonRequired,
      confirmLabel: strings.consoleReject,
      cancelLabel: strings.actionCancel,
    );

    if (reason == null || !mounted) return;

    await _run(
      () => ref
          .read(referralRepositoryProvider)
          .reject(widget.referral.id, reason),
    );
  }

  Future<void> _complete(AmStrings strings) async {
    final outcome = await _promptForText(
      context,
      title: strings.consoleCompleteOutcome,
      confirmLabel: strings.consoleComplete,
      cancelLabel: strings.actionCancel,
    );

    if (outcome == null || !mounted) return;

    await _run(
      () => ref.read(referralRepositoryProvider).advance(
            widget.referral.id,
            ReferralStatus.completed,
            outcome: outcome,
          ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.referral,
    required this.transitions,
    required this.isBusy,
    required this.onAccept,
    required this.onReject,
    required this.onAdvance,
    required this.onComplete,
  });

  final Referral referral;
  final List<ReferralTransition> transitions;
  final bool isBusy;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final void Function(ReferralStatus to) onAdvance;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final strings = AmStrings.of(context);
    final allowed = transitions.map((t) => t.toStatus).toSet();

    // Only the transitions the database will accept for this role and state are
    // rendered. Offering anything else would produce a guaranteed error.
    final buttons = <Widget>[
      if (allowed.contains(ReferralStatus.accepted))
        FilledButton.icon(
          onPressed: isBusy ? null : onAccept,
          icon: const Icon(Icons.check),
          label: Text(strings.consoleAccept),
        ),
      if (allowed.contains(ReferralStatus.rejected))
        OutlinedButton.icon(
          onPressed: isBusy ? null : onReject,
          icon: const Icon(Icons.close),
          label: Text(strings.consoleReject),
        ),
      if (allowed.contains(ReferralStatus.arrived))
        FilledButton.icon(
          onPressed: isBusy ? null : () => onAdvance(ReferralStatus.arrived),
          icon: const Icon(Icons.how_to_reg),
          label: Text(strings.consoleMarkArrived),
        ),
      if (allowed.contains(ReferralStatus.consultation))
        FilledButton.icon(
          onPressed: isBusy
              ? null
              : () => onAdvance(ReferralStatus.consultation),
          icon: const Icon(Icons.medical_information_outlined),
          label: Text(strings.consoleStartConsultation),
        ),
      if (allowed.contains(ReferralStatus.completed))
        FilledButton.icon(
          onPressed: isBusy ? null : onComplete,
          icon: const Icon(Icons.task_alt),
          label: Text(strings.consoleComplete),
        ),
    ];

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AmTokens.spaceSm,
      runSpacing: AmTokens.spaceSm,
      children: buttons,
    );
  }
}

/// Collects required free text. Confirm stays disabled while it is blank, which
/// mirrors the database constraint instead of failing after the round trip.
Future<String?> _promptForText(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  required String cancelLabel,
  String? helper,
}) {
  final controller = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (helper != null) ...[
            Text(helper, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AmTokens.spaceMd),
          ],
          TextField(controller: controller, autofocus: true, minLines: 2, maxLines: 4),
        ],
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

/// Live queue for the signed-in officer's facility.
final referralQueueProvider = StreamProvider<List<Referral>>((ref) {
  final facilityId = ref.watch(currentFacilityIdProvider);
  if (facilityId == null) return Stream.value(const []);

  return ref
      .watch(referralRepositoryProvider)
      .watchIncomingQueue(facilityId)
      .map(_sortByUrgency);
});

List<Referral> _sortByUrgency(List<Referral> referrals) {
  final sorted = [...referrals]..sort((a, b) {
      // Emergencies first.
      final byPriority =
          b.priority.index.compareTo(a.priority.index);
      if (byPriority != 0) return byPriority;

      // Then whichever is closest to breaching its SLA.
      final aDue = a.slaDueAt;
      final bDue = b.slaDueAt;
      if (aDue != null && bDue != null) return aDue.compareTo(bDue);
      if (aDue != null) return -1;
      if (bDue != null) return 1;

      return a.createdAt.compareTo(b.createdAt);
    });
  return sorted;
}

/// Legal transitions from a state for a role, read from the database.
final allowedTransitionsProvider = FutureProvider.family<
    List<ReferralTransition>,
    ({ReferralStatus status, UserRole? role})>((ref, args) async {
  final role = args.role;
  if (role == null) return const [];

  final result = await ref.watch(catalogRepositoryProvider).allowedTransitions(
        from: args.status,
        role: role,
      );
  return result.fold(onSuccess: (list) => list, onFailure: (_) => const []);
});
