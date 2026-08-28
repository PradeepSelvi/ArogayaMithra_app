import 'package:am_core/am_core.dart';
import 'package:am_models/am_models.dart';
import 'package:meta/meta.dart';

/// Where the user stands with respect to access.
enum AuthStage {
  /// Still resolving the stored session.
  resolving,

  /// No session.
  signedOut,

  /// Awaiting the one-time code for a phone sign-in.
  awaitingOtp,

  /// Signed in and the profile is loaded.
  signedIn,

  /// Signed in, but the account cannot be used yet. Covers a pending or
  /// suspended account and a staff role with no facility or district assigned.
  blocked,
}

/// Session plus resolved profile.
@immutable
class AmAuthState {
  const AmAuthState({
    required this.stage,
    this.profile,
    this.pendingPhone,
    this.failure,
  });

  const AmAuthState.resolving() : this(stage: AuthStage.resolving);
  const AmAuthState.signedOut({Failure? failure})
      : this(stage: AuthStage.signedOut, failure: failure);

  final AuthStage stage;
  final AppUser? profile;

  /// Phone number a code was sent to, so the verify screen can show it.
  final String? pendingPhone;

  final Failure? failure;

  bool get isSignedIn => stage == AuthStage.signedIn && profile != null;
  bool get isResolving => stage == AuthStage.resolving;

  UserRole? get role => profile?.role;

  /// Why the account is unusable, for the blocked screen.
  String? get blockedReasonKey {
    final user = profile;
    if (user == null) return null;
    if (!user.isActive) return 'error.account_not_active';
    if (!user.hasUsableScope) return 'error.profile_missing';
    return null;
  }

  AmAuthState copyWith({
    AuthStage? stage,
    AppUser? profile,
    String? pendingPhone,
    Failure? failure,
    bool clearFailure = false,
  }) =>
      AmAuthState(
        stage: stage ?? this.stage,
        profile: profile ?? this.profile,
        pendingPhone: pendingPhone ?? this.pendingPhone,
        failure: clearFailure ? null : (failure ?? this.failure),
      );
}
