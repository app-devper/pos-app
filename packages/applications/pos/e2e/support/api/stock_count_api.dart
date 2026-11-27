// Stock counts through the app's own repository: how a test learns the
// number pos-api gave the count it just made on screen (the screen closes
// without saying it).

// Package imports:
import 'package:common/injection.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/domain/repositories/stock_count_repository.dart';

/// The countNo of the one stock count noted exactly [note]; fails if there
/// is none or several (the note carries the run id).
Future<String> stockCountNoWithNote(String note) async {
  final counts = await getIt()<StockCountRepository>().getStockCounts();
  final matching = counts.where((c) => c.note == note).toList();
  expect(matching, hasLength(1), reason: 'stock counts noted "$note"');
  return matching.single.countNo;
}
