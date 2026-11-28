// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// Package imports:
import 'package:common/core/ext/number_ext.dart';
import 'package:design_system/theme/app_colors.dart';
import 'package:design_system/theme/spacing.dart';
import 'package:design_system/widgets/app_tag.dart';
import 'package:design_system/widgets/figure_tile.dart';
import 'package:design_system/widgets/filter_pills.dart';
import 'package:design_system/widgets/error_state.dart';
import 'package:design_system/widgets/search_decoration.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

// Project imports:
import 'package:pos/localizations/language/languages.dart';
import 'package:pos/container.dart';
import 'package:pos/domain/model/core/core.dart';
import 'package:pos/domain/model/product/product.dart';
import 'package:pos/presentation/constants.dart';
import 'package:pos/presentation/home/main/catalogue_figures.dart';
import 'package:pos/presentation/home/main/product_card.dart';
import 'package:pos/presentation/home/main/product_search_view_model.dart';

class ProductSearch extends StatefulWidget {
  final Function(String) onSelected;

  /// Each recorded sale reloads the products (it has moved their stock) and
  /// puts the cursor back in the search field, ready for the next scan.
  final Stream<Object?>? saleRecorded;

  /// How many of each product the open cart holds, by the unit's barcode.
  final Map<String, int> inCart;

  const ProductSearch({
    super.key,
    required this.onSelected,
    this.saleRecorded,
    this.inCart = const {},
  });

  @override
  State<StatefulWidget> createState() {
    return _ProductSearchState();
  }
}

class _ProductSearchState extends State<ProductSearch> {
  /// A panel narrower than this is a phone's: two compact cards per row,
  /// pills on one scrolling row, and no figures.
  static const double _compactBelow = 600;
  static const double _cardWidth = 230;
  static const int _compactColumns = 2;
  static const double _gap = 12;

  final _serialNumberEditingController = TextEditingController();
  final _serialNumberNode = FocusNode();

  late ProductSearchViewModel _viewModel;
  StreamSubscription<Object?>? _sales;

  @override
  void initState() {
    _viewModel = sl<ProductSearchViewModel>();
    _viewModel.prepareData();
    _sales = widget.saleRecorded?.listen((_) => _onSaleRecorded());
    super.initState();
  }

  @override
  void dispose() {
    _sales?.cancel();
    _serialNumberEditingController.dispose();
    _serialNumberNode.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  /// The payment dialog closing does not hand the focus back (on the web it
  /// stays on the route), so the next scan would go nowhere.
  void _onSaleRecorded() {
    _viewModel.refresh();
    _refocusSearch();
  }

  /// Set by the layout: a phone's panel, where the search field never takes
  /// the focus by itself (its soft keyboard would cover the products and
  /// the tabs).
  bool _compact = false;

  /// Puts the cursor back in the search field, ready for the next scan, on
  /// a screen with a scanner or a keyboard of its own.
  void _refocusSearch() {
    if (!_compact) _serialNumberNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return _buildProducts();
  }

  LayoutBuilder _buildProducts() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final compact = constraints.maxWidth < _compactBelow;
        _compact = compact;
        final columns = compact
            ? _compactColumns
            : (constraints.maxWidth ~/ _cardWidth).clamp(1, 12);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _buildSearchField(context, autofocus: !compact),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildCategoryPills(scrollable: compact),
            ),
            if (!compact)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _buildFigures(),
              ),
            const SizedBox(height: _gap),
            Expanded(child: _buildGridArea(columns, compact)),
          ],
        );
      },
    );
  }

  Widget _buildSearchField(BuildContext context, {required bool autofocus}) {
    return TextField(
      autofocus: autofocus,
      focusNode: _serialNumberNode,
      controller: _serialNumberEditingController,
      decoration: buildSearchDecoration(
        context,
        hintText: 'ค้นหาชื่อสินค้า หรือสแกนบาร์โค้ด',
        suffixIcon: kIsWeb
            ? null
            : IconButton(
                tooltip: Languages.of(context).scanBarcode,
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () => _scanBarcode(context),
              ),
      ),
      onChanged: _viewModel.searchProduct,
      onSubmitted: (value) {
        if (value.isEmpty) return;
        widget.onSelected(value);
        _serialNumberEditingController.text = "";
        _refocusSearch();
        _viewModel.searchProduct("");
      },
    );
  }

  /// ทั้งหมด and a pill for each category the catalogue holds.
  Widget _buildCategoryPills({required bool scrollable}) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: _viewModel.categories,
      builder: (context, categories, _) => ValueListenableBuilder<String?>(
        valueListenable: _viewModel.selectedCategory,
        builder: (context, selected, _) => FilterPills<String?>(
          scrollable: scrollable,
          selected: selected,
          // A tap outside the field takes its focus on the web and a
          // desktop; the next scan must still land in it.
          onSelected: (category) {
            _viewModel.selectCategory(category);
            _refocusSearch();
          },
          items: [
            FilterPill<String?>(
              value: null,
              label: Languages.of(context).allCategories,
            ),
            for (final category in categories)
              FilterPill<String?>(
                value: category,
                label: findCategoryType(category).name,
              ),
          ],
        ),
      ),
    );
  }

  /// How many products are on sale, their stock, and how many run low.
  Widget _buildFigures() {
    return ValueListenableBuilder<CatalogueFigures>(
      valueListenable: _viewModel.figures,
      builder: (context, figures, _) {
        final strings = Languages.of(context);
        return Row(
          children: [
            Expanded(
              child: FigureTile(
                icon: Icons.inventory_2_outlined,
                label: strings.catalogueProducts,
                value: formatDecimal(figures.products.toDouble()),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FigureTile(
                icon: Icons.layers_outlined,
                label: strings.catalogueTotalStock,
                value: formatDecimal(figures.totalStock.toDouble()),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FigureTile(
                icon: Icons.warning_amber_rounded,
                label: strings.lowStock,
                value: formatDecimal(figures.lowStock.toDouble()),
                tone: figures.lowStock > 0
                    ? AppTagTone.warning
                    : AppTagTone.neutral,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGridArea(int columns, bool compact) {
    // A failed inventory load has to say so. Without this the grid spun
    // forever and every scan reported "ไม่พบสินค้า", which reads as "we do
    // not stock that" rather than "we are offline".
    return ValueListenableBuilder<String?>(
      valueListenable: _viewModel.error,
      builder: (context, error, child) {
        if (error != null) {
          return ErrorState(
            message: error,
            onRetry: () => _viewModel.getProducts(),
          );
        }
        return child!;
      },
      child: ValueListenableBuilder<List<ProductUnitItem>?>(
        valueListenable: _viewModel.items,
        builder: (context, items, _) {
          if (items == null) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                strokeCap: StrokeCap.round,
              ),
            );
          }
          if (items.isEmpty) return _buildNoMatch(context);
          return _buildGrid(items, columns, compact);
        },
      ),
    );
  }

  Widget _buildNoMatch(BuildContext context) {
    return Center(
      child: Text(
        "ไม่พบสินค้า\nลองค้นหาด้วยชื่อหรือบาร์โค้ดอื่น",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.of(context).textSecondary,
          height: 1.8,
        ),
      ),
    );
  }

  Widget _buildGrid(List<ProductUnitItem> items, int columns, bool compact) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisExtent:
            compact ? ProductCard.compactHeight : ProductCard.height,
        mainAxisSpacing: _gap,
        crossAxisSpacing: _gap,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final barcode = items[i].unit.barcode;
        return ProductCard(
          item: items[i],
          inCart: widget.inCart[barcode] ?? 0,
          compact: compact,
          onAdd: () {
            widget.onSelected(barcode);
            _refocusSearch();
          },
        );
      },
    );
  }

  Future<void> _scanBarcode(BuildContext context) async {
    final result = await Navigator.pushNamed(context, scanRoute);
    if (result is Barcode) {
      final code = result.code;
      if (code != null && code.isNotEmpty) {
        widget.onSelected(code);
      }
    }
  }
}
