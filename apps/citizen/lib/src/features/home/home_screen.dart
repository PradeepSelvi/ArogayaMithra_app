import 'package:am_auth/am_auth.dart';
import 'package:am_localization/am_localization.dart';
import 'package:am_networking/am_networking.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../emergency/emergency_screen.dart';
import '../notifications/notification_screen.dart';
import '../onboarding/profile_setup_screen.dart';
import '../referrals/referral_list_screen.dart';
import '../triage/care_journey_controller.dart';
import '../triage/symptom_screen.dart';

/// Citizen home (PRD 5.1).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AmStrings.of(context);
    final profile = ref.watch(currentUserProvider);
    final patient = ref.watch(selfPatientProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.appName),
        actions: [
          const _NotificationBell(),
          IconButton(
            tooltip: strings.signOut,
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AmTokens.spaceMd),
          children: [
            Text(
              strings.homeGreeting(
                patient.valueOrNull?.fullName ?? profile?.fullName ?? '',
              ),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AmTokens.spaceLg),

            // Emergency sits first and alone. Someone in crisis should not have
            // to read past anything to reach it (PRD 5.1).
            AmBigButton.emergency(
              label: strings.homeEmergency,
              onPressed: () => _push(context, const EmergencyScreen()),
            ),
            const SizedBox(height: AmTokens.spaceLg),

            AmBigButton(
              label: strings.homeNeedCare,
              subtitle: strings.homeNeedCareHint,
              icon: Icons.medical_services_outlined,
              onPressed: () => _startCareJourney(context, ref),
            ),
            const SizedBox(height: AmTokens.spaceMd),

            AmBigButton(
              label: strings.homeMyReferrals,
              icon: Icons.assignment_outlined,
              onPressed: () => _push(context, const ReferralListScreen()),
            ),
            const SizedBox(height: AmTokens.spaceMd),

            AmBigButton(
              label: strings.homeNotifications,
              icon: Icons.notifications_none,
              onPressed: () => _push(context, const NotificationScreen()),
            ),
          ],
        ),
      ),
    );
  }

  /// Sends the user to profile setup first when there is no patient record yet,
  /// because triage cannot judge risk without age and pregnancy status.
  void _startCareJourney(BuildContext context, WidgetRef ref) {
    final patient = ref.read(selfPatientProvider).valueOrNull;
    ref.read(careJourneyProvider.notifier).reset();

    _push(
      context,
      patient == null ? const ProfileSetupScreen() : const SymptomScreen(),
    );
  }

  void _push(BuildContext context, Widget screen) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => screen),
      );
}

class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AmStrings.of(context);
    final userId = ref.watch(currentUserProvider)?.id;
    if (userId == null) return const SizedBox.shrink();

    final unread = ref.watch(unreadCountProvider);

    return IconButton(
      tooltip: strings.homeNotifications,
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const NotificationScreen()),
      ),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text('$unread'),
        child: const Icon(Icons.notifications_none),
      ),
    );
  }
}

/// Live unread count for the bell.
final unreadCountProvider = Provider<int>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return 0;

  final stream = ref.watch(unreadStreamProvider);
  return stream.valueOrNull ?? 0;
});

final unreadStreamProvider = StreamProvider<int>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return Stream.value(0);
  return ref.watch(engagementRepositoryProvider).watchUnreadCount(userId);
});
