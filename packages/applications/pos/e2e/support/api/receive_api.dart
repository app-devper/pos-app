// Goods-receipt look-ups and clean-up through the app's own repository.
// The receipt screens never show a receipt's code next to its reference, so
// a test finds its receipt here by the reference it typed, then looks for
// that code on screen.

// Package imports:
import 'package:common/injection.dart';

// Project imports:
import 'package:pos/domain/model/receive/param.dart';
import 'package:pos/domain/model/receive/receive.dart';
import 'package:pos/domain/repositories/receive_repository.dart';
import '../stock_plan.dart';

/// The receipt list asks for the last 365 days; so does this.
const _lookBack = Duration(days: 365);

/// Covers a server clock a little ahead of this one.
const _lookAhead = Duration(days: 1);

/// Every receipt with exactly [reference], cancelled ones included.
Future<List<Receive>> receivesWithReference(String reference) async =>
    (await _recentReceives()).where((r) => r.reference == reference).toList();

/// The code of the one receipt with [reference]; fails if there is not
/// exactly one.
Future<String> receiveCodeFor(String reference) async {
  final receives = await receivesWithReference(reference);
  if (receives.length != 1) {
    throw StateError('E2E: expected one receipt with reference $reference, '
        'found ${receives.length}');
  }
  return receives.single.code;
}

/// The server's status of the receipt with [code], or null if none.
Future<String?> receiveStatus(String code) async =>
    (await _recentReceives()).where((r) => r.code == code).firstOrNull?.status;

/// What the receipt list loads, as the server has it now.
Future<List<Receive>> _recentReceives() {
  final now = DateTime.now();
  return getIt()<ReceiveRepository>().getReceives(
    GetReceivesRangeParam(
      startDate: now.subtract(_lookBack).toUtc().toIso8601String(),
      endDate: now.add(_lookAhead).toUtc().toIso8601String(),
    ),
  );
}

/// Deletes (pos-api cancels) every draft receipt with [reference]; does
/// nothing for one already cancelled through the screens, and leaves an
/// imported one, which pos-api locks.
Future<void> cancelDraftReceivesWithReference(String reference) async {
  final repository = getIt()<ReceiveRepository>();
  for (final receive in await receivesWithReference(reference)) {
    if (receive.status == cancelledReceiveStatus || receive.isImported) {
      continue;
    }
    await repository.removeReceiveById(receive.id);
  }
}
