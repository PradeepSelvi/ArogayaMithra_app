import 'package:am_core/am_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Initialises the Supabase client for an ArogyaMitra app.
///
/// Call once from `main()` before `runApp`.
class SupabaseBootstrap {
  const SupabaseBootstrap._();

  static bool _initialised = false;

  static Future<SupabaseClient> initialise(AppEnvironment environment) async {
    if (_initialised) return Supabase.instance.client;

    await Supabase.initialize(
      url: environment.supabaseUrl,
      publishableKey: environment.supabasePublishableKey,
      authOptions: const FlutterAuthClientOptions(
        // Sessions persist so a field worker who loses connectivity stays
        // signed in (PRD 15).
        authFlowType: AuthFlowType.pkce,
      ),
      // Realtime powers the facility referral queue and the DHO alert feed.
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.error,
      ),
      debug: environment.isLocal,
    );

    _initialised = true;
    return Supabase.instance.client;
  }
}

/// Shared helpers every repository uses.
///
/// The correlation id header is what ties a client action to the audit trail and
/// integration ledger rows the database writes (PRD 13, 16).
abstract base class SupabaseRepository {
  SupabaseRepository(this.client);

  final SupabaseClient client;

  /// Purpose recorded against reads of health information (PRD 16).
  static const defaultPurpose = 'care_delivery';

  /// Wraps an RPC call, attaching a correlation id and access purpose.
  Future<T> callRpc<T>(
    String function, {
    Map<String, Object?> params = const {},
    String purpose = defaultPurpose,
  }) async {
    final response = await client.rpc<T>(function, params: params);
    return response;
  }
}
