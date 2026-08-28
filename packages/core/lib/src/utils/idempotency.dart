import 'dart:math';

/// Generates the idempotency keys and client-side record ids that make offline
/// writes safe to replay (PRD 15, PRD 27).
///
/// A record created offline keeps the same id through synchronisation, so a
/// retried sync updates the original row instead of inserting a duplicate.
class IdempotencyKeys {
  IdempotencyKeys({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  /// A RFC 4122 version 4 identifier.
  String newRecordId() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));

    // Version 4, variant 1.
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).toList();
    return '${hex.sublist(0, 4).join()}-${hex.sublist(4, 6).join()}-'
        '${hex.sublist(6, 8).join()}-${hex.sublist(8, 10).join()}-'
        '${hex.sublist(10, 16).join()}';
  }

  /// A stable key for one logical command.
  ///
  /// [operation] names the command and [scope] identifies its subject, so a
  /// retry of the same intent reuses the key while a genuinely new request
  /// does not. Callers must persist the key alongside the queued write.
  String forOperation(String operation, {required String scope}) =>
      '$operation:$scope:${newRecordId()}';
}
