// Flutter imports:
import 'package:flutter/material.dart';

/// A page's top bar. [leading] replaces the arrow Material would imply on a
/// pushed page, so a host can name it in its own words.
AppBar buildAppBar(String title, {List<Widget>? actions, Widget? leading}) {
  return AppBar(
    elevation: 0,
    centerTitle: false,
    leading: leading,
    title: Text(title, style: buildAppBarTextStyle()),
    actions: actions,
  );
}

TextStyle buildAppBarTextStyle() {
  return const TextStyle(fontSize: 18, fontWeight: FontWeight.w600);
}
