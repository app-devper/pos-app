import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:design_system/widgets/app_bar.dart';
import 'package:design_system/widgets/snack_bar.dart';

// Project imports:
import 'package:pos/container.dart';
import 'package:pos/domain/model/order/order_item_detail.dart';
import 'package:pos/domain/model/product/product.dart';
import 'package:pos/localizations/language/languages.dart';
import 'package:pos/presentation/constants.dart';
import 'package:pos/presentation/order/core/export_csv.dart';
import 'package:design_system/theme/color.dart';
import 'package:pos/presentation/order/bill_summary.dart';
import 'package:pos/presentation/order/history/order_history_tile.dart';
import 'order_history_view_model.dart';

class OrderHistoryPage extends StatefulWidget {
  final Product product;

  const OrderHistoryPage({
    super.key,
    required this.product,
  });

  @override
  State<StatefulWidget> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  late CustomSnackBar _snackBar;
  late OrderHistoryViewModel _viewModel;
  late StreamSubscription<String> _errors;

  double change = 0;

  bool isAdmin = true;
  List<OrderItemDetail> orderItems = [];

  bool _loadingShown = false;

  @override
  void initState() {
    super.initState();
    _viewModel = sl<OrderHistoryViewModel>();
    _viewModel.state.addListener(_onStateChanged);
    _errors = _viewModel.errors.listen(_showError);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.getOrderItemByProductId(widget.product.id);
    });
  }

  void _showError(String message) {
    _snackBar.hideAll();
    _snackBar.showErrorSnackBar(message);
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
      orderItems = state.items;
    });
  }

  @override
  void dispose() {
    _viewModel.state.removeListener(_onStateChanged);
    _errors.cancel();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _snackBar = CustomSnackBar(key: const Key("snackbar"), context: context);
    return Scaffold(
      key: _scaffoldKey,
      appBar: buildAppBar(
        Languages.of(context).orderHistoryTitle,
        actions: _buildAction(context),
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: CustomColor.statusBarColor,
        ),
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return SizedBox(
      height: size.height,
      width: size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 50,
            padding: const EdgeInsets.only(left: defaultPagePadding),
            alignment: Alignment.centerLeft,
            child: Text(
              widget.product.name,
              textAlign: TextAlign.justify,
            ),
          ),
          _buildOrderItem(context),
          _buildSummaryTotal(),
        ],
      ),
    );
  }

  List<Widget> _buildAction(BuildContext context) {
    return <Widget>[
      IconButton(
        tooltip: Languages.of(context).downloadSalesCsv,
        splashRadius: 20,
        onPressed: () {
          ExportCsv.downloadOrderItems(widget.product, orderItems);
        },
        icon: const Icon(Icons.download),
      ),
    ];
  }

  Expanded _buildOrderItem(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: orderItems.length,
        itemBuilder: (context, index) =>
            OrderHistoryTile(line: orderItems[index], showCost: isAdmin),
      ),
    );
  }

  Widget _buildSummaryTotal() {
    final state = _viewModel.state.value;
    return BillSummary(
      total: state.total,
      totalCost: state.totalCost,
      showCost: isAdmin,
    );
  }
}
