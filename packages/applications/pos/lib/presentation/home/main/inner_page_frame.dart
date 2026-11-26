// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/widgets/app_shell.dart';

// Project imports:
import 'package:pos/presentation/constants.dart';
import 'package:pos/presentation/home/main/menu_event.dart';

/// A page opened from จัดการ, pushed over it. A wide screen keeps the side
/// menu beside the page, with จัดการ chosen; a narrow one shows the page
/// alone, its bar's back arrow leading back. The pages are admin-only, so
/// the menu is the admin's.
class InnerPageFrame extends StatelessWidget {
  final Widget child;

  const InnerPageFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      brand: posBrand,
      title: '',
      showTopBar: false,
      showDrawer: false,
      initiallyExpanded: MediaQuery.sizeOf(context).width >= 1280,
      items: posMenuItems(isAdmin: true),
      selectedId: MenuEvent.database.name,
      onSelect: (id) => _openSection(context, id),
      child: child,
    );
  }

  /// Leaves the pages opened from จัดการ for the shell's section [id].
  void _openSection(BuildContext context, String id) {
    Navigator.pushNamedAndRemoveUntil(context, homeRoute, (_) => false,
        arguments: id);
  }
}
