import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/theme/color.dart';
import 'package:design_system/widgets/app_shell.dart';
import 'package:um/presentation/constants.dart';

// Project imports:
import 'package:pos/container.dart';
import 'package:pos/localizations/language/languages.dart';
import 'package:pos/presentation/home/main/cart_page.dart';
import 'package:pos/presentation/home/main/home_database_page.dart';
import 'package:pos/presentation/home/main/home_view_model.dart';
import 'package:pos/presentation/home/main/menu_event.dart';
import 'package:pos/presentation/order/main/order_page.dart';
import 'package:pos/presentation/product/main/product_page.dart';

class HomePage extends StatefulWidget {
  /// The side-menu entry to open first (see [posMenuItems]); null opens
  /// selling.
  final String? section;

  const HomePage({super.key, this.section});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _viewNode = FocusNode();

  late HomeViewModel _viewModel;
  late StreamSubscription<void> _loggedOut;

  /// An admin-only section asked for by [HomePage.section], opened once
  /// the role is known to be an admin's; selling shows until then.
  late MenuEvent? _pendingSection = _requestedAdminSection();

  late MenuEvent _menuEvent =
      _pendingSection == null ? menuEventOf(widget.section) : MenuEvent.home;
  bool _isAdmin = false;

  /// Back within the current section (a product's detail to the list), or
  /// null when the section shows its first page.
  VoidCallback? _sectionBack;

  @override
  void initState() {
    super.initState();
    _viewModel = sl<HomeViewModel>();
    _viewModel.state.addListener(_onStateChanged);
    _loggedOut = _viewModel.loggedOut.listen(_onLoggedOut);
    _viewModel.prepareData();
  }

  MenuEvent? _requestedAdminSection() {
    final requested = menuEventOf(widget.section);
    return isAdminOnly(requested) ? requested : null;
  }

  /// A section the role may not see is never shown: it gives way to
  /// selling.
  void _onStateChanged() {
    setState(() {
      _isAdmin = _viewModel.state.value.isAdmin;
      final pending = _pendingSection;
      if (_isAdmin && pending != null) _menuEvent = pending;
      _pendingSection = null;
      if (!_isAdmin && isAdminOnly(_menuEvent)) _menuEvent = MenuEvent.home;
    });
  }

  void _onLoggedOut(void _) {
    if (mounted) Navigator.popAndPushNamed(context, routeLogin);
  }

  @override
  void dispose() {
    _viewModel.state.removeListener(_onStateChanged);
    _loggedOut.cancel();
    _viewModel.dispose();
    _viewNode.dispose();
    super.dispose();
  }

  String get _selectedId => _menuEvent.name;

  void _onSelect(String id) {
    setState(() {
      _pendingSection = null;
      _sectionBack = null;
      _menuEvent = menuEventOf(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(_viewNode),
      child: AppShell(
        brand: posBrand,
        title: '',
        // Each section draws its own header already.
        showTopBar: false,
        // Keep room for the product picker on shop tablets.
        initiallyExpanded: MediaQuery.sizeOf(context).width >= 1280,
        items: posMenuItems(isAdmin: _isAdmin),
        selectedId: _selectedId,
        onSelect: _onSelect,
        onBack: _onBack,
        sidebarFooter: _buildFooter,
        child: _buildPage(),
      ),
    );
  }

  /// Back steps out of the section's inner page first; from another
  /// section it goes to selling; from selling it leaves the app (null).
  VoidCallback? get _onBack {
    if (_sectionBack case final back?) return back;
    if (_menuEvent == MenuEvent.home) return null;
    return () => _onSelect('home');
  }

  void _onSectionBackChanged(VoidCallback? back) {
    if (mounted) setState(() => _sectionBack = back);
  }

  Widget _buildFooter(bool collapsed) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _footerAction(
          collapsed: collapsed,
          icon: Icons.account_circle_outlined,
          label: Languages.of(context).userInfoTitle,
          onTap: () => Navigator.pushNamed(context, routeUserInfo),
        ),
        _footerAction(
          collapsed: collapsed,
          icon: Icons.logout,
          label: 'ออกจากระบบ',
          color: CustomColor.error,
          onTap: _viewModel.logout,
        ),
      ],
    );
  }

  Widget _footerAction({
    required bool collapsed,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return AppSidebarAction(
      label: label,
      icon: icon,
      collapsed: collapsed,
      onTap: onTap,
      color: color,
    );
  }

  Widget _buildPage() {
    switch (_menuEvent) {
      case MenuEvent.home:
        return const CartPage();
      case MenuEvent.order:
        return const OrderPage();
      case MenuEvent.product:
        return ProductsPage(onBackChanged: _onSectionBackChanged);
      case MenuEvent.database:
        return const HomeDatabasePage();
    }
  }
}
