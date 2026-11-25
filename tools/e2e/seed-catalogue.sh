#!/usr/bin/env bash
# Crowds the LOCAL e2e database the way a real shop's would be, so that the
# robots are proven against lists that do not fit on one screen: 400 active
# products (named "AA filler …" and "ZZ filler …", so a run's product sorts
# neither first nor last), 150 customers and 50 suppliers, in the shapes
# pos-api writes. Run once after tools/e2e/local-stack.sh start; running it
# again adds nothing. Local target only.
#
#   tools/e2e/seed-catalogue.sh local
set -eu

[ "$#" -eq 1 ] && [ "$1" = local ] || {
  printf 'usage: %s local   (the local e2e stack only; refuses anything else)\n' "$0" >&2
  exit 2
}

MONGO_PORT=27719
POS_DB=e2e_pos

mongosh --quiet --port "$MONGO_PORT" "$POS_DB" --eval '
const marker = /^(AA|ZZ) filler /;
if (db.products.countDocuments({name: marker}) > 0) {
  print("seed-catalogue: filler data is already there; nothing added");
  quit(0);
}
const now = new Date();
const by = "seed-catalogue";
const pad = (n) => String(n).padStart(3, "0");
let products = 0;
for (const prefix of ["AA", "ZZ"]) {
  for (let i = 1; i <= 200; i++) {
    const id = new ObjectId();
    const unitId = new ObjectId();
    const barcode = (prefix === "AA" ? "91" : "92") + "00000000" + pad(i);
    db.products.insertOne({_id: id, name: `${prefix} filler ${pad(i)}`, nameEn: "",
      description: "", price: 20, costPrice: 8, unit: "ชิ้น", quantity: 0, soldFirst: 0,
      serialNumber: barcode, category: "None", status: "Active", minStock: 0,
      createdBy: by, createdDate: now, updatedBy: by, updatedDate: now});
    db.product_units.insertOne({_id: unitId, productId: id, unit: "ชิ้น", size: 1,
      costPrice: 8, volume: 0, volumeUnit: "", barcode: barcode});
    db.product_prices.insertOne({productId: id, unitId: unitId,
      customerType: "General", price: 20});
    products++;
  }
}
for (let i = 1; i <= 150; i++) {
  const prefix = i % 2 ? "AA" : "ZZ";
  db.customers.insertOne({code: `FILL_${pad(i)}`, customerType: "General",
    name: `${prefix} filler customer ${pad(i)}`, address: "", phone: "0800000000",
    email: "", status: "ACTIVE", createdBy: by, createdDate: now, updatedBy: by,
    updatedDate: now});
}
for (let i = 1; i <= 50; i++) {
  const prefix = i % 2 ? "AA" : "ZZ";
  db.suppliers.insertOne({clientId: "", name: `${prefix} filler supplier ${pad(i)}`,
    address: "filler", phone: "", taxId: "", status: "ACTIVE", createdBy: by,
    createdDate: now, updatedBy: by, updatedDate: now});
}
print(`seed-catalogue: added ${products} products, 150 customers, 50 suppliers`);
'
