import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:um/presentation/constants.dart';

// Project imports:
import 'package:pos/container.dart';
import 'package:pos/presentation/constants.dart';
import 'package:pos/presentation/home/main/home_view_model.dart';
import 'package:pos/presentation/home/main/menu_event.dart';
import 'package:pos/presentation/home/main/pos_shell.dart';

/// A list opened from จัดการ, pushed over it. A wide screen keeps the
/// shell's side menu beside the list, with จัดการ chosen: the entries of
/// the signed-in role and the footer's user info and sign-out, as home
/// shows them. A narrow one shows the list alone, its bar's back arrow
/// leading back.
///
/// The list is built only once the role is known to be admin's: until then
/// the shell shows a progress indicator, and anyone else is sent home.
class InnerPageFrame extends StatefulWidget {
  final Widget child;

  const InnerPageFrame({super.key, required this.child});

  @override
  State<InnerPageFrame> createState() => _InnerPageFrameState();
}

class _InnerPageFrameState extends State<InnerPageFrame> {
  late final HomeViewModel _viewModel = sl<HomeViewModel>();
  late final StreamSubscription<void> _loggedOut;
  bool _isAdmin = false;
  bool _roleKnown = false;

  @override
  void initState() {
    super.initState();
    _viewModel.state.addListener(_onStateChanged);
    _loggedOut = _viewModel.loggedOut.listen(_onLoggedOut);
    _viewModel.prepareData();
  }

  void _onStateChanged() {
    final state = _viewModel.state.value;
    if (state.roleKnown && !state.isAdmin) {
      Navigator.pushNamedAndRemoveUntil(context, homeRoute, (_) => false);
      return;
    }
    setState(() {
      _isAdmin = state.isAdmin;
      _roleKnown = state.roleKnown;
    });
  }

  void _onLoggedOut(void _) {
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, routeLogin, (_) => false);
    }
  }

  @override
  void dispose() {
    _viewModel.state.removeListener(_onStateChanged);
    _loggedOut.cancel();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PosShell(
      isAdmin: _isAdmin,
      selectedId: MenuEvent.database.name,
      onSelect: _openSection,
      onLogout: _viewModel.logout,
      showDrawer: false,
      child: _roleKnown
          ? widget.child
          : const Center(child: CircularProgressIndicator()),
    );
  }

  /// Leaves the pages opened from จัดการ for the shell's section [id].
  void _openSection(String id) {
    Navigator.pushNamedAndRemoveUntil(context, homeRoute, (_) => false,
        arguments: id);
  }
}
