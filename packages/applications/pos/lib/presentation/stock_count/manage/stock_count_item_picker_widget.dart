// Flutter imports:
import 'package:flutter/material.dart';
import 'package:design_system/theme/app_colors.dart';

// Package imports:
import 'package:design_system/widgets/title_bar.dart';

// Project imports:
import 'package:pos/container.dart';
import 'package:pos/domain/model/product/product.dart';
import 'package:pos/domain/model/stock_count/param.dart';
import 'package:pos/presentation/stock_count/manage/stock_count_item_picker_state.dart';
import 'package:pos/presentation/stock_count/manage/stock_count_item_picker_view_model.dart';

/// The product picker with its search: a stock count picks a product and
/// then one of its lots ([onSelected]); a receipt line picks only the
/// product ([StockCountItemPickerWidget.product]), one row per product.
class StockCountItemPickerWidget extends StatefulWidget {
  final Function(StockCountItemParam)? onSelected;
  final ValueChanged<ProductUnitItem>? onProductSelected;

  const StockCountItemPickerWidget({
    super.key,
    required Function(StockCountItemParam) this.onSelected,
  }) : onProductSelected = null;

  /// Picks a product, not a lot: the dialog closes on the product's row.
  const StockCountItemPickerWidget.product({
    super.key,
    required ValueChanged<ProductUnitItem> this.onProductSelected,
  }) : onSelected = null;

  @override
  State<StatefulWidget> createState() => _StockCountItemPickerWidgetState();
}

class _StockCountItemPickerWidgetState
    extends State<StockCountItemPickerWidget> {
  final _searchController = TextEditingController();
  late StockCountItemPickerViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = sl<StockCountItemPickerViewModel>();
    _viewModel.getProducts(onePerProduct: widget.onProductSelected != null);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StockCountItemPickerState>(
      valueListenable: _viewModel.state,
      builder: (context, state, _) {
        if (state.selectedProduct != null) {
          return _buildStockList(state.selectedProduct!);
        }
        return _buildProductSearch(state);
      },
    );
  }

  Widget _buildProductSearch(StockCountItemPickerState state) {
    return Column(
      children: [
        TitleBar(
          title: "เลือกสินค้า",
          onBack: () {
            Navigator.of(context).pop();
          },
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(0),
              hintText: 'ค้นหาสินค้า...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              fillColor: AppColors.of(context).border,
              filled: true,
            ),
            onChanged: (value) {
              _viewModel.searchProduct(value);
            },
          ),
        ),
        Expanded(
          child: state.loading
              ? const Center(child: CircularProgressIndicator())
              : state.error != null
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.cloud_off_outlined,
                          size: 36, color: Colors.blueGrey),
                      const SizedBox(height: 12),
                      Text(state.error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                          onPressed: () => _viewModel.getProducts(
                              onePerProduct: widget.onProductSelected != null),
                          icon: const Icon(Icons.refresh),
                          label: const Text('ลองใหม่')),
                    ]))
                  : state.products.isEmpty
                      ? const Center(
                          child: Text('ไม่พบสินค้า กรุณาลองคำค้นอื่น'))
                      : ListView.builder(
                          itemCount: state.products.length,
                          itemBuilder: (context, index) {
                            final product = state.products[index];
                            return ListTile(
                              title: Text(product.name),
                              subtitle: Text(
                                  '${product.unit.unit}, ${product.stocks.length} ล็อต'),
                              onTap: () => _onProductTapped(product),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  void _onProductTapped(ProductUnitItem product) {
    final onProductSelected = widget.onProductSelected;
    if (onProductSelected == null) {
      _viewModel.selectProduct(product);
      return;
    }
    Navigator.of(context).pop();
    onProductSelected(product);
  }

  Widget _buildStockList(ProductUnitItem product) {
    return Column(
      children: [
        TitleBar(
          title: product.name,
          onBack: () {
            _viewModel.clearSelection();
          },
        ),
        const Divider(height: 1),
        Expanded(
          child: product.stocks.isEmpty
              ? Center(
                  child: Text(
                    'สินค้านี้ยังไม่มีล็อตสต็อก',
                    style:
                        TextStyle(color: AppColors.of(context).textSecondary),
                  ),
                )
              : ListView.builder(
                  itemCount: product.stocks.length,
                  itemBuilder: (context, index) {
                    final stock = product.stocks[index];
                    return ListTile(
                      title: Text('ล็อต ${stock.lotNumber}'),
                      subtitle: Text('คงเหลือในระบบ: ${stock.quantity}'),
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onSelected?.call(
                          StockCountItemParam(
                            productId: stock.productId,
                            stockId: stock.id,
                            counted: stock.quantity,
                            productName: product.name,
                            lotNumber: stock.lotNumber,
                            systemQuantity: stock.quantity,
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
