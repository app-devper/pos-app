// The app's own strings (Languages) for a widget test, in Thai (the app's
// default) or English, without the app's config file.

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:common/config/app_config.dart';

// Project imports:
import 'package:pos/localizations/language/language_en.dart';
import 'package:pos/localizations/language/language_th.dart';
import 'package:pos/localizations/language/languages.dart';

/// Serves [Languages] in the language [thai] picks, for any locale.
class TestLanguages extends LocalizationsDelegate<Languages> {
  final bool thai;

  const TestLanguages({this.thai = true});

  static final _config =
      AppConfig(apiUrl: '', logo: '', name: 'Devper POS', system: '', home: '');

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<Languages> load(Locale locale) => SynchronousFuture<Languages>(
      thai ? LanguageTh(config: _config) : LanguageEn());

  @override
  bool shouldReload(LocalizationsDelegate<Languages> old) => false;
}

/// Thai strings, as the app shows them by default.
const thaiLanguages = TestLanguages();

/// English strings.
const englishLanguages = TestLanguages(thai: false);
