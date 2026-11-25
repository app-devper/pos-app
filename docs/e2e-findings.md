# What the e2e suite found in the POS app

This list was made while the end-to-end UI suite was being built (see
[e2e.md](e2e.md)). It is as of 2026-11-25, re-checked at the final review fixes (pos-app branch
`feature/ui-e2e-tests`), run against pos-api `28cbb3e` on the local stack.

Each item is pinned in one of two ways:

- **A skipped test.** It is marked `skip: 'FINDING: …'`, states what a user
  expects, and fails until the app is fixed.
- **A counted tolerance.** It lets one known error through and fails once
  the error stops happening.

To act on an item:

1. Fix the app.
2. Unskip the named test, or remove the named tolerance (and the assertion
   that counts it).
3. Change the running test's "asserted as the app behaves" line next to it.
4. Run `tools/e2e/run.sh local <file>`.

"Observed" means a test run showed it. "Read in code" means it was found by
reading the code and no test exercises it. Every file:line was re-checked
at the commit above. Paths are under `packages/applications/pos/lib/`, except
those starting `libraries/` or `features/`, which are under `packages/`.
pos-api paths are under `pos-api/app/`.

## Summary, most serious first

### Figures and data a shop relies on

| # | What a user sees | Where | Effect | Pinned by |
|---|---|---|---|---|
| 1 | A cancelled bill stays in รายการขาย, unmarked, and its amount stays in the screen's Total | `presentation/order/main/order_view_model.dart:40-57` (sums every bill returned); pos-api `data/repositories/order.go:105` `GetOrderRange` (no status filter) | The day's Total on the bills screen is overstated by every cancelled bill. Observed: after the local runs the screen showed `Total ฿ 870.00`, made only of cancelled E2E bills | `selling_test.dart` group FINDING, test "a cancelled bill is no longer listed" |
| 2 | After a line is cancelled, the bill detail still lists it, still sums it into its Total, and still offers delete and return on it. The server's bill total is 0.00 | `presentation/order/detail/order_detail_page.dart:248` (list of every line), `:386` (`getTotalPrice` sums all); pos-api `data/repositories/order.go:444` (returns every line) | The bill detail disagrees with the list row and the server. Observed | `selling_test.dart` "a cancelled line no longer counts on the bill" |
| 3 | Editing a customer (even only the phone) resets its type to ลูกค้าทั่วไป | `presentation/customer/edit/customer_edit_page.dart:59` (`_customer = customerTypes.first`), `:138-143` (`_setupData` never sets the type) | The type picks the price tier (`domain/model/order/order_item.dart:63`), so a wholesale or regular customer silently loses its prices after any edit. Observed | `customer_test.dart` "editing only the phone keeps the customer type". The running test "editing a wholesale customer's phone resets its type" (local only) asserts today's behaviour |
| 4 | After a sale, the selling grid still shows the stock from before the sale until the screen is left | `presentation/home/main/product_search.dart:41-44` (loads in `initState` only); `presentation/home/main/cart_page.dart:75-81` (the sale reloads nothing) | A cashier reads wrong on-hand figures, e.g. `คงเหลือ 10 ชิ้น` after selling 3. Observed | `selling_test.dart` "after a sale the grid shows the new stock" |
| 5 | No one, an admin included, ever gets the bills date-range dropdown, so no earlier day's bills can be viewed in the app | `presentation/order/main/order_view_model.dart:60-63` (`checkLogin` reads `_state.value` before its `await` and writes that stale copy back, wiping the `ranges` set by `initData` meanwhile) | The bills screen shows today only: a shop cannot look up yesterday's sales or a past bill in the app. Observed | `navigation_test.dart` "an admin can choose the date range of the bills" |
| 6 | A product with stock on hand can be deleted, and its stock stays in pos-api's stock report | the app's delete (`presentation/product/edit/product_edit_page.dart` `_showConfirmDialog`) asks nothing about stock; pos-api `data/repositories/product_stock.go:635-672` (`buildStockReportPipeline`) and `:567-610` (`buildLowStockProductsPipeline`) sum `product_stocks` and join `products` with no `deletedDate` filter | The stock report keeps the quantity and cost of deleted products for good; a deleted product at 0 shows in the low-stock list. Read in code (pos-api), and observed: the suite deletes products with stock | — (the defect stands; the suite now zeroes the lots and deletes the stock rows before every product delete, so it leaves no rows in either report) |
| 7 | A removed customer stays in the customer list | pos-api `data/repositories/customer.go:109-124` (sets ARCHIVED), `:40` (`GetCustomerAll` returns every status); `presentation/customer/main/customers_view_model.dart:24-28`, `data/repositories/customer_repository_impl.dart:30-31` (no filter) | Removed customers look current; the list grows forever. Observed | `customer_test.dart` "a removed customer is no longer listed" |
| 8 | A deleted draft receipt stays in the receipt list, unmarked | pos-api `data/repositories/receive.go:522-535` (`CancelReceiveById` sets CANCELLED), `:117` (`GetReceives` returns every status); `presentation/receive/main/receives_view_model.dart:48-50` (no filter) | The list reads as if the delete had not worked. Observed | `stock_in_test.dart` "a deleted draft receive is no longer listed" |
| 9 | The stock count detail titles each line `สินค้า <product id>` | `presentation/stock_count/manage/stock_count_manage_page.dart:124`; the count lines carry only ids | A user cannot tell which product a counted line is. Observed | `stock_count_test.dart` "the stock count detail names the counted product" |
| 10 | A wrong password is reported as `เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่ [UM-401-004]` ("session expired") | `libraries/common/lib/core/network/error_mapper.dart:27` (every 401 becomes `AuthException`), `libraries/common/lib/core/error/failure.dart:26` | Misleading message at sign-in. Observed (the alert text) | No skip. `auth_test.dart` asserts the alert carries `[UM-401-004]` |

### Usability

| # | What a user sees | Where | Effect | Pinned by |
|---|---|---|---|---|
| 11 | Success snackbars (`Add success`, `นำเข้าสต็อกสำเร็จ`, `Order success`) never close on their own | `libraries/design_system/lib/widgets/snack_bar.dart:48` (`action` defaults to true), `:61-67`; Flutter 3.38 keeps a snackbar with an action until dismissed | The snackbar covers buttons at the bottom of later screens: the receipt page's `นำเข้าสต็อก`, the stock count's `เพิ่มสินค้า`. Observed | `stock_in_test.dart` "the receipt page success snackbar closes on its own" |
| 12 | Once the screen that showed one of those snackbars is gone, its `Clear` does nothing (debug builds throw "Looking up a deactivated widget's ancestor is unsafe") | `libraries/design_system/lib/widgets/snack_bar.dart:65` (uses the showing screen's `context`) | Combined with #11, the user must swipe it away. Observed | `stock_count_test.dart` "a success snackbar from an earlier screen can be cleared" |
| 13 | On a wide screen the customer list does not show an added customer, a removal or a rename until the user leaves and returns | `presentation/customer/main/customers_widget.dart:38-42` (loads in `initState` only), `presentation/customer/main/customer_page.dart:74-85` | A new customer looks as if it was not saved. Observed | `customer_test.dart` "a new customer appears in the list without leaving the page" |
| 14 | ร้านค้าของฉัน with no shop profile yet shows a red `Error: ไม่พบข้อมูลที่ต้องการ [SY-404-002]` over the empty form | `presentation/supplier/info/supplier_info_view_model.dart:37-43` (no not-found branch); the bill detail sends the user here on exactly that error, `presentation/order/detail/order_detail_view_model.dart:113` | The screen meant to create the profile greets the user with an error. Observed. Cosmetic | Tolerance: `navigation_test.dart` `_noShopProfileYet` (`[SY-404-002]`, at that one stop) |
| 15 | The product's stock tab never shows a lot's number | `presentation/product/main/product_detail_widget.dart:593` (`_buildStocks`: dates, cost, price, quantities, no lot) | A user who received lot L… cannot find it except by opening each row's adjustment dialog. Observed | `stock_in_test.dart` "the stock tab shows the received lot number" |
| 16 | An adjustment's note shows on the ปรับสต็อก tab but not on ประวัติ | pos-api `domain/request/product_history.go:141-151` (description from the reason only); `presentation/product/stock/stock_adjustment_history_widget.dart:123-126` shows the note | Observed. Probably by design: the note is visible where adjustments are listed. Not pinned | — |

### Layout (fixed sizes too small for the app's Sarabun text)

| # | What a user sees | Where | Effect | Pinned by |
|---|---|---|---|---|
| 17 | The receipt page's supplier picker overflows its box; the chosen name is clipped | `presentation/receive/manage/receive_manage_page.dart:224-225` (a labelled dropdown in a 50 px `SizedBox`) | Clipped text, about 30 px of overflow. Observed | Tolerance `onReceiptPage` in `e2e/support/known_faults.dart`, counted in `stock_in_test.dart`; skipped test "the receipt page shows the chosen supplier without overflow" |
| 18 | The quantity dialog `จำนวนสินค้า` overflows | `libraries/design_system/lib/widgets/dialogs.dart:99-100` (430 px), `libraries/design_system/lib/widgets/decimal_input.dart:94` (100 px box), `:103` (the Column that overflows) | 12–13 px overflow. Observed | Tolerance `onQuantityKeypad` in `e2e/support/selling_faults.dart`, counted in `selling_test.dart`; skipped test "the quantity and payment dialogs fit their text" |
| 19 | The payment dialog's `ยอดรับเงินรวม` display overflows | `presentation/home/main/payment_screen.dart:214` (100 px box), `:221` (the Column that overflows) | 18 px overflow. Observed | Tolerance `onPaymentDialog` in `e2e/support/selling_faults.dart`; same skipped test as #18 |

The two tolerance files, `known_faults.dart` and `selling_faults.dart`, use
the same mechanism twice. Both were reviewed as they are and are left
unmerged.

### Security and hygiene

| # | What happens | Where | Effect | Pinned by |
|---|---|---|---|---|
| 20 | In any debug build, the HTTP logger prints every request header (`Authorization` included) and full request and response bodies: sign-in passwords, access tokens | `libraries/common/lib/core/network/http_logging_interceptor.dart:15-38`; added for every app in `features/um/lib/container.dart:52`; printed by `setupLogging` (`:34-41`), which `main.dart:16` of both POS and SM calls | Credentials in console logs, e.g. a debug build run against production. Read in code. The suite leaves `setupLogging` out so that nothing is printed | — (cannot be asserted without printing secrets) |
| 21 | The app builds its first screen twice at start: two splash pages, then two sign-in pages, are in the tree | `presentation/app.dart:62` (`initialRoute: '/um-splash'` also pushes `/`), `presentation/router.dart:130-132` (`/` builds the splash again); each splash runs keep-alive, `features/um/lib/presentation/splash/splash_page.dart:51` | Duplicate work at start, and two keep-alive calls are possible. Observed (two sign-in pages; the suite uses `.hitTestable()` to pick the top one). The double keep-alive is read in code | — |

## Questions for the owner

These may be intended. Each needs a decision rather than a fix.

1. **A manager sees exactly what a user sees.** Every gate in the app is
   `atLeast(Role.admin)` (`presentation/home/main/home_view_model.dart:40`,
   `presentation/order/main/order_view_model.dart:62`,
   `presentation/order/detail/order_detail_view_model.dart:59`; roles are
   ordered user < manager < admin in
   `features/um/lib/domain/entities/auth/role.dart:6-10`). Observed in
   `navigation_test.dart` "a manager sees what a user sees". Is MANAGER meant
   to have more?
2. **Removed records stay listed.** pos-api soft-deletes: customers are
   archived, draft receipts and bills are cancelled. It returns those records
   from its list endpoints, and the app does not filter them (#1, #7, #8).
   One decision covers all three: filter in the API, filter in the app, or
   show them marked.
3. **Reports and the bills screen disagree.** pos-api's order analytics
   count only ACTIVE and CONFIRMED bills
   (`data/repositories/order_analytics.go:174`, `:192`), while the app's
   bills screen includes cancelled ones (#1). Which figure is the shop's?
4. **`Store` hides PromptPay bills.** The `Store` chip keeps only `Cash` (or
   untyped) bills
   (`presentation/order/main/order_view_model.dart:153-158`), so a PromptPay
   sale made at the till shows only under `All`. Observed. Is `Store` meant
   to be "cash"?

## Screens with no way in from the UI

These routes exist in `presentation/router.dart`, but no screen navigates to
them. Each was checked by searching `presentation/` for the route constant
outside `constants.dart` and `router.dart`. A user can never open them, so
they are untested.

| Route (`presentation/constants.dart`) | Page | Note |
|---|---|---|
| `categoriesRoute` `/categories` (:24) | `presentation/category/main/category_page.dart` | no entry point. `categoryAddRoute` (:25) and `categoryEditRoute` (:26) are reached only from this page |
| `suppliersRoute` `/suppliers` (:18) | `presentation/supplier/main/suppliers_page.dart` | no entry point. `supplierEditRoute` (:20) is reached only from it. Its delete is the only supplier delete in the app |
| `productExpiredRoute` `/product-expired` (:10) | `presentation/product/expired/products_expired_page.dart` | no entry point. `productLotEditRoute` (:11) is reached only from it |
| `productAddRoute` `/product-add` (:8) | none | not in the router ("Page Not Found"). The add form is embedded in the products screen |
| `customersRoute`, `customerAddRoute`, `customerEditRoute` (:28-30) | none | not in the router. The customer pages are embedded under จัดการ |
| `scanRoute` `/scan` on the web (:22) | `presentation/router.dart:115-127` | the web build shows only `Scanner is not available on web`. The button that opens it is hidden on the web (`presentation/home/main/product_search.dart`, `kIsWeb`) |

## What the suite itself cannot see

- How a browser renders the app (the suite runs on the Dart VM).
- Web-only code behind `kIsWeb` and conditional imports: PDF and CSV
  downloads, the web scanner placeholder, the browser passkey.
- The camera scanner.
- The file picker (CSV product import).
- Passkey sign-in.
- The date pickers.
- The SM app.
- UM's user management screens (the tile is only checked to be shown).

The hosted target (`api.devper.app`) has not been run by the suite's
authors. Everything above was observed on the local stack, built from the
pos-api and um-api checkouts named at the top.
