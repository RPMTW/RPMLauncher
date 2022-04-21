import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_discord_rpc/dart_discord_rpc.dart';
import 'package:flutter/material.dart';
import 'package:no_context_navigation/no_context_navigation.dart';
import 'package:path/path.dart';
// ignore: implementation_imports
import 'package:provider/src/provider.dart';
import 'package:rpmlauncher/function/analytics.dart';
import 'package:rpmlauncher/function/counter.dart';
import 'package:rpmlauncher/handler/window_handler.dart';
import 'package:rpmlauncher/util/Config.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:rpmlauncher/util/LauncherInfo.dart';
import 'package:rpmlauncher/util/Logger.dart';
import 'package:rpmlauncher/util/launcher_path.dart';
import 'package:rpmtw_dart_common_library/rpmtw_dart_common_library.dart';

late bool isInit;
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

const String microsoftClientID = "b7df55b4-300f-4409-8ea9-a172f844aa15";

class Data {
  static Future<void> init() async {
    isInit = false;
    argsInit();
    await LauncherPath.init();
    await I18n.init();
    if (!kTestMode) {
      await WindowHandler.init();

      if (WindowHandler.isMainWindow) {
        try {
          DiscordRPC discordRPC = DiscordRPC(
              applicationId: 903883530822627370,
              libTempPath:
                  Directory(join(dataHome.path, 'discord-rpc-library')));
          await discordRPC.initialize();

          if (Config.getValue('discord_rpc')) {
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
          }
        } catch (e) {
          logger.error(ErrorType.io, 'failed to initialize discord rpc\n$e');
        }
      }

      googleAnalytics = Analytics();
    }
  }

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
