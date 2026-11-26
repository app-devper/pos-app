// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:pos/localizations/language/languages.dart';

/// On a narrow layout, opens a list's commands (add, export, …), which a
/// wide layout shows beside the list. A vertical ellipsis, so it is never
/// taken for the main menu.
class MoreCommandsButton extends StatelessWidget {
  final VoidCallback onPressed;

  const MoreCommandsButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: Languages.of(context).moreCommands,
      splashRadius: 20,
      onPressed: onPressed,
      icon: const Icon(Icons.more_vert),
      color: Theme.of(context).colorScheme.primary,
    );
  }
}
