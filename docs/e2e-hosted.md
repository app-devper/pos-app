# Running the POS e2e suite against the hosted API

This page is the owner's. A hosted run writes to the real Client `000`
behind `api.devper.app`, where real users see the data. The suite's authors
have never run it there. Read all of this page first. The suite itself is
described in [e2e.md](e2e.md). What it found in the app is in
[e2e-findings.md](e2e-findings.md).

## Setting up

Only the owner runs this. It writes to the real Client `000` behind
`api.devper.app`, where real users see the data.

1. Copy `packages/applications/pos/.env.e2e.example` to `.env.e2e` in the
   same folder (git-ignored). Fill in three accounts of Client `000`: one
   ADMIN, one MANAGER and one USER, as `E2E_ADMIN_USERNAME`,
   `E2E_ADMIN_PASSWORD`, `E2E_MANAGER_…` and `E2E_USER_…`. Never commit it.
   The test reads the file at run time, so the credentials are neither
   compiled in nor visible on the command line.
2. `tools/e2e/run-all.sh hosted` (or `tools/e2e/run.sh hosted <file>`).

## What the owner accepts by running against the hosted API

Every item below is a real cost. None of them can be undone from the app.

- **Bills screen figures for the day.** Each run adds 75.00 to the รายการขาย
  Total, and 30.00 to its Total Cost, for the day it runs. Two extra bills
  show in the list. The app counts cancelled bills (a finding).
- **Items that stay listed.** Cancelled bills stay listed, unmarked.
  Cancelled draft receipts stay listed too.
- **Records that can never be removed.** Per run:
  - 4 imported receipts,
  - 1 stock count (every admin of the Branch sees it in the นับสต็อก list),
  - 1 return,
  - the stock adjustments, including the ones that zero the stock,
  - the 4 deleted products' history rows, including one stock-row history
    entry per deleted lot.
  The products' stock rows themselves are deleted, so the deleted products
  do not appear in pos-api's stock report or its low-stock list.
- **The kept customer `E2E customer`.** Its phone is edited every run, and
  each edit resets its type to ลูกค้าทั่วไป (an app defect). It is never
  removed.
- **The kept supplier `E2E supplier`.** It is never removed.
- **Code numbers.** Every run uses up order codes, receipt codes,
  stock-count numbers and return records.
- **E2E products on the real selling grid.** While a file runs, its product
  is ACTIVE and every cashier of the Branch can see it and sell it, for a
  minute or two per file. The clean-up cancels only bills made wholly of the
  run's product. A real bill that includes it is left alone and reported.
- **UM sessions and one failed sign-in.** The five files that write data
  never sign out, so each leaves a session to expire. `auth_test` makes one
  deliberate failed sign-in per run.
- **The shared sign-in limit.** A run makes 12 sign-in calls, paced to at
  most 3 a minute, against a limit that may be shared with every user behind
  the gateway (below).
- **The midnight caveat.** Do not run near local midnight. The bill
  clean-up looks from the start of the day the file began. A run that
  crosses midnight is handled, but it splits its figures across two days in
  the bills screen.

## First hosted run: do it in stages

1. Run `tools/e2e/run.sh hosted auth_test.dart`, then
   `tools/e2e/run.sh hosted navigation_test.dart`. These write no POS data.
   They check the credentials, the roles and that every screen opens.
2. Run one stocking file: `tools/e2e/run.sh hosted stock_in_test.dart`. Read
   its `E2E leftovers:` line. Then look in the app at what it left:
   - the product is gone from the product list and from the selling grid,
   - the receipt is listed as imported (and the draft as cancelled),
   - nothing new is in the low-stock list.
3. Only then run the rest (`customer`, `selling`, `stock_count`,
   `product_edit`), or `tools/e2e/run-all.sh hosted`.

## The sign-in limit is shared

um-api allows 5 `/auth/login` calls a minute and refuses more with
`UM-429-001` (`app/featues/api/auth.go:31`). What the code says:

- The limit is counted per client address: the key is
  `rate_limit:<route>:<ClientIP>` (`middlewares/rate_limit.go:17-21`).
- The window is fixed. It starts at the first call (`rate_limit.go:37-43`).
- um-api trusts no proxy headers (`app/init.go:27`,
  `SetTrustedProxies(nil)`), so the client address is the connecting address.
- um-api's own comment (`rate_limit.go:23-25`) says the deployed service sees
  every request from the gateway's address. If so, the 5 a minute is one
  limit shared by every user behind the gateway.

Which address the deployed service really sees was not verified.

So on the hosted target:

- **The suite's sign-ins count against a limit that may be shared with
  every real user.** A full run makes 12 sign-in calls: auth 4, navigation 3,
  and 1 for each of the other five files.
- **The harness paces them.** It makes at most 3 in any 60 s, across files,
  through a shared log of sign-in times (`support/sign_in_pacing.dart`). It
  prints `E2E: pacing sign-ins … waiting Ns` when it waits. This adds up to
  about 3 minutes to a full run. The local target is not paced.
- **If the limit refuses a sign-in anyway,** the harness waits 65 s and tries
  once more. That covers `auth_test`'s deliberate wrong password too.
- **Other users' sign-ins can still use up the limit,** and a suite sign-in
  can then fail. A suite burst can also briefly refuse a real user's
  sign-in.
- **If the suite's own credentials are refused** (`[UM-401-004]`, a typo in
  `.env.e2e`), `run-all.sh hosted` stops the whole run right there with
  `run-all: STOPPED … check .env.e2e`. Repeated failed sign-ins could lock
  the account if lockout is enabled. `auth_test`'s plain admin sign-in runs
  before anything else signs in, so it is the one that stops the run.

The error and role watches are longer on the hosted target: 6 s and 3 s,
instead of 2 s and 1 s. A slow API can still show an error after the watch
has ended. Such an error is then missed, or it fails a later step.

## What a hosted run writes to Client 000, and what stays

Everything a run creates is named `E2E-<run id> …` (the run id is
`yyyyMMddHHmmss-<pid>`), or is one of the fixed `E2E …` records that every
run reuses. Barcodes start with `2` (the in-store GS1 range), so they never
match a real product. No test edits anything that already existed, except
the suite's own kept records.

The suite deletes whatever it can. Some data cannot be deleted at all:
receipts, bills, returns and stock counts have no delete. A deleted product
also leaves its rows behind, because pos-api keeps them.

Before deleting a run's product, the clean-up takes every lot of it to 0
with one stock adjustment each (reason อื่นๆ, note `E2E clean-up: stock
zeroed before the product is deleted`). Then it deletes each stock row
(`DELETE /products/stocks/{id}`, the stock dialog's 'ลบสต็อกสินค้า'), and
only then the product. `product_edit_test` does the same through the screens:
the adjustment dialog, then the stock dialog, then delete. pos-api's stock
and low-stock reports count a deleted product's stock rows (a finding). With
no rows left, the product drops out of both. A bill cancelled after that puts
nothing back, because pos-api skips stock rows that are gone. What stays per
product: one zeroing adjustment and one stock-row history entry per lot,
plus its other history rows. A row pos-api refuses to delete (still holding
goods, or reserved by a pending transfer) is named in the leftovers line.

**The four files that stock a product (stock_in, selling, stock_count,
product_edit):** the fixed supplier `E2E supplier`. It is created once and
reused. A supplier cannot be deleted from the app.

**auth and navigation** write no POS data. They do create UM sessions, and
auth makes one failed login on purpose.

**The five files that write data** (customer, stock_in, selling, stock_count,
product_edit) never sign out. They leave a session to expire.

**Every file that writes** consumes code numbers that are never given back:
order codes, receipt codes, stock-count numbers and return records.

**While a file runs,** its product is ACTIVE and shows on the real selling
grid for every cashier of the Branch. A file takes a minute or two.

**`customer_test.dart`:** on hosted it does not create a customer per run.
It reuses the kept customer `E2E customer` (address marked
`created by the E2E suite — safe to edit`) and changes its phone each run.
That edit also resets its type to ลูกค้าทั่วไป, because the app resets a
customer's type on every edit (a finding). The customer is never removed:
pos-api only archives a removed customer, and the app keeps listing archived
customers.

**`stock_in_test.dart`, per run:**

- one product, deleted at the end. Its stock row is deleted first; its
  history and adjustment rows remain in pos-api,
- one imported receipt,
- one cancelled draft receipt. Both stay in the receipt list, because the app
  lists cancelled receipts too. References: `<run id>` and `<run id>-draft`.

**`selling_test.dart`, per run:**

- one product, deleted with its stock rows; its history remains,
- one imported receipt,
- two bills, 75.00 (cash) and 40.00 (PromptPay, to `E2E customer`), both
  cancelled before the file ends,
- one return of 1 piece on the second bill. A return cannot be undone.

**`stock_count_test.dart`, per run:**

- one product, deleted with its stock rows; its history remains,
- one imported receipt,
- one stock count document (`SC-…`, noted `E2E-<run id> stock count`).
  Every admin of the Branch sees it in the นับสต็อก list, for good.

**`product_edit_test.dart`, per run:**

- one product, renamed to `… edit product renamed` and then deleted through
  the screen, its rows remaining,
- one imported receipt.

**Cancelled bills stay in the bills screen, and in its Total.** pos-api marks
a cancelled bill CANCELLED and keeps its amount. The app's รายการขาย list
shows every bill whatever its status and adds all of them into the day's
Total (a finding: `order_view_model.dart:40-57`). The 40.00 bill has its only
line cancelled first, which brings that bill's amount to 0.00. The 75.00 bill
is cancelled whole and keeps its amount. So after a hosted run, the bills
screen for that day lists two extra bills. Its Total shows **75.00 more**
than was really sold, and its Total Cost 30.00 more, for every run made that
day. (The selling file prints
this note when it starts. pos-api's own reports exclude cancelled bills.)
The app's bills screen for that day will not match what was taken. Run the
hosted suite on a day when that is acceptable, or not at all, until the
finding is fixed.

## If a run is interrupted

A run killed part-way (Ctrl-C, a crash, the machine sleeping) skips its
clean-up. It can leave:

- an ACTIVE `E2E-<run id> …` product with stock, on the real selling grid,
- up to two CONFIRMED bills of it, 75.00 and 40.00. pos-api's reports count
  these as revenue,
- a run customer (local target only),
- a draft receipt.

The one command that cleans it up:

```sh
tools/e2e/sweep.sh hosted     # or: tools/e2e/sweep.sh local
```

Worst-case timing: the "each role can sign in" test signs in twice. On the
hosted target each sign-in can be paced and then hit one rate-limit wait
(about 60 s and 65 s). In the worst case that test approaches its 5-minute
bound.

It signs in as admin, using the same pacing. Then it works only through the
app's repositories:

**Run it only when no run is in progress, on any machine.** It cancels a
running file's bills and deletes its product.

It acts on run names only: `E2E-<yyyyMMddHHmmss>-<pid> <what>`, the shape
every run name has (`RunData.runNamePattern`). The kept `E2E customer` and
`E2E supplier` never match, and neither does any other name that merely
starts with `E2E-`.

- It cancels every bill of the last 3 days whose every line is a run-named
  product, **whoever rang it up**. That includes a bill a real cashier rang
  up from the selling grid while a file was running, if it holds only that
  product. A bill that mixes one with anything else is left and reported.
- For every run-named product not yet deleted, it zeroes the lots, deletes
  the stock rows, then deletes the product.
- It removes run-named customers on the local target. On hosted it keeps
  them.
- It cancels draft receipts whose reference starts with a run id followed by
  a space, a hyphen or nothing (`^\d{14}-\d+`). A receipt reference is free
  text, so a real reference typed in that shape would match too.

It prints what it did and what it left. For `hosted` it prints the API host and "run by the owner"
first, and it refuses to run without `.env.e2e`.

Limits:

- It cannot see deleted products. For a product deleted by an older version
  of the suite, which kept its stock rows, cancelling its bill puts the
  pieces back on a row that then stays above 0. Since the rows are now
  deleted with the product, nothing is put back.
