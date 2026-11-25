// Product clean-up through the app's own repository: the same API calls the
// product screens make, usable after the app has been unmounted.

// Package imports:
import 'package:common/injection.dart';

// Project imports:
import 'package:pos/domain/model/core/core.dart';
import 'package:pos/domain/model/product/product.dart';
import 'package:pos/domain/model/stock_adjustment/param.dart';
import 'package:pos/domain/repositories/product_repository.dart';
import 'package:pos/domain/repositories/stock_adjustment_repository.dart';
import '../stock_zeroing.dart';

/// The note on every clean-up adjustment, so it is told apart on a server.
const zeroingNote = 'E2E clean-up: stock zeroed before the product is deleted';

/// Every product named exactly [name] that is not deleted, as the server has
/// them (getProducts asks the server, not the cache).
Future<List<Product>> productsNamed(String name) async {
  final products = await getIt()<ProductRepository>().getProducts();
  return products.where((p) => p.name == name).toList();
}

/// Brings every lot of [product] to 0 with one adjustment each (reason
/// อื่นๆ, note [zeroingNote]), the call the adjustment dialog makes
/// (stock_adjustment_widget.dart:211); returns how many it made.
Future<int> zeroStockOf(Product product) async {
  final deltas = zeroingDeltas(
      [for (final s in product.stocks) (stockId: s.id, quantity: s.quantity)]);
  final adjustments = getIt()<StockAdjustmentRepository>();
  for (final lot in deltas) {
    await adjustments.createStockAdjustment(CreateStockAdjustmentParam(
      productId: product.id,
      stockId: lot.stockId,
      reason: stockAdjustmentReasonOther,
      note: zeroingNote,
      delta: lot.delta,
    ));
  }
  return deltas.length;
}

/// Zeroes the stock of every product named exactly [name], then deletes it;
/// does nothing when there is none (a test may already have deleted it
/// through the screens). Tries every one, then rethrows the first failure.
/// Returns how many zeroing adjustments it made.
///
/// pos-api only marks a deleted product (deletedDate) and leaves its units,
/// prices, stock rows, history and adjustments in place; it does not refuse a
/// product that still has stock, and its stock report keeps counting that
/// stock (product_stock.go:635-672). Hence the zeroing first.
Future<int> deleteProductsNamed(String name) async {
  final repository = getIt()<ProductRepository>();
  Object? firstError;
  StackTrace? firstStack;
  var zeroed = 0;
  for (final product in await productsNamed(name)) {
    try {
      zeroed += await zeroStockOf(product);
      await repository.removeProductById(product.id);
    } on Object catch (error, stack) {
      // Try the rest: one refusal must not leave the others behind.
      firstError ??= error;
      firstStack ??= stack;
    }
  }
  if (firstError != null) Error.throwWithStackTrace(firstError, firstStack!);
  return zeroed;
}
