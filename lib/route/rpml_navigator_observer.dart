import 'package:flutter/widgets.dart';
import 'package:rpmlauncher/i18n/launcher_language.dart';
import 'package:rpmlauncher/route/rpml_route_settings.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/util/launcher_info.dart';
import 'package:rpmtw_dart_common_library/rpmtw_dart_common_library.dart';
import 'package:window_size/window_size.dart';

class RPMLNavigatorObserver extends NavigatorObserver {
  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    try {
      did(previousRoute!.settings, "Pop");
    } catch (_) {}
  }

  void did(RouteSettings settings, String action) {
    RPMLRouteSettings routeSettings =
        RPMLRouteSettings.fromRouteSettings(settings);
    String key = "navigator.pages.${routeSettings.routeName ?? "unknown"}";

    String i18n = I18n.format(key);

    String englishTitle = I18n.format(
      key,
      errorMessage: "Unknown Page",
      language: LauncherLanguage.americanEnglish,
    ).toTitleCase();

    if (!kTestMode) {
      if (englishTitle != "Unknown Page") {
        googleAnalytics?.pageView(englishTitle, action);
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
    } catch (_) {}
  }
}
