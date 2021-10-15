import 'package:flutter/widgets.dart';
import 'package:rpmlauncher/Route/RPMRouteSettings.dart';
import 'package:rpmlauncher/Utility/Extensions.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/main.dart';
import 'package:window_size/window_size.dart';

class RPMNavigatorObserver extends NavigatorObserver {
  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    try {
      ga.pageView(did(previousRoute!.settings), "Pop");
    } catch (e) {}
  }

  String did(RouteSettings settings) {
    RPMRouteSettings _routeSettings =
        RPMRouteSettings.fromRouteSettings(settings);
    String _key = "navigator.pages.${_routeSettings.routeName ?? "unknown"}";

    String _i18n = i18n.format(_key);
    setWindowTitle("RPMLauncher - $_i18n");

    String _english = i18n.format(_key,
        onError: "Unknown Page",
        lang: "en_us",
        handling: (String str) => str.toTitleCase());

        
    return _english;
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    try {
      ga.pageView(did(route.settings), "Push");
    } catch (e) {}
  }
}
