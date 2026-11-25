# What the e2e suite found in the POS app

This list was made while the end-to-end UI suite was being built (see
[e2e.md](e2e.md)). It is as of 2026-11-25, re-checked at the final review fixes (pos-app branch
`feature/ui-e2e-tests`), run against pos-api `28cbb3e` on the local stack.

Each open item is pinned by **a skipped test**: it is marked
`skip: 'FINDING: …'`, states what a user expects, and fails until the app
is fixed. (The suite also used counted tolerances, which let one known
layout overflow through; the last three went with findings #17-#19, fixed
2026-11-26, and nothing is let through now.)

To act on an item:

1. Fix the app.
2. Unskip the named test.
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
| 1 | **Fixed 2026-11-26** (the app reads pos-api's `status`: a cancelled bill stays listed, marked `ยกเลิกแล้ว`, its amount struck through, and counts in no total; the server is unchanged). A cancelled bill stays in รายการขาย, unmarked, and its amount stays in the screen's Total | `presentation/order/main/order_view_model.dart:40-57` (sums every bill returned); pos-api `data/repositories/order.go:105` `GetOrderRange` (no status filter) | The day's Total on the bills screen is overstated by every cancelled bill. Observed: after the local runs the screen showed `Total ฿ 870.00`, made only of cancelled E2E bills | `selling_test.dart` "the bills list" / "a cancelled bill is marked and not counted" (row marked, ยอดรวม equals today's bills not cancelled); `order_view_model_test.dart` "a cancelled bill stays listed but counts in no total"; `order_list_tile_test.dart` |
| 2 | **Fixed 2026-11-26** (a cancelled line stays on the bill marked `ยกเลิกแล้ว`, struck through, counts in no total, and offers no delete, history or return). After a line is cancelled, the bill detail still lists it, still sums it into its Total, and still offers delete and return on it. The server's bill total is 0.00 | `presentation/order/detail/order_detail_page.dart:248` (list of every line), `:386` (`getTotalPrice` sums all); pos-api `data/repositories/order.go:444` (returns every line) | The bill detail disagrees with the list row and the server. Observed | `selling_test.dart` "the bill detail" / "a cancelled line is marked, not counted, and offers nothing"; `order_detail_view_model_test.dart` "the bill totals"; `order_line_tile_test.dart` |
| 3 | **Fixed 2026-11-26** (the edit form opens on the customer's own type). Editing a customer (even only the phone) resets its type to ลูกค้าทั่วไป | `presentation/customer/edit/customer_edit_page.dart:59` (`_customer = customerTypes.first`), `:138-143` (`_setupData` never sets the type) | The type picks the price tier (`domain/model/order/order_item.dart:63`), so a wholesale or regular customer silently loses its prices after any edit. Observed | `customer_test.dart` "editing only the phone keeps the customer type" and "editing a wholesale customer's phone (made by the API) keeps its type"; `customer_edit_page_test.dart` |
| 4 | **Fixed 2026-11-26** (the grid reloads after each sale; the test below runs). After a sale, the selling grid still shows the stock from before the sale until the screen is left | `presentation/home/main/product_search.dart:41-44` (loads in `initState` only); `presentation/home/main/cart_page.dart:75-81` (the sale reloads nothing) | A cashier reads wrong on-hand figures, e.g. `คงเหลือ 10 ชิ้น` after selling 3. Observed | `selling_test.dart` "after a sale the grid shows the new stock" |
| 5 | **Fixed 2026-11-26** (`checkLogin` builds on the state after its `await`). No one, an admin included, ever gets the bills date-range dropdown, so no earlier day's bills can be viewed in the app | `presentation/order/main/order_view_model.dart:60-63` (`checkLogin` reads `_state.value` before its `await` and writes that stale copy back, wiping the `ranges` set by `initData` meanwhile) | The bills screen shows today only: a shop cannot look up yesterday's sales or a past bill in the app. Observed | `navigation_test.dart` "an admin can choose the date range of the bills" (runs; user and manager assert no dropdown); `order_view_model_test.dart` "the role answer keeps the ranges set while it was awaited" |
| 6 | **App side fixed 2026-11-26** (deleting a product with stock asks `สินค้านี้มีสต็อกคงเหลือ <n> <unit> ต้องการลบใช่หรือไม่?` first; the server follow-up stands). A product with stock on hand can be deleted, and its stock stays in pos-api's stock report | the app's delete (`presentation/product/edit/product_edit_page.dart` `_showConfirmDialog`) asks nothing about stock; pos-api `data/repositories/product_stock.go:635-672` (`buildStockReportPipeline`) and `:567-610` (`buildLowStockProductsPipeline`) sum `product_stocks` and join `products` with no `deletedDate` filter | The stock report keeps the quantity and cost of deleted products for good; a deleted product at 0 shows in the low-stock list. Read in code (pos-api), and observed: the suite deletes products with stock | `product_edit_test.dart` "a product can be deleted and no longer sells" (the question, answered no, before the lot is zeroed); `product_delete_question_test.dart`. The pos-api report filter is a server follow-up; the suite still zeroes the lots and deletes the stock rows before every product delete |
| 7 | **Fixed 2026-11-26** (the app leaves ARCHIVED customers out of the list and of the selling screen's customer picker; the server is unchanged, and an old bill still finds its customer). A removed customer stays in the customer list | pos-api `data/repositories/customer.go:109-124` (sets ARCHIVED), `:40` (`GetCustomerAll` returns every status); `presentation/customer/main/customers_view_model.dart:24-28`, `data/repositories/customer_repository_impl.dart:30-31` (no filter) | Removed customers look current; the list grows forever. Observed | `customer_test.dart` "a removed customer is no longer listed" and the removal in "a customer can be added, seen, changed and removed"; `customers_view_model_test.dart`, `customer_search_view_model_test.dart`; Maestro `customer` |
| 8 | **Fixed 2026-11-26** (the app leaves CANCELLED receipts out of the list and its search; the server is unchanged). A deleted draft receipt stays in the receipt list, unmarked | pos-api `data/repositories/receive.go:522-535` (`CancelReceiveById` sets CANCELLED), `:117` (`GetReceives` returns every status); `presentation/receive/main/receives_view_model.dart:48-50` (no filter) | The list reads as if the delete had not worked. Observed | `stock_in_test.dart` "a deleted draft receive is no longer listed" and "a draft receive can be deleted"; `receives_view_model_test.dart` |
| 9 | **Fixed 2026-11-26** (the detail looks the names up in the product catalogue; an unknown product still falls back to its id). The stock count detail titles each line `สินค้า <product id>` | `presentation/stock_count/manage/stock_count_manage_page.dart:124`; the count lines carry only ids | A user cannot tell which product a counted line is. Observed | `stock_count_test.dart` "the stock count detail names the counted product" and the chain's detail check; `stock_count_manage_view_model_test.dart`, `stock_count_detail_line_test.dart` |
| 10 | **Fixed 2026-11-26** (the alert now reads `ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง [UM-401-004]`; `auth_test.dart` asserts it). A wrong password is reported as `เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่ [UM-401-004]` ("session expired") | `libraries/common/lib/core/network/error_mapper.dart:27` (every 401 becomes `AuthException`), `libraries/common/lib/core/error/failure.dart:26` | Misleading message at sign-in. Observed (the alert text) | No skip. `auth_test.dart` asserts the alert carries `[UM-401-004]` |

### Usability

| # | What a user sees | Where | Effect | Pinned by |
|---|---|---|---|---|
| 11 | **Fixed 2026-11-26** (a success bar closes after 4 s; the test below runs). Success snackbars (`Add success`, `นำเข้าสต็อกสำเร็จ`, `Order success`) never close on their own | `libraries/design_system/lib/widgets/snack_bar.dart:48` (`action` defaults to true), `:61-67`; Flutter 3.38 keeps a snackbar with an action until dismissed | The snackbar covers buttons at the bottom of later screens: the receipt page's `นำเข้าสต็อก`, the stock count's `เพิ่มสินค้า`. Observed | `stock_in_test.dart` "the receipt page success snackbar closes on its own" |
| 12 | **Fixed 2026-11-26** (Clear uses the messenger captured when shown; `stock_count_test.dart` "success bar from an earlier screen closes, and can be cleared while it shows"). Once the screen that showed one of those snackbars is gone, its `Clear` does nothing (debug builds throw "Looking up a deactivated widget's ancestor is unsafe") | `libraries/design_system/lib/widgets/snack_bar.dart:65` (uses the showing screen's `context`) | Combined with #11, the user must swipe it away. Observed | `stock_count_test.dart` "a success snackbar from an earlier screen can be cleared" |
| 13 | **Fixed 2026-11-26** (the page reloads the list after an add, a rename and a removal). On a wide screen the customer list does not show an added customer, a removal or a rename until the user leaves and returns | `presentation/customer/main/customers_widget.dart:38-42` (loads in `initState` only), `presentation/customer/main/customer_page.dart:74-85` | A new customer looks as if it was not saved. Observed | `customer_test.dart` "a new customer appears in the list without leaving the page"; `customer_page_test.dart` |
| 14 | **Fixed 2026-11-26** (with no profile the form is empty and says `ยังไม่มีข้อมูลร้านค้า กรอกแล้วกดบันทึก`). ร้านค้าของฉัน with no shop profile yet shows a red `Error: ไม่พบข้อมูลที่ต้องการ [SY-404-002]` over the empty form | `presentation/supplier/info/supplier_info_view_model.dart:37-43` (no not-found branch); the bill detail sends the user here on exactly that error, `presentation/order/detail/order_detail_view_model.dart:113` | The screen meant to create the profile greets the user with an error. Observed. Cosmetic | `navigation_test.dart` (the tolerance is gone: the stop must show no error, and the hint when there is no profile); `supplier_info_view_model_test.dart` (the hint also goes once a profile is saved or found) |
| 15 | **Fixed 2026-11-26** (the stock tab has a ล็อต column). The product's stock tab never shows a lot's number | `presentation/product/main/product_detail_widget.dart:593` (`_buildStocks`: dates, cost, price, quantities, no lot) | A user who received lot L… cannot find it except by opening each row's adjustment dialog. Observed | `stock_in_test.dart` "the stock tab shows the received lot number"; `product_stock_card_test.dart` |
| 16 | An adjustment's note shows on the ปรับสต็อก tab but not on ประวัติ | pos-api `domain/request/product_history.go:141-151` (description from the reason only); `presentation/product/stock/stock_adjustment_history_widget.dart:123-126` shows the note | Observed. Probably by design: the note is visible where adjustments are listed. Not pinned | — |

### Layout (fixed sizes too small for the app's Sarabun text)

All fixed 2026-11-26 but #29. Every layout test now pumps with the app's own
fonts (`test/support/app_fonts.dart`) at 360×640 and 1400×900, and
`test/presentation/layout_sweep_test.dart` lays out each main screen and
dialog the widget tests can build at both sizes, and each dialog also at
640×360 (a phone held sideways: the number and return dialogs scroll), and
fails on any overflow.
The sweep does not reach screens no widget test can build yet: the bills
list and bill detail pages, the receipt list and receipt page as a whole,
the stock count pages, the supplier pages, the shop profile, the product
detail with its tabs, sign-in and splash (UM), and the home shell with
real navigation.

| # | What a user sees | Where | Effect | Pinned by |
|---|---|---|---|---|
| 17 | **Fixed 2026-11-26** (the picker's row has no fixed height). The receipt page's supplier picker overflows its box; the chosen name is clipped | `presentation/receive/manage/receive_manage_page.dart:224-225` (a labelled dropdown in a 50 px `SizedBox`) | Clipped text, about 30 px of overflow. Observed | `stock_in_test.dart` "the receipt page shows the chosen supplier without overflow" (runs; the tolerance is gone); `receive_supplier_picker_test.dart` |
| 18 | **Fixed 2026-11-26** (`DecimalInput`'s display sizes itself and the dialog grows to its content, up to 600 px). The quantity dialog `จำนวนสินค้า` overflows | `libraries/design_system/lib/widgets/dialogs.dart:99-100` (430 px), `libraries/design_system/lib/widgets/decimal_input.dart:94` (100 px box), `:103` (the Column that overflows) | 12–13 px overflow. Observed | `selling_test.dart` "the quantity and payment dialogs fit their text" (runs; the tolerance is gone); `quantity_dialog_layout_test.dart` |
| 19 | **Fixed 2026-11-26** (the dialog is as tall as its content, up to 720 px, and scrolls on a phone lower than that; the summary amounts shrink to one line on a narrow phone instead of wrapping). The payment dialog's `ยอดรับเงินรวม` display overflows | `presentation/home/main/payment_screen.dart:214` (100 px box), `:221` (the Column that overflows) | 18 px overflow (42 and 27 px on a 360×640 phone). Observed | Same E2E test as #18; `payment_dialog_layout_test.dart`; `cart_page_sale_test.dart` (its filter for this overflow is gone) |
| 28 | **Fixed 2026-11-26**, found by the layout sweep: the stock tab's ปรับจำนวนคงเหลือ dialog overflows, like #18 | `presentation/product/stock/product_stock_quantity_widget.dart` (`showStockQuantityDialog`, a fixed 320×430 dialog around `DecimalInput`) | 13 px overflow. Observed in a widget test | `layout_sweep_test.dart` "the stock quantity dialog lays out without overflow" |
| 29 | **Open**, found by the accessibility walk: on a 360 px phone a cart line has no room for its product name. The cart is the screen less its 51 px cart slots, 309 px; the line's buttons and price take 288 px and its padding 40 (`Trailing widget consumes the entire tile width`) | `presentation/home/main/cart_widget.dart` `CartOrderItem` (a 288 px trailing `SizedBox`) | Observed in a widget test; the emulator's 411 px phone fits. Needs a narrow layout for the line (a visible change, the owner's call) | `cart_order_item_layout_test.dart` "a cart line fits the 309 px cart of a 360 px phone" (skipped, FINDING 29) |
| — | **Checked 2026-11-26, no fault**: the product's stock row (eight columns since #15) overflowed by 264 px on a 360 px phone with a long lot number; it now scrolls sideways. The cart line's price column, the cancelled-bill marks and the bill code fit at 360 px in the app's fonts | `presentation/product/main/product_stock_card.dart` | — | `product_stock_card_test.dart`; `cart_order_item_layout_test.dart`; `cancelled_marks_layout_test.dart` |

### Security and hygiene

| # | What happens | Where | Effect | Pinned by |
|---|---|---|---|---|
| 20 | In any debug build, the HTTP logger prints every request header (`Authorization` included) and full request and response bodies: sign-in passwords, access tokens | `libraries/common/lib/core/network/http_logging_interceptor.dart:15-38`; added for every app in `features/um/lib/container.dart:52`; printed by `setupLogging` (`:34-41`), which `main.dart:16` of both POS and SM calls | Credentials in console logs, e.g. a debug build run against production. Read in code. The suite leaves `setupLogging` out so that nothing is printed | — (cannot be asserted without printing secrets) |
| 21 | The app builds its first screen twice at start: two splash pages, then two sign-in pages, are in the tree | `presentation/app.dart:62` (`initialRoute: '/um-splash'` also pushes `/`), `presentation/router.dart:130-132` (`/` builds the splash again); each splash runs keep-alive, `features/um/lib/presentation/splash/splash_page.dart:51` | Duplicate work at start, and two keep-alive calls are possible. Observed (two sign-in pages; the suite uses `.hitTestable()` to pick the top one). The double keep-alive is read in code | — |

## Found by the Maestro flows

The flows in [e2e-maestro.md](e2e-maestro.md) read the app through its
accessibility tree, on a phone layout and on the web. What that showed:

| # | Finding | Where | Seen on |
|---|---|---|---|
| 22 | **Fixed 2026-11-26**, as #10. A wrong password is answered with "เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่ [UM-401-004]" — the text of an expired session, not of a wrong password | the sign-in alert | Android, web |
| 23 | **Fixed 2026-11-26** (every icon-only control has a name in the app's strings, Thai and English, and no two on a screen share one; a row's buttons name the row's product, lot or customer). Controls with no accessible name: the back arrows of the list headers, the products list's clear, sort and menu buttons, the add-supplier button on a receipt, the bill detail's four actions, the cart line's add and remove, the stock row's lot actions (shared names), the keypad's backspace | `cart_widget.dart`, `customer_list_header.dart`, `products_widget.dart`, `receives_widget.dart`, `receive_manage_page.dart`, `receive_supplier_picker.dart`, `order_detail_header.dart`, `order_line_tile.dart`, `product_stock_card.dart`, design_system `input_number.dart`, `buttons.dart` | Android (TalkBack would say only "button"). Pinned by `test/presentation/accessibility_walk_test.dart` (16 screens and widgets, phone and desktop: every tappable has a name, none shared) |
| 24 | **Fixed 2026-11-26** (a row's texts are one node of their own beside its buttons, `ReadableTile`; titles are header nodes; a dropdown option's name is a node of its own inside its menu item). On the web, text inside a list row that also holds a button does not reach assistive technology: the product name on a cart line, the chosen customer, the lines of a bill and of a receipt; nor do dialog, list and cart titles, nor the options of an open dropdown. Cause: Flutter web writes a node's label as text only when it has no children, and a menu item's only as an `aria-label` | Flutter web semantics of `ListTile` with a leading or trailing control, `TitleBar`, `DropdownButton` | web. Pinned by `text_beside_controls_semantics_test.dart`, `customer_list_header_test.dart`, design_system `title_semantics_test.dart`, `dropdown_input_semantics_test.dart`; Maestro `sell_and_bill`, `customer`, `receive_stock` read them by their own text |
| 25 | **Fixed 2026-11-26** (the customer list has a search, `ค้นหาลูกค้า...`, by name, code and phone; a receipt line picks its product through the app's product picker and its search; the flows use both). Choosing needs scrolling through everything: the customer list has no search, and a receipt line picks its product from a plain dropdown of every product | `customers_widget.dart`, `receive_item_dialog.dart:48` | both |
| 26 | **Fixed 2026-11-26**: the sale says `ขายสำเร็จ เลขที่บิล <code>`, a bill row shows its number above its time, the labels read ยอดรวม, ต้นทุน, กำไร. After a sale the app shows no bill number (only "Order success"); the bills list numbers rows by position, so a bill can only be recognised by its time and total. Labels there are English (Total, Cost, Profit) among Thai | `order_page.dart`, `order_detail_page.dart` | both |
| 27 | **Fixed 2026-11-26** (`AppShell` keeps its body in a `SafeArea`; `design_system/test/app_shell_safe_area_test.dart`). On the phone layout the menu button of the products screen sits partly under the status bar | products screen, narrow layout | Android |

Findings 7 (a removed customer stays listed, fixed 2026-11-26: the customer
flow now waits for the row to leave the list), 19 (payment dialog overflow) and
the never-closing success bar that covers the import button on a narrow screen
(#11, fixed 2026-11-26) were met again by the flows.

The paused Edge run also found that on the web, after paying, the focus stayed
on the page instead of the search field, so the next scan went nowhere. Fixed
2026-11-26: the field takes the focus after each sale on every platform
(`cart_page_sale_test.dart`; `sell_and_bill` checks it on the web).

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
   archived, draft receipts and bills are cancelled, and it returns those
   records from its list endpoints. The app now decides (2026-11-26):
   archived customers and cancelled receipts are left out of their lists
   (#7, #8), cancelled bills are shown marked (#1). Filtering in the API
   instead is still open.
3. **Reports and the bills screen disagree.** pos-api's order analytics
   count only ACTIVE and CONFIRMED bills
   (`data/repositories/order_analytics.go:174`, `:192`), while the app's
   bills screen included cancelled ones (#1, fixed 2026-11-26: the screen's
   ยอดรวม now leaves them out, as the reports do).
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
