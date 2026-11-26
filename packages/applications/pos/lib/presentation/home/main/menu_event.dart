// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/widgets/app_shell.dart';

/// The shell's sections, in side-menu order.
enum MenuEvent {
  home,
  order,
  product,
  database,
}

const posBrand = 'Devper POS';

/// The side menu's entries. Cashiers only sell and review sales; the rest
/// is admin territory.
List<AppShellItem> posMenuItems({required bool isAdmin}) {
  return [
    const AppShellItem(
        id: 'home', label: 'ขายสินค้า', icon: Icons.shopping_cart_outlined),
    const AppShellItem(
        id: 'order', label: 'รายการขาย', icon: Icons.receipt_long_outlined),
    if (isAdmin) ...[
      const AppShellItem(
          id: 'product', label: 'สินค้า', icon: Icons.inventory_2_outlined),
      const AppShellItem(id: 'database', label: 'จัดการ', icon: Icons.storage),
    ],
  ];
}

/// The section a side-menu entry [id] opens; an unknown one opens selling.
MenuEvent menuEventOf(String? id) {
  return switch (id) {
    'order' => MenuEvent.order,
    'product' => MenuEvent.product,
    'database' => MenuEvent.database,
    _ => MenuEvent.home,
  };
}
