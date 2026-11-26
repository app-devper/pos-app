// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_hooks/flutter_hooks.dart';

// Project imports:
import 'package:um/domain/entities/auth/system.dart';
import 'package:um/hooks/use_app_config.dart';
import 'package:um/hooks/use_continue_from_um.dart';
import 'package:um/hooks/use_keep_alive.dart';
import 'package:um/presentation/constants.dart';
import 'package:um/presentation/splash/launch_ticket.dart';

class SplashPage extends HookWidget {
  /// Given when the app was opened at one of its pages (a reload in the
  /// browser): the home route is built with them under that page, which
  /// stays, instead of replacing everything.
  final Object? homeArguments;

  const SplashPage({super.key, this.homeArguments});

  @override
  Widget build(BuildContext context) {
    final viewNode = useFocusNode();
    final config = useAppConfig();

    nextHome(System system) {
      if (system.systemCode != config.system) {
        Navigator.pushNamedAndRemoveUntil(context, routeError, (r) => false);
      } else if (!_putHomeUnderPage(context, config.home)) {
        Navigator.pushNamedAndRemoveUntil(context, config.home, (r) => false);
      }
    }

    nextLogin() {
      Navigator.pushNamedAndRemoveUntil(context, routeLogin, (r) => false);
    }

    buildBody() {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 6,
          color: Theme.of(context).colorScheme.primary,
          strokeCap: StrokeCap.round,
        ),
      );
    }

    final keepAlive = useKeepAlive();
    final continueFromUm = useContinueFromUm();
    final ticket = useMemoized(takeLaunchTicket);
    useEffect(() {
      var active = true;
      // Opened from UM: the ticket starts the session instead of a stored one.
      final start =
          ticket != null ? continueFromUm(ticket, config.system) : keepAlive();
      start.then((system) {
        if (active && context.mounted) nextHome(system);
      }, onError: (Object error, StackTrace stack) {
        if (active && context.mounted) nextLogin();
      });
      return () => active = false;
    }, [keepAlive, continueFromUm, ticket]);

    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(viewNode),
      child: Scaffold(
        body: buildBody(),
      ),
    );
  }

  /// When the app was opened at one of its pages (the splash is under it),
  /// replaces the splash with [home] built with [homeArguments], so the page
  /// stays on top with home to go back to. False when there is no such
  /// page, or nothing to build home with.
  bool _putHomeUnderPage(BuildContext context, String home) {
    final splash = ModalRoute.of(context);
    if (homeArguments == null || splash == null || splash.isCurrent) {
      return false;
    }
    final navigator = Navigator.of(context);
    final homeRoute = navigator.widget.onGenerateRoute
        ?.call(RouteSettings(name: home, arguments: homeArguments));
    if (homeRoute == null) return false;
    navigator.replace(oldRoute: splash, newRoute: homeRoute);
    return true;
  }
}
