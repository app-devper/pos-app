// Flutter imports:
import 'package:flutter/material.dart';
import 'package:pos/localizations/language/languages.dart';

/// On a narrow layout, opens the receipts menu (add a receipt, …), which a
/// wide layout shows beside the list.
class ReceiveMenuButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ReceiveMenuButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: Languages.of(context).receiveMenu,
      splashRadius: 20,
      onPressed: onPressed,
      icon: const Icon(Icons.menu),
      color: Theme.of(context).colorScheme.primary,
    );
  }
}
