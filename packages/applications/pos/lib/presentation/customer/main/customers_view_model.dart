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

  Future<void> getCustomers() async {
    _state.value = _state.value.copyWith(loading: true, clearError: true);
    try {
      final customers = await customerRepo.getLocalCustomers();
      // A removed customer is only archived by pos-api, which still returns
      // it; the repository keeps it (an old bill still names it).
      final items = List<Customer>.unmodifiable(
          customers.where((customer) => !customer.isArchived));
      _state.value = _state.value.copyWith(loading: false, items: items);
    } on Exception catch (e) {
      _state.value = _state.value
          .copyWith(loading: false, error: toFailure(e).getMessage());
    }
  }

  /// Loads the list again: after an add, a rename or a removal beside it,
  /// on a wide screen, where the list stays on screen.
  Future<void> reload() => getCustomers();

  void dispose() {
    _state.dispose();
  }
}
