// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/widgets/responsive.dart';

// Project imports:
import 'package:pos/domain/model/customer/customer.dart';
import 'package:pos/localizations/language/languages.dart';
import 'package:pos/presentation/customer/main/customers_state.dart';
import 'customer_list_header.dart';
import 'package:pos/presentation/customer/main/customers_view_model.dart';
import 'package:design_system/theme/app_colors.dart';
import 'package:design_system/widgets/error_state.dart';

// Package imports:

/// The customer list. Its [viewModel] belongs to the page, which reloads it
/// after an add, a rename or a removal and disposes it.
class CustomersWidget extends StatefulWidget {
  final CustomersViewModel viewModel;
  final Function(Customer) onSelected;
  final Function() onBack;
  final Function() onAdd;

  const CustomersWidget({
    super.key,
    required this.viewModel,
    required this.onSelected,
    required this.onBack,
    required this.onAdd,
  });

  @override
  State<StatefulWidget> createState() => _CustomersWidgetState();
}

class _CustomersWidgetState extends State<CustomersWidget> {
  CustomersViewModel get _viewModel => widget.viewModel;
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: _viewModel.query);
    // A narrow layout builds the list afresh each time it is shown; a load
    // the page already started is not repeated.
    if (!_viewModel.state.value.loading) {
      _viewModel.getCustomers();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  Widget _buildBody() {
    final isMobile = Responsive.isMobile(context);
    return Column(
      children: <Widget>[
        CustomerListHeader(
          title: Languages.of(context).customerTitle,
          addLabel: Languages.of(context).customerAddTitle,
          showAdd: isMobile,
          onBack: () => widget.onBack(),
          onAdd: () => widget.onAdd(),
          onSearch: _viewModel.search,
          searchController: _search,
        ),
        const Divider(height: 1),
        _buildCustomerList(),
      ],
    );
  }

  void _retry() => _viewModel.getCustomers();

  ValueListenableBuilder<CustomersState> _buildCustomerList() {
    return ValueListenableBuilder<CustomersState>(
      valueListenable: _viewModel.state,
      builder: (BuildContext context, CustomersState state, _) {
        // A failed load used to fall through to an empty list, which reads as
        // "there is nothing" rather than "we could not find out".
        if (state.error != null && state.items.isEmpty) {
          return Expanded(
            child: ErrorState(
              message: state.error!,
              onRetry: _retry,
            ),
          );
        }
        if (state.loading && state.items.isEmpty) {
          return Expanded(
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 6,
                color: Theme.of(context).colorScheme.primary,
                strokeCap: StrokeCap.round,
              ),
            ),
          );
        }
        return _buildCustomer(state.items);
      },
    );
  }

  Expanded _buildCustomer(List<Customer> item) {
    return Expanded(
      child: ListView.builder(
        itemCount: item.length,
        itemBuilder: (context, index) {
          final content = item[index];
          return Column(
            children: [
              ListTile(
                title: Text(content.name),
                subtitle: Text(content.code),
                onTap: () {
                  widget.onSelected(content);
                },
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.of(context).textSecondary,
                ),
              ),
              const Divider(height: 1),
            ],
          );
        },
      ),
    );
  }
}
