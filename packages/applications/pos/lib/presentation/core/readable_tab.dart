// Flutter imports:
import 'package:flutter/material.dart';

/// A [Tab] of the detail pages, 36 px high, named [label].
///
/// Flutter web writes a tab's own label only as an aria-label, which
/// Maestro and some screen readers on the web do not read as text; the name
/// is a plain node of its own inside the tab.
class ReadableTab extends StatelessWidget {
  final String label;

  const ReadableTab(this.label, {super.key});

  @override
  Widget build(BuildContext context) => Tab(
        height: 36,
        child: Semantics(
          container: true,
          label: label,
          excludeSemantics: true,
          child: Text(label, maxLines: 1),
        ),
      );
}
