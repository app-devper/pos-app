// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/widgets/app_bar.dart';

// Project imports:
import 'package:pos/localizations/language/languages.dart';

/// The arrow back to the page underneath, named "ย้อนกลับ" (Languages.back).
/// [onPressed] defaults to popping the route, which is also what system Back
/// does, so a page's own PopScope steps out of its inner states first.
class PageBackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const PageBackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: Languages.of(context).back,
      onPressed: onPressed ?? () => Navigator.maybePop(context),
    );
  }
}

/// A pushed page's top bar: the back arrow at its start whenever there is a
/// page underneath to return to. The arrow's own padding sets the title off
/// from it, so the title takes no further spacing: on a 320 px phone a
/// title beside the arrow and three actions still fits.
AppBar buildPageBar(BuildContext context, String title,
    {List<Widget>? actions}) {
  final canGoBack = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
  return buildAppBar(
    title,
    actions: actions,
    leading: canGoBack ? const PageBackButton() : null,
    titleSpacing: canGoBack ? 0 : null,
  );
}
