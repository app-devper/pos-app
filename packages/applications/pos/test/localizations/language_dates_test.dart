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
}
