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
