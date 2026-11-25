// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:common/core/state/view_state.dart';

// Project imports:
import 'package:pos/domain/model/core/core.dart';
import 'package:pos/domain/model/product/product.dart';
import 'package:pos/domain/repositories/product_repository.dart';
import 'package:pos/presentation/stock_count/manage/stock_count_item_picker_state.dart';

class StockCountItemPickerViewModel {
  final ProductRepository productRepo;

  StockCountItemPickerViewModel({
    required this.productRepo,
  });

  final _state =
      ViewState<StockCountItemPickerState>(const StockCountItemPickerState());

  ValueListenable<StockCountItemPickerState> get state => _state;

  List<ProductUnitItem> _all = [];
  String _query = '';

  /// Loads the active products, one row per unit, or with [onePerProduct]
  /// one row per product: its base unit's (a receipt counts in it).
  Future<void> getProducts({bool onePerProduct = false}) async {
    _state.value = _state.value.copyWith(loading: true, clearError: true);
    try {
      final products = await productRepo.getProducts();
      _all = [
        for (final item in products)
          if (item.status == productStatusActive)
            ...onePerProduct ? _baseUnitItem(item) : item.toProductItems(),
      ];
      // What was typed while the products loaded still applies.
      _state.value =
          _state.value.copyWith(loading: false, products: _filter(_query));
    } on Exception catch (_) {
      _state.value = _state.value
          .copyWith(loading: false, error: "โหลดสินค้าไม่สำเร็จ กรุณาลองใหม่");
    }
  }

  /// The product's row in its base unit, or in its first unit when none
  /// is named so; none for a product without units.
  static List<ProductUnitItem> _baseUnitItem(Product product) {
    final items = product.toProductItems();
    if (items.isEmpty) return const [];
    return [
      items.firstWhere((item) => item.unit.unit == product.unit,
          orElse: () => items.first),
    ];
  }

  void searchProduct(String text) {
    _query = text;
    _state.value = _state.value.copyWith(products: _filter(text));
  }

  List<ProductUnitItem> _filter(String text) {
    if (text.isEmpty) return List<ProductUnitItem>.unmodifiable(_all);
    final lower = text.toLowerCase();
    return List<ProductUnitItem>.unmodifiable(
        _all.where((item) => item.name.toLowerCase().contains(lower)));
  }

  void selectProduct(ProductUnitItem product) {
    _state.value = _state.value.copyWith(selectedProduct: product);
  }

  void clearSelection() {
    _state.value = _state.value.copyWith(clearSelectedProduct: true);
  }

  void dispose() {
    _state.dispose();
  }
}
