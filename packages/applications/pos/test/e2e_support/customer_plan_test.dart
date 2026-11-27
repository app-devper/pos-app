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

  group('CustomerPlan.decide', () {
    const plan = CustomerPlan.kept();
    CustomerRecord record(
      String code, {
      String name = keptCustomerName,
      String status = 'ACTIVE',
      String address = keptCustomerMarker,
    }) =>
        (name: name, status: status, code: code, address: address);

    test('creates the customer, with the marker, when none has its name', () {
      // Act
      final decision =
          plan.decide([record('MB_1', name: 'Somchai', address: '')]);

      // Assert
      expect(decision, isA<CreateCustomer>());
      expect(plan.markerOnCreate, keptCustomerMarker);
    });

    test('creates it again when the only one of that name is archived', () {
      // Act / Assert
      expect(plan.decide([record('MB_1', status: 'ARCHIVED')]),
          isA<CreateCustomer>());
    });

    test('reuses the one active customer the suite created', () {
      // Act
      final decision = plan.decide([
        record('MB_1', status: 'ARCHIVED'),
        record('MB_2'),
      ]);

      // Assert
      expect(decision, const ReuseCustomer(code: 'MB_2', ownedCount: 1));
    });

    test('refuses a customer of that name the suite did not create', () {
      // Act
      final decision = plan.decide([record('MB_7', address: 'Bangkok')]);

      // Assert
      expect(decision, const RefuseCustomer(foreignCode: 'MB_7'));
    });

    test('reuses its own customer and leaves a foreign one of that name alone',
        () {
      // Act
      final decision = plan.decide([
        record('MB_3', address: ''),
        record('MB_5'),
      ]);

      // Assert
      expect(decision, const ReuseCustomer(code: 'MB_5', ownedCount: 1));
    });

    test('picks the lowest code when the suite owns several', () {
      // Act
      final decision = plan.decide([
        record('MB_20260012'),
        record('MB_20260003'),
        record('MB_20260009'),
      ]);

      // Assert
      expect(decision, const ReuseCustomer(code: 'MB_20260003', ownedCount: 3));
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
