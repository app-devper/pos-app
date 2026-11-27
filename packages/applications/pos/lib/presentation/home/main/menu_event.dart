// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/widgets/app_shell.dart';

/// The shell's sections, in tab order.
enum MenuEvent {
  home,
  order,
  product,
  database,
}

const posBrand = 'Devper POS';

/// Whether only an admin may open [section]; the others are every role's.
bool isAdminOnly(MenuEvent section) =>
    section == MenuEvent.product || section == MenuEvent.database;

/// The shell's tabs. Cashiers only sell and review sales; the rest
/// is admin territory.
List<AppShellItem> posMenuItems({required bool isAdmin}) {
  return [
    const AppShellItem(
        id: 'home',
        label: 'ขายสินค้า',
        shortLabel: 'ขาย',
        icon: Icons.shopping_cart_outlined),
    const AppShellItem(
        id: 'order',
        label: 'รายการขาย',
        shortLabel: 'บิล',
        icon: Icons.receipt_long_outlined),
    if (isAdmin) ...[
      const AppShellItem(
          id: 'product', label: 'สินค้า', icon: Icons.inventory_2_outlined),
      const AppShellItem(id: 'database', label: 'จัดการ', icon: Icons.storage),
    ],
  ];
}

/// The section a tab [id] opens; an unknown one opens selling.
MenuEvent menuEventOf(String? id) {
  return switch (id) {
    'order' => MenuEvent.order,
    'product' => MenuEvent.product,
    'database' => MenuEvent.database,
    _ => MenuEvent.home,
  };
}
