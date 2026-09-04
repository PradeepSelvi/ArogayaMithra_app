import 'dart:async';

import 'package:am_core/am_core.dart';
import 'package:am_models/am_models.dart';
import 'package:am_networking/am_networking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_state.dart';

/// Owns the session and the resolved profile.
class AuthController extends Notifier<AmAuthState> {
  StreamSubscription<AuthState>? _subscription;
  final _mapper = const FailureMapper();

  @override
  AmAuthState build() {
    final client = ref.watch(supabaseClientProvider);

    _subscription = client.auth.onAuthStateChange.listen(_onAuthEvent);
    ref.onDispose(() => _subscription?.cancel());

    // A persisted session is restored synchronously by supabase_flutter, so a
    // returning field worker is signed in before the first frame.
    if (client.auth.currentSession != null) {
      Future.microtask(refreshProfile);
      return const AmAuthState.resolving();
    }

    return const AmAuthState.signedOut();
  }

  SupabaseClient get _client => ref.read(supabaseClientProvider);
  PeopleRepository get _people => ref.read(peopleRepositoryProvider);

  void _onAuthEvent(AuthState event) {
    switch (event.event) {
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.tokenRefreshed:
      case AuthChangeEvent.userUpdated:
        unawaited(refreshProfile());
      case AuthChangeEvent.signedOut:
        state = const AmAuthState.signedOut();
      default:
        break;
    }
  }

  /// Loads the profile and decides whether the account is usable.
  Future<void> refreshProfile() async {
    if (_client.auth.currentSession == null) {
      state = const AmAuthState.signedOut();
      return;
    }

    final result = await _people.currentUser();

    state = result.fold(
      onSuccess: (user) {
        // An inactive account or a staff role with no scope is a blocked state,
        // not a signed-in one. Letting them through would show an empty console
        // and hide the real problem from the user (PRD 4).
        if (!user.isActive || !user.hasUsableScope) {
          return AmAuthState(stage: AuthStage.blocked, profile: user);
        }
        return AmAuthState(stage: AuthStage.signedIn, profile: user);
      },
      onFailure: (failure) => AmAuthState(
        stage: AuthStage.blocked,
        failure: failure,
      ),
    );
  }

  /// Sends a one-time code to a mobile number (citizen path).
  Future<Result<void>> requestPhoneCode(String phone) async {
    final normalised = _normalisePhone(phone);
    if (normalised == null) {
      const failure = Failure(
        kind: FailureKind.invalidInput,
        messageKey: 'error.invalid_input',
        detail: 'Phone number must be 10 digits.',
      );
      state = state.copyWith(failure: failure);
      return const Err(failure);
    }

    state = state.copyWith(clearFailure: true);

    try {
      await _client.auth.signInWithOtp(phone: normalised);
      state = AmAuthState(
        stage: AuthStage.awaitingOtp,
        pendingPhone: normalised,
      );
      return const Success(null);
    } catch (error, stackTrace) {
      final failure = _mapper.map(error, stackTrace);
      state = state.copyWith(failure: failure);
      return Err(failure);
    }
  }

  /// Verifies the code and establishes the session.
  Future<Result<void>> verifyPhoneCode(String code) async {
    final phone = state.pendingPhone;
    if (phone == null) {
      return const Err(Failure.unauthenticated());
    }

    try {
      await _client.auth.verifyOTP(
        phone: phone,
        token: code.trim(),
        type: OtpType.sms,
      );
      await refreshProfile();
      return const Success(null);
    } catch (error, stackTrace) {
      final failure = _mapper.map(error, stackTrace);
      state = state.copyWith(failure: failure);
      return Err(failure);
    }
  }

  /// Staff sign-in with a provisioned account.
  Future<Result<void>> signInWithPassword({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(clearFailure: true);

    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      await refreshProfile();
      return const Success(null);
    } catch (error, stackTrace) {
      final failure = _mapper.map(error, stackTrace);
      state = state.copyWith(failure: failure);
      return Err(failure);
    }
  }

  /// One-tap instant sign-in for the primary demo citizen (Meena Ravi, 9876500002).
  ///
  /// Only usable against a local build: the phone number and OTP are the
  /// well-known local seed credentials, so this must never be reachable from
  /// a staging or production binary even if a UI ends up calling it.
  Future<Result<void>> signInDemoCitizen() async {
    if (!ref.read(appEnvironmentProvider).isLocal) {
      const failure = Failure(
        kind: FailureKind.forbidden,
        messageKey: 'error.forbidden',
        detail: 'Demo sign-in is only available on local builds.',
      );
      state = state.copyWith(failure: failure);
      return const Err(failure);
    }

    state = state.copyWith(clearFailure: true);
    try {
      await _client.auth.signInWithOtp(phone: '+919876500002');
      await _client.auth.verifyOTP(
        phone: '+919876500002',
        token: '123456',
        type: OtpType.sms,
      );
      await refreshProfile();
      return const Success(null);
    } catch (error, stackTrace) {
      final failure = _mapper.map(error, stackTrace);
      state = state.copyWith(failure: failure);
      return Err(failure);
    }
  }

  /// Signs out and clears cached reference data.
  ///
  /// PRD 15 requires a logout to invalidate access and protect local data, so
  /// caches are dropped rather than left for the next user of the device.
  Future<void> signOut() async {
    ref.read(catalogRepositoryProvider).invalidate();
    try {
      await _client.auth.signOut();
    } finally {
      state = const AmAuthState.signedOut();
    }
  }

  /// Persists a language choice on the profile.
  Future<void> setPreferredLanguage(LanguageCode language) async {
    final result = await _people.updatePreferredLanguage(language);
    result.fold(
      onSuccess: (user) => state = state.copyWith(profile: user),
      onFailure: (failure) => state = state.copyWith(failure: failure),
    );
  }

  /// Accepts `9876500001`, `+919876500001` and `919876500001`.
  String? _normalisePhone(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');

    return switch (digits.length) {
      10 => '+91$digits',
      12 when digits.startsWith('91') => '+$digits',
      _ => null,
    };
  }
}
