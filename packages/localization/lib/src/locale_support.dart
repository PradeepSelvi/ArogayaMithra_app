import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'generated/am_strings.dart';

/// Locales the platform ships with today (PRD 6 FR-003).
abstract final class AmLocales {
  static const tamil = Locale('ta');
  static const english = Locale('en');

  /// Tamil first: it is the default for the target geography, and the list order
  /// is what Flutter falls back through.
  static const supported = <Locale>[tamil, english];

  static const delegates = <LocalizationsDelegate<Object?>>[
    AmStrings.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  /// Resolves a language tag stored on the user profile or a patient record.
  static Locale fromWire(String? wire) => switch (wire) {
        'en' => english,
        _ => tamil,
      };

  static String toWire(Locale locale) =>
      locale.languageCode == 'en' ? 'en' : 'ta';
}
