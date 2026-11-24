// What a run is pointed at and who it signs in as. ENV, E2E_RUN_ID and
// E2E_ENV_FILE are --dart-define values (tools/e2e/run.sh supplies them); the
// credentials are read from the E2E_ENV_FILE file at run time, so they are
// never compiled into the test or shown on a command line.

// Project imports:
import 'env_file.dart';

/// A seeded user the suite can sign in as.
enum E2ERole { admin, manager, user }

/// The run's settings.
class E2EEnv {
  E2EEnv._();

  /// The configs a run may use: the local stack, or the hosted API.
  static const allowedConfigs = {'e2e-local', 'app'};

  /// The `config/<name>.json` the app loads.
  static const String config = String.fromEnvironment('ENV');

  /// Unique per run, for naming the data a run creates.
  static const String runId = String.fromEnvironment('E2E_RUN_ID');

  /// Absolute path of the credentials file.
  static const String envFile = String.fromEnvironment('E2E_ENV_FILE');

  static const _defines = {
    'ENV': config,
    'E2E_RUN_ID': runId,
    'E2E_ENV_FILE': envFile,
  };

  static final _credentialKeys = [
    for (final role in E2ERole.values) ...[
      _key(role, 'USERNAME'),
      _key(role, 'PASSWORD'),
    ],
  ];

  static Map<String, String>? _credentials;

  static String username(E2ERole role) => _credential(_key(role, 'USERNAME'));

  static String password(E2ERole role) => _credential(_key(role, 'PASSWORD'));

  static String _key(E2ERole role, String field) =>
      'E2E_${role.name.toUpperCase()}_$field';

  static String _credential(String key) {
    final credentials = _credentials;
    if (credentials == null) {
      throw StateError('E2E: call E2EEnv.require() before reading $key');
    }
    return credentials[key]!;
  }

  /// Throws naming the first missing define or credential key (never a
  /// value), the env file's path when it cannot be read, or a config the
  /// suite does not run against. Then loads the credentials.
  static void require() {
    for (final entry in _defines.entries) {
      if (entry.value.isEmpty) {
        throw StateError('E2E: missing --dart-define ${entry.key}');
      }
    }
    if (!allowedConfigs.contains(config)) {
      throw StateError(
        'E2E: ENV must be one of ${allowedConfigs.join(', ')}, not "$config"',
      );
    }
    _credentials = readEnvFile(envFile, _credentialKeys);
  }
}
