import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rpmlauncher/route/PushTransitions.dart';
import 'package:rpmlauncher/route/RPMRouteSettings.dart';
import 'package:rpmlauncher/screen/Account.dart';
import 'package:rpmlauncher/screen/HomePage.dart';
import 'package:rpmlauncher/screen/Settings.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:rpmlauncher/util/util.dart';
import 'package:rpmlauncher/widget/rpmtw_design/OkClose.dart';
import 'package:rpmlauncher/widget/RWLLoading.dart';
import 'package:rpmlauncher/screen/Edit.dart';
import 'package:rpmlauncher/screen/Log.dart';

Route onGenerateRoute(RouteSettings _) {
  RPMRouteSettings settings = RPMRouteSettings.fromRouteSettings(_);
  if (settings.name == HomePage.route) {
    settings.routeName = "home_page";

    return PushTransitions(
        settings: settings,
        builder: (context) {
          if (isInit) {
            return const HomePage();
          } else {
            return FutureBuilder(future: Future.sync(() async {
              await Future.delayed(const Duration(milliseconds: 1500));
              return await Util.hasNetWork();
            }), builder: (context, snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data == true) {
                  return const HomePage();
                } else {
                  return AlertDialog(
                    title: I18nText('gui.error.info'),
                    content: I18nText("homepage.nonetwork"),
                    actions: [
                      OkClose(
                        onOk: () {
                          exit(0);
                        },
                      )
                    ],
                  );
                }
              } else {
                return const Material(
                  child: RWLLoading(animations: true, logo: true),
                );
              }
            });
          }
        });
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
