# POS main-path flows with Maestro (Android and web)

Eleven [Maestro](https://maestro.dev) flows drive the real POS app the way a
person does — by what is on the screen — on the Android emulator and in a
browser, against the local test stack. They sit beside the Dart suite
([e2e.md](e2e.md)), which is the thorough one; these are the short, readable
check that the main paths work on a phone and on the web.

## What the flows cover

| Flow | What it proves |
|---|---|
| `auth` | a wrong password is refused with UM's code and the user stays on sign-in; admin, manager and user each sign in to the selling screen and out |
| `navigation` | every main menu item opens its own screen (bills, products, the five manage tiles, profile) and selling is reachable again |
| `sell_and_bill` | two of a product in the cart (the line read by its own text), the totals, a payment of the exact amount, on the web a scan typed straight after paying lands in the search field, a new bill on the server with that total, and that bill found by the number its row shows in the bills list, its line read by its own text |
| `customer` | two customers added by the form are on the server; one is found and chosen for a sale (the cart shows its name and code), found by the list's search, and archived by its delete button: it leaves the list while the other, found by the same search, is listed (finding 7, fixed) |
| `receive_stock` | a goods receipt for a supplier chosen from the dropdown by its name (and shown chosen), one line of five of the product chosen through the product search, imported: the server holds 1005 on hand |
| `product_edit` | a product renamed on its page: the server and the selling screen show the new name, stock untouched |
| `stock_adjust` | the run's lot adjusted up 2 then down 2 (reason อื่นๆ, each with a note) on the product's สต็อก tab: the server holds 1002, then 1000, and lists `+2,-2`; the ประวัติ tab lists both adjustments and the ปรับสต็อก tab both notes |
| `stock_count` | a new count of the run's lot (picked through the product picker), counted to 0: the server has the count with one line and its note, and holds 0 on hand; the count's detail names the product, `ในระบบ 1000 / นับได้ 0` and `-1000` |
| `product_add_delete` | a product added by the form (shown in the shop, unit, price, cost, barcode) is on the server and on the selling grid at its price; deleted from its edit form (the plain question) it leaves the server and the list; deleting the stocked run's product asks first, naming its 1000 on hand, and is answered no |
| `bill_cancel_return` | two sold; one returned from the bill's line (the line reads `คืน 1`, the server holds 999); the bill cancelled from its detail: the row reads `ยกเลิกแล้ว`, the server says CANCELLED and holds 1000, and the list's ยอดรวม is today's bills without the cancelled ones, which differs from the server's own sum |
| `roles` | an admin's menu has products and จัดการ and the bills show costs; a manager's and a user's menu has selling and bills only and the bills show no cost (row or foot) |

Not covered: iOS; anything hosted (see "Local only"); PDF/CSV export, the
scanner; prices per customer type; and the features listed as "not
automated yet" in the coverage table of [e2e.md](e2e.md#2-coverage), which
says, feature by feature, which Dart test and which flow check it.

## Running

Prerequisites, all already on the development Mac: Maestro 2.12
(`maestro --version`), a JDK 17, the Android SDK with the AVD `Medium_Phone`
(override with `E2E_AVD`), Chrome for Testing in `~/.cache/selenium` (Maestro
fetched it on its first web run), and what the local stack needs (MongoDB,
Redis, Go — see [e2e.md](e2e.md)).

```bash
tools/e2e/maestro-all.sh                    # every flow, web (headless) and emulator at once
tools/e2e/maestro.sh android all            # every flow on the emulator
tools/e2e/maestro.sh web all --headless     # every flow in a headless browser, 1400x900
tools/e2e/maestro.sh web sell_and_bill      # one flow, in a visible window
tools/e2e/maestro-selftest.sh               # the runner's own checks, no device needed
```

One `PASS|FAIL <platform> <flow> <seconds>s` line per flow; exit 0 only when
all passed. One flow takes about one to two minutes: measured per flow,
67–116 s on the headless web and 84–143 s on the emulator (the five flows
Task 6 added, three passes each, and `roles` alone). A run of all eleven is
the sum of its flows, plus the build the first time (APK about four
minutes, web about one). `E2E_MAESTRO_REUSE_BUILD=1` skips the build when the artefact is
there — only when the app's code has not changed.

`maestro-all.sh [<flow>|all]` is the quick way to run everything: it builds
the two apps one after the other, then runs the web and the emulator side by
side, once each, and exits 0 only when both passed. Measured on the eleven
flows with the builds already there: 1477 s (about 25 minutes) for both
platforms together, against 900 s for the web alone plus 1441 s for the
emulator alone when run one after the other. The emulator is the longer half,
so the pair takes as long as the emulator does. One pass is the normal check;
run a flow more than once when it is new or was just changed.

What the runner does: refuses unless `config/e2e-local.json` points at
127.0.0.1; starts the flows' own local stack; builds the debug APK (or the web
build with `--dart-define=E2E_SEMANTICS=true`); starts the emulator if none is
running, keeps its screen on and forwards the two API ports (or serves the web
build on 127.0.0.1:8090); then for each flow seeds one product (1000 on hand in one lot) and one
supplier named `MST-<run id>`, runs Maestro and removes every product,
customer and supplier whose name starts `MST-<run id>` (a product a flow
adds is named so). A stock count cannot be deleted: `stock_count`'s counts
stay in the flows' own local database, as do the sales. It stops what it
started — an emulator or a stack that was already running is left running.
On the emulator it reinstalls the app and clears its data (a session you had
in `app.devper.pos` there is gone) and leaves "stay awake while charging" on.

### The emulator's lock screen

The runner never types a PIN and never changes the lock. If the emulator shows
its lock screen the run stops with a message and leaves the emulator open:
unlock it and run again, or set *Settings > Security > Screen lock* to *None*
once.

### Local only

There is no way to name another target. The flows type passwords, and Maestro
writes what it types into its logs (`~/.maestro/tests` and the run's output
under `${TMPDIR}/pos-e2e-maestro/`), so they are only ever given the seeded
local accounts from `.env.e2e.local`. The runner also switches off Maestro's
analytics, update check and cloud notices, and tells Selenium Manager not to
download anything (`SE_OFFLINE=true`): when Chrome for Testing is missing or
too old for the bundled driver the web run fails instead of fetching one.

### A database of their own

The flows use their own stacks, not the Dart suite's. That one is crowded on
purpose; Maestro cannot pick a supplier out of a plain dropdown of dozens.
Each platform has one, so the two can run at once without seeing each other's
bills and customers:

| | state | um-api / pos-api | mongod / redis | accounts |
|---|---|---|---|---|
| web | `${TMPDIR}/pos-e2e-maestro-stack` | 8585 / 8586 | 27719 / 6390 | `.env.e2e.local` |
| Android | `${TMPDIR}/pos-e2e-maestro-stack-android` | 9585 / 9586 | 28719 / 7390 | `env.e2e.local` in that state folder |

The app is built once for 127.0.0.1:8585 and :8586; on the emulator
`adb reverse` points those two at the Android stack's ports. The offset is
`E2E_STACK_PORT_OFFSET` (see `tools/e2e/stack-ports.sh`), which
`local-stack.sh` and `maestro-data.sh` read too. The web's stack uses the same
ports as the Dart suite's, so those two cannot run at the same time: the
runner says so when the other one is up (`tools/e2e/local-stack.sh stop` stops
the Dart suite's). Sales the flows make stay in those local databases.

## How the flows are written

```
packages/applications/pos/maestro/
  android/<flow>.yaml   appId, LAYOUT: narrow, launchApp with clearState
  web/<flow>.yaml       url,   LAYOUT: wide,   launchApp (a fresh profile each run)
  shared/<flow>.yaml    the flow itself, the same file for both
  shared/steps/         sign_in, sign_out, open_screen, add_product_twice, add_customer,
                        choose_dropdown_option, open_product, open_product_edit,
                        adjust_stock, sell_two, expect_staff_menu
  scripts/api.js        asks the local API what the server recorded (bills, a
                        bill's status, the day's totals, stock on hand,
                        adjustments, stock counts, products, customers)
```

- **Layout, not platform.** The phone shows the narrow layout (menu in a
  drawer, product grid behind a button), the browser the wide one. Steps that
  differ are picked with `when: true: ${LAYOUT == 'narrow'}`, which costs no
  waiting. Only one thing is truly per platform: hiding the soft keyboard,
  always through `steps/hide_keyboard.yaml`, never a bare `hideKeyboard`.
  Maestro hides it on Android by pressing Back, and with no keyboard up that
  Back leaves the screen (from sign-in it closes the app, and Android's
  autofill then covers the screen with "Save password to Google?"). An
  emulator with a hardware keyboard shows no on-screen keyboard, only
  Gboard's "More keyboard options" button, so the step hides the keyboard
  only when Gboard shows something else. Sign-in also answers that autofill
  sheet "Not now" if it shows (`steps/dismiss_save_password.yaml`): that
  saves nothing and changes no device setting.
- **Selectors are full-match regular expressions.** Flutter hands a widget's
  texts over as one node — joined by a newline on Android, by nothing on the
  web — so a total is `"ยอดรวมสุทธิ\n?฿50\\.00"`, and a partial text never
  matches without `.*`. Never use `flt-semantic-node-N` ids (they change), a
  `point:` tap, or `{`/`}` inside `${…}` (Maestro stops at the first `}`).
- **Every wait is bounded**; there are no sleeps.
- **A flow checks the server too**, through `scripts/api.js`, where the screen
  alone would not prove it (the bill's total, stock on hand, a customer
  archived). After an action the screen is waited on first; asking the server
  at once races the app's own request.
- **Prove a flow can fail.** Each flow was run once with one expectation
  changed to something false (a wrong error code, total, screen, name, stock
  figure) and failed there. Do the same for a new flow before trusting it.

### What had to change in the app

Maestro reads the screen through the accessibility (semantics) tree. On the
web it reads an element's own DOM text only, and Flutter web writes a node's
label as text only when the node has no children (a node with children, a
menu item, a tab or a toggle gets an `aria-label`). Each change has a widget
test. Most change nothing a sighted user sees; those that do are listed in
[e2e-findings.md](e2e-findings.md#what-a-user-now-sees-differently) (the
cart line's two rows on every cart the app builds today, tooltips, Thai
button labels, the stock row's scrollbar, among others).

- `lib/main.dart`: `e2eSemanticsEnabled` — a web build made with
  `--dart-define=E2E_SEMANTICS=true` keeps the semantics tree on. An ordinary
  build is unchanged: Maestro sees nothing of it (checked).
- Every icon-only control has a name, in the app's strings (`Languages`,
  Thai and English), and no two on a screen share one
  (`test/presentation/accessibility_walk_test.dart` walks the screens the
  widget tests can build). The ones the flows use: `เลือกสินค้า` (the phone's
  product picker), `นำลูกค้า <name> ออก`, `เพิ่มลูกค้า`, `คำสั่งเพิ่มเติม`
  (a list's commands on a phone), `ย้อนกลับ` (a pushed page's back arrow),
  `ปรับสต็อก ล็อต <lot>`, `เพิ่มการนับสต็อก`,
  `บันทึกการนับสต็อก`, `คำสั่งเพิ่มเติมของบิล` (the bill's menu, which
  holds `ลบบิล`). A row's buttons name their row:
  `ลดจำนวน <product> <unit>`, `เพิ่มจำนวน <product> <unit>`,
  `2x แก้ไขจำนวน <product> <unit>` on a cart line, `คำสั่งเพิ่มเติมของ 2x
  <product> <unit> ฿<amount>` on a bill line, the menu that holds its
  `คืนสินค้า 2x <product> <unit> ฿<amount>` (the unit's name comes from the
  product catalogue: the bill sends only its id).
- A row's texts are one node of their own, beside its buttons
  (`ReadableTile`): the cart line `2x <product> <unit> ฿<amount> <price
  kind>`, the chosen customer `<name>\n<code>`, a bill line `2x <product>
  … ฿<amount>`, a receipt line `Name: <product>\n…`, a new stock count's
  line `<product>\nล็อต <lot>, ในระบบ <n>`. Each row of a bill's foot is a
  node of its own (`ยอดรวม ฿ 950.00`). Dialog and list titles and the cart
  title `ตะกร้าสินค้า #N` are header nodes of their own. An open dropdown's
  options each have a text node of their own (`DropdownInput`,
  `readableOption`), so `choose_dropdown_option` taps the option's text on
  both platforms.
- Tabs and the stock adjustment's add / take toggle carry their text as
  their identifier (above).

### Known limits

- A flow that fails leaves its run's data for `maestro-data.sh down <run id>`,
  which the runner calls in any case.
- `flutter build apk` fails on this Mac (Flutter picks Android Studio's Java
  25, which the project's Gradle cannot run on); `maestro-build.sh` calls
  Gradle with a JDK 17 instead. `flutter config --jdk-dir <jdk 17>` would fix
  the ordinary command too — the owner's call.
- A centred number field cannot be overwritten: a tap puts the cursor
  somewhere in the figure, Maestro has no select-all, and a double tap does
  not select on the web. `stock_count` therefore counts the lot to 0 (what
  is right of the cursor is only zeros), not 8 as the Dart suite does.
- The store filter chips' labels are not text on the web (Flutter writes a
  chip's label as an `aria-label`); `roles` checks the costs a role hides
  instead, and the chips are left to `navigation_test.dart`.
- A role's hidden items are checked once the bills list has loaded and its
  animations ended (`expect_staff_menu`): the admin's run of the same flow
  shows them at that same point.
- The flows type only ASCII (names `MST-<run id> …`, the unit `pc`):
  Maestro's typing of Thai on Android is not relied on (not tried).

What the flows showed about the app is in
[e2e-findings.md](e2e-findings.md#found-by-the-maestro-flows).
