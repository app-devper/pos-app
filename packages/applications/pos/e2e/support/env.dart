// What a run is pointed at and who it signs in as, from --dart-define and
// --dart-define-from-file (tools/e2e/run.sh supplies both).

/// A seeded user the suite can sign in as.
enum E2ERole { admin, manager, user }

/// The run's settings. Every value is a compile-time define, so the keys are
/// spelled out once each below.
class E2EEnv {
  E2EEnv._();

  /// The configs a run may use: the local stack, or the hosted API.
  static const allowedConfigs = {'e2e-local', 'app'};

  /// The `config/<name>.json` the app loads.
  static const String config = String.fromEnvironment('ENV');

  /// Unique per run, for naming the data a run creates.
  static const String runId = String.fromEnvironment('E2E_RUN_ID');

  static const _values = <String, String>{
    'ENV': config,
    'E2E_RUN_ID': runId,
    'E2E_ADMIN_USERNAME': String.fromEnvironment('E2E_ADMIN_USERNAME'),
    'E2E_ADMIN_PASSWORD': String.fromEnvironment('E2E_ADMIN_PASSWORD'),
    'E2E_MANAGER_USERNAME': String.fromEnvironment('E2E_MANAGER_USERNAME'),
    'E2E_MANAGER_PASSWORD': String.fromEnvironment('E2E_MANAGER_PASSWORD'),
    'E2E_USER_USERNAME': String.fromEnvironment('E2E_USER_USERNAME'),
    'E2E_USER_PASSWORD': String.fromEnvironment('E2E_USER_PASSWORD'),
  };

  static String username(E2ERole role) => _values[_key(role, 'USERNAME')]!;

  static String password(E2ERole role) => _values[_key(role, 'PASSWORD')]!;

  static String _key(E2ERole role, String field) =>
      'E2E_${role.name.toUpperCase()}_$field';

  /// Throws naming the first missing key (never a value), or a config the
  /// suite does not run against.
  static void require() {
    for (final entry in _values.entries) {
      if (entry.value.isEmpty) {
        throw StateError('E2E: missing --dart-define ${entry.key}');
      }
    }
    if (!allowedConfigs.contains(config)) {
      throw StateError(
        'E2E: ENV must be one of ${allowedConfigs.join(', ')}, not "$config"',
      );
    }
  }
}
