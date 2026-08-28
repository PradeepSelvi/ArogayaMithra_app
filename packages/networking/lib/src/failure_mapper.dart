import 'dart:async';
import 'dart:io';

import 'package:am_core/am_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Translates transport and database errors into the app's failure taxonomy.
///
/// The domain rules live in Postgres and signal refusal through SQLSTATE codes.
/// Mapping them here is what lets the UI say "this facility already declined,
/// choose another" instead of leaking `check_violation` text to a citizen.
class FailureMapper {
  const FailureMapper();

  static const _sqlStateForbidden = '42501'; // insufficient_privilege
  static const _sqlStateCheckViolation = '23514'; // check_violation
  static const _sqlStateUniqueViolation = '23505';
  static const _sqlStateForeignKeyViolation = '23503';
  static const _sqlStateInvalidParameter = '22023'; // invalid_parameter_value
  static const _sqlStateNoData = 'P0002'; // no_data_found
  static const _sqlStateConfigLimit = '53400'; // configuration_limit_exceeded
  static const _sqlStateNotNull = '23502';

  Failure map(Object error, [StackTrace? stackTrace]) {
    if (error is Failure) return error;

    if (error is PostgrestException) return _mapPostgrest(error);
    if (error is AuthException) {
      return Failure(
        kind: FailureKind.unauthenticated,
        messageKey: 'error.sign_in_failed',
        detail: error.message,
        code: error.statusCode,
        cause: error,
      );
    }

    if (error is SocketException ||
        error is HttpException ||
        error is TimeoutException) {
      return Failure(
        kind: FailureKind.offline,
        messageKey: 'error.offline',
        detail: error.toString(),
        cause: error,
        isRetryable: true,
      );
    }

    if (error is StorageException) {
      return Failure(
        kind: FailureKind.integration,
        messageKey: 'error.storage',
        detail: error.message,
        cause: error,
        isRetryable: true,
      );
    }

    return Failure(
      kind: FailureKind.unexpected,
      messageKey: 'error.unexpected',
      detail: error.toString(),
      cause: error,
    );
  }

  Failure _mapPostgrest(PostgrestException error) {
    final code = error.code;

    // A row-level security denial surfaces as an empty result or a 42501. Both
    // mean "not permitted", never "does not exist", so the message must not
    // imply the record is absent.
    //
    // PostgrestException.code carries either a SQLSTATE or, for transport level
    // problems, the HTTP status as a string.
    if (code == _sqlStateForbidden || code == '403') {
      return Failure(
        kind: FailureKind.forbidden,
        messageKey: 'error.not_permitted',
        detail: error.message,
        code: code,
        cause: error,
      );
    }

    if (code == '401' || code == 'PGRST301') {
      return Failure(
        kind: FailureKind.unauthenticated,
        messageKey: 'error.session_expired',
        detail: error.message,
        code: code,
        cause: error,
      );
    }

    if (code == _sqlStateCheckViolation) {
      // Raised by the referral state machine and the readiness override guard.
      return Failure(
        kind: FailureKind.domainRule,
        messageKey: _domainRuleKey(error.message),
        detail: error.message,
        code: code,
        cause: error,
      );
    }

    if (code == _sqlStateInvalidParameter || code == _sqlStateNotNull) {
      return Failure(
        kind: FailureKind.invalidInput,
        messageKey: 'error.invalid_input',
        detail: error.message,
        code: code,
        cause: error,
      );
    }

    if (code == _sqlStateNoData) {
      return Failure(
        kind: FailureKind.notFound,
        messageKey: 'error.not_found',
        detail: error.message,
        code: code,
        cause: error,
      );
    }

    if (code == _sqlStateUniqueViolation) {
      return Failure(
        kind: FailureKind.domainRule,
        messageKey: 'error.already_exists',
        detail: error.message,
        code: code,
        cause: error,
      );
    }

    if (code == _sqlStateForeignKeyViolation) {
      return Failure(
        kind: FailureKind.invalidInput,
        messageKey: 'error.related_record_missing',
        detail: error.message,
        code: code,
        cause: error,
      );
    }

    if (code == _sqlStateConfigLimit) {
      // No active triage rule set. This is a deployment fault, not user error,
      // and must be visible rather than silently degrading triage.
      return Failure(
        kind: FailureKind.unexpected,
        messageKey: 'error.triage_unavailable',
        detail: error.message,
        code: code,
        cause: error,
      );
    }

    return Failure(
      kind: FailureKind.unexpected,
      messageKey: 'error.unexpected',
      detail: error.message,
      code: code,
      cause: error,
    );
  }

  /// Picks a specific message for the domain guards the user can act on.
  String _domainRuleKey(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('illegal referral transition')) {
      return 'error.referral_transition_illegal';
    }
    if (lower.contains('requires a reason')) {
      return 'error.reason_required';
    }
    if (lower.contains('not operational')) {
      return 'error.facility_not_operational';
    }
    if (lower.contains('override')) {
      return 'error.override_reason_required';
    }
    return 'error.action_not_allowed';
  }
}

/// Runs [body] and converts any thrown error into a [Failure].
Future<Result<T>> guard<T>(
  Future<T> Function() body, {
  FailureMapper mapper = const FailureMapper(),
}) async {
  try {
    return Success(await body());
  } catch (error, stackTrace) {
    return Err(mapper.map(error, stackTrace));
  }
}
