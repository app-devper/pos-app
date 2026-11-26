/// The banknote steps a quick-cash amount rounds a total up to.
const _stepsInBaht = [20, 50, 100, 500, 1000];

/// The most quick-cash amounts the payment dialog offers.
const _maxQuickCashAmounts = 4;

const _satangPerBaht = 100;

/// The quick-cash amounts the payment dialog offers for [total]: [total]
/// rounded up to the next multiple of 20, 50, 100, 500 and 1000, each
/// strictly above it, distinct, ascending, at most four. None for a total of
/// zero or less.
///
/// Worked in whole satang, so a total such as 59.99 rounds up to exactly 60.
List<double> quickCashAmounts(double total) {
  if (total <= 0) return List.unmodifiable(const <double>[]);
  final totalSatang = (total * _satangPerBaht).round();
  final amounts = {
    for (final step in _stepsInBaht) _nextAbove(totalSatang, step),
  }.toList()
    ..sort();
  return List.unmodifiable(
      amounts.take(_maxQuickCashAmounts).map((baht) => baht.toDouble()));
}

/// The smallest multiple of [stepBaht], in baht, strictly above
/// [totalSatang].
int _nextAbove(int totalSatang, int stepBaht) {
  final stepSatang = stepBaht * _satangPerBaht;
  return (totalSatang ~/ stepSatang + 1) * stepBaht;
}
