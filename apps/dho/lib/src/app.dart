import 'package:am_auth/am_auth.dart';
import 'package:am_localization/am_localization.dart';
import 'package:am_models/am_models.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/oversight_sign_in_screen.dart';
import 'features/dashboard/dashboard_screen.dart';

/// District and state oversight dashboard (PRD 5.4).
class DhoDashboardApp extends ConsumerWidget {
  const DhoDashboardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(currentLanguageProvider);

    return MaterialApp(
      onGenerateTitle: (context) => AmStrings.of(context).dashboardTitle,
      debugShowCheckedModeBanner: false,
      theme: AmTheme.console(),
      locale: AmLocales.fromWire(language.wire),
      supportedLocales: AmLocales.supported,
      localizationsDelegates: AmLocales.delegates,
      home: AuthGate(
        allowedRoles: const {
          UserRole.dho,
          UserRole.stateAdmin,
          UserRole.systemAdmin,
        },
        resolving: (context) => Scaffold(
          body: AmLoadingView(message: AmStrings.of(context).loading),
        ),
        signedOut: (context) => const OversightSignInScreen(),
        signedIn: (context) => const DashboardScreen(),
        blocked: (context, reasonKey) => Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(AmTokens.spaceLg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AmStrings.of(context)
                        .failureMessage(reasonKey ?? 'error.profile_missing'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AmTokens.spaceLg),
                  OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).signOut(),
                    icon: const Icon(Icons.logout),
                    label: Text(AmStrings.of(context).signOut),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
