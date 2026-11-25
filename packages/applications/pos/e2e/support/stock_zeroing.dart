// How much to adjust each lot of a run's product so that it holds nothing
// before the product is deleted. Pure, so it is unit-tested.
//
// pos-api only marks a deleted product (deletedDate) and its stock report
// keeps summing the product's stock rows (product_stock.go:635-672), so a
// product deleted with stock on hand would stay in that report for good.

typedef LotOnHand = ({String stockId, int quantity});
typedef LotAdjustment = ({String stockId, int delta});

/// One adjustment per lot that holds anything, bringing it to 0. Lots at 0
/// are skipped: pos-api refuses a zero delta (ledger/adjust.go:123).
List<LotAdjustment> zeroingDeltas(Iterable<LotOnHand> lots) => [
      for (final lot in lots)
        if (lot.quantity != 0) (stockId: lot.stockId, delta: -lot.quantity),
    ];
