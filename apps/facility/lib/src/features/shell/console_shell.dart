import 'package:am_auth/am_auth.dart';
import 'package:am_localization/am_localization.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../queue/referral_queue_screen.dart';
import '../readiness/readiness_screen.dart';

/// Console frame with the two things a medical officer does: work the incoming
/// referral queue and keep readiness honest (PRD 5.3).
class ConsoleShell extends ConsumerStatefulWidget {
  const ConsoleShell({super.key});

  @override
  ConsumerState<ConsoleShell> createState() => _ConsoleShellState();
}

class _ConsoleShellState extends ConsumerState<ConsoleShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final strings = AmStrings.of(context);
    final profile = ref.watch(currentUserProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    final destinations = <({IconData icon, String label})>[
      (icon: Icons.inbox_outlined, label: strings.consoleQueueTitle),
      (icon: Icons.inventory_2_outlined, label: strings.consoleReadinessTitle),
    ];

    final body = switch (_index) {
      0 => const ReferralQueueScreen(),
      _ => const ReadinessScreen(),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.appName),
        actions: [
          if (profile?.fullName != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AmTokens.spaceSm,
              ),
              child: Center(
                child: Text(
                  profile!.fullName!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          IconButton(
            tooltip: strings.signOut,
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (value) =>
                      setState(() => _index = value),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final destination in destinations)
                      NavigationRailDestination(
                        icon: Icon(destination.icon),
                        label: Text(destination.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              destinations: [
                for (final destination in destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    label: destination.label,
                  ),
              ],
            ),
    );
  }
}
