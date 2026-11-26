# POS end-to-end UI tests

The e2e suite drives the real POS app (`packages/applications/pos`) through
its screens and checks what a user would see, against a real backend
(um-api and pos-api).

A second, smaller set drives the app from outside with Maestro, on the Android
emulator and in a browser: see [e2e-maestro.md](e2e-maestro.md).

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
  (`launchApp(tester, keepSession: true)` + `continueSignedIn`). Every launch
  checks that the app points at the run's target API.
- In the four files that write POS data (stock_in, selling, stock_count,
  product_edit), the tests form one ordered chain (`StepChain`). When a step
  fails, every later test fails at once and names the step that broke. auth,
  navigation and customer tests are independent.
- Every test has a 5-minute bound (`e2eTestTimeout`); every list search is
  bounded too (`support/robots/scroll.dart`).
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

One row per feature of the app, built from `presentation/router.dart`, the
shell's sidebar (`home_page.dart`), the จัดการ tiles
(`home_database_page.dart`), the products and receipts menus
(`product_menu_widget.dart`, `receive_menu_widget.dart`) and every dialog
the screens open (`showCenterDialog`, `showConfirmDialog` and the named
`show…Dialog` helpers). **Dart** is this suite (`packages/applications/pos/e2e/`),
**Maestro** the flows of [e2e-maestro.md](e2e-maestro.md) (Android and web).
Widget tests that reach a feature without a server are named where they are
all there is. Where neither suite drives a feature, the last column says why:
**cannot be automated** (and why), or **not automated yet** (it could be;
listed under "Coverage still open" in [e2e-findings.md](e2e-findings.md)).

| Area | Feature | Dart | Maestro | Notes |
|---|---|---|---|---|
| Sign-in | sign in, sign out, a wrong password refused (`[UM-401-004]`), each role signs in | `auth_test.dart` | `auth` | |
| Sign-in | passkey sign-in | — | — | cannot be automated: the browser's or OS's own passkey prompt |
| Shell | every sidebar area opens its screen, and back to selling | `navigation_test.dart` | `navigation` | |
| Shell | what each role sees: admin all areas and bill costs; manager and user selling and bills only, no cost, no store filter, no date range | `navigation_test.dart` | `roles` | the store filter is checked by Dart only: a chip's label is not text on the web |
| Shell | ข้อมูลผู้ใช้งาน (UM's profile page) | `navigation_test.dart` (opens, returns) | `navigation` (opens, returns) | its content is UM's own screen, tested in um-api / the um package |
| ขายสินค้า | a product added from the grid and its search | `selling_test.dart`, `product_edit_test.dart` | `sell_and_bill`, `product_add_delete`, `bill_cancel_return` | |
| ขายสินค้า | a barcode typed + Enter adds a line; unknown says `ไม่พบสินค้า`; a scan right after paying lands in the search field | `selling_test.dart`, `product_edit_test.dart` | `sell_and_bill` (web) | the phone layout has no search field on the selling screen |
| ขายสินค้า | camera barcode scanner (`/scan`) | — | — | cannot be automated: needs a camera (typing the barcode goes through the same lookup, above) |
| ขายสินค้า | quantity dialog `จำนวนสินค้า` (the line's `2x`) | `selling_test.dart` | — | layout: `quantity_dialog_layout_test.dart`, the sweep |
| ขายสินค้า | line dialog: per-unit discount, remove the line | `selling_test.dart`, `product_edit_test.dart` | — | |
| ขายสินค้า | the line's + and − | — | `sell_and_bill` (the product tapped twice) | widget: `cart_order_item_layout_test.dart` taps each button |
| ขายสินค้า | oversell toggle on a line | — | — | not automated yet; widget: its name and tap (`cart_order_item_layout_test.dart`) |
| ขายสินค้า | choose a customer for the sale, take it off | `selling_test.dart` | `customer` | |
| ขายสินค้า | add a customer from the cart (customer add dialog) | — | — | not automated yet |
| ขายสินค้า | compliance info dialog (a product whose category requires the buyer's details) | — | — | not automated yet: needs a category with `requireCustomerOrder`, and categories have no way in (below); it could be seeded |
| ขายสินค้า | payment: exact cash | `selling_test.dart` | `sell_and_bill`, `bill_cancel_return` | |
| ขายสินค้า | payment: a short payment refused | `selling_test.dart` | — | |
| ขายสินค้า | payment: PromptPay with a customer and change | `selling_test.dart` | — | |
| ขายสินค้า | several carts (the cart slots) | — | — | not automated yet |
| รายการขาย | the list: row numbers, a cancelled bill marked `ยกเลิกแล้ว`, ยอดรวม leaving it out | `selling_test.dart` | `sell_and_bill`, `bill_cancel_return` | |
| รายการขาย | the date-range dropdown | `navigation_test.dart` (shown to an admin only) | — | choosing a range is not automated yet |
| รายการขาย | store filter chips (All, Store, Online) | `navigation_test.dart`, `selling_test.dart` (All lists a PromptPay bill) | — | a chip's label is not text on the web |
| รายการขาย | bill detail: lines, totals | `selling_test.dart` | `sell_and_bill`, `bill_cancel_return` | |
| รายการขาย | return dialog `รับคืนสินค้า` | `selling_test.dart` | `bill_cancel_return` | |
| รายการขาย | returns history | `selling_test.dart` | — | |
| รายการขาย | cancel a line | `selling_test.dart` | — | |
| รายการขาย | cancel a bill | `selling_test.dart` | `bill_cancel_return` | |
| รายการขาย | a line's sales history page (`/order-history`) | — | — | not automated yet; widget: `order_history_totals_test.dart`, the walk |
| รายการขาย | a line opens its product's edit page | — | — | not automated yet |
| รายการขาย | receipt PDF, sales history CSV | — | — | cannot be automated here: web-only download code; the buttons are named and walked, never pressed |
| สินค้า | list, search, sort by stock | `stock_in_test.dart`, `product_edit_test.dart` | `product_edit`, `stock_adjust`, `product_add_delete` | |
| สินค้า | add a product (form) | `stock_in_test.dart` | `product_add_delete` | an empty name refused: Dart |
| สินค้า | export products (`ส่งออกสินค้า`) | — | — | cannot be automated here: a file download |
| สินค้า | import from CSV | — | — | cannot be automated: the OS file dialog |
| สินค้า | ข้อมูลทั่วไป: edit (rename) | `product_edit_test.dart` | `product_edit` | |
| สินค้า | delete a product, the stock question | `product_edit_test.dart` | `product_add_delete` | |
| สินค้า | หน่วยนับ: the unit dialog | — | — | not automated yet |
| สินค้า | ราคา: add and change a price (price dialog) | `product_edit_test.dart` | — | |
| สินค้า | สต็อก: add a lot (lot form) | — | — | not automated yet (lots come in through receipts, above); widget: the walk |
| สินค้า | สต็อก: edit a lot | — | — | not automated yet |
| สินค้า | สต็อก: set on hand (`ปรับจำนวนคงเหลือ`) | — | — | not automated yet; widget: the sweep and walk |
| สินค้า | สต็อก: lot order (sequence dialog) | — | — | not automated yet |
| สินค้า | สต็อก: delete a stock row | `product_edit_test.dart` | — | |
| สินค้า | สต็อก: stock adjustment dialog | `stock_in_test.dart`, `product_edit_test.dart` | `stock_adjust` | |
| สินค้า | ประวัติ and ปรับสต็อก tabs | `stock_in_test.dart`, `stock_count_test.dart` | `stock_adjust` | |
| จัดการ | ร้านค้าของฉัน (shop profile) | `navigation_test.dart` (opened, never saved) | `navigation` (tile shown) | saving is not automated: on the hosted target it is the shop's real profile |
| จัดการ | จัดการลูกค้า: list, search, add, detail, edit, remove | `customer_test.dart` | `customer` | |
| จัดการ | a customer's purchase history tab | — | — | not automated yet |
| จัดการ | จัดการผู้ใช้งาน | — | `navigation` (tile shown) | cannot be automated here: UM's own screens |
| จัดการ | Goods Receipt: list, new, supplier, a line through the product picker, import | `stock_in_test.dart` | `receive_stock` | |
| จัดการ | Goods Receipt: add a supplier from the receipt | — | — | not automated yet |
| จัดการ | Goods Receipt: delete a draft | `stock_in_test.dart` | — | |
| จัดการ | Goods Receipt: delete a line | — | — | not automated yet |
| จัดการ | นับสต็อก: list, new count, detail naming the product | `stock_count_test.dart` | `stock_count` | |
| จัดการ | นับสต็อก: an empty count refused | `stock_count_test.dart` | — | |
| No way in | categories (`/categories`, add, edit) | — | — | cannot be automated: no button leads there (below); widget: the walk |
| No way in | suppliers list and edit (`/suppliers`, `/supplier-edit`) | — | — | cannot be automated: no way in; widget: the walk |
| No way in | expired products and lot edit (`/product-expired`, `/product-lot-edit`) | — | — | cannot be automated: no way in |

Every screen and dialog in the widget tests' shared set
(`test/support/main_screens.dart`, `test/support/manage_screens.dart` and
the product detail's tabs) is laid out by
`test/presentation/layout_sweep_test.dart` (360×640, 1400×900, dialogs at
640×360) and walked by `test/presentation/accessibility_walk_test.dart`,
which also walks a few more (the filled selling screen, cart and bill
lines, the receipt list and page, a product stock card). The walk skips
none of them: the English names finding 30 leaves on the bills list are
let through by their exact text, and every other fault there still fails.
A screen outside that set is not walked; the camera scanner is one (it
opens the camera plugin), and its app-bar actions have a test of their own.

The helpers in `e2e/support/` that hold logic have unit tests in
`packages/applications/pos/test/e2e_support/`. Those tests run with the
normal `flutter test`. The e2e files themselves never do: `flutter test`
only picks up `test/`.

#### Not reachable from the UI

These screens exist in the code but no button leads to them, so a user can
never see them. Deciding what to do with them is the owner's call:

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

`tools/e2e/seed-catalogue.sh local` crowds the local database like a real
shop's: 400 products (`AA filler …`, `ZZ filler …`), 150 customers and 50
suppliers. It runs once and adds nothing the second time. The robots are
proven against it: lists are searched or scrolled to the end, never assumed
to show the run's row.

### State, and stopping the stack

Everything the stack writes is under `${TMPDIR:-/tmp}/pos-e2e-stack`
(override with `E2E_STACK_STATE`):

- the Mongo data (databases `e2e_um` and `e2e_pos`),
- a Redis directory with nothing in it: Redis runs with saving off
  (`--save '' --appendonly no`), so sessions and rate-limit counters live
  only while it runs,
- the built binaries,
- logs and pid files.

```sh
tools/e2e/local-stack.sh status
tools/e2e/local-stack.sh stop     # stops only what the script started
```

To start from an empty database, stop the stack and delete that directory.

`config/e2e-local.json` is in the app's `config/` asset directory, so it
ships in every release bundle. It holds only loopback URLs, so this is
harmless; `pubspec.yaml` is left as it is.

## 4. Running against the hosted API

Only the owner runs this, and only after reading
[e2e-hosted.md](e2e-hosted.md). That page covers what a run writes to Client
`000` and what stays, the shared sign-in limit, the first run in stages,
everything the owner accepts by running it, and how to clean up after an
interrupted run (`tools/e2e/sweep.sh`).

## 5. Findings

The full list of what the suite found, each with its file:line and the test
that pins it, is in [e2e-findings.md](e2e-findings.md).

Where the app does something a user would call wrong, the suite does not
quietly accept it:

- The running test asserts what the app does now, with a `FINDING` comment
  that names the file and line.
- What a user expects is kept in a test skipped with
  `skip: 'FINDING: <one line with file:line>'`. Each such test was seen
  failing when unskipped. `run-all.sh` lists them under "Findings".
- Nothing is let through: a layout overflow, like any other framework
  error, fails the test that raised it. (The counted tolerances for the
  three overflowing layouts, findings #17-#19, went with their fixes.)

When a FINDING test starts failing, the app has probably
been fixed:

1. Confirm the fix in the app's code.
2. Unskip the FINDING test.
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

A run's products are deleted together with their stock rows (lots zeroed
first). What stays is their history, including one stock-row history entry
per lot (see [e2e-hosted.md](e2e-hosted.md)).

`none` means the file left nothing. Undos run after the test, through the
app's repositories rather than its screens, even when the test failed
(`support/cleanup.dart`).

To find suite data on a server:

- Look for run names `E2E-<yyyyMMddHHmmss>-<pid> …` (one run: `E2E-<run id>`) or the
  fixed `E2E supplier` and `E2E customer`.
- Lot numbers are `L<run id>`.
- Receipt references are `<run id> <what>` (fixtures), and `<run id>` and
  `<run id>-draft` (stock_in).
- A stock count's note is `E2E-<run id> stock count`. Its adjustment notes
  read `SC-… E2E-<run id> stock count`.
- Bills carry the run's product name on their lines.

Locally you can also reset everything by deleting the stack's state
directory.
