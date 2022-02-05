import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rpmlauncher/Route/PushTransitions.dart';
import 'package:rpmlauncher/Route/RPMRouteSettings.dart';
import 'package:rpmlauncher/Screen/Account.dart';
import 'package:rpmlauncher/Screen/HomePage.dart';
import 'package:rpmlauncher/Screen/Settings.dart';
import 'package:rpmlauncher/Utility/Data.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:rpmlauncher/Widget/RPMTW-Design/OkClose.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';
import 'package:rpmlauncher/Screen/Edit.dart';
import 'package:rpmlauncher/Screen/Log.dart';

Route onGenerateRoute(RouteSettings settings) {
  RPMRouteSettings _settings = RPMRouteSettings.fromRouteSettings(settings);
  if (_settings.name == HomePage.route) {
    _settings.routeName = "home_page";

    return PushTransitions(
        settings: _settings,
        builder: (context) {
          if (isInit) {
            return const HomePage();
          } else {
            return FutureBuilder(future: Future.sync(() async {
              await Future.delayed(const Duration(milliseconds: 1500));
              return await Uttily.hasNetWork();
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

  Uri uri = Uri.parse(_settings.name!);
  if (_settings.name!.startsWith('/instance/') && uri.pathSegments.length > 2) {
    // "/instance/${instanceUUID}"
    String instanceUUID = uri.pathSegments[1];

    if (_settings.name!.startsWith('/instance/$instanceUUID/edit')) {
      _settings.routeName = "edit_instance";
      return PushTransitions(
          settings: _settings,
          builder: (context) => EditInstance(
              instanceUUID: instanceUUID));
    } else if (_settings.name!.startsWith('/instance/$instanceUUID/launcher')) {
      _settings.routeName = "launcher_instance";
      return PushTransitions(
          settings: _settings,
          builder: (context) => LogScreen(
              instanceUUID: instanceUUID));
    }
  }

  if (_settings.name == SettingScreen.route) {
    _settings.routeName = "settings";
    return PushTransitions(
        settings: _settings, builder: (context) => SettingScreen());
  } else if (_settings.name == AccountScreen.route) {
    _settings.routeName = "account";
    return PushTransitions(
        settings: _settings, builder: (context) => AccountScreen());
  }

  return PushTransitions(
      settings: _settings, builder: (context) => const HomePage());
}
