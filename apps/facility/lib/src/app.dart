import 'package:am_auth/am_auth.dart';
import 'package:am_localization/am_localization.dart';
import 'package:am_models/am_models.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/staff_sign_in_screen.dart';
import 'features/shell/console_shell.dart';

/// Facility console for medical officers and facility administrators (PRD 5.3).
class FacilityConsoleApp extends ConsumerWidget {
  const FacilityConsoleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(currentLanguageProvider);

    return MaterialApp(
      onGenerateTitle: (context) => AmStrings.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: AmTheme.console(),
      locale: AmLocales.fromWire(language.wire),
      supportedLocales: AmLocales.supported,
      localizationsDelegates: AmLocales.delegates,
      home: AuthGate(
        allowedRoles: const {
          UserRole.medicalOfficer,
          UserRole.facilityAdmin,
        },
        resolving: (context) => Scaffold(
          body: AmLoadingView(message: AmStrings.of(context).loading),
        ),
        signedOut: (context) => const StaffSignInScreen(),
        signedIn: (context) => const ConsoleShell(),
        blocked: (context, reasonKey) => _BlockedScreen(reasonKey: reasonKey),
      ),
    );
  }
}

/// Shown when a staff account has no facility assigned or is not active.
///
/// This is a real operational case: an account is created before the posting is
/// finalised. An empty queue would look like "no referrals today", which is a
/// dangerous thing to imply.
class _BlockedScreen extends ConsumerWidget {
  const _BlockedScreen({required this.reasonKey});

  final String? reasonKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AmStrings.of(context);

    return Scaffold(
      body: AmContentFrame(
        maxWidth: 520,
        child: Padding(
          padding: const EdgeInsets.all(AmTokens.spaceLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.badge_outlined,
                size: 56,
                color: AmTokens.textSecondary,
              ),
              const SizedBox(height: AmTokens.spaceLg),
              Text(
                strings.failureMessage(reasonKey ?? 'error.profile_missing'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AmTokens.spaceLg),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
                icon: const Icon(Icons.logout),
                label: Text(strings.signOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
