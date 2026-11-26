// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:pos/container.dart';
import 'package:pos/presentation/constants.dart';
import 'package:pos/presentation/home/main/home_view_model.dart';

/// A page only an admin may see, however it was opened: from the app's own
/// menus or from an address typed into the browser.
///
/// Until the signed-in role is known it shows a progress indicator on a
/// page of its own (never [child]); an admin then gets [child], anyone else
/// is sent home, to selling.
class AdminOnly extends StatefulWidget {
  final Widget child;

  const AdminOnly({super.key, required this.child});

  @override
  State<AdminOnly> createState() => _AdminOnlyState();
}

class _AdminOnlyState extends State<AdminOnly> {
  late final HomeViewModel _viewModel = sl<HomeViewModel>();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _viewModel.state.addListener(_onStateChanged);
    _viewModel.prepareData();
  }

  void _onStateChanged() {
    final state = _viewModel.state.value;
    if (!state.roleKnown || !mounted) return;
    if (!state.isAdmin) {
      Navigator.pushNamedAndRemoveUntil(context, homeRoute, (_) => false);
      return;
    }
    setState(() => _isAdmin = true);
  }

  @override
  void dispose() {
    _viewModel.state.removeListener(_onStateChanged);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdmin) return widget.child;
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
