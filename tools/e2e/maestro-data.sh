#!/usr/bin/env bash
# The data one Maestro flow needs, put straight into the LOCAL e2e database
# with mongosh, the way seed-catalogue.sh does. Local only by construction:
# it talks to the local stack's MongoDB port and nothing else.
#
#   maestro-data.sh up <run-id>    one sellable product "MST-<run-id> product":
#                                  barcode 93<run-id>0001, price 25, cost 10,
#                                  1000 on hand in the active branch; and one
#                                  supplier "MST-<run-id> supplier"
#   maestro-data.sh down <run-id>  delete every product, customer and supplier
#                                  whose name starts with "MST-<run-id>"
set -eu

MONGO_PORT=27719
POS_DB=e2e_pos

usage() { echo "usage: $0 up|down <run-id>   (run id: letters and digits)" >&2; exit 2; }

[ "$#" -eq 2 ] || usage
mode="$1"
run_id="$2"
case "$mode" in up|down) ;; *) usage ;; esac
case "$run_id" in ''|*[!0-9A-Za-z]*) usage ;; esac

mongosh --quiet --port "$MONGO_PORT" "$POS_DB" --eval "const mode='$mode', runId='$run_id';"'
const prefix = "MST-" + runId;
const named = {name: {$regex: "^" + prefix}};
const old = db.products.find(named).toArray().map(p => p._id);
db.product_stocks.deleteMany({productId: {$in: old}});
db.product_prices.deleteMany({productId: {$in: old}});
db.product_units.deleteMany({productId: {$in: old}});
db.products.deleteMany({_id: {$in: old}});
const customers = db.customers.deleteMany(named).deletedCount;
const suppliers = db.suppliers.deleteMany(named).deletedCount;
if (mode === "down") {
  print(`maestro-data: removed ${old.length} product(s), ${customers} customer(s), ${suppliers} supplier(s) of ${prefix}`);
  quit(0);
}
const name = prefix + " product", barcode = "93" + runId + "0001";
const now = new Date(), by = "maestro";
const id = new ObjectId(), unitId = new ObjectId();
const branch = db.branches.findOne({status: "ACTIVE"})._id;
db.products.insertOne({_id: id, name, nameEn: "", description: "", price: 25, costPrice: 10,
  unit: "ชิ้น", quantity: 0, soldFirst: 0, serialNumber: barcode, category: "None",
  status: "Active", minStock: 0, createdBy: by, createdDate: now, updatedBy: by, updatedDate: now});
db.product_units.insertOne({_id: unitId, productId: id, unit: "ชิ้น", size: 1, costPrice: 10,
  volume: 0, volumeUnit: "", barcode});
db.product_prices.insertOne({productId: id, unitId, customerType: "General", price: 25});
db.product_stocks.insertOne({branchId: branch, productId: id, unitId, receiveCode: prefix,
  sequence: 1, lotNumber: "L" + runId, costPrice: 10, price: 0, import: 1000, quantity: 1000,
  expireDate: new Date(Date.now() + 365*864e5), importDate: now});
db.suppliers.insertOne({clientId: "", name: prefix + " supplier", address: "maestro", phone: "",
  taxId: "", status: "ACTIVE", createdBy: by, createdDate: now, updatedBy: by, updatedDate: now});
print(`maestro-data: ${name} with 1000 on hand, and ${prefix} supplier`);
'
