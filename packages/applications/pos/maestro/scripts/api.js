// What a flow asks the LOCAL API directly, to check what the app did against
// what the server recorded. Runs on the host (Maestro's JS engine), so
// 127.0.0.1 is the local stack on both platforms. No other host, ever.
//
// runScript: { file: ../scripts/api.js, env: { ACTION: newestBill } }
//   newestBill             -> output.billCode, output.billTotal ('' when there is none)
//   productOnHand  (NAME)  -> output.onHand, output.productPrice
//   customerCount  (NAME)  -> output.customerCount (customers of that name that are not archived)
//   productCount   (NAME)  -> output.productCount (products of exactly that name)
//   adjustments    (NAME)  -> output.adjustDeltas ('+2,-2': the product's adjustments, oldest first),
//                             output.adjustNotes (their notes, the same way)
//   stockCount     (NOTE)  -> output.countNo, output.countLines ('' when no count has that note)
//   billStatus     (CODE)  -> output.billStatus (CONFIRMED or CANCELLED)
//   dayTotal               -> output.dayTotal (today's bills less the cancelled ones, '#,##0.00'),
//                             output.dayTotalAll (with the cancelled ones)
const UM = 'http://127.0.0.1:8585';
const POS = 'http://127.0.0.1:8586';

function signIn() {
  const res = http.post(UM + '/api/um/v1/auth/login', {
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: MAESTRO_USERNAME, password: MAESTRO_PASSWORD, system: 'POS' }),
  });
  if (res.status !== 200) throw new Error('api.js: UM sign-in answered ' + res.status);
  return json(res.body).accessToken;
}

function get(path) {
  if (!output.apiToken) output.apiToken = signIn();
  const res = http.get(POS + path, { headers: { Authorization: 'Bearer ' + output.apiToken } });
  if (res.status !== 200) throw new Error('api.js: GET ' + path + ' answered ' + res.status);
  return json(res.body);
}

function newestBill() {
  const dayMs = 24 * 60 * 60 * 1000;
  const from = new Date(Date.now() - dayMs).toISOString();
  const to = new Date(Date.now() + dayMs).toISOString();
  const bills = get('/api/pos/v1/orders?startDate=' + from + '&endDate=' + to);
  if (!bills.length) {
    output.billCode = '';
    output.billTotal = '';
    return;
  }
  const newest = bills.reduce((a, b) => (a.createdDate > b.createdDate ? a : b));
  output.billCode = newest.code;
  output.billTotal = String(newest.total);
}

function productOnHand() {
  const product = get('/api/pos/v1/products').filter((p) => p.name === NAME)[0];
  if (!product) throw new Error('api.js: no product named ' + NAME);
  const rows = get('/api/pos/v1/products/' + product.id + '/stocks');
  output.onHand = String(rows.reduce((sum, row) => sum + row.quantity, 0));
  output.productPrice = String(product.price);
}

function customerCount() {
  // pos-api archives a removed customer and still returns it; the app
  // leaves archived ones out (finding 7), and so does this count.
  const named = get('/api/pos/v1/customers').filter((c) => c.name === NAME);
  output.customerCount = String(named.filter((c) => c.status !== 'ARCHIVED').length);
}

function productNamed(name) {
  const product = get('/api/pos/v1/products').filter((p) => p.name === name)[0];
  if (!product) throw new Error('api.js: no product named ' + name);
  return product;
}

function productCount() {
  output.productCount = String(get('/api/pos/v1/products').filter((p) => p.name === NAME).length);
}

function adjustments() {
  const rows = get('/api/pos/v1/stock-adjustments/product/' + productNamed(NAME).id) || [];
  rows.sort((a, b) => (a.createdDate < b.createdDate ? -1 : 1));
  output.adjustDeltas = rows.map((r) => (r.delta > 0 ? '+' : '') + r.delta).join(',');
  output.adjustNotes = rows.map((r) => r.note || '').join(',');
}

function stockCount() {
  const count = (get('/api/pos/v1/stock-counts') || []).filter((c) => c.note === NOTE)[0];
  output.countNo = count ? count.countNo : '';
  output.countLines = count ? String((count.items || []).length) : '';
}

// The bills of the local day, as the bills list's "Today" asks for them.
function todaysBills() {
  const start = new Date();
  start.setHours(0, 0, 0, 0);
  const end = new Date(start.getTime() + 24 * 60 * 60 * 1000);
  return get('/api/pos/v1/orders?startDate=' + start.toISOString() + '&endDate=' + end.toISOString()) || [];
}

function billStatus() {
  const bill = todaysBills().filter((b) => b.code === CODE)[0];
  if (!bill) throw new Error('api.js: no bill ' + CODE + ' today');
  output.billStatus = bill.status;
}

function money(value) {
  const [whole, satang] = (Math.round(value * 100) / 100).toFixed(2).split('.');
  return whole.replace(/\B(?=(\d{3})+(?!\d))/g, ',') + '.' + satang;
}

function dayTotal() {
  const bills = todaysBills();
  const sum = (list) => list.reduce((total, b) => total + b.total, 0);
  output.dayTotal = money(sum(bills.filter((b) => b.status !== 'CANCELLED')));
  output.dayTotalAll = money(sum(bills));
}

const actions = {
  newestBill: newestBill,
  productOnHand: productOnHand,
  customerCount: customerCount,
  productCount: productCount,
  adjustments: adjustments,
  stockCount: stockCount,
  billStatus: billStatus,
  dayTotal: dayTotal,
};
if (!actions[ACTION]) throw new Error('api.js: unknown ACTION ' + ACTION);
actions[ACTION]();
