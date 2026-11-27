// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/main.dart';

void main() {
  test(
      'the semantics switch for Maestro test builds is off in an ordinary build',
      () {
    // Arrange: this test run was started without --dart-define=E2E_SEMANTICS.

    // Act
    const enabled = e2eSemanticsEnabled;

    // Assert
    expect(enabled, isFalse);
  });
}
