import 'package:flutter/material.dart';
import 'package:rpmlauncher/route/fade_route.dart';
import 'package:rpmlauncher/route/rpml_route_settings.dart';
import 'package:rpmlauncher/ui/pages/account_page.dart';
import 'package:rpmlauncher/ui/pages/home_page.dart';
import 'package:rpmlauncher/ui/screens/loading_screen.dart';
// import 'package:sentry_flutter/sentry_flutter.dart';

Route onGenerateRoute(RouteSettings _) {
  RPMLRouteSettings settings = RPMLRouteSettings.fromRouteSettings(_);

  if (settings.name == HomePage.route) {
    settings.routeName = 'home_page';

    return FadeRoute(
        settings: settings, builder: (context) => const HomePage());
  }

  if (settings.name == AccountScreen.route) {
    settings.routeName = 'account';
    return FadeRoute(
        settings: settings, builder: (context) => const AccountScreen());
  }

  if (settings.name == LoadingScreen.route) {
    settings.routeName = 'loading';
    return MaterialPageRoute(
        settings: settings,
        builder: (context) =>
            // const SentryScreenshotWidget(child: LoadingScreen())
            const LoadingScreen());
  }

  return FadeRoute(settings: settings, builder: (context) => const HomePage());
}
