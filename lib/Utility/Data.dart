import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_discord_rpc/dart_discord_rpc.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Function/Analytics.dart';
import 'package:rpmlauncher/Utility/Extensions.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/LauncherInfo.dart';
import 'package:rpmlauncher/Utility/RPMPath.dart';
import 'package:rpmlauncher/main.dart';

late bool isInit;
late DiscordRPC discordRPC;
late Analytics googleAnalytics;

class Data {
  static Future<void> init() async {
    isInit = false;
    argsInit();
    await RPMPath.init();
    await I18n.init();
    discordRPC = DiscordRPC(
        applicationId: 903883530822627370,
        libTempPath: Directory(join(dataHome.path, 'discord-rpc-library')));
    googleAnalytics = Analytics();
    await discordRPC.initialize();
  }

  static void argsInit() {
    ArgParser parser = ArgParser();
    parser.addOption('route', defaultsTo: '/', callback: (route) {
      LauncherInfo.route = route!;
    });

    parser.addOption('newWindow', defaultsTo: 'false', callback: (newWindow) {
      LauncherInfo.newWindow = newWindow!.toBool();
    });

    parser.addOption('isFlatpakApp', defaultsTo: 'false',
        callback: (isFlatpakApp) {
      LauncherInfo.isFlatpakApp = isFlatpakApp!.toBool();
    });

    try {
      parser.parse(launcherArgs);
    } catch (e) {}
  }
}
