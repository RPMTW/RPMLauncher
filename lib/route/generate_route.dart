import 'package:flutter/material.dart';
import 'package:rpmlauncher/route/PushTransitions.dart';
import 'package:rpmlauncher/route/RPMRouteSettings.dart';
import 'package:rpmlauncher/screen/account.dart';
import 'package:rpmlauncher/screen/home_page.dart';
import 'package:rpmlauncher/screen/settings.dart';
import 'package:rpmlauncher/util/data.dart';

Route onGenerateRoute(RouteSettings _) {
  RPMRouteSettings settings = RPMRouteSettings.fromRouteSettings(_);
  if (settings.name == HomePage.route) {
    settings.routeName = 'home_page';

    return PushTransitions(
        settings: settings, builder: (context) => const HomePage());
  }

  if (settings.name == SettingScreen.route) {
    settings.routeName = 'settings';
    return DialogRoute(
        settings: settings,
        builder: (context) => SettingScreen(),
        context: navigator.context);
  } else if (settings.name == AccountScreen.route) {
    settings.routeName = 'account';
    return PushTransitions(
        settings: settings, builder: (context) => AccountScreen());
  }

  return PushTransitions(
      settings: settings, builder: (context) => const HomePage());
}
