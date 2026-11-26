// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/theme/color.dart';
import 'package:design_system/widgets/app_shell.dart';
import 'package:um/presentation/constants.dart';

// Project imports:
import 'package:pos/localizations/language/languages.dart';
import 'package:pos/presentation/home/main/menu_event.dart';

/// The app's shell: the side menu (a drawer on a phone when [showDrawer])
/// with the entries [isAdmin]'s role may open and the footer's user info
/// and sign-out, beside [child]. Home and the lists opened from จัดการ
/// both build their side menu here, so the two never differ.
class PosShell extends StatelessWidget {
  final bool isAdmin;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback onLogout;
  final VoidCallback? onBack;
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
      // Keep room for the product picker on shop tablets.
      initiallyExpanded: MediaQuery.sizeOf(context).width >= 1280,
      items: posMenuItems(isAdmin: isAdmin),
      selectedId: selectedId,
      onSelect: onSelect,
      onBack: onBack,
      sidebarFooter: (collapsed) => _buildFooter(context, collapsed),
      child: child,
    );
  }

  Widget _buildFooter(BuildContext context, bool collapsed) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSidebarAction(
          label: Languages.of(context).userInfoTitle,
          icon: Icons.account_circle_outlined,
          collapsed: collapsed,
          onTap: () => Navigator.pushNamed(context, routeUserInfo),
        ),
        AppSidebarAction(
          label: 'ออกจากระบบ',
          icon: Icons.logout,
          collapsed: collapsed,
          onTap: onLogout,
          color: CustomColor.error,
        ),
      ],
    );
  }
}
