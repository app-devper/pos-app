# POS end-to-end UI tests

The e2e suite drives the real POS app (`packages/applications/pos`) through
its screens and checks what a user would see, against a real backend
(um-api and pos-api).

## 1. What the suite is

- Each file under `packages/applications/pos/e2e/` is a `flutter test` file.
  It starts the real app inside the test: the real dependency registrations
  (`um.initCore`, `um.initUm`, `pos.initPos`), the real repositories and real
  HTTP. Nothing is mocked. It runs on the Dart VM. There is no browser and no
  device.
- The test taps, types and reads widgets the way a user does. Every finder is
  `.hitTestable()` or scoped to a screen. The suite never calls
  `pumpAndSettle`: the app has spinners that never settle, so every wait is a
  bounded pump-until (`support/pump.dart`).
- The window is 1400×900 (wide layout: sidebar expanded, list and detail side
  by side). The app's Sarabun and Roboto fonts are loaded so that Thai text
  is measured the way it is on a real screen.
- Each file signs in once, as admin unless it tests roles
  (`launchApp(tester, keepSession: true)` + `continueSignedIn`).
- The tests in a file form one ordered chain (`StepChain`). When a step
  fails, every later test fails at once and names the step that broke.
- The app's own HTTP logging is left off, because it would print passwords
  and tokens. No credential or token is printed.

What it cannot see:

- How a browser renders the page (CanvasKit or HTML, browser fonts, CSS),
  and code paths that only run on the web (`kIsWeb` branches, conditional
  imports such as the passkey authenticator and file downloads).
- The camera barcode scanner (`/scan`), passkey sign-in (native prompt),
  file pickers (CSV import) and downloads (PDF/CSV export: the buttons are
  checked to exist, never pressed).
- Anything a production build does differently from a debug build.

## 2. Coverage

| Screen / feature | File | What is asserted |
|---|---|---|
| Sign-in, sign-out | `auth_test.dart` | the app talks to the server the run names; a wrong password gives `[UM-401-004]` and stays on sign-in; sign-in opens the selling screen, sign-out returns to sign-in; admin, manager and user can each sign in |
| Navigation and roles | `navigation_test.dart` | every sidebar area opens its screen without an error; the five จัดการ tiles are shown, and ร้านค้าของฉัน, customers, Goods Receipt, นับสต็อก and ข้อมูลผู้ใช้งาน open and return; a user and a manager see only selling and bills |
| Customers (จัดการ → จัดการลูกค้า) | `customer_test.dart` | add, list, detail, edit phone, remove (local), the kept customer reused (hosted), a missing name is refused |
| Products, Goods Receipt, stock adjustment | `stock_in_test.dart` | a product is created and listed (an empty name is refused); receiving 10 and importing gives exactly 10 on hand, on the list and the stock tab; +2/−2 adjustments give 12 then 10, with history rows and notes; a draft receipt can be deleted |
| Selling, payment, bills, returns, cancelling | `selling_test.dart` | barcode + Enter adds a line, an unknown barcode says `Error: ไม่พบสินค้า`; a cash sale of 3 (`฿75.00`); a short payment is refused; a PromptPay sale with a customer and a per-unit discount (`฿40.00`); a return of 1; cancelling a line and a bill puts stock back: 10 → 7 → 7 → 5 → 6 → 7 → 10 |
| Stock count (จัดการ → นับสต็อก) | `stock_count_test.dart` | an empty count is refused (`โปรดเพิ่มสินค้าอย่างน้อย 1 รายการ`); counting 8 of a lot of 10 sets the stock to 8 (list and stock tab), the count's list row (found by its number, not its position, since another admin may count at the same time) shows `รายการ: 1`, the detail shows `ในระบบ 10 / นับได้ 8` and `-2`, and the product shows the `นับสต็อก` adjustment of −2 |
| Product edit, price, delete | `product_edit_test.dart` | a rename shows in the detail and the list; changing the General price to 30 and adding a wholesale price of 20 shows both on the ราคา tab; the selling grid and a scanned line show the new name at `฿30.00` (the selling screen is entered afresh, so the "grid does not refresh" finding is not met here); deleting the product removes it from the list and its barcode then gives `Error: ไม่พบสินค้า` |

The helpers in `e2e/support/` that hold logic have unit tests in
`packages/applications/pos/test/e2e_support/`. Those tests run with the
normal `flutter test`. The e2e files themselves never do: `flutter test`
only picks up `test/`.

### Not covered

| What | Why |
|---|---|
| Barcode scanner (`/scan`) | needs a camera. Typing the barcode and pressing Enter goes through the same lookup and is covered |
| Passkey sign-in | native/browser prompt |
| CSV import of products | OS file dialog |
| PDF and CSV export, receipts to print | web-only download code. The buttons are checked to exist, not pressed |
| Date-range pickers | platform date picker. Also, an admin never gets the bills date-range dropdown (a finding) |
| UM user management (จัดการ → จัดการผู้ใช้งาน) | belongs to UM. The tile is checked to be shown, not opened |

#### Not reachable from the UI

These screens exist in the code but no button leads to them, so a user can
never see them. They are not tested. Deciding what to do with them is the
owner's call:

- Categories: `/categories`, add and edit. No entry point.
- Suppliers list and edit: `/suppliers`, `/supplier-edit`. Only
  `/supplier-add` (from the receipt page) and `/supplier` (ร้านค้าของฉัน)
  can be reached.
- Expired products and lot edit: `/product-expired`, `/product-lot-edit`.
- `/product-add` and the customer routes are named in `constants.dart` but
  are not in the router ("Page Not Found"). The real pages are embedded in
  the shell.

## 3. Running locally

### Prerequisites

- `fvm` with Flutter 3.38.7 (see `README.md`) and `melos bootstrap` done.
- Go, `mongod` with `mongosh`, and `redis-server` on `PATH`.
- Checkouts of `um-api` and `pos-api` next to this repo's main checkout:

  ```
  <workspace>/Devper/pos-app     this repo (the main checkout)
  <workspace>/Devper/pos-api
  <workspace>/UM/um-api
  ```

  From a git worktree, the main checkout is found through git. Set
  `E2E_WORKSPACE`, or `UM_API_DIR` and `POS_API_DIR`, to use other
  locations.

### Commands (from the repo root)

```sh
tools/e2e/run.sh local stock_in_test.dart   # one file
tools/e2e/run-all.sh local                  # every file, one run id, summary
```

`run.sh local` starts whatever part of the stack is not running:

- MongoDB as a one-node replica set (pos-api needs transactions for its
  stock ledger) on port 27719,
- Redis on 6390,
- um-api on 8585,
- pos-api on 8586.

It builds the two APIs, seeds UM and waits for `/health`. It also clears
um-api's sign-in rate-limit counters. The seed (`tools/e2e/seed-local`)
creates System POS for Client `000` and three ACTIVE users, `e2e-admin`,
`e2e-manager` and `e2e-user`. It writes their passwords to
`packages/applications/pos/.env.e2e.local`, which is git-ignored. A
password that still verifies is kept, so runs can overlap.

`run-all.sh` runs the files in this order: auth, navigation, customer,
stock_in, selling, stock_count, product_edit, then any other `*_test.dart`
alphabetically. All files share one run id. At the end it prints:

- one line per file (`PASS`/`FAIL`, passed/skipped/failed, sign-ins),
- each file's `E2E leftovers:` line,
- the FINDING skips.

It exits non-zero if any file failed. The logs stay in
`${TMPDIR}/pos-e2e-run-all.*`.

### State, and stopping the stack

Everything the stack writes is under `${TMPDIR:-/tmp}/pos-e2e-stack`
(override with `E2E_STACK_STATE`):

- the Mongo data (databases `e2e_um` and `e2e_pos`),
- the Redis dump,
- the built binaries,
- logs and pid files.

```sh
tools/e2e/local-stack.sh status
tools/e2e/local-stack.sh stop     # stops only what the script started
```

To start from an empty database, stop the stack and delete that directory.

## 4. Running against the hosted API

Only the owner runs this. It writes to the real Client `000` behind
`api.devper.app`, where real users see the data.

1. Copy `packages/applications/pos/.env.e2e.example` to `.env.e2e` in the
   same folder (git-ignored). Fill in three accounts of Client `000`: one
   ADMIN, one MANAGER and one USER, as `E2E_ADMIN_USERNAME`,
   `E2E_ADMIN_PASSWORD`, `E2E_MANAGER_…` and `E2E_USER_…`. Never commit it.
   The test reads the file at run time, so the credentials are neither
   compiled in nor visible on the command line.
2. `tools/e2e/run-all.sh hosted` (or `tools/e2e/run.sh hosted <file>`).

um-api allows 5 sign-ins a minute per address and refuses more with
`UM-429-001`. The hosted target cannot reset this limit, so the suite keeps
its sign-ins down:

- every file signs in once and keeps the session between its tests,
- `navigation_test.dart` signs in three times (once per role),
- `auth_test.dart` signs in a few times by design.

If the limit is hit, `signIn` waits 65 s and tries once more. A full run
therefore may pause a minute at a time. The per-file `sign-ins` count in the
summary shows each file's share.

### What a hosted run writes to Client 000, and what stays

Everything a run creates is named `E2E-<run id> …` (the run id is
`yyyyMMddHHmmss-<pid>`), or is one of the fixed `E2E …` records that every
run reuses. Barcodes start with `2` (the in-store GS1 range), so they never
match a real product. No test edits anything that already existed, except
the suite's own kept records.

The suite deletes whatever it can. Some data cannot be deleted at all:
receipts, bills, returns and stock counts have no delete. A deleted product
also leaves its rows behind, because pos-api keeps them.

**The four files that stock a product (stock_in, selling, stock_count,
product_edit):** the fixed supplier `E2E supplier`. It is created once and
reused. A supplier cannot be deleted from the app. (auth and navigation write
nothing; customer touches only customers.)

**`customer_test.dart`:** on hosted it does not create a customer per run.
It reuses the kept customer `E2E customer` (address marked
`created by the E2E suite — safe to edit`) and changes its phone each run.
That edit also resets its type to ลูกค้าทั่วไป, because the app resets a
customer's type on every edit (a finding). The customer is never removed:
pos-api only archives a removed customer, and the app keeps listing archived
customers.

**`stock_in_test.dart`, per run:**

- one product, deleted at the end. Its stock row, history and adjustment
  rows remain in pos-api,
- one imported receipt,
- one cancelled draft receipt. Both stay in the receipt list, because the app
  lists cancelled receipts too.

**`selling_test.dart`, per run:**

- one product, deleted, its rows remaining,
- one imported receipt,
- two bills, 75.00 (cash) and 40.00 (PromptPay, to `E2E customer`), both
  cancelled before the file ends,
- one return of 1 piece on the second bill. A return cannot be undone.

**`stock_count_test.dart`, per run:**

- one product, deleted, its rows remaining,
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
Total (a finding: `order_view_model.dart:41-56`). The 40.00 bill has its only
line cancelled first, which brings that bill's amount to 0.00. The 75.00 bill
is cancelled whole and keeps its amount. So after a hosted run, the bills
screen for that day lists two extra bills and its Total shows **75.00 more**
than was really sold, for every run made that day. (The selling file prints
this note when it starts. pos-api's own reports exclude cancelled bills.)
The app's bills screen for that day will not match what was taken. Run the
hosted suite on a day when that is acceptable, or not at all, until the
finding is fixed.

## 5. Findings

Where the app does something a user would call wrong, the suite does not
quietly accept it:

- The running test asserts what the app does now, with a `FINDING` comment
  that names the file and line.
- What a user expects is kept in a test skipped with
  `skip: 'FINDING: <one line with file:line>'`. Each such test was seen
  failing when unskipped. `run-all.sh` lists them under "Findings".
- Layout overflows that would fail every test are let through only around
  the one screen that raises them, and counted:
  - `onReceiptPage` in `support/known_faults.dart`: the supplier picker,
  - `onQuantityKeypad` and `onPaymentDialog` in `support/selling_faults.dart`:
    the two dialogs.

  The tests expect each count to be at least 1. So when the app is fixed,
  those assertions fail, with a message saying what to delete.

When a FINDING test or a tolerance starts failing, the app has probably
been fixed:

1. Confirm the fix in the app's code.
2. Unskip the FINDING test, or delete the tolerance and its counter
   assertion.
3. Change the running test's "as the app behaves" assertion to the expected
   behaviour.
4. Delete the FINDING comment.

If the app has not changed and the test still fails, the test is wrong.
Find out why before editing anything.

## 6. Leftovers, and finding E2E data on a server

Every file prints one line at its end:

```
E2E leftovers: supplier "E2E supplier" (kept for reuse), receive RC_… (imported, cannot be deleted), …
```

The line holds:

- what was kept on purpose (`Cleanup.keep`, the label says why),
- every undo that failed or timed out,
- anything still queued.

`none` means the file left nothing. Undos run after the test, through the
app's repositories rather than its screens, even when the test failed
(`support/cleanup.dart`).

To find suite data on a server:

- Look for names that start with `E2E-` (one run: `E2E-<run id>`) or the
  fixed `E2E supplier` and `E2E customer`.
- Lot numbers are `L<run id>`.
- Receipt references are `<run id> <what>`.
- A stock count's note is `E2E-<run id> stock count`. Its adjustment notes
  read `SC-… E2E-<run id> stock count`.
- Bills carry the run's product name on their lines.

Locally you can also reset everything by deleting the stack's state
directory.
