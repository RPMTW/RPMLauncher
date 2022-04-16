import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_discord_rpc/dart_discord_rpc.dart';
import 'package:flutter/material.dart';
import 'package:no_context_navigation/no_context_navigation.dart';
import 'package:path/path.dart';
// ignore: implementation_imports
import 'package:provider/src/provider.dart';
import 'package:rpmlauncher/Function/Analytics.dart';
import 'package:rpmlauncher/Function/Counter.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/LauncherInfo.dart';
import 'package:rpmlauncher/Utility/Logger.dart';
import 'package:rpmlauncher/Utility/RPMPath.dart';
import 'package:rpmtw_dart_common_library/rpmtw_dart_common_library.dart';

late bool isInit;
late Analytics googleAnalytics;
final NavigatorState navigator = NavigationService.navigationKey.currentState!;
final Logger logger = Logger.currentLogger;
List<String> launcherArgs = [];
Directory get dataHome {
  try {
    return navigator.context.read<Counter>().dataHome;
  } catch (e) {
    return RPMPath.currentDataHome;
  }
}

const String microsoftClientID = "b7df55b4-300f-4409-8ea9-a172f844aa15";

class Data {
  static Future<void> init() async {
    isInit = false;
    argsInit();
    await RPMPath.init();
    await I18n.init();

    if (!LauncherInfo.multiWindow) {
      DiscordRPC discordRPC = DiscordRPC(
          applicationId: 903883530822627370,
          libTempPath: Directory(join(dataHome.path, 'discord-rpc-library')));
      await discordRPC.initialize();

      if (Config.getValue('discord_rpc')) {
        try {
          discordRPC.handler.start(autoRegister: true);
          discordRPC.handler.updatePresence(
            DiscordPresence(
                state: 'https://www.rpmtw.com/RWL',
                details: I18n.format('rpmlauncher.discord_rpc.details'),
                startTimeStamp: LauncherInfo.startTime.millisecondsSinceEpoch,
                largeImageKey: 'rwl_logo',
                largeImageText:
                    I18n.format('rpmlauncher.discord_rpc.largeImageText'),
                smallImageKey: 'minecraft',
                smallImageText:
                    '${LauncherInfo.getFullVersion()} - ${LauncherInfo.getVersionType().name}'),
          );
        } catch (e) {}
      }
    }

    googleAnalytics = Analytics();
  }

  static void argsInit() {
    ArgParser parser = ArgParser();
    parser.addOption('isFlatpakApp', defaultsTo: 'false',
        callback: (isFlatpakApp) {
      LauncherInfo.isFlatpakApp = isFlatpakApp!.toBool();
    });

    int windowID = 0;
    Map arguments = {};

    int index = launcherArgs.indexOf("multi_window");
    if (index != -1) {
      arguments = json.decode(launcherArgs[index + 2]);
      windowID = int.parse(launcherArgs[index + 1]);
    }
    String? route = arguments['route'];
    LauncherInfo.route = route ?? "/";
    LauncherInfo.windowID = windowID;

    try {
      parser.parse(launcherArgs);
    } catch (e) {}
  }
}
