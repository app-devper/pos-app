// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:common/core/error/failure.dart';
import 'package:common/core/state/view_state.dart';

// Project imports:
import 'package:pos/domain/model/customer/customer.dart';
import 'package:pos/presentation/customer/main/customers_state.dart';

import 'package:pos/domain/repositories/customer_repository.dart';

class CustomersViewModel {
  final CustomerRepository customerRepo;

  CustomersViewModel({
    required this.customerRepo,
  });

  final _state = ViewState<CustomersState>(const CustomersState());

  ValueListenable<CustomersState> get state => _state;

  /// The customers that are listed (archived ones never are), and the
  /// search typed above them.
  List<Customer> _all = const [];
  String _query = '';

  Future<void> getCustomers() async {
    _state.value = _state.value.copyWith(loading: true, clearError: true);
    try {
      final customers = await customerRepo.getLocalCustomers();
      // A removed customer is only archived by pos-api, which still returns
      // it; the repository keeps it (an old bill still names it).
      _all = List<Customer>.unmodifiable(
          customers.where((customer) => !customer.isArchived));
      _state.value = _state.value.copyWith(loading: false, items: _filter());
    } on Exception catch (e) {
      _state.value = _state.value
          .copyWith(loading: false, error: toFailure(e).getMessage());
    }
  }

  /// What was typed in the search; a list built afresh shows it again.
  String get query => _query;

  /// Whether the list is narrowed by a search: a query of only spaces is
  /// none, as [search] trims it.
  bool get isSearching => _query.trim().isNotEmpty;

  /// Lists the customers whose name, code or phone holds [query], ignoring
  /// case; an empty query lists them all.
  void search(String query) {
    _query = query;
    _state.value = _state.value.copyWith(items: _filter());
  }

  List<Customer> _filter() {
    final lower = _query.trim().toLowerCase();
    if (lower.isEmpty) return _all;
    return List<Customer>.unmodifiable(_all.where((customer) =>
        customer.name.toLowerCase().contains(lower) ||
        customer.code.toLowerCase().contains(lower) ||
        customer.phone.toLowerCase().contains(lower)));
  }

  /// Loads the list again: after an add, a rename or a removal beside it,
  /// on a wide screen, where the list stays on screen.
  Future<void> reload() => getCustomers();

  void dispose() {
    _state.dispose();
  }
}
