import 'package:flutter/material.dart';
import 'package:rpmlauncher/route/PushTransitions.dart';
import 'package:rpmlauncher/route/RPMRouteSettings.dart';
import 'package:rpmlauncher/ui/screen/account.dart';
import 'package:rpmlauncher/ui/screen/collection_page.dart';
import 'package:rpmlauncher/ui/screen/loading_screen.dart';
import 'package:rpmlauncher/ui/screen/settings.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Route onGenerateRoute(RouteSettings _) {
  RPMRouteSettings settings = RPMRouteSettings.fromRouteSettings(_);

  if (settings.name == CollectionPage.route) {
    settings.routeName = 'collection_page';

    return PushTransitions(
        settings: settings, builder: (context) => const CollectionPage());
  }

  if (settings.name == SettingScreen.route) {
    settings.routeName = 'settings';
    return DialogRoute(
        settings: settings,
        builder: (context) => SettingScreen(),
        context: navigator.context);
  }

  if (settings.name == AccountScreen.route) {
    settings.routeName = 'account';
    return PushTransitions(
        settings: settings, builder: (context) => AccountScreen());
  }

  if (settings.name == LoadingScreen.route) {
    settings.routeName = 'loading';
    return MaterialPageRoute(
        settings: settings,
        builder: (context) =>
            const SentryScreenshotWidget(child: LoadingScreen()));
  }

  return PushTransitions(
      settings: settings, builder: (context) => const CollectionPage());
}
