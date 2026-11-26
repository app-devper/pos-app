// Flutter imports:
import 'package:flutter/foundation.dart';

/// What this screen renders: whether the signed-in user is an admin, which
/// decides what the menu offers.
///
/// It used to be nullable and cleared after reading, as though it were an
/// event. It is a predicate the screen draws from, so it stays, and defaults
/// to the safer answer until the role comes back.
///
/// Logging out is the event, and it is on the view model's channel.
@immutable
class HomeState {
  final bool isAdmin;

  /// Whether the role has come back; until then [isAdmin] is only the safer
  /// default.
  final bool roleKnown;

  const HomeState({this.isAdmin = false, this.roleKnown = false});

  HomeState copyWith({bool? isAdmin, bool? roleKnown}) {
    return HomeState(
      isAdmin: isAdmin ?? this.isAdmin,
      roleKnown: roleKnown ?? this.roleKnown,
    );
  }
}
