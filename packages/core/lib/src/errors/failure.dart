import 'package:meta/meta.dart';

/// Categories of failure the UI needs to distinguish.
///
/// The database raises specific SQLSTATE codes for domain rule violations
/// (illegal referral transition, missing reason, insufficient role), so the
/// data layer can map them onto these categories instead of showing raw
/// Postgres text to a citizen.
enum FailureKind {
  /// Not signed in, or the session expired.
  unauthenticated,

  /// Signed in but not permitted. Covers RLS denials and role gates.
  forbidden,

  /// Input rejected by validation or a domain guard.
  invalidInput,

  /// The requested record does not exist or is not visible to the caller.
  notFound,

  /// A domain rule refused the operation, e.g. an illegal state transition.
  domainRule,

  /// No connectivity. On the field app this means "queue it and retry".
  offline,

  /// An external system failed. The core workflow must still function
  /// (PRD 27: integration failures do not crash the referral workflow).
  integration,

  /// Anything unclassified.
  unexpected,
}

/// A user-presentable failure.
@immutable
class Failure implements Exception {
  const Failure({
    required this.kind,
    required this.messageKey,
    this.detail,
    this.code,
    this.cause,
    this.isRetryable = false,
  });

  const Failure.unauthenticated({String? detail})
      : this(
          kind: FailureKind.unauthenticated,
          messageKey: 'error.unauthenticated',
          detail: detail,
        );

  const Failure.forbidden({String? detail})
      : this(
          kind: FailureKind.forbidden,
          messageKey: 'error.forbidden',
          detail: detail,
        );

  const Failure.offline({String? detail})
      : this(
          kind: FailureKind.offline,
          messageKey: 'error.offline',
          detail: detail,
          isRetryable: true,
        );

  const Failure.unexpected({String? detail, Object? cause})
      : this(
          kind: FailureKind.unexpected,
          messageKey: 'error.unexpected',
          detail: detail,
          cause: cause,
        );

  final FailureKind kind;

  /// Localisation key. The UI never renders [detail] to end users; it exists
  /// for logs and for staff-facing consoles.
  final String messageKey;

  final String? detail;

  /// Underlying error code, e.g. a Postgres SQLSTATE.
  final String? code;

  final Object? cause;

  /// Whether retrying the same request could succeed.
  final bool isRetryable;

  @override
  String toString() =>
      'Failure(${kind.name}, key: $messageKey, code: $code, detail: $detail)';
}
