import 'package:am_core/am_core.dart';
import 'package:am_maps/am_maps.dart';
import 'package:am_networking/am_networking.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final environment = AppEnvironment.fromDartDefines();
  await SupabaseBootstrap.initialise(environment);

  runApp(
    ProviderScope(
      overrides: [
        appEnvironmentProvider.overrideWithValue(environment),
        mapsEnvironmentProvider.overrideWithValue(environment),
      ],
      child: const AshaApp(),
    ),
  );
}
