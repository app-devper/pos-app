# POS main-path flows with Maestro (Android and web)

Six [Maestro](https://maestro.dev) flows drive the real POS app the way a
person does — by what is on the screen — on the Android emulator and in a
browser, against the local test stack. They sit beside the Dart suite
([e2e.md](e2e.md)), which is the thorough one; these are the short, readable
check that the main paths work on a phone and on the web.

## What the flows cover

| Flow | What it proves |
|---|---|
| `auth` | a wrong password is refused with UM's code and the user stays on sign-in; admin, manager and user each sign in to the selling screen and out |
| `navigation` | every main menu item opens its own screen (bills, products, the five manage tiles, profile) and selling is reachable again |
| `sell_and_bill` | two of a product in the cart, the totals, a cash payment, the total the server recorded, and that bill found by its number in the bills list |
| `customer` | a customer added by the form is on the server, can be found and chosen for a sale, and is archived by its delete button (finding 7 pinned: it stays listed) |
| `receive_stock` | a goods receipt for a supplier, one line of five, imported: the server holds 1005 on hand |
| `product_edit` | a product renamed on its page: the server and the selling screen show the new name, stock untouched |

Not covered: iOS; anything hosted (see "Local only"); stock counts, returns,
PDF/CSV export, the scanner; prices per customer type. The Dart suite covers
more of those.

## Running

Prerequisites, all already on the development Mac: Maestro 2.12
(`maestro --version`), a JDK 17, the Android SDK with the AVD `Medium_Phone`
(override with `E2E_AVD`), Chrome for Testing in `~/.cache/selenium` (Maestro
fetched it on its first web run), and what the local stack needs (MongoDB,
Redis, Go — see [e2e.md](e2e.md)).

```bash
tools/e2e/maestro.sh android all            # every flow on the emulator
tools/e2e/maestro.sh web all --headless     # every flow in a headless browser, 1400x900
tools/e2e/maestro.sh web sell_and_bill      # one flow, in a visible window
tools/e2e/maestro-selftest.sh               # the runner's own checks, no device needed
```

One `PASS|FAIL <platform> <flow> <seconds>s` line per flow; exit 0 only when
all passed. A run of all six takes about nine minutes on the emulator and
seven on the web, plus the build the first time (APK about four minutes, web
about one). `E2E_MAESTRO_REUSE_BUILD=1` skips the build when the artefact is
there — only when the app's code has not changed.

What the runner does: refuses unless `config/e2e-local.json` points at
127.0.0.1; starts the flows' own local stack; builds the debug APK (or the web
build with `--dart-define=E2E_SEMANTICS=true`); starts the emulator if none is
running, keeps its screen on and forwards the two API ports (or serves the web
build on 127.0.0.1:8090); then for each flow seeds one product and one
supplier named `MST-<run id>`, runs Maestro and removes them. It stops what it
started — an emulator or a stack that was already running is left running.

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

The flows use their own stack state (`${TMPDIR}/pos-e2e-maestro-stack`), not
the Dart suite's. That one is crowded on purpose; Maestro cannot pick a
product out of a plain dropdown of hundreds or find a row far down a list
with no search. Both stacks use the same ports, so they cannot run at the same
time: the runner says so when the other one is up
(`tools/e2e/local-stack.sh stop` stops the Dart suite's). Sales the flows make
stay in that local database.

## How the flows are written

```
packages/applications/pos/maestro/
  android/<flow>.yaml   appId, LAYOUT: narrow, launchApp with clearState
  web/<flow>.yaml       url,   LAYOUT: wide,   launchApp (a fresh profile each run)
  shared/<flow>.yaml    the flow itself, the same file for both
  shared/steps/         sign_in, sign_out, open_screen, add_product_twice, choose_dropdown_option
  scripts/api.js        asks the local API what the server recorded
```

- **Layout, not platform.** The phone shows the narrow layout (menu in a
  drawer, product grid behind a button), the browser the wide one. Steps that
  differ are picked with `when: true: ${LAYOUT == 'narrow'}`, which costs no
  waiting. Only two things are truly per platform: hiding the soft keyboard,
  and choosing a dropdown option.
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

Maestro reads the screen through the accessibility (semantics) tree. Two
kinds of change, each with a widget test, none changing what a user sees
except a tooltip on hover or long-press:

- `lib/main.dart`: `e2eSemanticsEnabled` — a web build made with
  `--dart-define=E2E_SEMANTICS=true` keeps the semantics tree on. An ordinary
  build is unchanged: Maestro sees nothing of it (checked).
- Labels where a control had none or could not be told apart:
  `CartSearchButton` (tooltip เลือกสินค้า), the cart line's quantity
  (`<n>x <product>`), `OrderListTile` (position + bill number),
  `CartCustomerRemoveButton` (นำลูกค้า … ออก), `CustomerListHeader`'s add icon
  (เพิ่มลูกค้า), `ReceiveMenuButton` (เมนูใบรับสินค้า).

### Known limits

- On the web an open dropdown exposes no option text, so
  `choose_dropdown_option` presses Enter on the focused option; it is right
  only because the flows' database holds exactly one supplier and one product
  per run. What was chosen is asserted afterwards on the page.
- Several texts never reach the web's semantics tree (page and cart titles,
  the lines of a bill); the flows anchor on something beside them.
- A flow that fails leaves its run's data for `maestro-data.sh down <run id>`,
  which the runner calls in any case.
- `flutter build apk` fails on this Mac (Flutter picks Android Studio's Java
  25, which the project's Gradle cannot run on); `maestro-build.sh` calls
  Gradle with a JDK 17 instead. `flutter config --jdk-dir <jdk 17>` would fix
  the ordinary command too — the owner's call.

What the flows showed about the app is in
[e2e-findings.md](e2e-findings.md#found-by-the-maestro-flows).
