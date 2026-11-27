import 'package:design_system/theme/theme.dart';
import 'package:flutter/material.dart';

/// [child] on a page of the product's theme.
Widget themed(Widget child, {bool dark = false}) => MaterialApp(
      theme: dark ? CustomTheme.darkTheme : CustomTheme.mainTheme,
      home: Scaffold(body: Center(child: child)),
    );
