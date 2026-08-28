/// ArogyaMitra authentication and session state.
///
/// Two sign-in paths, matching how the two audiences actually get access:
///   * Citizens: mobile number plus a one-time code. No password to forget.
///   * Staff: email and password against an account an administrator created.
///
/// Role and scope are never chosen at sign-in. They are read from the profile
/// the administrator provisioned, and enforced by database policy (PRD 6 FR-002).
library;

export 'src/auth_controller.dart';
export 'src/auth_providers.dart';
export 'src/auth_state.dart';
export 'src/widgets/auth_gate.dart';
