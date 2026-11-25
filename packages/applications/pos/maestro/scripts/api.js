// What a flow asks the LOCAL API directly, to check what the app did against
// what the server recorded. Runs on the host (Maestro's JS engine), so
// 127.0.0.1 is the local stack on both platforms. No other host, ever.
//
// runScript: { file: ../scripts/api.js, env: { ACTION: newestBill } }
//   newestBill             -> output.billCode, output.billTotal ('' when there is none)
//   productOnHand  (NAME)  -> output.onHand, output.productPrice
//   customerCount  (NAME)  -> output.customerCount (customers of that name that are not archived)
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
  // pos-api archives a removed customer and still lists it (finding 7).
  const named = get('/api/pos/v1/customers').filter((c) => c.name === NAME);
  output.customerCount = String(named.filter((c) => c.status !== 'ARCHIVED').length);
}

const actions = { newestBill: newestBill, productOnHand: productOnHand, customerCount: customerCount };
if (!actions[ACTION]) throw new Error('api.js: unknown ACTION ' + ACTION);
actions[ACTION]();
