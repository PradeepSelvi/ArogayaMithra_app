import 'package:am_core/am_core.dart';
import 'package:am_localization/am_localization.dart';
import 'package:am_models/am_models.dart';
import 'package:am_networking/am_networking.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'referral_detail_screen.dart';

/// The citizen's referrals (PRD 5.1).
class ReferralListScreen extends ConsumerWidget {
  const ReferralListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AmStrings.of(context);
    final referrals = ref.watch(myReferralsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.referralsTitle)),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(myReferralsProvider),
          child: referrals.when(
            loading: () => AmLoadingView(message: strings.loading),
            error: (error, _) => AmFailureView(
              failure: error is Failure
                  ? error
                  : Failure.unexpected(detail: error.toString()),
              onRetry: () => ref.invalidate(myReferralsProvider),
            ),
            data: (list) => list.isEmpty
                ? AmEmptyView(message: strings.referralsEmpty)
                : ListView.separated(
                    padding: const EdgeInsets.all(AmTokens.spaceMd),
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AmTokens.spaceSm),
                    itemBuilder: (context, index) =>
                        _ReferralTile(referral: list[index]),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ReferralTile extends StatelessWidget {
  const _ReferralTile({required this.referral});

  final Referral referral;

  @override
  Widget build(BuildContext context) {
    final strings = AmStrings.of(context);
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AmTokens.spaceMd,
          vertical: AmTokens.spaceSm,
        ),
        title: Text(strings.referralReference(referral.referenceCode)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AmTokens.spaceSm),
          child: Wrap(
            spacing: AmTokens.spaceSm,
            runSpacing: AmTokens.spaceXs,
            children: [
              AmStatusChip.referral(referral.status, strings: strings, dense: true),
              if (referral.isOverdue)
                AmStatusChip(
                  label: strings.consoleSlaBreached,
                  icon: Icons.timer_off_outlined,
                  foreground: AmTokens.emergency,
                  background: AmTokens.emergencyLight,
                  dense: true,
                ),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${referral.createdAt.day}/${referral.createdAt.month}',
              style: theme.textTheme.bodySmall,
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ReferralDetailScreen(referralId: referral.id),
          ),
        ),
      ),
    );
  }
}

/// Referrals visible to the signed-in citizen. RLS decides the set.
final myReferralsProvider = FutureProvider<List<Referral>>((ref) async {
  final result = await ref.watch(referralRepositoryProvider).visible();
  return result.fold(
    onSuccess: (list) => list,
    onFailure: (failure) => throw failure,
  );
});
