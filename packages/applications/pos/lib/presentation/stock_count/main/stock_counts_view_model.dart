// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:common/core/error/failure.dart';
import 'package:common/core/state/one_shot.dart';
import 'package:common/core/state/view_state.dart';

// Project imports:
import 'package:pos/presentation/stock_count/main/stock_counts_state.dart';
import 'package:pos/domain/repositories/stock_count_repository.dart';

class StockCountsViewModel {
  final StockCountRepository stockCountRepo;

  StockCountsViewModel({
    required this.stockCountRepo,
  });

  /// Loading from the start: the page's first frame comes before its first
  /// load, and must not say the list is empty.
  final _state =
      ViewState<StockCountsState>(const StockCountsState(loading: true));

  /// Shown as a snackbar and then gone. It never belonged in state: a message
  /// the view had to remember to clear is one it can forget to clear.
  final _errors = OneShot<String>();

  ValueListenable<StockCountsState> get state => _state;

  Stream<String> get errors => _errors.stream;

  Future<void> getStockCounts() async {
    _state.value = _state.value.copyWith(loading: true, clearError: true);
    try {
      final items = await stockCountRepo.getStockCounts();
      _state.value = _state.value.copyWith(loading: false, items: items);
    } on Exception catch (e) {
      _failLoad(toFailure(e).getMessage());
    }
  }

  /// A failed load: with nothing listed the page shows [message] with a
  /// retry instead of an empty list; over a list it is a snackbar.
  void _failLoad(String message) {
    final hadItems = _state.value.items.isNotEmpty;
    _state.value = _state.value.copyWith(loading: false, error: message);
    if (hadItems) _errors.emit(message);
  }

  void dispose() {
    _state.dispose();
    _errors.dispose();
  }
}
