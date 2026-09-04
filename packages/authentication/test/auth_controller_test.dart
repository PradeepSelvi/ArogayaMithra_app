import 'package:am_auth/am_auth.dart';
import 'package:am_core/am_core.dart';
import 'package:am_networking/am_networking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late _MockSupabaseClient client;
  late _MockGoTrueClient auth;

  setUpAll(() {
    registerFallbackValue(OtpType.sms);
  });

  setUp(() {
    client = _MockSupabaseClient();
    auth = _MockGoTrueClient();
    when(() => client.auth).thenReturn(auth);
    when(() => auth.currentSession).thenReturn(null);
    when(() => auth.onAuthStateChange).thenAnswer((_) => const Stream.empty());
  });

  AppEnvironment environmentFor(DeploymentTarget target) => AppEnvironment(
        supabaseUrl: 'https://example.supabase.co',
        supabasePublishableKey: 'not-a-real-key',
        target: target,
      );

  test('signInDemoCitizen is refused outside a local build', () async {
    final container = ProviderContainer(overrides: [
      appEnvironmentProvider.overrideWithValue(environmentFor(DeploymentTarget.staging)),
      supabaseClientProvider.overrideWithValue(client),
    ]);
    addTearDown(container.dispose);

    final result =
        await container.read(authControllerProvider.notifier).signInDemoCitizen();

    expect(result, isA<Err<void>>());
    expect((result as Err<void>).failure.kind, FailureKind.forbidden);
    verifyNever(() => auth.signInWithOtp(phone: any(named: 'phone')));
  });

  test('signInDemoCitizen attempts sign-in on a local build', () async {
    when(() => auth.signInWithOtp(phone: any(named: 'phone')))
        .thenAnswer((_) async {});
    when(
      () => auth.verifyOTP(
        phone: any(named: 'phone'),
        token: any(named: 'token'),
        type: any(named: 'type'),
      ),
    ).thenThrow(const AuthException('network unreachable in test'));

    final container = ProviderContainer(overrides: [
      appEnvironmentProvider.overrideWithValue(environmentFor(DeploymentTarget.local)),
      supabaseClientProvider.overrideWithValue(client),
    ]);
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).signInDemoCitizen();

    verify(() => auth.signInWithOtp(phone: '+919876500002')).called(1);
  });
}
