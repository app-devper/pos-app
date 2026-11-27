// Repositories that hold nothing, for the screens of an empty list.

// Project imports:
import 'package:pos/domain/model/customer/customer.dart';
import 'package:pos/domain/model/stock_count/param.dart';
import 'package:pos/domain/model/stock_count/stock_count.dart';
import 'package:pos/domain/repositories/customer_repository.dart';
import 'package:pos/domain/repositories/stock_count_repository.dart';

/// The shop's customers: none.
class NoCustomers implements CustomerRepository {
  @override
  Future<List<Customer>> getLocalCustomers() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// The shop's stock counts: none.
class NoStockCounts implements StockCountRepository {
  @override
  Future<List<StockCount>> getStockCounts() async => const [];

  @override
  Future<StockCount> createStockCount(CreateStockCountParam param) =>
      throw UnimplementedError();

  @override
  Future<StockCount> getStockCountById(String stockCountId) =>
      throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
