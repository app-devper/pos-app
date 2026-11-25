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

  String get productMenu;

  String get addSupplier;

  String get chooseProduct;

  String removeCustomer(String name);

  String get receiveMenu;

  String get deleteReceive;

  String deleteReceiveLine(String name);

  String importedReceiveLine(String name);

  String get billReceipt;

  String get billReload;

  String get billReturns;

  String get billDelete;

  String deleteBillLine(String name);

  String billLineHistory(String name);

  String returnBillLine(String name);

  String oneLess(String name);

  String oneMore(String name);

  String changeQuantity(String name);

  String allowOversell(String name);

  String oversellAllowed(String name);

  String editLot(String lot);

  String lotOnHand(String lot);

  String adjustLot(String lot);
}
