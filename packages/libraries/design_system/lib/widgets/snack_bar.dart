// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:design_system/theme/color.dart';

class CustomSnackBar {
  final BuildContext context;
  final Key key;

  CustomSnackBar({required this.key, required this.context});

  /// How long a success bar stays before it closes by itself.
  static const successDuration = Duration(seconds: 4);
  static const _errorDuration = Duration(seconds: 3);

  /// The widest a bar is drawn; on a wide screen it floats in the middle,
  /// clear of a page's foot (labels at the start, figures at the end).
  static const maxWidth = 480.0;

  /// Flutter's margin around a floating bar on each side.
  static const _sideMargin = 15.0;

  /// The bar's width on a screen wider than [maxWidth] and its margins;
  /// null on a narrower one, where it spans the screen inside its margins.
  double? _width() {
    final screen = MediaQuery.sizeOf(context).width;
    return screen > maxWidth + 2 * _sideMargin ? maxWidth : null;
  }

  /// What an error bar says before its message, so an error is not told
  /// by the bar's colour alone.
  static const errorPrefix = "ข้อผิดพลาด: ";

  /// The bar's action that closes it.
  static const closeLabel = "ปิด";

  /// An error bar; with [action] it keeps its ปิด and stays until closed.
  void showErrorSnackBar(final Object? msg, {bool action = false}) {
    _show(
      text: "$errorPrefix$msg",
      duration: _errorDuration,
      color: Colors.red[400],
      action: action,
    );
  }

  void showLoadingSnackBar() {
    hideAll();
    final snackBar = SnackBar(
      key: key,
      elevation: 8.0,
      content: Row(
        children: const <Widget>[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: CustomColor.white,
            ),
          ),
          SizedBox(width: 12.0),
          Text("กำลังโหลด..."),
        ],
      ),
      // Green reads as "done"; loading is neutral. The duration is only a
      // safety net for a missed hideAll, so it need not run for a minute.
      backgroundColor: CustomColor.fontBlack,
      duration: const Duration(seconds: 20),
      behavior: SnackBarBehavior.floating,
      width: _width(),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// A success bar: it closes by itself after [duration], and its ปิด
  /// closes it sooner.
  void showSnackBar({
    required String text,
    Duration duration = successDuration,
    Color? color,
    bool action = true,
  }) {
    _show(
      text: text,
      duration: duration,
      color: color ?? Colors.green[400],
      action: action,
      persist: false,
    );
  }

  /// [persist] null keeps Flutter's rule: a bar with an action stays.
  void _show({
    required String text,
    required Duration duration,
    required Color? color,
    required bool action,
    bool? persist,
  }) {
    hideAll();
    // The messenger outlives the screen that shows the bar; ปิด may be
    // pressed after that screen's context is gone.
    final messenger = ScaffoldMessenger.of(context);
    final snackBar = SnackBar(
      key: key,
      elevation: 8.0,
      content: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
      backgroundColor: color,
      duration: duration,
      persist: persist,
      // Floating: the page under it keeps its full height, and a wide
      // screen's bar is narrow enough to leave the page's foot readable.
      behavior: SnackBarBehavior.floating,
      width: _width(),
      action: action
          ? SnackBarAction(
              label: closeLabel,
              textColor: Colors.black,
              onPressed: messenger.removeCurrentSnackBar,
            )
          : null,
    );
    messenger.showSnackBar(snackBar);
  }

  void hideAll() {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
  }
}
