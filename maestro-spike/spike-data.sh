#!/usr/bin/env bash
# Spike only. Puts (or removes) one sellable product in the LOCAL e2e database,
# straight through mongosh the way tools/e2e/seed-catalogue.sh does.
#   maestro-spike/spike-data.sh up     product "MSPIKE product" (barcode 9300000000001), 1000 on hand, ฿25
#   maestro-spike/spike-data.sh down   delete it, its unit, price and stock rows
set -eu
[ "$#" -eq 1 ] || { echo "usage: $0 up|down" >&2; exit 2; }
mongosh --quiet --port 27719 e2e_pos --eval "const mode='$1';"'
const name = "MSPIKE product", barcode = "9300000000001";
const old = db.products.find({$or: [{name}, {serialNumber: barcode}]}).toArray().map(p => p._id);
db.product_stocks.deleteMany({productId: {$in: old}});
db.product_prices.deleteMany({productId: {$in: old}});
db.product_units.deleteMany({productId: {$in: old}});
db.products.deleteMany({_id: {$in: old}});
if (mode === "down") { print(`spike-data: removed ${old.length} product(s)`); quit(0); }
const now = new Date(), by = "maestro-spike";
const id = new ObjectId(), unitId = new ObjectId();
const branch = db.branches.findOne({status: "ACTIVE"})._id;
db.products.insertOne({_id: id, name, nameEn: "", description: "", price: 25, costPrice: 10,
  unit: "ชิ้น", quantity: 0, soldFirst: 0, serialNumber: barcode, category: "None",
  status: "Active", minStock: 0, createdBy: by, createdDate: now, updatedBy: by, updatedDate: now});
db.product_units.insertOne({_id: unitId, productId: id, unit: "ชิ้น", size: 1, costPrice: 10,
  volume: 0, volumeUnit: "", barcode});
db.product_prices.insertOne({productId: id, unitId, customerType: "General", price: 25});
db.product_stocks.insertOne({branchId: branch, productId: id, unitId, receiveCode: "MSPIKE",
  sequence: 1, lotNumber: "LMSPIKE", costPrice: 10, price: 0, import: 1000, quantity: 1000,
  expireDate: new Date(Date.now() + 365*864e5), importDate: now});
print(`spike-data: product ${id} with 1000 on hand`);
'
