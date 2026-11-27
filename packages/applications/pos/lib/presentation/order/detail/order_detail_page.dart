import 'dart:async';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:common/core/ext/widget_ext.dart';
import 'package:pos/presentation/core/page_bar.dart';
import 'package:design_system/widgets/snack_bar.dart';
import 'package:intl/intl.dart';

// Project imports:
import 'package:pos/container.dart';
import 'package:pos/domain/model/customer/customer.dart';
import 'package:pos/domain/model/order/order_detail.dart';
import 'package:pos/domain/model/order/order_item_detail.dart';
import 'package:pos/domain/model/product/product.dart';
import 'package:pos/presentation/order/detail/bill_receipt.dart';
import 'package:pos/domain/model/supplier/supplier.dart';
import 'package:pos/localizations/language/languages.dart';
import 'package:pos/presentation/constants.dart';
import 'package:pos/presentation/order/bill_summary.dart';
import 'package:design_system/widgets/dialogs.dart';
import 'package:pos/presentation/order/argument.dart';
import 'package:pos/presentation/order/core/export_pdf.dart';
import 'package:pos/presentation/order/return/product_return_widget.dart';
import 'package:pos/presentation/order/return/product_returns_history_widget.dart';
import 'package:pos/presentation/product/argument.dart';
import 'package:design_system/theme/color.dart';
import 'order_detail_header.dart';
import 'order_detail_state.dart';
import 'order_line_tile.dart';
import 'order_detail_view_model.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<StatefulWidget> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final _nameEditingController = TextEditingController();
  final _addressEditingController = TextEditingController();

  final _viewNode = FocusNode();
  final _nameNode = FocusNode();
  final _addressNode = FocusNode();

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final format = NumberFormat("#,##0.00", "en_US");

  late CustomSnackBar _snackBar;
  late OrderDetailViewModel _viewModel;

  List<OrderItemDetail> orderItem = [];

  OrderDetail? order;

  double change = 0;

  bool isAdmin = false;

  bool _loadingShown = false;

  final _subscriptions = <StreamSubscription<void>>[];

  @override
  void initState() {
    super.initState();
    _viewModel = sl<OrderDetailViewModel>();
    _viewModel.state.addListener(_onStateChanged);
    _subscriptions.addAll([
      _viewModel.errors.listen(_showError),
      _viewModel.removals.listen(_onOrderRemoved),
      _viewModel.receipts.listen(_onReceiptReady),
      _viewModel.supplierSetups.listen(_onSupplierSetupNeeded),
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.checkLogin();
      _viewModel.getOrderById(widget.orderId);
    });
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
    setState(() {
      order = state.order;
      orderItem = state.items;
      isAdmin = state.isAdmin;
    });
  }

  void _showError(String message) {
    _snackBar.hideAll();
    _snackBar.showErrorSnackBar(message);
  }

  void _onOrderRemoved(OrderDetail removed) {
    Navigator.pop(context, removed);
  }

  void _onReceiptReady(SupplierResult result) {
    _showCustomerDialog(result.supplier, result.customer);
  }

  void _onSupplierSetupNeeded(void _) {
    if (!mounted) return;
    _nextToSupplier(context);
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _viewModel.state.removeListener(_onStateChanged);
    _viewModel.dispose();

    _nameNode.dispose();
    _addressNode.dispose();
    _viewNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _snackBar = CustomSnackBar(key: const Key("snackbar"), context: context);
    return Scaffold(
      key: _scaffoldKey,
      appBar: buildPageBar(
        context,
        Languages.of(context).orderDetailTitle,
        actions: _buildAction(context),
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: CustomColor.statusBarColor,
        ),
        child: _buildBody(context),
      ),
      // The foot is the Scaffold's bottom bar, which a floating snack bar
      // (success, loading, error) rises above instead of covering.
      bottomNavigationBar: BillSummary(
          total: _viewModel.state.value.total,
          totalCost: _viewModel.state.value.totalCost,
          showCost: isAdmin),
    );
  }

  List<Widget> _buildAction(BuildContext context) {
    return <Widget>[
      OrderDetailActions(
        bill: order,
        isAdmin: isAdmin,
        onPrint: () => _viewModel.getSupplier(order?.customerCode ?? ""),
        // The sync button refetches. It used to set a "total cost updated"
        // flag in state that this page read back and turned into exactly
        // this call.
        onSync: () => _viewModel.getOrderById(widget.orderId),
        onReturns: () => _showProductReturnsHistoryDialog(context),
        onDelete: () => _showRemoveOrderConfirm(context),
      ),
    ];
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        OrderDetailHeader(bill: order),
        _buildOrderItem(context),
      ],
    );
  }

  Widget _buildOrderItem(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: orderItem.length,
        itemBuilder: (context, index) {
          final content = orderItem[index];
          return OrderLineTile(
            line: content,
            unitName: _viewModel.state.value.unitNameOf(content),
            billCancelled: _viewModel.state.value.order?.isCancelled ?? false,
            isAdmin: isAdmin,
            onTap: () {
              if (isAdmin) {
                _nextToProductEdit(context, content.product);
              }
            },
            onDelete: () => _showRemoveOrderItemConfirm(context, content),
            onHistory: () => _nextToOrderHistory(context, content.product),
            onReturn: () => _showProductReturnDialog(context, content),
          );
        },
      ),
    );
  }

  void _showRemoveOrderConfirm(BuildContext context) {
    showConfirmDialog(context, "ต้องการลบรายการใช่หรือไม่?", () {
      _viewModel.removeOrderById(widget.orderId);
    });
  }

  void _showRemoveOrderItemConfirm(
      BuildContext context, OrderItemDetail orderItem) {
    showConfirmDialog(context, "ต้องการลบสินค้าใช่หรือไม่?", () {
      _viewModel.removeOrderItem(widget.orderId, orderItem.id);
    });
  }

  Future<void> _nextToProductEdit(
      BuildContext context, Product? product) async {
    if (product != null) {
      var result = await Navigator.pushNamed(context, productEditRoute,
          arguments: ProductArgument(product));
      if (result != null) {
        _viewModel.getOrderById(widget.orderId);
      }
    }
  }

  Future<void> _nextToOrderHistory(
      BuildContext context, Product? product) async {
    if (product != null) {
      var result = await Navigator.pushNamed(context, orderHistoryRoute,
          arguments: OrderHistoryArgument(product));
      if (result != null) {
        _viewModel.getOrderById(widget.orderId);
      }
    }
  }

  void _showProductReturnDialog(BuildContext context, OrderItemDetail content) {
    showCenterDialog(
      minWidth: 360,
      minHeight: 560,
      maxHeight: 560,
      maxWidth: 360,
      context: context,
      builder: (context) => ProductReturnWidget(
        orderId: widget.orderId,
        orderItemId: content.id,
        productName: content.product?.name ?? "",
        price: content.paidPerUnit(),
        maxReturnable: content.quantity - content.returnedQty,
        onComplete: () {
          _viewModel.getOrderById(widget.orderId);
        },
      ),
    );
  }

  void _showProductReturnsHistoryDialog(BuildContext context) {
    showCenterDialog(
      context: context,
      builder: (context) =>
          ProductReturnsHistoryWidget(orderId: widget.orderId),
    );
  }

  Future<void> _generateReceipt(Supplier supplier) async {
    final bill = order;
    if (bill == null) return;
    final receipt =
        billReceipt(order: bill, supplier: supplier, customer: _getCustomer());

    if (kIsWeb) {
      ExportPdf.download(receipt);
    } else {
      ExportPdf.generate(receipt);
    }
  }

  Future<void> _nextToSupplier(BuildContext context) async {
    var _ = await Navigator.pushNamed(context, supplierRoute);
  }

  void _showCustomerDialog(Supplier supplier, Customer? customer) {
    _nameEditingController.text = customer?.name ?? order?.customerName ?? "";
    _addressEditingController.text = customer?.address ?? "";

    AlertDialog alert = AlertDialog(
      title: const Text("Input Customer"),
      contentPadding: const EdgeInsets.all(16.0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          buildTextFormField(
            context,
            _nameNode,
            _nameEditingController,
            "Name*",
            TextInputType.text,
            _addressNode,
          ),
          const Padding(
            padding: EdgeInsets.only(top: 12),
          ),
          buildAddressFormField(
            context,
            _addressNode,
            _addressEditingController,
            "Address*",
            TextInputType.text,
            _viewNode,
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        TextButton(
          child: const Text('Confirm'),
          onPressed: () {
            Navigator.pop(context);
            _generateReceipt(supplier);
          },
        ),
      ],
    );
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Customer _getCustomer() {
    return Customer(
      id: "",
      name: _nameEditingController.text,
      address: _addressEditingController.text,
      phone: "",
      email: "",
      code: '',
      status: '',
      type: '',
    );
  }
}
