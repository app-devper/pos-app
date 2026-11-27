// Flutter imports:
import 'package:flutter/material.dart';

/// The stock adjustment's choice: add stock (เพิ่มสต็อก) or take it
/// (ลดสต็อก). Each side carries its text as its semantics identifier too:
/// the web writes a toggle's name only as an aria-label, never as text, so
/// an end-to-end test on the web finds it by that.
class StockDirectionToggle extends StatelessWidget {
  final bool isIncrease;
  final ValueChanged<bool> onChanged;

  const StockDirectionToggle({
    super.key,
    required this.isIncrease,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      isSelected: [isIncrease, !isIncrease],
      onPressed: (index) => onChanged(index == 0),
      borderRadius: BorderRadius.circular(8.0),
      children: const [_Side('เพิ่มสต็อก'), _Side('ลดสต็อก')],
    );
  }
}

class _Side extends StatelessWidget {
  final String label;

  const _Side(this.label);

  @override
  Widget build(BuildContext context) => Semantics(
        identifier: label,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(label),
        ),
      );
}
