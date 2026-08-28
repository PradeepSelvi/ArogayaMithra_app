import 'package:am_auth/am_auth.dart';
import 'package:am_localization/am_localization.dart';
import 'package:am_models/am_models.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/blocked_screen.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/home/home_screen.dart';
import 'features/language/language_screen.dart';
import 'features/language/locale_controller.dart';

/// Citizen application root (PRD 5.1).
class CitizenApp extends ConsumerWidget {
  const CitizenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);

    return MaterialApp(
      onGenerateTitle: (context) => AmStrings.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: AmTheme.mobile(),
      locale: locale,
      supportedLocales: AmLocales.supported,
      localizationsDelegates: AmLocales.delegates,
      home: const _CitizenEntry(),
    );
  }
}

class _CitizenEntry extends ConsumerWidget {
  const _CitizenEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasChosenLanguage = ref.watch(hasChosenLanguageProvider);

    // Language comes before anything else. Asking someone to read a sign-in
    // screen in a language they do not use is the first place the platform can
    // lose them (PRD 5.1).
    if (!hasChosenLanguage) {
      return const LanguageScreen();
    }

    return AuthGate(
      resolving: (context) => Scaffold(
        body: AmLoadingView(message: AmStrings.of(context).loading),
      ),
      signedOut: (context) => const SignInScreen(),
      signedIn: (context) => const HomeScreen(),
      blocked: (context, reasonKey) => BlockedScreen(reasonKey: reasonKey),
    );
  }
}

/// Language currently in use, as a wire value for records the app writes.
final activeLanguageProvider = Provider<LanguageCode>((ref) {
  final locale = ref.watch(localeControllerProvider);
  return LanguageCode.tryParse(AmLocales.toWire(locale ?? AmLocales.tamil)) ??
      LanguageCode.tamil;
});
