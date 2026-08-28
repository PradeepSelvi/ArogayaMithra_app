import 'package:am_core/am_core.dart';
import 'package:am_localization/am_localization.dart';
import 'package:am_models/am_models.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'household_detail_screen.dart';
import 'household_providers.dart';

/// Assigned households (PRD 5.2).
class HouseholdListScreen extends ConsumerWidget {
  const HouseholdListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AmStrings.of(context);
    final households = ref.watch(assignedHouseholdsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(assignedHouseholdsProvider),
      child: households.when(
        loading: () => AmLoadingView(message: strings.loading),
        error: (error, _) => AmFailureView(
          failure: error is Failure
              ? error
              : Failure.unexpected(detail: error.toString()),
          onRetry: () => ref.invalidate(assignedHouseholdsProvider),
        ),
        data: (list) => list.isEmpty
            ? AmEmptyView(
                message: strings.noResults,
                icon: Icons.home_work_outlined,
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AmTokens.spaceMd),
                itemCount: list.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AmTokens.spaceSm),
                itemBuilder: (context, index) =>
                    _HouseholdTile(household: list[index]),
              ),
      ),
    );
  }
}

class _HouseholdTile extends StatelessWidget {
  const _HouseholdTile({required this.household});

  final Household household;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(AmTokens.spaceMd),
        leading: const Icon(Icons.home_outlined, size: 32),
        title: Text(household.headOfHousehold ?? household.code),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(household.code, style: theme.textTheme.bodySmall),
            if (household.addressLine != null)
              Text(household.addressLine!, style: theme.textTheme.bodySmall),
            const SizedBox(height: AmTokens.spaceXs),
            Row(
              children: [
                const Icon(
                  Icons.people_outline,
                  size: 16,
                  color: AmTokens.textSecondary,
                ),
                const SizedBox(width: AmTokens.spaceXs),
                Text(
                  '${household.memberCount}',
                  style: theme.textTheme.bodySmall,
                ),
                // Surfaces a record that has not reached the server yet, so the
                // worker can see what is still queued (PRD 15).
                if (household.isPendingSync) ...[
                  const SizedBox(width: AmTokens.spaceMd),
                  const Icon(
                    Icons.cloud_upload_outlined,
                    size: 16,
                    color: AmTokens.warning,
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => HouseholdDetailScreen(household: household),
          ),
        ),
      ),
    );
  }
}
