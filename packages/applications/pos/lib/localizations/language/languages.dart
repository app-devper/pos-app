// Flutter imports:
import 'package:flutter/material.dart';

abstract class Languages {
  static Languages of(BuildContext context) {
    return Localizations.of<Languages>(context, Languages)!;
  }

  String get appName;

  String get homeTitle;

  String get productsTitle;

  String get productAddTitle;

  String get productEditTitle;

  String get productFindTitle;

  String get changeLanguage;

  String get ordersTitle;

  String get orderSelectStartDate;

  String get orderSelectEndDate;

  String get orderDetailTitle;

  String get orderHistoryTitle;

  String get categoryTitle;

  String get categoryAddTitle;

  String get categoryEditTitle;

  String get changePasswordTitle;

  String get userManageTitle;

  String get userInfoTitle;

  String get userAddTitle;

  String get userEditTitle;

  String get customerManageTitle;

  String get customerTitle;

  String get customerAddTitle;

  String get customerEditTitle;

  String get supplierInfoTitle;

  String get suppliersTitle;

  String get supplierAddTitle;

  String get supplierEditTitle;

  String get receiveManageTitle;

  String get receivesTitle;

  String get productsExpiredTitle;

  String get productLotEditTitle;

  String get stockCountsTitle;

  String get stockCountManageTitle;

  String get stockCountCreateTitle;

  // The names of icon-only controls: what a screen reader says, and the
  // tooltip on hover or long-press. A name that takes a product, lot or
  // customer names which row the control acts on.

  String get back;

  String get clearSearch;

  String get sortByBalance;

  String get sortByName;

  String get addSupplier;

  String get chooseProduct;

  String removeCustomer(String name);

  String get moreCommands;

  String get deleteReceive;

  String deleteReceiveLine(String name);

  String importedReceiveLine(String name);

  String get billReceipt;

  String get billReload;

  String get billReturns;

  String get billDelete;

  /// The bill's menu of its less common commands.
  String get billCommands;

  String deleteBillLine(String name);

  String billLineHistory(String name);

  String returnBillLine(String name);

  /// A bill line's menu of its actions, named for the line [name].
  String billLineCommands(String name);

  /// The visible labels of a bill line's menu items; each item is named
  /// in full by [deleteBillLine], [billLineHistory] and [returnBillLine].
  String get billLineDelete;

  String get billLineSales;

  String get billLineReturn;

  String oneLess(String name);

  String oneMore(String name);

  String changeQuantity(String name);

  String allowOversell(String name);

  String oversellAllowed(String name);

  String editLot(String lot);

  String lotOnHand(String lot);

  String adjustLot(String lot);

  /// A lot with no lot number, by its row (and import date when known).
  String unnumberedLot(int row, {String importDate = ''});

  String get saveStockCount;

  String removeCountLine(String name);

  String get newStockCount;

  String get toggleFlash;

  String get switchCamera;

  String get addCategory;

  String get deleteCategory;

  String get deleteSupplier;

  String get downloadSalesCsv;

  String get pickImportDate;

  String get pickExpiryDate;

  String get scanBarcode;

  String get saveButton;

  String get addButton;

  String get requireCustomerOrder;

  /// A quick-cash chip's name: receive [amount] (already formatted, ฿100).
  String receiveCash(String amount);

  /// The payment's pay button when the amount due is paid exactly: its
  /// first line, its smaller second line, and its name in full.
  String get exactPayment;

  String get exactPaymentNoChange;

  String get exactPaymentName;

  /// The pay button while the amount received is short of the amount due.
  String get enterAmountReceived;

  /// The pay button with change to give: [amount] already formatted.
  String payWithChange(String amount);

  /// A product row's stock: [quantity] of [unit] on hand.
  String productOnHand(String quantity, String unit);

  /// Said beside a product's stock when none is left, so it is not told by
  /// colour alone.
  String get outOfStock;

  /// Said beside a product's stock when it is at or below its minimum.
  String get lowStock;

  /// A wide list page's pane while nothing in the list is chosen.
  String get chooseProductHint;

  String get chooseCustomerHint;

  String get chooseReceiveHint;

  /// The receipts page's add: a new goods receipt.
  String get addReceive;

  /// An empty list: what it says, and its add of the first one (named apart
  /// from the page's own add, which may be on screen too).
  String get noProductsYet;

  String get addFirstProduct;

  String get noCustomersYet;

  String get addFirstCustomer;

  String get noReceivesYet;

  String get addFirstReceive;

  String get noStockCountsYet;

  String get addFirstStockCount;

  String get noCategoriesYet;

  String get addFirstCategory;

  String get noSuppliersYet;

  String get addFirstSupplier;

  /// A searched list that matched nothing.
  String get noSearchResults;

  /// The pay button while PromptPay is chosen: the total, [amount] already
  /// formatted.
  String payByPromptPay(String amount);

  /// The bills list's store filter chips.
  String get billFilterAll;

  String get billFilterStore;

  String get billFilterOnline;

  /// The bills list's date ranges.
  String get rangeToday;

  String get rangeYesterday;

  String get rangeDate;

  String get rangeDateRange;

  String get rangeCurrentMonth;

  String get rangeLastMonth;

  /// The date range picker's confirm.
  String get dateRangeDone;

  /// A day as the bills list shows it: `26 พ.ย.`, `Nov 26`.
  String shortDate(DateTime date);

  /// A month as the bills list shows it: `พ.ย.`, `Nov`.
  String shortMonth(DateTime date);
}
