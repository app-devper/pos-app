import 'dart:async';

// Flutter imports:

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:common/core/ext/date_ext.dart';
import 'package:common/core/ext/widget_ext.dart';
import 'package:design_system/widgets/snack_bar.dart';
import 'package:design_system/widgets/title_bar.dart';

// Project imports:
import 'package:pos/container.dart';
import 'package:pos/domain/model/order/order.dart';
import 'package:pos/domain/model/customer/customer.dart';
import 'package:pos/domain/model/order/order_item.dart';
import 'package:design_system/widgets/dialogs.dart';
import 'package:pos/presentation/core/dialog_widget.dart';
import 'package:pos/presentation/customer/add/customer_add_page.dart';
import 'package:pos/localizations/language/languages.dart';
import 'package:pos/presentation/home/main/cart_bar.dart';
import 'package:pos/presentation/home/main/cart_panel.dart';
import 'package:pos/presentation/home/main/cart_quantities.dart';
import 'package:pos/presentation/home/main/cart_state.dart';
import 'package:pos/presentation/home/main/cart_widget.dart';
import 'package:pos/presentation/home/main/customer_search.dart';
import 'package:pos/presentation/home/main/payment_screen.dart';
import 'package:pos/presentation/home/main/product_search.dart';
import 'package:pos/presentation/home/main/sale_recorded_message.dart';
import 'package:design_system/theme/app_colors.dart';
import 'cart_view_model.dart';

class CartPage extends StatefulWidget {
  /// The phone's open cart, over the products; at most one at a time.
  static final GlobalKey cartSheetKey = GlobalKey(debugLabel: 'cart-sheet');

  const CartPage({super.key});

  @override
  State<StatefulWidget> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> with WidgetsBindingObserver {
  final _alertKey = GlobalKey();

  late CustomSnackBar _snackBar;
  late CartViewModel _viewModel;
  late StreamSubscription<String> _lookupErrors;
  late StreamSubscription<String> _checkoutErrors;
  late StreamSubscription<OrderResult> _orderPlaced;

  List<OrderItem> _orderItems = [];
  Function refreshCustomer = () {};

  DateTime currentDate = getCurrentDate();

  double _total = 0;

  bool _loadingShown = false;
  bool _orderSavingShown = false;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    _viewModel = sl<CartViewModel>();
    _viewModel.state.addListener(_onStateChanged);
    _lookupErrors = _viewModel.lookupErrors.listen(_showError);
    _checkoutErrors = _viewModel.checkoutErrors.listen(_showError);
    _orderPlaced = _viewModel.orderPlaced.listen(_onOrderPlaced);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.prepareData();
    });
  }

  void _showError(String message) {
    _snackBar.hideAll();
    _snackBar.showErrorSnackBar(message);
  }

  void _onOrderPlaced(OrderResult result) {
    _snackBar.hideAll();
    _snackBar.showSnackBar(text: saleRecordedMessage(result.data.code));
    if (_alertKey.currentContext != null) {
      Navigator.of(context).pop();
    }
    _closeCartSheet();
  }

  /// The phone's open cart, while it is open.
  Route<Object?>? _cartSheetRoute;
  bool _cartSheetOpening = false;

  /// After a sale the phone goes back to the products, ready for the next
  /// customer. The cart's own route is taken away wherever it is in the
  /// stack, so a dialog still closing above it cannot be popped instead.
  void _closeCartSheet() {
    final route = _cartSheetRoute;
    _cartSheetRoute = null;
    if (route == null || !route.isActive) return;
    route.navigator?.removeRoute(route);
  }

  void _onStateChanged() {
    final state = _viewModel.state.value;
    if (state.loading && !_loadingShown) {
      _loadingShown = true;
      _snackBar.hideAll();
      _snackBar.showLoadingSnackBar();
    } else if (!state.loading && _loadingShown) {
      _loadingShown = false;
      _snackBar.hideAll();
    }
    if (state.orderSaving && !_orderSavingShown) {
      _orderSavingShown = true;
      showLoadingDialog(context);
    } else if (!state.orderSaving && _orderSavingShown) {
      _orderSavingShown = false;
      hideLoadingDialog(context);
    }
    setState(() {
      _orderItems = state.orderItems ?? const [];
      _total = state.total;
    });
  }

  @override
  void dispose() {
    // The cart reads this page; it does not outlive it.
    _closeCartSheet();
    WidgetsBinding.instance.removeObserver(this);
    _viewModel.state.removeListener(_onStateChanged);
    _lookupErrors.cancel();
    _checkoutErrors.cancel();
    _orderPlaced.cancel();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _viewModel.prepareData();
    }
  }

  static const double _tabletBreakpoint = 600;
  static const double _desktopBreakpoint = 850;

  @override
  Widget build(BuildContext context) {
    _snackBar = CustomSnackBar(key: const Key("snackbar"), context: context);
    final width = MediaQuery.of(context).size.width;
    if (width >= _desktopBreakpoint) {
      return _buildDesktop();
    } else if (width >= _tabletBreakpoint) {
      return _buildTablet();
    } else {
      return _buildMobile();
    }
  }

  /// The phone: the products first, the open cart a bar along the foot.
  Widget _buildMobile() {
    return Column(
      children: [
        Expanded(child: _buildProductSearch()),
        Container(height: 1, color: AppColors.of(context).border),
        CartBar(
          cartNumber: _viewModel.openCart + 1,
          lineCount: _orderItems.length,
          total: _total,
          onOpen: _showCartSheet,
        ),
      ],
    );
  }

  Widget _buildProductSearch() {
    return ProductSearch(
      onSelected: (serialNumber) {
        _viewModel.addOrderItem(serialNumber);
      },
      saleRecorded: _viewModel.orderPlaced,
      inCart: cartQuantities(_orderItems),
    );
  }

  /// The phone's cart, over the products: the cart and the strip of carts
  /// beside it, following every change to the sale.
  void _showCartSheet() {
    // One cart at a time: a second tap before it is up opens nothing.
    if (_cartSheetOpening || _cartSheetRoute != null) return;
    _cartSheetOpening = true;
    // Let go of the search field: closing the cart would hand it the focus
    // back, and a phone's keyboard with it, over the products and the tabs.
    FocusManager.instance.primaryFocus?.unfocus();
    showRightDialog(
      context,
      builder: (sheetContext) {
        _cartSheetRoute ??= ModalRoute.of(sheetContext);
        return _buildCartSheet(sheetContext);
      },
    ).whenComplete(() {
      _cartSheetOpening = false;
      _cartSheetRoute = null;
    });
  }

  Widget _buildCartSheet(BuildContext sheetContext) {
    return KeyedSubtree(
        key: CartPage.cartSheetKey,
        child: ValueListenableBuilder<CartState>(
          valueListenable: _viewModel.state,
          builder: (context, _, __) => Column(
            children: [
              TitleBar(
                title: Languages.of(context).cartTitle,
                onBack: () => Navigator.pop(sheetContext),
              ),
              const Divider(height: 1),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _buildCart()),
                    Container(width: 1, color: AppColors.of(context).border),
                    SizedBox(width: 50, child: _buildCartItem()),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }

  Row _buildTablet() {
    return Row(
      children: [
        Expanded(
          child: _buildProductSearch(),
        ),
        Container(width: 1, color: AppColors.of(context).border),
        SizedBox(
          width: 340,
          child: _buildCart(),
        ),
        Container(width: 1, color: AppColors.of(context).border),
        SizedBox(
          width: 50,
          child: _buildCartItem(),
        ),
      ],
    );
  }

  Row _buildDesktop() {
    return Row(
      children: [
        Expanded(
          child: _buildProductSearch(),
        ),
        Container(width: 1, color: AppColors.of(context).border),
        SizedBox(
          width: 400,
          child: _buildCart(),
        ),
        Container(width: 1, color: AppColors.of(context).border),
        SizedBox(
          width: 50,
          child: _buildCartItem(),
        ),
      ],
    );
  }

  Widget _buildCart() {
    return CartPanel(
      cartNumber: _viewModel.openCart + 1,
      lineCount: _orderItems.length,
      lineBuilder: _buildLine,
      total: _total,
      customer: _viewModel.customer,
      complianceSummary:
          _hasComplianceInfo() ? _getComplianceSummary() : null,
      onChooseCustomer: _showCustomerDialog,
      onRemoveCustomer: () => _viewModel.setCustomer(null),
      onCompliance: _showComplianceDialog,
      onPay: _showPaymentDialog,
    );
  }

  Column _buildCartItem() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _viewModel.cartCount,
            itemBuilder: (context, index) {
              return CartItem(
                active: index == _viewModel.openCart,
                index: index + 1,
                onTap: () {
                  _viewModel.selectCart(index);
                },
                haveOrder: _viewModel.cartHasLines(index),
              );
            },
          ),
        ),
        const Divider(height: 1),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            const Text(
              'วันนี้',
              style: TextStyle(
                fontSize: 14,
              ),
            ),
            Text(
              currentDate.formatShortDate(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ],
    );
  }

  /// The cart's line [index], with what each of its controls does.
  Widget _buildLine(BuildContext context, int index) {
    final content = _orderItems[index];
    return CartOrderItem(
      title: content.product.name,
      quantity: content.quantity,
      price: content.priceType.price,
      unit: content.unit,
      discount: content.discount,
      priceDetail: content.getPriceDetail(),
      allowOversell: content.allowOversell,
      onToggleOversell: () {
        _viewModel.toggleAllowOversell(index);
      },
      onRemove: () {
        _viewModel.minusItem(index);
      },
      onAdd: () {
        _viewModel.plusItem(index);
      },
      onEdit: () {
        showInputNumberDialog(
          context,
          title: 'จำนวนสินค้า',
          onCompleted: (value) {
            _viewModel.editItem(index, value);
          },
        );
      },
      onEditPrice: () {
        showEditOrderItemDialog(
          context,
          orderItem: content,
          onCompleted: (value) {
            _viewModel.editLine(index, value);
          },
          onRemove: () {
            _viewModel.removeItem(index);
          },
        );
      },
    );
  }

  void _showCustomerDialog() {
    showRightDialog(
      context,
      builder: (context) => Column(
        children: [
          TitleBar(
            title: "เลือกลูกค้า",
            onBack: () {
              Navigator.pop(context);
            },
            action: "เพิ่มลูกค้า",
            onAction: () {
              _showAddCustomerDialog();
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: CustomerSearch(
              onRefresh: (func) {
                refreshCustomer = func;
              },
              onSelected: (Customer customer) {
                _viewModel.setCustomer(customer);
                Navigator.pop(context);
              },
            ),
          )
        ],
      ),
    );
  }

  bool _hasComplianceInfo() {
    return (_viewModel.patientId?.isNotEmpty ?? false) ||
        (_viewModel.prescriberName?.isNotEmpty ?? false) ||
        (_viewModel.pharmacistName?.isNotEmpty ?? false);
  }

  String _getComplianceSummary() {
    final parts = [
      if (_viewModel.patientId?.isNotEmpty ?? false)
        'ผู้ป่วย: ${_viewModel.patientId}',
      if (_viewModel.prescriberName?.isNotEmpty ?? false)
        'แพทย์: ${_viewModel.prescriberName}',
      if (_viewModel.pharmacistName?.isNotEmpty ?? false)
        'เภสัชกร: ${_viewModel.pharmacistName}',
    ];
    return parts.join(', ');
  }

  void _showComplianceDialog() {
    final patientController = TextEditingController(text: _viewModel.patientId);
    final prescriberController =
        TextEditingController(text: _viewModel.prescriberName);
    final pharmacistController =
        TextEditingController(text: _viewModel.pharmacistName);
    showCenterDialog(
      context: context,
      minWidth: 360,
      maxWidth: 360,
      minHeight: 420,
      maxHeight: 420,
      builder: (dialogContext) => Column(
        children: [
          TitleBar(
            title: "ข้อมูลยาควบคุม",
            onBack: () {
              Navigator.pop(dialogContext);
            },
            action: "บันทึก",
            onAction: () {
              _viewModel.setCompliance(
                patientId: patientController.text.trim(),
                prescriberName: prescriberController.text.trim(),
                pharmacistName: pharmacistController.text.trim(),
              );
              Navigator.pop(dialogContext);
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: patientController,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อ/รหัสผู้ป่วย',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: prescriberController,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อแพทย์ผู้สั่งยา',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pharmacistController,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อเภสัชกรผู้จ่ายยา',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCustomerDialog() {
    showCenterDialog(
      context: context,
      builder: (context) => CustomerAddPage(onBack: () {
        Navigator.pop(context);
      }, onAdd: () {
        Navigator.pop(context);
        refreshCustomer();
      }),
    );
  }

  void _showPaymentDialog() {
    showPaymentDialog(
      context,
      alertKey: _alertKey,
      amount: _total,
      onCompleted: (tendered, typeMode) {
        _viewModel.checkout(tendered: tendered, type: typeMode);
      },
      onError: () {
        _showError("คุณรับเงินน้อยกว่ายอดราคาสินค้า");
      },
    );
  }
}
