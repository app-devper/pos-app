// Spike: signs in to the LOCAL UM and reads the LOCAL pos-api from Maestro's JS (runs on the host, not in the app).
const login = http.post('http://127.0.0.1:8585/api/um/v1/auth/login', {
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ username: USERNAME, password: PASSWORD, system: 'POS' }),
});
if (login.status !== 200) throw new Error('UM login: ' + login.status);
const token = json(login.body).accessToken;
const res = http.get('http://127.0.0.1:8586/api/pos/v1/products', {
  headers: { Authorization: 'Bearer ' + token },
});
if (res.status !== 200) throw new Error('products: ' + res.status);
const list = json(res.body);
const items = Array.isArray(list) ? list : (list.data || list.items || []);
const spike = items.filter((p) => p.name === 'MSPIKE product');
output.spikeCount = String(spike.length);
output.spikeBarcode = spike.length ? String(spike[0].serialNumber) : '';
console.log('api-check: products=' + items.length + ' MSPIKE=' + spike.length);
