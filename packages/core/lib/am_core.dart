/// ArogyaMitra shared kernel.
///
/// Contains only things every layer may depend on: environment configuration,
/// the failure taxonomy and the result type. No UI and no data access.
library;

export 'src/config/app_environment.dart';
export 'src/config/app_flavor.dart';
export 'src/errors/failure.dart';
export 'src/utils/idempotency.dart';
export 'src/utils/result.dart';
