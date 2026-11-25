// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/theme/app_colors.dart';

/// The bar above the customer list: back, the title, and on a narrow layout
/// the add button (a wide layout has it in the pane beside the list).
class CustomerListHeader extends StatelessWidget {
  final String title;
  final String addLabel;
  final bool showAdd;
  final VoidCallback onBack;
  final VoidCallback onAdd;

  const CustomerListHeader({
    super.key,
    required this.title,
    required this.addLabel,
    required this.showAdd,
    required this.onBack,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onBack,
          child: Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              Icons.arrow_back_ios,
              color: AppColors.of(context).textSecondary,
              size: 16,
            ),
          ),
        ),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (showAdd) ...[
          InkWell(
            onTap: onAdd,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                Icons.add,
                semanticLabel: addLabel,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
          ),
        ] else ...[
          const SizedBox(width: 40)
        ]
      ],
    );
  }
}
