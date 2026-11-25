// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/theme/app_colors.dart';
import 'package:design_system/widgets/search_decoration.dart';

/// The bar above the customer list: back, the title, on a narrow layout the
/// add button (a wide layout has it in the pane beside the list), and the
/// search field.
/// The hint of the customer list's search field.
const customerSearchHint = 'ค้นหาลูกค้า...';

class CustomerListHeader extends StatelessWidget {
  final String title;
  final String backLabel;
  final String addLabel;
  final bool showAdd;
  final VoidCallback onBack;
  final VoidCallback onAdd;
  final ValueChanged<String> onSearch;

  /// Holds the search text, so a list built afresh can show what was typed.
  final TextEditingController? searchController;

  const CustomerListHeader({
    super.key,
    required this.title,
    required this.backLabel,
    required this.addLabel,
    required this.showAdd,
    required this.onBack,
    required this.onAdd,
    required this.onSearch,
    this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBar(context),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: TextField(
            controller: searchController,
            decoration:
                buildSearchDecoration(context, hintText: customerSearchHint),
            onChanged: onSearch,
          ),
        ),
      ],
    );
  }

  Widget _buildBar(BuildContext context) {
    return Row(
      children: [
        Semantics(
          button: true,
          label: backLabel,
          child: InkWell(
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
