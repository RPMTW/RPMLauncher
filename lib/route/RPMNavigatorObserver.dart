import 'package:flutter/widgets.dart';
import 'package:rpmlauncher/route/RPMRouteSettings.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:rpmlauncher/util/LauncherInfo.dart';
import 'package:rpmtw_dart_common_library/rpmtw_dart_common_library.dart';
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
    RPMRouteSettings routeSettings =
        RPMRouteSettings.fromRouteSettings(settings);
    String key = "navigator.pages.${routeSettings.routeName ?? "unknown"}";

    String i18n = I18n.format(key);

    String english = I18n.format(key,
        onError: "Unknown Page",
        lang: "en_us",
        handling: (String str) => str.toTitleCase());

    if (!kTestMode) {
      if (english != "Unknown Page") {
        googleAnalytics.pageView(english, action);
        setWindowTitle("RPMLauncher - $i18n");
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
