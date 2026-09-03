import 'package:am_models/am_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth_providers.dart';
import '../auth_state.dart';

/// Routes between the sign-in flow and the app based on session state.
///
/// The blocked branch is deliberate. A staff account with no facility assigned,
/// or an account an administrator has suspended, gets a clear explanation rather
/// than an empty console that looks broken.
class AuthGate extends ConsumerWidget {
  const AuthGate({
    required this.resolving,
    required this.signedOut,
    required this.signedIn,
    required this.blocked,
    this.allowedRoles,
    super.key,
  });

  final WidgetBuilder resolving;
  final WidgetBuilder signedOut;
  final WidgetBuilder signedIn;

  /// Receives the reason key so the screen can explain the problem.
  final Widget Function(BuildContext context, String? reasonKey) blocked;

  /// Roles permitted into this application. If non-null and the signed-in user's
  /// role is not in this set, [blocked] is shown with 'error.forbidden'.
  final Set<UserRole>? allowedRoles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    return switch (auth.stage) {
      AuthStage.resolving => resolving(context),
      AuthStage.signedOut || AuthStage.awaitingOtp => signedOut(context),
      AuthStage.signedIn => _buildSignedIn(context, auth),
      AuthStage.blocked => blocked(
          context,
          auth.blockedReasonKey ?? auth.failure?.messageKey,
        ),
    };
  }

  Widget _buildSignedIn(BuildContext context, AmAuthState auth) {
    if (allowedRoles != null && auth.profile != null) {
      if (!allowedRoles!.contains(auth.profile!.role)) {
        return blocked(context, 'error.forbidden');
      }
    }
    return signedIn(context);
  }
}
