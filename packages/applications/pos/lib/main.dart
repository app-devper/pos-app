// Package imports:
import 'package:common/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:um/container.dart' as um;

// Project imports:
import 'package:pos/container.dart' as pos;
import 'presentation/app.dart';

/// On only in a build made with `--dart-define=E2E_SEMANTICS=true`: the
/// Maestro flows read a Flutter web page through its semantics tree, which is
/// otherwise built only when assistive technology asks for it.
const e2eSemanticsEnabled = bool.fromEnvironment('E2E_SEMANTICS');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (e2eSemanticsEnabled) {
    SemanticsBinding.instance.ensureSemantics();
  }
  // Use --dart-define=ENV=dev to load dev.json (local APIs)
  // Default is "app" which loads app.json (production)
  const env = String.fromEnvironment('ENV', defaultValue: 'app');
  final config = await AppConfig.forEnvironment(env);
  um.setupLogging();
  await um.initCore(config);
  await um.initUm();
  await pos.initPos();
  runApp(const DevperPos());
}
