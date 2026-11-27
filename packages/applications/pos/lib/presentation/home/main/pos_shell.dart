// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/widgets/app_shell.dart';
import 'package:design_system/widgets/app_shell_tabs.dart';
import 'package:um/presentation/constants.dart';

// Project imports:
import 'package:pos/localizations/language/languages.dart';
import 'package:pos/presentation/home/main/menu_event.dart';

/// The app's shell: the sections [isAdmin]'s role may open as tabs (along
/// the bottom of a phone when [showDrawer]) and the account button's user
/// info and sign-out, around [child]. Home and the lists opened from จัดการ
/// both build their navigation here, so the two never differ.
class PosShell extends StatelessWidget {
  static const String logoutLabel = 'ออกจากระบบ';

  final bool isAdmin;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback onLogout;
  final VoidCallback? onBack;

  /// False for a page pushed over home: a phone then shows it alone.
  final bool showDrawer;
  final Widget child;

  const PosShell({
    super.key,
    required this.isAdmin,
    required this.selectedId,
    required this.onSelect,
    required this.onLogout,
    this.onBack,
    this.showDrawer = true,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AppShell(
      brand: posBrand,
      title: '',
      // Each page draws its own header already.
      showTopBar: false,
      showDrawer: showDrawer,
      navigation: AppShellNavigation.tabs,
      items: posMenuItems(isAdmin: isAdmin),
      selectedId: selectedId,
      onSelect: onSelect,
      onBack: onBack,
      accountMenu: [
        AppShellAction(
          label: Languages.of(context).userInfoTitle,
          icon: Icons.account_circle_outlined,
          onTap: () => Navigator.pushNamed(context, routeUserInfo),
        ),
        AppShellAction(
          label: logoutLabel,
          icon: Icons.logout,
          destructive: true,
          onTap: onLogout,
        ),
      ],
      child: child,
    );
  }
}
