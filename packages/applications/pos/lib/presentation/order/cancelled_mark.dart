// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/widgets/status_badge.dart';

/// What a cancelled bill or line is marked with.
const cancelledLabel = 'ยกเลิกแล้ว';

/// The mark on a cancelled bill row or bill line.
class CancelledBadge extends StatelessWidget {
  const CancelledBadge({super.key});

  @override
  Widget build(BuildContext context) => StatusBadge(
      label: cancelledLabel, color: Theme.of(context).colorScheme.error);
}

/// A cancelled bill's or line's amount is struck through: it is shown, and
/// counts in no total.
TextStyle? amountStyle({required bool cancelled}) =>
    cancelled ? const TextStyle(decoration: TextDecoration.lineThrough) : null;
