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

  /// An error bar; with [action] it keeps its Clear and stays until cleared.
  void showErrorSnackBar(final Object? msg, {bool action = false}) {
    _show(
      text: "Error: $msg",
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
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// A success bar: it closes by itself after [duration], and its Clear
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
    // The messenger outlives the screen that shows the bar; Clear may be
    // pressed after that screen's context is gone.
    final messenger = ScaffoldMessenger.of(context);
    final snackBar = SnackBar(
      key: key,
      elevation: 8.0,
      content: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
      backgroundColor: color,
      duration: duration,
      persist: persist,
      action: action
          ? SnackBarAction(
              label: "Clear",
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
