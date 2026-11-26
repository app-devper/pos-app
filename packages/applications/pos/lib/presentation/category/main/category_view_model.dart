// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:common/core/error/failure.dart';
import 'package:common/core/state/one_shot.dart';
import 'package:common/core/state/view_state.dart';

// Project imports:
import 'category_state.dart';

import 'package:pos/domain/repositories/category_repository.dart';

class CategoryViewModel {
  final CategoryRepository categoryRepo;

  CategoryViewModel({
    required this.categoryRepo,
  });

  final _state = ViewState<CategoryState>(const CategoryState());

  /// Shown as a snackbar and then gone. It never belonged in state: a message
  /// the view had to remember to clear is one it can forget to clear.
  final _errors = OneShot<String>();

  ValueListenable<CategoryState> get state => _state;

  Stream<String> get errors => _errors.stream;

  Future<void> getCategories() async {
    _state.value = _state.value.copyWith(loading: true, clearError: true);
    try {
      final items = await categoryRepo.getCategories();
      _state.value = _state.value.copyWith(loading: false, items: items);
    } on Exception catch (e) {
      _failLoad(toFailure(e).getMessage());
    }
  }

  Future<void> updateDefaultCategoryById(String categoryId) async {
    _state.value = _state.value.copyWith(loading: true);
    try {
      await categoryRepo.updateDefaultCategoryById(categoryId);
      await getCategories();
    } on Exception catch (e) {
      _state.value = _state.value.copyWith(loading: false);
      _errors.emit(toFailure(e).getMessage());
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
