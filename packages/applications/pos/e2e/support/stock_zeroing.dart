// How much to adjust each lot of a run's product so that it holds nothing,
// and which of its stock rows to delete then, before the product itself is
// deleted. Pure, so it is unit-tested.
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

/// Which stock rows of a run's product to delete once its lots are zeroed:
/// pos-api deletes a row only when it holds nothing (ledger/stock.go:70-72),
/// so a row still above 0 is kept and reported. With no rows left, the
/// deleted product drops out of both stock reports (product_stock.go
/// :567-610 and :635-672 group `product_stocks`).
({List<String> delete, List<LotOnHand> keep}) stockRowsToDelete(
        Iterable<LotOnHand> lots) =>
    (
      delete: [
        for (final lot in lots)
          if (lot.quantity <= 0) lot.stockId,
      ],
      keep: [
        for (final lot in lots)
          if (lot.quantity > 0) lot,
      ],
    );
