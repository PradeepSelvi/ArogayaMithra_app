import 'package:am_auth/am_auth.dart';
import 'package:am_localization/am_localization.dart';
import 'package:am_models/am_models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Active locale.
///
/// Starts null so the app can tell "not chosen yet" from "chose Tamil". Once a
/// user signs in, their stored preference wins, so a returning user does not get
/// asked again on a new device.
class LocaleController extends Notifier<Locale?> {
  Locale? _chosen;

  @override
  Locale? build() {
    final profile = ref.watch(currentUserProvider);
    if (profile != null) {
      // If the user made an explicit choice in this session, honor it and sync to profile
      if (_chosen != null) {
        final chosenLanguage =
            LanguageCode.tryParse(AmLocales.toWire(_chosen!));
        if (chosenLanguage != null &&
            chosenLanguage != profile.preferredLanguage) {
          Future.microtask(() {
            ref
                .read(authControllerProvider.notifier)
                .setPreferredLanguage(chosenLanguage);
          });
        }
        return _chosen;
      }
      return AmLocales.fromWire(profile.preferredLanguage.wire);
    }
    return _chosen;
  }

  /// Records the choice and persists it to the profile when signed in.
  Future<void> choose(Locale locale) async {
    _chosen = locale;
    state = locale;

    final language = LanguageCode.tryParse(AmLocales.toWire(locale));
    if (language != null && ref.read(currentUserProvider) != null) {
      await ref
          .read(authControllerProvider.notifier)
          .setPreferredLanguage(language);
    }
  }
}

final localeControllerProvider =
    NotifierProvider<LocaleController, Locale?>(LocaleController.new);

final hasChosenLanguageProvider = Provider<bool>(
  (ref) => ref.watch(localeControllerProvider) != null,
);
