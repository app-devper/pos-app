// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/widgets/buttons.dart';
import 'package:design_system/widgets/dropdown_input.dart';

// Project imports:
import 'package:pos/domain/model/supplier/supplier.dart';

/// The receipt's supplier: a labelled dropdown and a button that adds one.
class ReceiveSupplierPicker extends StatelessWidget {
  final List<Supplier> suppliers;
  final Supplier? value;
  final ValueChanged<Supplier?> onChanged;
  final VoidCallback onAdd;

  /// The add button's name.
  final String addLabel;

  const ReceiveSupplierPicker({
    super.key,
    required this.suppliers,
    required this.value,
    required this.onChanged,
    required this.onAdd,
    required this.addLabel,
  });

  @override
  Widget build(BuildContext context) {
    // No fixed height: a labelled dropdown is taller than 50 px in Sarabun.
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Flexible(
          child: DropdownInput<Supplier>(
            hintText: "ร้านขายสินค้า",
            options: suppliers,
            value: value,
            onChanged: onChanged,
            getLabel: (Supplier value) => value.name,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          height: 50,
          child: ButtonIconWidget(
            key: const Key("supplier"),
            onClicked: onAdd,
            tooltip: addLabel,
            icon: const Icon(Icons.add_business),
          ),
        ),
      ],
    );
  }
}
