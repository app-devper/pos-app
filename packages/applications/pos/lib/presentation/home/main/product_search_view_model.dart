// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:common/core/error/failure.dart';
import 'package:common/core/state/view_state.dart';

// Project imports:
import 'package:pos/domain/model/core/core.dart';
import 'package:pos/domain/model/product/product.dart';
import 'package:pos/domain/repositories/product_repository.dart';
import 'package:pos/presentation/home/main/catalogue_figures.dart';

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

  /// The categories the catalogue holds, in the app's own order; a pill each.
  final _categories = ViewState<List<String>>(const []);

  ValueListenable<List<String>> get categories => _categories;

  /// The category the grid is narrowed to; null shows every category.
  final _selectedCategory = ViewState<String?>(null);

  ValueListenable<String?> get selectedCategory => _selectedCategory;

  /// The figures of the whole catalogue, worked out once per load.
  final _figures = ViewState<CatalogueFigures>(CatalogueFigures.empty);

  ValueListenable<CatalogueFigures> get figures => _figures;

  List<ProductUnitItem> _products = const [];
  String _query = '';

  /// Counts the loads started, and names the newest one whose answer is on
  /// screen. An answer, or a failure, is shown only when it is newer than
  /// what is shown: two quick sales cannot leave the older stock on screen,
  /// a failed reload cannot hide an older load still on its way, and an
  /// older failure cannot cover a newer grid.
  int _startedId = 0;
  int _appliedId = 0;

  Future<void> prepareData() async {
    await getProducts();
  }

  /// A first load, or a retry: the grid spins until the products are in,
  /// and a failure replaces it with the error and its retry.
  Future<void> getProducts() async {
    _error.value = null;
    _items.value = null;
    await _load(showError: true);
  }

  /// Loads the products again behind the grid the cashier sees, keeping what
  /// was typed in the search: after a sale the stock figures have moved. A
  /// failed reload keeps the grid as it was, with no error: the cashier goes
  /// on selling, and the next sale reloads again.
  Future<void> refresh() => _load(showError: false);

  Future<void> _load({required bool showError}) async {
    final id = ++_startedId;
    try {
      final products = await productRepo.getLocalProducts();
      if (id <= _appliedId) return;
      _appliedId = id;
      _products = List<ProductUnitItem>.unmodifiable([
        for (final item in products)
          if (item.status == productStatusActive) ...item.toProductItems(),
      ]);
      _categories.value = _categoriesOf(_products);
      if (!_categories.value.contains(_selectedCategory.value)) {
        _selectedCategory.value = null;
      }
      _figures.value = CatalogueFigures.of(_products);
      _error.value = null;
      searchProduct(_query);
    } on Exception catch (e) {
      if (!showError || id <= _appliedId) return;
      _error.value = toFailure(e).getMessage();
    }
  }

  void searchProduct(String text) {
    _query = text;
    _showMatches();
  }

  /// Narrows the grid to [category], or to every category when null. What
  /// was typed in the search still applies.
  void selectCategory(String? category) {
    _selectedCategory.value = category;
    _showMatches();
  }

  void _showMatches() {
    final category = _selectedCategory.value;
    final lower = _query.toLowerCase();
    _items.value = [
      for (final item in _products)
        if ((category == null || categoryCodeOf(item) == category) &&
            (_query.isEmpty ||
                item.name.toLowerCase().contains(lower) ||
                item.unit.barcode.contains(_query)))
          item,
    ];
  }

  /// The category [item] reads as: codes that differ only in case, and
  /// every code the app does not know, are one category.
  static String categoryCodeOf(ProductUnitItem item) =>
      findCategoryType(item.category).type;

  /// The categories of [items], once each, in the order the app lists its
  /// categories everywhere else ([categoryTypes]).
  static List<String> _categoriesOf(List<ProductUnitItem> items) {
    final held = {for (final item in items) categoryCodeOf(item)};
    return List.unmodifiable([
      for (final category in categoryTypes)
        if (held.contains(category.type)) category.type,
    ]);
  }

  void dispose() {
    _items.dispose();
    _error.dispose();
    _categories.dispose();
    _selectedCategory.dispose();
    _figures.dispose();
  }
}
