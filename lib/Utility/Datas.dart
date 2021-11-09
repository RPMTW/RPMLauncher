import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_discord_rpc/dart_discord_rpc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Function/Analytics.dart';
import 'package:rpmlauncher/Utility/Extensions.dart';
import 'package:rpmlauncher/Utility/LauncherInfo.dart';
import 'package:rpmlauncher/main.dart';

late bool isInit;
late DiscordRPC discordRPC;
late Analytics googleAnalytics;

class Datas {
  static Future<void> init() async {
    isInit = false;
    argsInit();
    discordRPC = DiscordRPC(
        applicationId: 903883530822627370,
        libTempPath: Directory(join(dataHome.path, 'discord-rpc-library')));
    googleAnalytics = Analytics();
    initializeDateFormatting(Platform.localeName);
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
