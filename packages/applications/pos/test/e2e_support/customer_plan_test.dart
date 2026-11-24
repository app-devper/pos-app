// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import '../../e2e/support/customer_plan.dart';

const _runName = 'E2E-20261125103045-4242 customer';

void main() {
  group('CustomerPlan.forTarget', () {
    test('on the hosted target reuses the one fixed customer and keeps it', () {
      // Act
      final plan = CustomerPlan.forTarget(hosted: true, runName: _runName);

      // Assert
      expect(plan.name, 'E2E customer');
      expect(plan.removes, isFalse);
    });

    test('on the local target uses the run name and removes it', () {
      // Act
      final plan = CustomerPlan.forTarget(hosted: false, runName: _runName);

      // Assert
      expect(plan.name, _runName);
      expect(plan.removes, isTrue);
    });
  });

  group('CustomerPlan.needsCreating', () {
    const plan = CustomerPlan.kept();

    test('creates the customer when none has its name', () {
      // Act / Assert
      expect(plan.needsCreating([(name: 'Somchai', status: 'ACTIVE')]), isTrue);
    });

    test('reuses an active customer of that name', () {
      // Act / Assert
      expect(
        plan.needsCreating([
          (name: 'E2E customer', status: 'ARCHIVED'),
          (name: 'E2E customer', status: 'ACTIVE'),
        ]),
        isFalse,
      );
    });

    test('creates it again when the only one of that name is archived', () {
      // Act / Assert
      expect(plan.needsCreating([(name: 'E2E customer', status: 'ARCHIVED')]),
          isTrue);
    });
  });

  group('runPhone', () {
    test('is 08 and the day, hour, minute and second of the run', () {
      // Act / Assert
      expect(runPhone('20261125103045-4242'), '0825103045');
    });

    test('rejects a run id that does not start with a timestamp', () {
      // Act / Assert
      expect(() => runPhone('abc'), throwsArgumentError);
    });
  });
}
