import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter/material.dart';
import 'package:no_context_navigation/no_context_navigation.dart';
// ignore: implementation_imports
import 'package:provider/src/provider.dart';
import 'package:rpmlauncher/function/analytics.dart';
import 'package:rpmlauncher/function/counter.dart';
import 'package:rpmlauncher/handler/window_handler.dart';
import 'package:rpmlauncher/util/launcher_info.dart';
import 'package:rpmlauncher/util/logger.dart';
import 'package:rpmlauncher/util/launcher_path.dart';
import 'package:rpmtw_dart_common_library/rpmtw_dart_common_library.dart';

Analytics? googleAnalytics;
final NavigatorState navigator = NavigationService.navigationKey.currentState!;
final Logger logger = Logger.current;
List<String> launcherArgs = [];
Directory get dataHome {
  try {
    return navigator.context.read<Counter>().dataHome;
  } catch (e) {
    return LauncherPath.currentDataHome;
  }
}

class Data {
  static void argsInit() {
    ArgParser parser = ArgParser();
    parser.addOption('isFlatpakApp', defaultsTo: 'false',
        callback: (isFlatpakApp) {
      LauncherInfo.isFlatpakApp = isFlatpakApp!.toBool();
    });

    WindowHandler.parseArguments(launcherArgs);
    try {
      parser.parse(launcherArgs);
    } catch (e) {}
  }
}
