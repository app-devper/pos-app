// Which customer a run works on, and whether it may remove it. Pure, so it
// is unit-tested.
//
// pos-api only archives a removed customer, and the app keeps listing
// archived ones. So on the hosted target a run must not create and remove
// one customer per run: it reuses one fixed customer and never removes it.

/// The one customer the hosted target reuses, run after run.
const keptCustomerName = 'E2E customer';

/// pos-api's status for a removed customer.
const archivedStatus = 'ARCHIVED';

/// The customer's run id starts with yyyyMMddHHmmss.
final _runStart = RegExp(r'^\d{6}(\d{8})');

/// Written as the address of every customer the suite creates, and of no
/// other: a customer named like the kept one without it is a real one.
const keptCustomerMarker = 'created by the E2E suite — safe to edit';

typedef CustomerRecord = ({
  String name,
  String status,
  String code,
  String address,
});

/// What a run does about its customer.
sealed class CustomerDecision {
  const CustomerDecision();
}

/// No customer of the suite's is active: create one, with the marker.
final class CreateCustomer extends CustomerDecision {
  const CreateCustomer();
}

/// Reuse the suite's customer [code], the lowest of [ownedCount] owned ones.
final class ReuseCustomer extends CustomerDecision {
  const ReuseCustomer({required this.code, required this.ownedCount});

  final String code;
  final int ownedCount;

  @override
  bool operator ==(Object other) =>
      other is ReuseCustomer &&
      other.code == code &&
      other.ownedCount == ownedCount;

  @override
  int get hashCode => Object.hash(code, ownedCount);
}

/// An active customer has the name but not the marker: someone else's, so
/// the run must not touch it, nor add a second customer of that name.
final class RefuseCustomer extends CustomerDecision {
  const RefuseCustomer({required this.foreignCode});

  final String foreignCode;

  @override
  bool operator ==(Object other) =>
      other is RefuseCustomer && other.foreignCode == foreignCode;

  @override
  int get hashCode => foreignCode.hashCode;
}

class CustomerPlan {
  /// The run's own customer, removed at the end (the local target).
  const CustomerPlan.perRun(this.name) : removes = true;

  /// The fixed customer, reused and kept (the hosted target).
  const CustomerPlan.kept()
      : name = keptCustomerName,
        removes = false;

  factory CustomerPlan.forTarget({
    required bool hosted,
    required String runName,
  }) =>
      hosted ? const CustomerPlan.kept() : CustomerPlan.perRun(runName);

  final String name;

  /// Whether the run presses "ลบลูกค้า" and cleans the customer up.
  final bool removes;

  /// The address the suite gives a customer it creates.
  String get markerOnCreate => keptCustomerMarker;

  /// Reuses the lowest-coded active customer named [name] that carries the
  /// marker; refuses when only customers without it have the name; else
  /// creates one.
  CustomerDecision decide(Iterable<CustomerRecord> existing) {
    final active = existing
        .where((c) => c.name == name && c.status != archivedStatus)
        .toList();
    final owned = [
      for (final c in active)
        if (c.address == keptCustomerMarker) c.code,
    ]..sort();
    if (owned.isNotEmpty) {
      return ReuseCustomer(code: owned.first, ownedCount: owned.length);
    }
    if (active.isNotEmpty) {
      return RefuseCustomer(foreignCode: active.first.code);
    }
    return const CreateCustomer();
  }
}

/// A phone number unique to the run: `08` and the run's ddHHmmss, so an
/// edit always changes the reused customer's phone.
String runPhone(String runId) {
  final match = _runStart.firstMatch(runId);
  if (match == null) {
    throw ArgumentError.value(runId, 'runId', 'must start with yyyyMMddHHmmss');
  }
  return '08${match.group(1)}';
}
