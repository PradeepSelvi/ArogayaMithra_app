import 'package:am_core/am_core.dart';
import 'package:am_localization/am_localization.dart';
import 'package:flutter/material.dart';

import '../theme/am_tokens.dart';
import 'am_banner.dart';

/// Renders a [Failure] for the user.
///
/// Only the localised message is shown. [Failure.detail] carries raw Postgres or
/// transport text and is deliberately withheld from citizens; consoles can opt
/// in with [showTechnicalDetail] for staff troubleshooting.
class AmFailureView extends StatelessWidget {
  const AmFailureView({
    required this.failure,
    this.onRetry,
    this.showTechnicalDetail = false,
    super.key,
  });

  final Failure failure;
  final VoidCallback? onRetry;
  final bool showTechnicalDetail;

  @override
  Widget build(BuildContext context) {
    final strings = AmStrings.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AmTokens.spaceLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 56, color: _tone),
            const SizedBox(height: AmTokens.spaceMd),
            Text(
              strings.failureMessage(failure.messageKey),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            if (showTechnicalDetail && failure.detail != null) ...[
              const SizedBox(height: AmTokens.spaceMd),
              Text(
                failure.detail!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (onRetry != null && _isRetryable) ...[
              const SizedBox(height: AmTokens.spaceLg),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(strings.actionRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// A permission denial is never retryable: pressing the button again cannot
  /// change the outcome and implying otherwise wastes the user's time.
  bool get _isRetryable => switch (failure.kind) {
        FailureKind.forbidden ||
        FailureKind.unauthenticated ||
        FailureKind.notFound ||
        FailureKind.domainRule =>
          false,
        _ => true,
      };

  Color get _tone => switch (failure.kind) {
        FailureKind.offline => AmTokens.warning,
        FailureKind.forbidden || FailureKind.unauthenticated => AmTokens.info,
        _ => AmTokens.emergency,
      };

  IconData get _icon => switch (failure.kind) {
        FailureKind.offline => Icons.cloud_off,
        FailureKind.forbidden => Icons.lock_outline,
        FailureKind.unauthenticated => Icons.login,
        FailureKind.notFound => Icons.search_off,
        FailureKind.domainRule => Icons.rule,
        FailureKind.integration => Icons.link_off,
        _ => Icons.error_outline,
      };
}

/// Inline variant for use inside a form or a list.
class AmFailureBanner extends StatelessWidget {
  const AmFailureBanner({required this.failure, this.onRetry, super.key});

  final Failure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AmStrings.of(context);

    return AmBanner(
      message: strings.failureMessage(failure.messageKey),
      tone: failure.kind == FailureKind.offline
          ? AmBannerTone.warning
          : AmBannerTone.emergency,
      icon: failure.kind == FailureKind.offline
          ? Icons.cloud_off
          : Icons.error_outline,
      action: onRetry == null
          ? null
          : TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(strings.actionRetry),
            ),
    );
  }
}

/// Shows a failure as a snack bar, for actions that do not replace the screen.
void showAmFailureSnackBar(BuildContext context, Failure failure) {
  final strings = AmStrings.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(strings.failureMessage(failure.messageKey))),
  );
}
