import 'package:flutter/widgets.dart';
import 'package:rpmlauncher/Route/RPMRouteSettings.dart';
import 'package:rpmlauncher/Utility/Data.dart';
import 'package:rpmlauncher/Utility/Extensions.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/LauncherInfo.dart';
import 'package:window_size/window_size.dart';

class RPMNavigatorObserver extends NavigatorObserver {
  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    try {
      did(previousRoute!.settings, "Pop");
    } catch (e) {}
  }

  void did(RouteSettings settings, String action) {
    RPMRouteSettings _routeSettings =
        RPMRouteSettings.fromRouteSettings(settings);
    String _key = "navigator.pages.${_routeSettings.routeName ?? "unknown"}";

    String _i18n = I18n.format(_key);

    String _english = I18n.format(_key,
        onError: "Unknown Page",
        lang: "en_us",
        handling: (String str) => str.toTitleCase());

    if (!kTestMode) {
      if (_english != "Unknown Page") {
        googleAnalytics.pageView(_english, action);
        setWindowTitle("RPMLauncher - $_i18n");
      } else {
        setWindowTitle("RPMLauncher");
      }
    }
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    try {
      did(route.settings, "Push");
    } catch (e) {}
  }
}
