// Product clean-up through the app's own repository: the same API calls the
// product screens make, usable after the app has been unmounted.

// Package imports:
import 'package:common/injection.dart';

// Project imports:
import 'package:pos/domain/model/product/product.dart';
import 'package:pos/domain/repositories/product_repository.dart';

/// Every product named exactly [name] that is not deleted, as the server has
/// them (getProducts asks the server, not the cache).
Future<List<Product>> productsNamed(String name) async {
  final products = await getIt()<ProductRepository>().getProducts();
  return products.where((p) => p.name == name).toList();
}

/// Deletes every product named exactly [name]; does nothing when there is
/// none (a test may already have deleted it through the screens). Tries
/// every one, then rethrows the first failure.
///
/// pos-api only marks a deleted product (deletedDate) and leaves its units,
/// prices, stock rows, history and adjustments in place; it does not refuse a
/// product that still has stock. See the Task 4 report.
Future<void> deleteProductsNamed(String name) async {
  final repository = getIt()<ProductRepository>();
  Object? firstError;
  StackTrace? firstStack;
  for (final product in await productsNamed(name)) {
    try {
      await repository.removeProductById(product.id);
    } on Object catch (error, stack) {
      // Try the rest: one refusal must not leave the others behind.
      firstError ??= error;
      firstStack ??= stack;
    }
  }
  if (firstError != null) Error.throwWithStackTrace(firstError, firstStack!);
}
