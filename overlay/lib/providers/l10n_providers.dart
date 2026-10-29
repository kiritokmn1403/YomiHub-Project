import 'package:flutter/material.dart';
import 'package:mangayomi/models/settings.dart';
import 'package:mangayomi/repositories/settings_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mangayomi/l10n/generated/app_localizations.dart';
part 'l10n_providers.g.dart';

@riverpod
class L10nLocaleState extends _$L10nLocaleState {
  @override
  Locale build() {
    final locale = _getLocale();
    return Locale(locale.languageCode ?? "en", locale.countryCode ?? "");
  }

  L10nLocale _getLocale() {
    return settingsRepository.current.locale ??
        L10nLocale(languageCode: "vi", countryCode: "");
  }

  void setLocale(Locale locale) async {
    settingsRepository.update(
      (s) => s.locale = L10nLocale(
        languageCode: locale.languageCode,
        countryCode: locale.countryCode,
      ),
    );
    state = locale;
  }
}

AppLocalizations l10nLocalizations(BuildContext context) {
  try {
    final loc = AppLocalizations.of(context);
    if (loc != null) return loc;
  } catch (_) {}
  try {
    return lookupAppLocalizations(const Locale('vi'));
  } catch (_) {
    return lookupAppLocalizations(const Locale('en'));
  }
}

Locale currentLocale(BuildContext context) {
  try {
    return Localizations.localeOf(context);
  } catch (_) {
    return const Locale('vi');
  }
}

extension L10nExtension on BuildContext {
  AppLocalizations get l10n => l10nLocalizations(this);
}
