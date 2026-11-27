// Product clean-up through the app's own repository: the same API calls the
// product screens make, usable after the app has been unmounted.

// Package imports:
import 'package:common/core/error/exception.dart';
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

/// The stock rows the server has for the product named exactly [name].
Future<List<ProductStock>> stockRowsOf(String name) async {
  final product = (await productsNamed(name)).single;
  return getIt()<ProductRepository>().getProductStocksByProductId(product.id);
}

/// What [retireProduct] did to one product.
typedef Retired = ({
  int zeroed,
  int rowsDeleted,
  List<String> rowsKept,
});

/// Zeroes every lot of [product], deletes each stock row that then holds
/// nothing (the call the stock dialog's 'ลบสต็อกสินค้า' makes,
/// product_stock_widget.dart:442), then deletes the product. A row pos-api
/// refuses to delete (still holding goods, or reserved by a pending
/// transfer, ledger/stock.go:70-78) is kept and named in `rowsKept`; it
/// does not stop the rest.
Future<Retired> retireProduct(Product product) async {
  final repository = getIt()<ProductRepository>();
  final zeroed = await zeroStockOf(product);
  final rows = await repository.getProductStocksByProductId(product.id);
  final plan = stockRowsToDelete(
      [for (final r in rows) (stockId: r.id, quantity: r.quantity)]);
  final kept = [
    for (final lot in plan.keep) 'stock row ${lot.stockId} (${lot.quantity})',
  ];
  var deleted = 0;
  for (final id in plan.delete) {
    try {
      await repository.removeProductStockById(id);
      deleted++;
    } on AppException catch (error) {
      kept.add('stock row $id (refused: ${error.message})');
    }
  }
  await repository.removeProductById(product.id);
  return (zeroed: zeroed, rowsDeleted: deleted, rowsKept: kept);
}

/// Retires (see [retireProduct]) every product named exactly [name]; does
/// nothing when there is none (a test may already have deleted it through
/// the screens). Tries every one, then rethrows the first failure.
///
/// pos-api only marks a deleted product (deletedDate); both its stock
/// reports sum the product's stock rows with no `deletedDate` filter
/// (product_stock.go:567-610, :635-672). Removing the rows takes the
/// product out of both. Its history and adjustment rows stay.
Future<List<Retired>> deleteProductsNamed(String name) async {
  Object? firstError;
  StackTrace? firstStack;
  final retired = <Retired>[];
  for (final product in await productsNamed(name)) {
    try {
      retired.add(await retireProduct(product));
    } on Object catch (error, stack) {
      // Try the rest: one refusal must not leave the others behind.
      firstError ??= error;
      firstStack ??= stack;
    }
  }
  if (firstError != null) Error.throwWithStackTrace(firstError, firstStack!);
  return retired;
}
