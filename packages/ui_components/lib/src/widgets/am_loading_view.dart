import 'package:flutter/material.dart';

import '../theme/am_tokens.dart';

/// Full-area busy state with an explanation of what is happening.
class AmLoadingView extends StatelessWidget {
  const AmLoadingView({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AmTokens.spaceLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AmTokens.spaceLg),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
}

/// Empty state.
class AmEmptyView extends StatelessWidget {
  const AmEmptyView({
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
    super.key,
  });

  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AmTokens.spaceLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: AmTokens.border),
              const SizedBox(height: AmTokens.spaceMd),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (action != null) ...[
                const SizedBox(height: AmTokens.spaceLg),
                action!,
              ],
            ],
          ),
        ),
      );
}
