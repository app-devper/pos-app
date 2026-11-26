// A list whose load fails says so and offers to try again: it does not say
// "ยังไม่มี…" as if the shop had none (categories, suppliers, stock counts).

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:common/core/error/exception.dart';
import 'package:design_system/widgets/error_state.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/container.dart';
import 'package:pos/domain/model/category/category.dart';
import 'package:pos/domain/model/stock_count/stock_count.dart';
import 'package:pos/domain/model/supplier/supplier.dart';
import 'package:pos/domain/repositories/category_repository.dart';
import 'package:pos/domain/repositories/stock_count_repository.dart';
import 'package:pos/domain/repositories/supplier_repository.dart';
import 'package:pos/presentation/category/main/category_page.dart';
import 'package:pos/presentation/category/main/category_view_model.dart';
import 'package:pos/presentation/stock_count/main/stock_counts_page.dart';
import 'package:pos/presentation/stock_count/main/stock_counts_view_model.dart';
import 'package:pos/presentation/supplier/main/suppliers_page.dart';
import 'package:pos/presentation/supplier/main/suppliers_view_model.dart';
import '../../support/app_languages.dart';
import '../category/main/category_view_model_test.dart' as categories;
import '../stock_count/manage/stock_count_manage_view_model_test.dart'
    as counts;
import '../supplier/main/suppliers_view_model_test.dart' as suppliers;

/// A load that fails the first time and answers [items] after that.
class _FailsFirst<T> {
  final List<T> items;
  var calls = 0;

  _FailsFirst(this.items);

  Future<List<T>> load() async {
    calls++;
    if (calls == 1) throw const NetworkException(message: 'offline');
    return items;
  }
}

class _Categories implements CategoryRepository {
  final _FailsFirst<Category> loads;
  _Categories(this.loads);

  @override
  Future<List<Category>> getCategories() => loads.load();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Suppliers implements SupplierRepository {
  final _FailsFirst<Supplier> loads;
  _Suppliers(this.loads);

  @override
  Future<List<Supplier>> getSuppliers() => loads.load();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _StockCounts implements StockCountRepository {
  final _FailsFirst<StockCount> loads;
  _StockCounts(this.loads);

  @override
  Future<List<StockCount>> getStockCounts() => loads.load();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Categories that answer each load from [outcomes] in turn: a list, or
/// null for a failed load.
class _ScriptedCategories implements CategoryRepository {
  final List<List<Category>?> outcomes;
  var calls = 0;

  _ScriptedCategories(this.outcomes);

  @override
  Future<List<Category>> getCategories() async {
    final outcome = outcomes[calls++];
    if (outcome == null) throw const NetworkException(message: 'offline');
    return outcome;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// The categories list over [repo]; a category opens a page that only
/// goes back.
Future<void> _showCategories(
    WidgetTester tester, _ScriptedCategories repo) async {
  sl.registerFactory(() => CategoryViewModel(categoryRepo: repo));
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: const [thaiLanguages],
    onGenerateRoute: (settings) => MaterialPageRoute<void>(
      settings: settings,
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('back'),
        ),
      ),
    ),
    home: const CategoryPage(),
  ));
  await tester.pumpAndSettle();
}

typedef _List = ({
  Widget Function(_FailsFirst<Object>) build,
  _FailsFirst<Object> Function() loads,
  String shown,
});

final _lists = <String, _List>{
  'the categories list': (
    loads: () => _FailsFirst<Category>([categories.buildCategory('1')]),
    build: (loads) {
      sl.registerFactory(() => CategoryViewModel(
          categoryRepo: _Categories(loads as _FailsFirst<Category>)));
      return const CategoryPage();
    },
    shown: 'name-1',
  ),
  'the suppliers list': (
    loads: () => _FailsFirst<Supplier>([suppliers.buildSupplier('1')]),
    build: (loads) {
      sl.registerFactory(() => SuppliersViewModel(
          supplierRepo: _Suppliers(loads as _FailsFirst<Supplier>)));
      return const SuppliersPage();
    },
    shown: 'name-1',
  ),
  'the stock counts list': (
    loads: () => _FailsFirst<StockCount>([counts.buildStockCount('sc1')]),
    build: (loads) {
      sl.registerFactory(() => StockCountsViewModel(
          stockCountRepo: _StockCounts(loads as _FailsFirst<StockCount>)));
      return const StockCountsPage();
    },
    shown: '',
  ),
};

void main() {
  tearDown(() async => sl.reset());

  for (final MapEntry(key: name, value: list) in _lists.entries) {
    testWidgets('$name says its load failed and loads again on ลองใหม่',
        (tester) async {
      // Arrange
      final loads = list.loads();
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [thaiLanguages],
        home: list.build(loads),
      ));
      await tester.pumpAndSettle();

      // Assert: the failure, not an empty shop
      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.textContaining('ยังไม่มี'), findsNothing);

      // Act
      await tester.tap(find.text('ลองใหม่'));
      await tester.pumpAndSettle();

      // Assert: loaded again, and the list shows
      expect(loads.calls, 2);
      expect(find.byType(ErrorState), findsNothing);
      if (list.shown.isNotEmpty) {
        expect(find.textContaining(list.shown), findsWidgets);
      }
    });
  }

  group('the categories list', () {
    testWidgets('a retry that fails again says so again', (tester) async {
      // Arrange
      final repo = _ScriptedCategories([null, null]);
      await _showCategories(tester, repo);

      // Act
      await tester.tap(find.text('ลองใหม่'));
      await tester.pumpAndSettle();

      // Assert
      expect(repo.calls, 2);
      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('ลองใหม่'), findsOneWidget);
      expect(find.textContaining('ยังไม่มี'), findsNothing);
    });

    testWidgets('a failed reload over the list keeps the list and says so once',
        (tester) async {
      // Arrange
      final repo = _ScriptedCategories([
        [categories.buildCategory('1')],
        null,
      ]);
      await _showCategories(tester, repo);

      // Act: back from a category, the list loads again, and fails
      await tester.tap(find.text('name-1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('back'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Assert
      expect(repo.calls, 2);
      expect(find.text('name-1'), findsOneWidget);
      expect(find.byType(ErrorState), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
