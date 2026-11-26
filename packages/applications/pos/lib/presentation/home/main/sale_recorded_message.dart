/// What the till says once a sale is recorded: its bill number, the one the
/// server gave it, so the cashier can find the bill again. A response without
/// a code says only that the sale is done; no number is made up.
String saleRecordedMessage(String billCode) =>
    billCode.isEmpty ? 'ขายสำเร็จ' : 'ขายสำเร็จ เลขที่บิล $billCode';
