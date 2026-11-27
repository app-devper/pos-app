// Reads the run's credentials file (.env.e2e.local or .env.e2e) at run time,
// so the values are never compiled into the test or shown on a command line.
// Errors name a path, a key or a line number — never a value.

// Dart imports:
import 'dart:io';

/// Parses `KEY=value` lines. Blank lines and lines starting with `#` are
/// skipped; the first `=` splits key from value; there is no quoting, so a
/// value is taken as written (trimmed).
Map<String, String> parseEnvFile(String contents) {
  final values = <String, String>{};
  final lines = contents.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final split = line.indexOf('=');
    if (split <= 0) {
      throw FormatException('E2E env file: line ${i + 1} is not KEY=value');
    }
    values[line.substring(0, split).trim()] = line.substring(split + 1).trim();
  }
  return values;
}

/// Reads [path] and returns [keys] from it; throws naming the path when the
/// file is missing and the first key that is missing or empty.
Map<String, String> readEnvFile(String path, List<String> keys) {
  final file = File(path);
  if (!file.existsSync()) {
    throw StateError('E2E: env file not found: $path');
  }
  final values = parseEnvFile(file.readAsStringSync());
  for (final key in keys) {
    if ((values[key] ?? '').isEmpty) {
      throw StateError('E2E: $path has no value for $key');
    }
  }
  return {for (final key in keys) key: values[key]!};
}
