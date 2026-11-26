// Flutter imports:
import 'package:flutter/material.dart';

/// An option of a plain dropdown, [value] shown as [label].
///
/// Flutter web writes a menu item's own label only as an aria-label, which
/// Maestro and some screen readers on the web do not read as text; the name
/// is a plain node of its own inside the item (as design_system's
/// DropdownInput does).
DropdownMenuItem<T> readableOption<T>(T value, String label) =>
    DropdownMenuItem<T>(
      value: value,
      child: Semantics(
        container: true,
        label: label,
        excludeSemantics: true,
        child: Text(label),
      ),
    );
