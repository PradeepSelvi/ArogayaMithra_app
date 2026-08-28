import 'package:am_auth/am_auth.dart';
import 'package:am_localization/am_localization.dart';
import 'package:am_ui/am_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shown when a session exists but the account cannot be used.
///
/// Explaining the block beats dropping the user into an empty app: they can act
/// on "contact your administrator", but not on a blank screen.
class BlockedScreen extends ConsumerWidget {
  const BlockedScreen({required this.reasonKey, super.key});

  final String? reasonKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AmStrings.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AmTokens.spaceLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 64,
                color: AmTokens.textSecondary,
              ),
              const SizedBox(height: AmTokens.spaceLg),
              Text(
                strings.failureMessage(reasonKey ?? 'error.profile_missing'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AmTokens.spaceXl),
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
