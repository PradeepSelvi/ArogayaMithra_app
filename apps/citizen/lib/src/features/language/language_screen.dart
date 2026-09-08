import 'package:am_localization/am_localization.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'locale_controller.dart';

/// First screen: language choice (PRD 5.1, FR-003).
///
/// Each option is written in its own script, so it is legible to the person who
/// needs it without depending on the current app language.
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AmTokens.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AmTokens.spaceXl),
              Icon(
                Icons.health_and_safety_outlined,
                size: 72,
                color: AmTokens.primary,
              ),
              const SizedBox(height: AmTokens.spaceMd),
              Text(
                'ஆரோக்யமித்ரா',
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall,
              ),
              Text(
                'ArogyaMitra',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: AmTokens.textSecondary),
              ),
              const SizedBox(height: AmTokens.spaceXl),
              Text(
                'உங்கள் மொழியைத் தேர்ந்தெடுக்கவும்',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              Text(
                'Choose your language',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AmTokens.spaceLg),
              AmBigButton(
                label: 'தமிழ்',
                icon: Icons.translate,
                onPressed: () => ref
                    .read(localeControllerProvider.notifier)
                    .choose(AmLocales.tamil),
              ),
              const SizedBox(height: AmTokens.spaceMd),
              AmBigButton(
                label: 'English',
                icon: Icons.translate,
                onPressed: () => ref
                    .read(localeControllerProvider.notifier)
                    .choose(AmLocales.english),
              ),
              const SizedBox(height: AmTokens.spaceMd),
              AmBigButton(
                label: 'हिन्दी',
                icon: Icons.translate,
                onPressed: () => ref
                    .read(localeControllerProvider.notifier)
                    .choose(AmLocales.hindi),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

