import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:pos/presentation/core/page_bar.dart';
import 'package:design_system/widgets/snack_bar.dart';
import 'package:design_system/widgets/error_state.dart';

// Project imports:
import 'package:pos/container.dart';
import 'package:pos/domain/model/stock_count/stock_count.dart';
import 'package:pos/localizations/language/languages.dart';
import 'package:pos/presentation/core/list_empty_state.dart';
import 'package:pos/presentation/constants.dart';
import 'package:pos/presentation/stock_count/argument.dart';
import 'package:pos/presentation/stock_count/main/stock_counts_state.dart';
import 'package:pos/presentation/stock_count/main/stock_counts_view_model.dart';
import 'package:design_system/theme/app_colors.dart';

class StockCountsPage extends StatefulWidget {
  const StockCountsPage({super.key});

  @override
  State<StatefulWidget> createState() => _StockCountsPageState();
}

class _StockCountsPageState extends State<StockCountsPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  late CustomSnackBar _snackBar;
  late StockCountsViewModel _viewModel;
  late StreamSubscription<String> _errors;

  @override
  void initState() {
    super.initState();
    _viewModel = sl<StockCountsViewModel>();
    _errors = _viewModel.errors.listen(_showError);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.getStockCounts();
    });
  }

  void _showError(String message) {
    _snackBar.hideAll();
    _snackBar.showErrorSnackBar(message);
  }

  @override
  void dispose() {
    _errors.cancel();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _snackBar = CustomSnackBar(key: const Key("snackbar"), context: context);
    return Scaffold(
      key: _scaffoldKey,
      appBar: buildPageBar(
        context,
        Languages.of(context).stockCountsTitle,
        actions: [
          IconButton(
            tooltip: Languages.of(context).newStockCount,
            splashRadius: 20,
            onPressed: () {
              _nextToStockCountManage(context);
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return ValueListenableBuilder<StockCountsState>(
      valueListenable: _viewModel.state,
      builder: (BuildContext context, StockCountsState state, _) {
        // A failed load is not an empty shop: it says so, with a retry.
        if (state.error != null && state.items.isEmpty) {
          return ErrorState(
              message: state.error!, onRetry: _viewModel.getStockCounts);
        }
        if (state.loading && state.items.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 6,
              color: Theme.of(context).colorScheme.primary,
              strokeCap: StrokeCap.round,
            ),
          );
        }
        if (state.items.isEmpty) {
          return ListEmptyState(
            searched: false,
            icon: Icons.fact_check_outlined,
            title: Languages.of(context).noStockCountsYet,
            addLabel: Languages.of(context).addFirstStockCount,
            onAdd: () => _nextToStockCountManage(context),
          );
        }
        return _buildStockCounts(state.items);
      },
    );
  }

  Widget _buildStockCounts(List<StockCount> items) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final content = items[index];
        return Column(children: [
          ListTile(
            title: Text(content.countNo),
            subtitle: Text(
              "รายการ: ${content.items.length}, วันที่: ${content.getCreatedDate()}",
              style: TextStyle(
                  color: AppColors.of(context).textSecondary, fontSize: 14),
            ),
            trailing: Icon(Icons.arrow_forward_ios,
                size: 16, color: AppColors.of(context).textSecondary),
            onTap: () {
              _nextToStockCountManage(context, stockCountId: content.id);
            },
          ),
          const Divider(height: 1),
        ]);
      },
    );
  }

  Future<void> _nextToStockCountManage(BuildContext context,
      {String? stockCountId}) async {
    var _ = await Navigator.pushNamed(
      context,
      stockCountManageRoute,
      arguments: StockCountManageArgument(stockCountId),
    );
    _viewModel.getStockCounts();
  }
}
