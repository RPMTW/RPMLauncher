import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Route/RPMRouteSettings.dart';
import 'package:rpmlauncher/Screen/Account.dart';
import 'package:rpmlauncher/Screen/Settings.dart';
import 'package:rpmlauncher/Utility/Datas.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Widget/OkClose.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';
import 'package:rpmlauncher/Screen/Edit.dart';
import 'package:rpmlauncher/Screen/Log.dart';
import 'package:rpmlauncher/main.dart';

Route onGenerateRoute(RouteSettings settings) {
  RPMRouteSettings _settings = RPMRouteSettings.fromRouteSettings(settings);
  if (_settings.name == HomePage.route) {
    _settings.routeName = "home_page";

    return PushTransitions(
        settings: _settings,
        builder: (context) {
          if (isInit) {
            return HomePage();
          } else {
            return FutureBuilder(
                future: Future.delayed(Duration(seconds: 2)),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    Connectivity().checkConnectivity().then((value) async {
                      if (value == ConnectivityResult.none) {
                        WidgetsBinding.instance!
                            .addPostFrameCallback((timeStamp) {
                          showDialog(
                              barrierDismissible: false,
                              context: context,
                              builder: (context) => AlertDialog(
                                    title: I18nText('gui.error.info'),
                                    content: I18nText("homepage.nonetwork"),
                                    actions: [
                                      OkClose(
                                        onOk: () {
                                          exit(0);
                                        },
                                      )
                                    ],
                                  ));
                        });
                      }
                    });

                    return HomePage();
                  } else {
                    return Material(
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
              instanceUUID: instanceUUID, newWindow: _settings.newWindow));
    } else if (_settings.name!.startsWith('/instance/$instanceUUID/launcher')) {
      _settings.routeName = "launcher_instance";
      return PushTransitions(
          settings: _settings,
          builder: (context) => LogScreen(
              instanceUUID: instanceUUID, newWindow: _settings.newWindow));
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

  return PushTransitions(settings: _settings, builder: (context) => HomePage());
}
