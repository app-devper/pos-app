// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:pos/localizations/language/languages.dart';

/// The scanner's app-bar buttons: the flash and the camera switch, each
/// named for a screen reader. Apart from the page, which opens the camera.
class ScannerActions extends StatelessWidget {
  final VoidCallback onToggleFlash;
  final VoidCallback onSwitchCamera;

  const ScannerActions({
    super.key,
    required this.onToggleFlash,
    required this.onSwitchCamera,
  });

  @override
  Widget build(BuildContext context) {
    final names = Languages.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: names.toggleFlash,
          onPressed: onToggleFlash,
          icon: const Icon(Icons.flash_on),
        ),
        IconButton(
          tooltip: names.switchCamera,
          onPressed: onSwitchCamera,
          icon: const Icon(Icons.flip_camera_ios),
        ),
      ],
    );
  }
}
