import 'package:am_models/am_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';
import 'auth_state.dart';

/// Session and profile state.
final authControllerProvider =
    NotifierProvider<AuthController, AmAuthState>(AuthController.new);

/// The signed-in profile, or null.
final currentUserProvider = Provider<AppUser?>(
  (ref) => ref.watch(authControllerProvider).profile,
);

/// The signed-in user's role.
final currentRoleProvider = Provider<UserRole?>(
  (ref) => ref.watch(currentUserProvider)?.role,
);

/// The facility a staff user is assigned to.
///
/// Reading this rather than accepting a facility id from the UI is what stops
/// one facility from publishing readiness for another (PRD 6 FR-002).
final currentFacilityIdProvider = Provider<String?>(
  (ref) => ref.watch(currentUserProvider)?.facilityId,
);

/// The district an oversight user may see.
final currentDistrictIdProvider = Provider<String?>(
  (ref) => ref.watch(currentUserProvider)?.districtId,
);

/// Language for the session, defaulting to Tamil.
final currentLanguageProvider = Provider<LanguageCode>(
  (ref) => ref.watch(currentUserProvider)?.preferredLanguage ?? LanguageCode.tamil,
);

final isSignedInProvider = Provider<bool>(
  (ref) => ref.watch(authControllerProvider).isSignedIn,
);
