// Project imports:
import 'languages.dart';

class LanguageEn extends Languages {
  @override
  String get appName => "Devper POS";

  @override
  String get homeTitle => "Home";

  @override
  String get productsTitle => "Products";

  @override
  String get productAddTitle => "Add Product";

  @override
  String get productEditTitle => "Edit Product";

  @override
  String get productFindTitle => "Find Product";

  @override
  String get changeLanguage => "Change Language";

  @override
  String get ordersTitle => "Order Summary";

  @override
  String get orderSelectEndDate => "Select end date";

  @override
  String get orderSelectStartDate => "Select start date";

  @override
  String get orderDetailTitle => "Bill details";

  @override
  String get orderHistoryTitle => "Order History";

  @override
  String get categoryTitle => "Category";

  @override
  String get categoryAddTitle => "Add Category";

  @override
  String get categoryEditTitle => "Edit Category";

  @override
  String get changePasswordTitle => "Change Password";

  @override
  String get userManageTitle => "User Manage";

  @override
  String get userAddTitle => "Add User";

  @override
  String get userEditTitle => "Edit User";

  @override
  String get userInfoTitle => "User Info";

  @override
  String get customerAddTitle => "Add Customer";

  @override
  String get customerEditTitle => "Edit Customer";

  @override
  String get customerTitle => "Customer";

  @override
  String get customerManageTitle => "Customer Manage";

  @override
  String get supplierInfoTitle => "My Supplier";

  @override
  String get receiveManageTitle => "Receive";

  @override
  String get receivesTitle => "Receives";

  @override
  String get productsExpiredTitle => "Products Expired";

  @override
  String get productLotEditTitle => "Edit Lot Number";

  @override
  String get stockCountsTitle => "Stock Count";

  @override
  String get stockCountManageTitle => "Stock Count Detail";

  @override
  String get stockCountCreateTitle => "New Stock Count";

  @override
  String get supplierAddTitle => "Add Supplier";

  @override
  String get supplierEditTitle => "Edit Supplier";

  @override
  String get suppliersTitle => "Supplier Manage";

  @override
  String get back => "Back";

  @override
  String get clearSearch => "Clear search";

  @override
  String get sortByBalance => "Sort by stock on hand";

  @override
  String get sortByName => "Sort by name";

  @override
  String get addSupplier => "Add supplier";

  @override
  String get chooseProduct => "Choose product";

  @override
  String removeCustomer(String name) => "Remove customer $name";

  @override
  String get moreCommands => "More commands";

  @override
  String get deleteReceive => "Delete receipt";

  @override
  String deleteReceiveLine(String name) => "Delete line $name";

  @override
  String importedReceiveLine(String name) => "Line $name imported";

  @override
  String get billReceipt => "Receipt PDF";

  @override
  String get billReload => "Reload bill";

  @override
  String get billReturns => "Returns history";

  @override
  String get billDelete => "Delete bill";

  @override
  String get billCommands => "More bill commands";

  @override
  String deleteBillLine(String name) => "Delete line $name";

  @override
  String billLineHistory(String name) => "Sales history of $name";

  @override
  String returnBillLine(String name) => "Return $name";

  @override
  String billLineCommands(String name) => "More commands for $name";

  @override
  String get billLineDelete => "Delete line";

  @override
  String get billLineSales => "Sales history";

  @override
  String get billLineReturn => "Return";

  @override
  String oneLess(String name) => "One less $name";

  @override
  String oneMore(String name) => "One more $name";

  @override
  String changeQuantity(String name) => "Change quantity of $name";

  @override
  String allowOversell(String name) => "Allow selling $name beyond stock";

  @override
  String oversellAllowed(String name) => "Selling $name beyond stock allowed";

  @override
  String editLot(String lot) => "Edit lot $lot";

  @override
  String lotOnHand(String lot) => "Set on hand of lot $lot";

  @override
  String adjustLot(String lot) => "Adjust stock of lot $lot";

  @override
  String unnumberedLot(int row, {String importDate = ''}) => importDate.isEmpty
      ? "without a number, row $row"
      : "without a number, row $row, imported $importDate";

  @override
  String get saveStockCount => "Save stock count";

  @override
  String removeCountLine(String name) => "Remove count line $name";

  @override
  String get newStockCount => "New stock count";

  @override
  String get toggleFlash => "Turn the flash on or off";

  @override
  String get switchCamera => "Switch camera";

  @override
  String get addCategory => "Add category";

  @override
  String get deleteCategory => "Delete category";

  @override
  String get deleteSupplier => "Delete supplier";

  @override
  String get downloadSalesCsv => "Download sales history CSV";

  @override
  String get pickImportDate => "Pick the import date";

  @override
  String get pickExpiryDate => "Pick the expiry date";

  @override
  String get scanBarcode => "Scan barcode";

  @override
  String get saveButton => "Save";

  @override
  String get addButton => "Add";

  @override
  String get requireCustomerOrder => "Require customer order";

  @override
  String receiveCash(String amount) => "Receive $amount";

  @override
  String get exactPayment => "Exact amount";

  @override
  String get exactPaymentNoChange => "No change";

  @override
  String get exactPaymentName => "Exact amount, no change";

  @override
  String get enterAmountReceived => "Enter the amount received";

  @override
  String payWithChange(String amount) => "Change $amount";

  @override
  String productOnHand(String quantity, String unit) =>
      "$quantity $unit on hand";

  @override
  String get outOfStock => "Out of stock";

  @override
  String get lowStock => "Low stock";

  @override
  String get chooseProductHint => "Choose a product to see its details";

  @override
  String get chooseCustomerHint => "Choose a customer to see their details";

  @override
  String get chooseReceiveHint => "Choose a goods receipt to see its details";

  @override
  String get addReceive => "Add goods receipt";

  @override
  String get noProductsYet => "No products yet";

  @override
  String get addFirstProduct => "Add your first product";

  @override
  String get noCustomersYet => "No customers yet";

  @override
  String get addFirstCustomer => "Add your first customer";

  @override
  String get noReceivesYet => "No goods receipts yet";

  @override
  String get addFirstReceive => "Add your first goods receipt";

  @override
  String get noStockCountsYet => "No stock counts yet";

  @override
  String get addFirstStockCount => "Start your first stock count";

  @override
  String get noCategoriesYet => "No categories yet";

  @override
  String get addFirstCategory => "Add your first category";

  @override
  String get noSuppliersYet => "No suppliers yet";

  @override
  String get addFirstSupplier => "Add your first supplier";

  @override
  String get noSearchResults => "Nothing matches the search";
}
