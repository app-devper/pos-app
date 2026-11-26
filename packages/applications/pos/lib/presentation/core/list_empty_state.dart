// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/widgets/empty_state.dart';

// Project imports:
import 'package:pos/localizations/language/languages.dart';

/// What a list with no rows shows: while a search is typed, that nothing
/// matches it (adding the first one would be the wrong offer); otherwise
/// that there is nothing yet, with the add of the first one.
class ListEmptyState extends StatelessWidget {
  final bool searched;
  final IconData icon;
  final String title;
  final String addLabel;
  final VoidCallback onAdd;

  const ListEmptyState({
    super.key,
    required this.searched,
    required this.icon,
    required this.title,
    required this.addLabel,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    if (searched) {
      return EmptyState(
        icon: Icons.search_off,
        title: Languages.of(context).noSearchResults,
      );
    }
    return EmptyState(
      icon: icon,
      title: title,
      actionLabel: addLabel,
      onAction: onAdd,
    );
  }
}
