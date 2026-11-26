import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:design_system/theme/app_colors.dart';

// Package imports:
import 'package:design_system/widgets/empty_state.dart';
import 'package:design_system/widgets/responsive.dart';
import 'package:design_system/widgets/title_bar.dart';
import 'package:file_picker/file_picker.dart';

// Project imports:
import 'package:pos/container.dart';
import 'package:pos/domain/model/product/product.dart';
import 'package:pos/domain/model/product/product_history.dart';
import 'package:pos/localizations/language/languages.dart';
import 'package:design_system/widgets/dialogs.dart';
import 'package:pos/presentation/product/add/product_add_page.dart';
import 'package:pos/presentation/product/edit/product_edit_page.dart';
import 'package:pos/presentation/product/main/product_detail_widget.dart';
import 'package:pos/presentation/product/main/product_menu_widget.dart';
import 'package:pos/presentation/product/main/product_view_model.dart';
import 'package:pos/presentation/product/main/products_widget.dart';

// Package imports:

class ProductsPage extends StatefulWidget {
  final String? mode;

  /// Told how system Back leaves the page shown over the list (the detail,
  /// the add or edit form), or null when the list itself is shown. The
  /// shell owns Back, so the page reports rather than handling it.
  final ValueChanged<VoidCallback?>? onBackChanged;

  const ProductsPage({super.key, this.mode, this.onBackChanged});

  @override
  State<StatefulWidget> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  PageState _pageState = MainPage();

  /// Bumped when the list behind the panels is out of date, so it reloads.

  late ProductViewModel _viewModel;
  late StreamSubscription<Product> _loaded;
  late StreamSubscription<CSVImportResult> _importResults;
  late StreamSubscription<String> _errors;

  @override
  void initState() {
    _viewModel = sl<ProductViewModel>();
    _loaded = _viewModel.loaded.listen(_onLoaded);
    _importResults = _viewModel.importResults.listen(_onImported);
    _errors = _viewModel.errors.listen(_showError);
    super.initState();
  }

  void _onLoaded(Product data) {
    if (!mounted) return;
    _show(InfoPage(data: data));
  }

  /// Shows [page] and tells the host where Back from it goes.
  void _show(PageState page) {
    setState(() => _pageState = page);
    widget.onBackChanged?.call(_backFrom(page));
  }

  /// Back from [page]: a form returns to what it was opened from, the detail
  /// to the list; the list has nothing to go back to here.
  VoidCallback? _backFrom(PageState page) {
    return switch (page) {
      EditPage(:final data) => () => _show(InfoPage(data: data)),
      InfoPage() || AddPage() => () => _show(MainPage()),
      _ => null,
    };
  }

  void _onImported(CSVImportResult result) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'นำเข้าสำเร็จ ${result.success} รายการ, ล้มเหลว ${result.failed} รายการ',
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _loaded.cancel();
    _importResults.cancel();
    _errors.cancel();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Responsive(
      mobile: _buildMobile(),
      desktop: _buildDesktop(),
    );
  }

  Row _buildDesktop() {
    return Row(
      children: [
        SizedBox(
          width: 320,
          child: ProductsWidget(
            onAdd: () => _show(AddPage()),
            onMenu: () {
              _showProductMenuDialog();
            },
            onSelected: (value) {
              _viewModel.getProduct(value.id);
            },
          ),
        ),
        Container(width: 1, color: AppColors.of(context).border),
        Expanded(
          child: _buildPage(),
        ),
      ],
    );
  }

  Row _buildMobile() {
    return Row(
      children: [
        Expanded(
          child: _buildPage(),
        ),
      ],
    );
  }

  Widget _buildPage() {
    if (_pageState is MainPage) {
      final isMobile = Responsive.isMobile(context);
      if (isMobile) {
        return ProductsWidget(
          onAdd: () => _show(AddPage()),
          onMenu: () {
            _showProductMenuDialog();
          },
          onSelected: (value) {
            _viewModel.getProduct(value.id);
          },
        );
      } else {
        // The menu keeps its add, export and import; under it the pane says
        // what choosing a product does.
        return Column(
          children: [
            ProductMenuWidget(
              onAdd: () {
                _show(AddPage());
              },
              onExport: () {
                _viewModel.exportProducts();
              },
              onImportCsv: () {
                _pickAndImportCSV();
              },
            ),
            Expanded(
              child: EmptyState(
                icon: Icons.inventory_2_outlined,
                title: Languages.of(context).chooseProductHint,
              ),
            ),
          ],
        );
      }
    } else if (_pageState is InfoPage) {
      final product = (_pageState as InfoPage).data;
      return ProductDetailWidget(
        onEdit: () {
          _viewModel.getProduct(product.id);
        },
        product: product,
        onBack: () {
          _show(MainPage());
        },
        onClickEdit: () {
          _show(EditPage(data: product));
        },
        onClearSoldFirst: (productId) {
          _viewModel.clearSoldFirst(productId);
        },
      );
    } else if (_pageState is EditPage) {
      final product = (_pageState as EditPage).data;
      return ProductEditPage(
        product: product,
        onBack: () {
          _show(InfoPage(data: product));
        },
        onEdit: () {
          _viewModel.getProduct(product.id);
        },
        onRemove: () {
          // The Product is gone, so there is nothing to reload. This used to
          // call getProduct(id), which failed, reported "Product not found",
          // and left the cashier on the edit form of what they had deleted —
          // with it still listed alongside on a wide screen.
          _show(MainPage());
        },
      );
    } else if (_pageState is AddPage) {
      return ProductAddPage(
        onBack: () {
          _show(MainPage());
        },
        onAdd: () {
          _show(MainPage());
        },
      );
    }
    return const SizedBox.shrink();
  }

  void _pickAndImportCSV() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    _viewModel.importCSV(bytes: bytes, filename: file.name);
  }

  void _showProductMenuDialog() {
    showRightDialog(
      context,
      builder: (context) => Column(
        children: [
          TitleBar(
            title: "เมนู",
            onBack: () {
              Navigator.pop(context);
            },
          ),
          const Divider(height: 1),
          Expanded(
              child: ProductMenuWidget(
            onAdd: () {
              Navigator.pop(context);
              _show(AddPage());
            },
            onExport: () {
              Navigator.pop(context);
              _viewModel.exportProducts();
            },
            onImportCsv: () {
              Navigator.pop(context);
              _pickAndImportCSV();
            },
          )),
        ],
      ),
    );
  }
}

abstract class PageState {}

class MainPage extends PageState {}

class AddPage extends PageState {}

class InfoPage extends PageState {
  final Product data;

  InfoPage({
    required this.data,
  });
}

class EditPage extends PageState {
  final Product data;

  EditPage({
    required this.data,
  });
}
