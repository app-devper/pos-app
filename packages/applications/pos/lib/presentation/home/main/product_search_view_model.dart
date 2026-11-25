// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:common/core/error/failure.dart';
import 'package:common/core/state/view_state.dart';

// Project imports:
import 'package:pos/domain/model/core/core.dart';
import 'package:pos/domain/model/product/product.dart';
import 'package:pos/domain/repositories/product_repository.dart';

class ProductSearchViewModel {
  final ProductRepository productRepo;

  ProductSearchViewModel({
    required this.productRepo,
  });

  final _items = ViewState<List<ProductUnitItem>?>(null);

  ValueListenable<List<ProductUnitItem>?> get items => _items;

  /// Non-null when the inventory could not be loaded. The grid renders this
  /// instead of spinning forever, and the message says the shop is offline
  /// rather than leaving the till to conclude it stocks nothing.
  final _error = ViewState<String?>(null);

  ValueListenable<String?> get error => _error;

  List<ProductUnitItem> _products = const [];
  String _query = '';

  /// Counts the loads started; only the latest one's answer is shown, so two
  /// quick sales cannot leave the older stock on screen.
  int _loadId = 0;

  Future<void> prepareData() async {
    await getProducts();
  }

  /// A first load, or a retry: the grid spins until the products are in,
  /// and a failure replaces it with the error and its retry.
  Future<void> getProducts() async {
    _error.value = null;
    _items.value = null;
    try {
      await _load();
    } on Exception catch (e) {
      _error.value = toFailure(e).getMessage();
    }
  }

  /// Loads the products again behind the grid the cashier sees, keeping what
  /// was typed in the search: after a sale the stock figures have moved. A
  /// failed reload keeps the grid as it was, with no error: the cashier goes
  /// on selling, and the next sale reloads again.
  Future<void> refresh() async {
    try {
      await _load();
    } on Exception catch (_) {}
  }

  Future<void> _load() async {
    final id = ++_loadId;
    final products = await productRepo.getLocalProducts();
    if (id != _loadId) return;
    _products = List<ProductUnitItem>.unmodifiable([
      for (final item in products)
        if (item.status == productStatusActive) ...item.toProductItems(),
    ]);
    _error.value = null;
    searchProduct(_query);
  }

  void searchProduct(String text) {
    _query = text;
    if (text.isEmpty) {
      _items.value = List<ProductUnitItem>.of(_products);
    } else {
      final lower = text.toLowerCase();
      _items.value = _products
          .where((item) =>
              item.name.toLowerCase().contains(lower) ||
              item.unit.barcode.contains(text))
          .toList();
    }
  }

  void dispose() {
    _items.dispose();
    _error.dispose();
  }
}
