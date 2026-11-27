// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:design_system/theme/app_colors.dart';
import 'package:design_system/theme/radius.dart';

class ButtonWidget extends StatelessWidget {
  final String text;
  final VoidCallback onClicked;

  const ButtonWidget({super.key, required this.text, required this.onClicked});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        minimumSize: const Size.fromHeight(50),
      ),
      onPressed: onClicked,
      child: FittedBox(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}

class ButtonIconWidget extends StatelessWidget {
  final Icon icon;
  final VoidCallback onClicked;

  /// What the button does: said by a screen reader, shown on hover.
  final String tooltip;

  const ButtonIconWidget({
    super.key,
    required this.icon,
    required this.onClicked,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    // The tooltip shows over the whole button; its name is given inside the
    // button, so a screen reader says it with the button.
    return Tooltip(
      message: tooltip,
      excludeFromSemantics: true,
      child: _button(context),
    );
  }

  Widget _button(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        minimumSize: const Size.fromHeight(50),
      ),
      onPressed: onClicked,
      child: Semantics(tooltip: tooltip, child: FittedBox(child: icon)),
    );
  }
}

class ButtonPrimary extends StatelessWidget {
  final String text;
  final VoidCallback onClicked;

  const ButtonPrimary({super.key, required this.text, required this.onClicked});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        minimumSize: const Size.fromHeight(40),
        splashFactory: NoSplash.splashFactory,
      ),
      onPressed: onClicked,
      child: FittedBox(
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}

class ButtonSecondary extends StatelessWidget {
  final String text;
  final VoidCallback onClicked;

  const ButtonSecondary({
    super.key,
    required this.text,
    required this.onClicked,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        splashFactory: NoSplash.splashFactory,
        minimumSize: const Size.fromHeight(40),
        side: BorderSide(color: colors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
      onPressed: onClicked,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: colors.textPrimary,
        ),
      ),
    );
  }
}
