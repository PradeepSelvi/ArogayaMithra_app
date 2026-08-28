import 'package:am_auth/am_auth.dart';
import 'package:am_localization/am_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../followups/followup_queue_screen.dart';
import '../households/household_list_screen.dart';

/// Field app frame: assigned households and the follow-up queue (PRD 5.2).
class FieldShell extends ConsumerStatefulWidget {
  const FieldShell({super.key});

  @override
  ConsumerState<FieldShell> createState() => _FieldShellState();
}

class _FieldShellState extends ConsumerState<FieldShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final strings = AmStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.appName),
        actions: [
          IconButton(
            tooltip: strings.signOut,
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: switch (_index) {
        0 => const HouseholdListScreen(),
        _ => const FollowUpQueueScreen(),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_work_outlined),
            label: strings.homeProfile,
          ),
          NavigationDestination(
            icon: const Icon(Icons.event_available_outlined),
            label: strings.followUpsTitle,
          ),
        ],
      ),
    );
  }
}
