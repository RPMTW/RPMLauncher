import 'package:flutter/material.dart';
import 'package:rpmlauncher/route/PushTransitions.dart';
import 'package:rpmlauncher/route/RPMRouteSettings.dart';
import 'package:rpmlauncher/screen/Account.dart';
import 'package:rpmlauncher/screen/home_page.dart';
import 'package:rpmlauncher/screen/Settings.dart';
import 'package:rpmlauncher/screen/Edit.dart';
import 'package:rpmlauncher/screen/Log.dart';

Route onGenerateRoute(RouteSettings _) {
  RPMRouteSettings settings = RPMRouteSettings.fromRouteSettings(_);
  if (settings.name == HomePage.route) {
    settings.routeName = "home_page";

    return PushTransitions(
        settings: settings, builder: (context) => const HomePage());
  }

  Uri uri = Uri.parse(settings.name!);
  if (settings.name!.startsWith('/instance/') && uri.pathSegments.length > 2) {
    // "/instance/${instanceUUID}"
    String instanceUUID = uri.pathSegments[1];

    if (settings.name!.startsWith('/instance/$instanceUUID/edit')) {
      settings.routeName = "edit_instance";
      return PushTransitions(
          settings: settings,
          builder: (context) => EditInstance(instanceUUID: instanceUUID));
    } else if (settings.name!.startsWith('/instance/$instanceUUID/launcher')) {
      settings.routeName = "launcher_instance";
      return PushTransitions(
          settings: settings,
          builder: (context) => LogScreen(instanceUUID: instanceUUID));
    }
  }

  if (settings.name == SettingScreen.route) {
    settings.routeName = "settings";
    return PushTransitions(
        settings: settings, builder: (context) => SettingScreen());
  } else if (settings.name == AccountScreen.route) {
    settings.routeName = "account";
    return PushTransitions(
        settings: settings, builder: (context) => AccountScreen());
  }

  return PushTransitions(
      settings: settings, builder: (context) => const HomePage());
}
