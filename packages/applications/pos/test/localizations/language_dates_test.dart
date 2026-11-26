// Flutter imports:
import 'package:flutter_test/flutter_test.dart';

// Package imports:
import 'package:common/config/app_config.dart';

// Project imports:
import 'package:pos/localizations/language/language_en.dart';
import 'package:pos/localizations/language/language_th.dart';

final _thai = LanguageTh(
    config: AppConfig(
        apiUrl: '', logo: '', name: 'Devper POS', system: '', home: ''));
final _english = LanguageEn();

void main() {
  group('the bills list date', () {
    test('reads day then Thai short month in Thai', () {
      expect(_thai.shortDate(DateTime(2026, 11, 26)), '26 พ.ย.');
      expect(_thai.shortDate(DateTime(2026, 1, 5)), '5 ม.ค.');
    });

    test('keeps month then day in English', () {
      expect(_english.shortDate(DateTime(2026, 11, 26)), 'Nov 26');
      expect(_english.shortDate(DateTime(2026, 1, 5)), 'Jan 05');
    });

    test('every month has its Thai short name', () {
      const months = [
        'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', //
        'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
      ];
      for (var month = 1; month <= 12; month++) {
        expect(_thai.shortMonth(DateTime(2026, month, 1)), months[month - 1],
            reason: 'month $month');
        expect(_thai.shortDate(DateTime(2026, month, 9)),
            '9 ${months[month - 1]}');
      }
    });

    test('a month alone is the Thai short month, or the English one', () {
      expect(_thai.shortMonth(DateTime(2026, 12, 1)), 'ธ.ค.');
      expect(_english.shortMonth(DateTime(2026, 12, 1)), 'Dec');
    });
  });

  test('the bills filters and ranges are Thai, with English kept', () {
    expect([_thai.billFilterAll, _thai.billFilterStore, _thai.billFilterOnline],
        ['ทั้งหมด', 'หน้าร้าน', 'ออนไลน์']);
    expect([
      _english.billFilterAll,
      _english.billFilterStore,
      _english.billFilterOnline
    ], [
      'All',
      'Store',
      'Online'
    ]);
    expect(_thai.rangeToday, 'วันนี้');
    expect(_english.rangeToday, 'Today');
  });

  test('a bill row names its customer in Thai, with English kept', () {
    expect(_thai.customerNamed('สมชาย'), 'ลูกค้า: สมชาย');
    expect(_english.customerNamed('Somchai'), 'Customer: Somchai');
  });

  test('a total cost is Thai, with English kept', () {
    expect(_thai.totalCost, 'ต้นทุนรวม');
    expect(_english.totalCost, 'Total cost');
  });

  test('the จัดการ menu keeps its Thai titles and has English ones', () {
    expect([
      _thai.manageStore,
      _thai.manageCustomers,
      _thai.manageUsers,
      _thai.manageReceipts,
      _thai.manageStockCounts,
    ], [
      'ร้านค้าของฉัน',
      'จัดการลูกค้า',
      'จัดการผู้ใช้งาน',
      'ใบรับสินค้า',
      'นับสต็อก',
    ]);
    expect([
      _english.manageStore,
      _english.manageCustomers,
      _english.manageUsers,
      _english.manageReceipts,
      _english.manageStockCounts,
    ], [
      'My store',
      'Customers',
      'Users',
      'Goods receipts',
      'Stock counts',
    ]);
  });
}
