// Project imports:
import 'package:pos/localizations/language/languages.dart';

/// What a lot is called in a control's name: its lot number, or, for a lot
/// with none, its row on the screen (and its import date when it has one).
/// The row is always given for such a lot: two lots received the same day
/// share their date.
String lotName(
  Languages names,
  String lotNumber, {
  required int row,
  String importDate = '',
}) =>
    lotNumber.trim().isNotEmpty
        ? lotNumber
        : names.unnumberedLot(row, importDate: importDate);
