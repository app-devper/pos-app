import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:um/presentation/constants.dart';

// Project imports:
import 'package:pos/container.dart';
import 'package:pos/presentation/core/admin_only.dart';
import 'package:pos/presentation/constants.dart';
import 'package:pos/presentation/home/main/home_view_model.dart';
import 'package:pos/presentation/home/main/menu_event.dart';
import 'package:pos/presentation/home/main/pos_shell.dart';

/// A list opened from จัดการ, pushed over it. A wide screen keeps the
/// shell's tabs above the list, with จัดการ chosen: an admin's tabs and
/// the account button's user info and sign-out, as home shows them. A
/// narrow one shows the list alone, its bar's back arrow leading back.
///
/// Only an admin sees it ([AdminOnly]): until the role is known a progress
/// indicator shows, and anyone else is sent home.
class InnerPageFrame extends StatelessWidget {
  final Widget child;

  const InnerPageFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) =>
      AdminOnly(child: _AdminShell(child: child));
}

/// The shell around an admin's list, with its sign-out.
class _AdminShell extends StatefulWidget {
  final Widget child;

  const _AdminShell({required this.child});

  @override
  State<_AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<_AdminShell> {
  late final HomeViewModel _viewModel = sl<HomeViewModel>();
  late final StreamSubscription<void> _loggedOut;

  @override
  void initState() {
    super.initState();
    _loggedOut = _viewModel.loggedOut.listen(_onLoggedOut);
  }

  void _onLoggedOut(void _) {
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, routeLogin, (_) => false);
    }
  }

  @override
  void dispose() {
    _loggedOut.cancel();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PosShell(
      isAdmin: true,
      selectedId: MenuEvent.database.name,
      onSelect: _openSection,
      onLogout: _viewModel.logout,
      showDrawer: false,
      child: widget.child,
    );
  }

  /// Leaves the pages opened from จัดการ for the shell's section [id].
  void _openSection(String id) {
    Navigator.pushNamedAndRemoveUntil(context, homeRoute, (_) => false,
        arguments: id);
  }
}
