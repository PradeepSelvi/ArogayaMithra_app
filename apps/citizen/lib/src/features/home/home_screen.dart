import 'package:am_auth/am_auth.dart';
import 'package:am_localization/am_localization.dart';
import 'package:am_networking/am_networking.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../emergency/ambulance_tracker_screen.dart';
import '../facilities/facility_map_screen.dart';
import '../family/family_manager_modal.dart';
import '../language/locale_controller.dart';
import '../medications/medication_manager_screen.dart';
import '../notifications/notification_screen.dart';
import '../onboarding/profile_setup_screen.dart';
import '../profile/profile_screen.dart';
import '../records/lab_vault_screen.dart';
import '../referrals/referral_list_screen.dart';
import '../triage/care_journey_controller.dart';
import '../triage/symptom_screen.dart';
import '../vitals/vitals_tracker_screen.dart';

/// Main Citizen Home with Bottom Navigation and rich healthcare modules.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeControllerProvider);
    final isTamil = locale?.languageCode == 'ta';

    return Scaffold(
      body: switch (_currentIndex) {
        0 => _HomeDashboardView(
            onNavigateToTab: (index) => setState(() => _currentIndex = index),
          ),
        1 => const FacilityMapScreen(),
        2 => const ReferralListScreen(),
        3 => const ProfileScreen(),
        _ => _HomeDashboardView(
            onNavigateToTab: (index) => setState(() => _currentIndex = index),
          ),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: isTamil ? 'முகப்பு' : 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map),
            label: isTamil ? 'வரைபடம் & இடம்' : 'Map & Facilities',
          ),
          NavigationDestination(
            icon: const Icon(Icons.assignment_outlined),
            selectedIcon: const Icon(Icons.assignment),
            label: isTamil ? 'பரிந்துரைகள்' : 'Referrals',
          ),
          NavigationDestination(
            icon: const Icon(Icons.badge_outlined),
            selectedIcon: const Icon(Icons.badge),
            label: isTamil ? 'சுயவிவரம்' : 'Profile',
          ),
        ],
      ),
    );
  }
}

/// Primary Dashboard View inside Tab 0.
class _HomeDashboardView extends ConsumerWidget {
  const _HomeDashboardView({required this.onNavigateToTab});

  final void Function(int) onNavigateToTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AmStrings.of(context);
    final theme = Theme.of(context);
    final profile = ref.watch(currentUserProvider);
    final patient = ref.watch(selfPatientProvider);
    final locale = ref.watch(localeControllerProvider);
    final isTamil = locale?.languageCode == 'ta';
    final activeMember = ref.watch(currentFamilyMemberProvider);
    final isSelf = activeMember.id == 'fam-self';
    final patientName = isSelf ? (patient.valueOrNull?.fullName ?? profile?.fullName ?? 'Meena Ravi') : activeMember.fullName;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AmTokens.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.health_and_safety, color: AmTokens.primary, size: 24),
            ),
            const SizedBox(width: 8),
            Text(
              strings.appName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          const _LanguageToggle(),
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
            // Welcome Header Card
            Container(
              padding: const EdgeInsets.all(AmTokens.spaceMd),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AmTokens.radiusLarge),
                border: Border.all(color: AmTokens.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AmTokens.primaryLight,
                    child: Text(
                      patientName.isNotEmpty ? patientName[0].toUpperCase() : 'M',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AmTokens.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTamil ? 'வணக்கம், $patientName' : 'Welcome, $patientName',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isSelf
                              ? (isTamil ? 'திருவண்ணாமலை மாவட்டம் • ABHA இணைக்கப்பட்டது' : 'Tiruvannamalai District • ABHA Linked')
                              : (isTamil ? 'குடும்ப உறுப்பினர் (${activeMember.relation}, ${activeMember.age} வயது)' : 'Family Dependent (${activeMember.relation}, ${activeMember.age} Yrs)'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AmTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => onNavigateToTab(3),
                    icon: const Icon(Icons.qr_code, size: 20),
                    tooltip: isTamil ? 'மருத்துவ அட்டை' : 'View Health Pass',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AmTokens.spaceMd),

            // Household & Family Members Switcher
            FamilyMemberSwitcher(isTamil: isTamil),
            const SizedBox(height: AmTokens.spaceMd),

            // Emergency Care & Live 108 Ambulance Dispatch Banner
            Card(
              elevation: 0,
              color: Colors.red.shade50,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(AmTokens.radiusLarge),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AmTokens.spaceMd),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.emergency_outlined, color: Colors.red.shade800, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.homeEmergency,
                            style: TextStyle(
                              color: Colors.red.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isTamil
                                ? 'உடனடி 108 ஆம்புலன்ஸ் & நேரலை கண்காணிப்பு'
                                : 'Immediate 108 ambulance & live dispatch',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        minimumSize: const Size(60, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: () => _push(context, const AmbulanceTrackerScreen()),
                      child: Text(isTamil ? '108 நேரலை' : 'Track 108'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AmTokens.spaceLg),

            // Vitals & Chronic Metric Quick Banner
            Container(
              padding: const EdgeInsets.all(AmTokens.spaceMd),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AmTokens.radiusLarge),
                border: Border.all(color: AmTokens.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.monitor_heart_outlined, color: AmTokens.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isTamil ? 'சமீபத்திய உடல் அளவீடுகள்' : 'Daily Health Vitals',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => _push(context, const VitalsTrackerScreen()),
                        child: Text(isTamil ? 'அளவீடு பதிவு +' : 'Log & Track +'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(AmTokens.radiusSmall),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isTamil ? 'இரத்த அழுத்தம் (BP)' : 'Blood Pressure', style: const TextStyle(fontSize: 10, color: Colors.teal)),
                              const SizedBox(height: 2),
                              const Text('118 / 78', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)),
                              const Text('mmHg • Normal', style: TextStyle(fontSize: 10, color: Colors.teal)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(AmTokens.radiusSmall),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isTamil ? 'சர்க்கரை அளவு' : 'Blood Glucose', style: const TextStyle(fontSize: 10, color: Colors.indigo)),
                              const SizedBox(height: 2),
                              const Text('104 mg/dL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
                              const Text('Fasting • Normal', style: TextStyle(fontSize: 10, color: Colors.indigo)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade50,
                            borderRadius: BorderRadius.circular(AmTokens.radiusSmall),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isTamil ? 'துடிப்பு & SpO2' : 'Pulse & SpO2', style: const TextStyle(fontSize: 10, color: Colors.deepPurple)),
                              const SizedBox(height: 2),
                              const Text('72 bpm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepPurple)),
                              const Text('99% Saturation', style: TextStyle(fontSize: 10, color: Colors.deepPurple)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AmTokens.spaceLg),

            // Care Services (6 Modules in clean 2-column Rows)
            Text(
              isTamil ? 'மருத்துவ சேவைகள்' : 'Healthcare Services & Vault',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AmTokens.spaceSm),
            Row(
              children: [
                Expanded(
                  child: _QuickCard(
                    title: isTamil ? 'சிகிச்சை தொடங்கு' : 'Check Symptoms',
                    subtitle: isTamil ? 'அறிவுரை & வழிமுறை' : 'Triage Assessment',
                    icon: Icons.medical_services_outlined,
                    color: AmTokens.primary,
                    onTap: () => _startCareJourney(context, ref),
                  ),
                ),
                const SizedBox(width: AmTokens.spaceMd),
                Expanded(
                  child: _QuickCard(
                    title: isTamil ? 'மருத்துவமனைகள்' : 'Find Hospitals',
                    subtitle: isTamil ? 'வரைபடம் & தூரம்' : 'Nearby with Map',
                    icon: Icons.location_on_outlined,
                    color: Colors.indigo,
                    onTap: () => onNavigateToTab(1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AmTokens.spaceMd),
            Row(
              children: [
                Expanded(
                  child: _QuickCard(
                    title: isTamil ? 'பரிசோதனை முடிவுகள்' : 'Lab Diagnostic Vault',
                    subtitle: isTamil ? 'அறிக்கைகள் & CBC' : 'ABDM Health Records',
                    icon: Icons.folder_shared_outlined,
                    color: Colors.blue.shade800,
                    onTap: () => _push(context, const LabVaultScreen()),
                  ),
                ),
                const SizedBox(width: AmTokens.spaceMd),
                Expanded(
                  child: _QuickCard(
                    title: isTamil ? 'மருந்து அட்டவணை' : 'My Prescriptions',
                    subtitle: isTamil ? 'மாத்திரை நினைவூட்டல்' : 'Daily Dose Reminders',
                    icon: Icons.medication_outlined,
                    color: Colors.deepOrange.shade800,
                    onTap: () => _push(context, const MedicationManagerScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AmTokens.spaceMd),
            Row(
              children: [
                Expanded(
                  child: _QuickCard(
                    title: isTamil ? 'என் பரிந்துரைகள்' : 'My Referrals',
                    subtitle: isTamil ? 'நிலை & பின்தொடர்தல்' : 'Status & Visits',
                    icon: Icons.assignment_outlined,
                    color: Colors.teal.shade700,
                    onTap: () => onNavigateToTab(2),
                  ),
                ),
                const SizedBox(width: AmTokens.spaceMd),
                Expanded(
                  child: _QuickCard(
                    title: isTamil ? 'சுகாதார அட்டை' : 'Digital Health Pass',
                    subtitle: isTamil ? 'ABHA & சுயவிவரம்' : 'ID & Records',
                    icon: Icons.badge_outlined,
                    color: Colors.deepPurple,
                    onTap: () => onNavigateToTab(3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AmTokens.spaceLg),

            // Public Health Advisory Banner
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: AmTokens.border),
                borderRadius: BorderRadius.circular(AmTokens.radiusLarge),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AmTokens.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: AmTokens.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isTamil ? 'சுகாதார ஆலோசனை' : 'Public Health Advisory',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isTamil
                          ? 'பருவகால காய்ச்சல் மற்றும் டெங்கு தடுப்பு வழிகாட்டுதல்கள். கொசுக்கள் உற்பத்தியாகாமல் தடுக்க சுற்றுப்புறத்தை தூய்மையாக வைத்திருக்கவும்.'
                          : 'Monsoon fever surveillance is active across Tiruvannamalai block. Visit your nearest PHC for free testing and care.',
                      style: theme.textTheme.bodySmall?.copyWith(color: AmTokens.textSecondary),
                    ),
                    const SizedBox(height: AmTokens.spaceSm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => onNavigateToTab(1),
                        child: Text(isTamil ? 'அருகிலுள்ள PHC காண்க' : 'Locate Nearest PHC'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AmTokens.spaceXl),
          ],
        ),
      ),
    );
  }

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

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AmTokens.radiusLarge),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AmTokens.radiusLarge),
            border: Border.all(color: AmTokens.border),
          ),
          padding: const EdgeInsets.all(AmTokens.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(AmTokens.radiusMedium),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AmTokens.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
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

class _LanguageToggle extends ConsumerWidget {
  const _LanguageToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final isTamil = locale?.languageCode == 'ta';

    return TextButton.icon(
      onPressed: () {
        final next = isTamil ? AmLocales.english : AmLocales.tamil;
        ref.read(localeControllerProvider.notifier).choose(next);
      },
      icon: const Icon(Icons.translate, size: 18),
      label: Text(
        isTamil ? 'English' : 'தமிழ்',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
