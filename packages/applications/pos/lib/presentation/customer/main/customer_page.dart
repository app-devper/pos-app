import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:design_system/theme/app_colors.dart';

// Package imports:
import 'package:common/core/ext/widget_ext.dart';
import 'package:design_system/widgets/responsive.dart';

// Project imports:
import 'package:pos/container.dart';
import 'package:pos/domain/model/customer/customer.dart';
import 'package:pos/presentation/customer/add/customer_add_page.dart';
import 'package:pos/presentation/customer/edit/customer_edit_page.dart';
import 'package:pos/presentation/customer/main/customer_detail_widget.dart';
import 'package:pos/presentation/customer/main/customer_menu_widget.dart';
import 'package:pos/presentation/customer/main/customer_view_model.dart';
import 'package:pos/presentation/customer/main/customers_view_model.dart';
import 'package:pos/presentation/customer/main/customers_widget.dart';

class CustomerPage extends StatefulWidget {
  final Function() onBack;

  const CustomerPage({super.key, required this.onBack});

  @override
  State<StatefulWidget> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  late CustomerViewModel _viewModel;
  late CustomersViewModel _customers;
  late StreamSubscription<Customer> _loaded;
  late StreamSubscription<String> _errors;
  PageState _pageState = MainPage();

  @override
  void initState() {
    super.initState();
    _viewModel = sl<CustomerViewModel>();
    _customers = sl<CustomersViewModel>();
    _loaded = _viewModel.loaded.listen(_onLoaded);
    _errors = _viewModel.errors.listen(_showError);
  }

  void _onLoaded(Customer customer) {
    if (!mounted) return;
    _show(InfoPage(data: customer));
  }

  void _show(PageState page) => setState(() => _pageState = page);

  /// System Back from [page]: a form returns to what it was opened from, the
  /// detail to the list; on the list Back leaves the page (null).
  VoidCallback? _backFrom(PageState page) {
    return switch (page) {
      EditPage(:final data) => () => _show(InfoPage(data: data)),
      InfoPage() || AddPage() => () => _show(MainPage()),
      _ => null,
    };
  }

  /// The failure used to go nowhere: the panel simply did not change, so a
  /// lookup that could not reach the server looked like nothing happened.
  void _showError(String message) {
    showAlertDialog(context, message, () {});
  }

  @override
  void dispose() {
    _loaded.cancel();
    _errors.cancel();
    _viewModel.dispose();
    _customers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final back = _backFrom(_pageState);
    return PopScope<Object?>(
      canPop: back == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) back?.call();
      },
      child: Responsive(mobile: _buildMobile(), desktop: _buildDesktop()),
    );
  }

  Row _buildDesktop() {
    return Row(
      children: [
        SizedBox(
          width: 320,
          child: CustomersWidget(
            viewModel: _customers,
            onAdd: () {
              _show(AddPage());
            },
            onSelected: (value) {
              _viewModel.getCustomerById(value.id);
            },
            onBack: () {
              widget.onBack();
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
        return CustomersWidget(
          viewModel: _customers,
          onAdd: () {
            _show(AddPage());
          },
          onSelected: (value) {
            _viewModel.getCustomerById(value.id);
          },
          onBack: () {
            widget.onBack();
          },
        );
      } else {
        return CustomerMenuWidget(
          onAdd: () {
            _show(AddPage());
          },
          onExport: () {},
        );
      }
    } else if (_pageState is InfoPage) {
      final customer = (_pageState as InfoPage).data;
      return CustomerDetailWidget(
        onEdit: () {
          _viewModel.getCustomerById(customer.id);
        },
        customer: customer,
        onBack: () {
          _show(MainPage());
        },
        onClickEdit: () {
          _show(EditPage(data: customer));
        },
      );
    } else if (_pageState is EditPage) {
      final customer = (_pageState as EditPage).data;
      return CustomerEditPage(
        customer: customer,
        onBack: () {
          _show(InfoPage(data: customer));
        },
        onEdit: () {
          _customers.reload();
          _viewModel.getCustomerById(customer.id);
        },
        onRemove: () {
          _customers.reload();
          _show(MainPage());
        },
      );
    } else if (_pageState is AddPage) {
      return CustomerAddPage(
        onBack: () {
          _show(MainPage());
        },
        onAdd: () {
          _customers.reload();
          _show(MainPage());
        },
      );
    }
    return const SizedBox.shrink();
  }
}

abstract class PageState {}

class MainPage extends PageState {}

class AddPage extends PageState {}

class InfoPage extends PageState {
  final Customer data;

  InfoPage({
    required this.data,
  });
}

class EditPage extends PageState {
  final Customer data;

  EditPage({
    required this.data,
  });
}
