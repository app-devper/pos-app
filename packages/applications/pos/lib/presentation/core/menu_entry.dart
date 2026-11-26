// Flutter imports:
import 'package:flutter/material.dart';

/// A command menu's item: its icon and its label, in [color] when given
/// (a destructive command's error red).
Widget menuEntry(IconData icon, String label, {Color? color}) => Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Flexible(child: Text(label, style: TextStyle(color: color))),
      ],
    );

/// A command menu's item showing [text] beside [icon], named [name] in full
/// for a screen reader, in [color] when given.
PopupMenuItem<T> commandMenuItem<T>({
  required T value,
  required IconData icon,
  required String text,
  required String name,
  Color? color,
}) =>
    _CommandMenuItem<T>(
      value: value,
      child: Semantics(
        label: name,
        excludeSemantics: true,
        child: menuEntry(icon, text, color: color),
      ),
    );

/// A [PopupMenuItem] read as a plain button. Flutter web writes a
/// menuitem's name as an aria-label only, which a find by text in the page
/// (Maestro's) cannot read; a button's name it writes as text.
class _CommandMenuItem<T> extends PopupMenuItem<T> {
  const _CommandMenuItem({super.value, required super.child});

  @override
  PopupMenuItemState<T, _CommandMenuItem<T>> createState() =>
      _CommandMenuItemState<T>();
}

class _CommandMenuItemState<T>
    extends PopupMenuItemState<T, _CommandMenuItem<T>> {
  @override
  Widget buildSemantics({required Widget child}) =>
      Semantics(enabled: widget.enabled, button: true, child: child);
}
