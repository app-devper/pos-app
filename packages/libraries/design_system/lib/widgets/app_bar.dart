// Flutter imports:
import 'package:flutter/material.dart';

/// A page's top bar. [leading] replaces the arrow Material would imply on a
/// pushed page, so a host can name it in its own words. [titleSpacing] is
/// the room on each side of the title (Material's 16 when null).
AppBar buildAppBar(
  String title, {
  List<Widget>? actions,
  Widget? leading,
  double? titleSpacing,
}) {
  return AppBar(
    elevation: 0,
    centerTitle: false,
    leading: leading,
    titleSpacing: titleSpacing,
    title: Text(title, style: buildAppBarTextStyle()),
    actions: actions,
  );
}

TextStyle buildAppBarTextStyle() {
  return const TextStyle(fontSize: 18, fontWeight: FontWeight.w600);
}
