import 'dart:io';

import 'package:dart_discord_rpc/dart_discord_rpc.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Function/Analytics.dart';
import 'package:rpmlauncher/main.dart';

late bool isInit;
late DiscordRPC discordRPC;
late Analytics googleAnalytics;

class Datas {
  static Future<void> init() async {
    isInit = false;
    discordRPC = DiscordRPC(
        applicationId: 903883530822627370,
        libTempPath: Directory(join(dataHome.path, 'discord-rpc-library')));
    googleAnalytics = Analytics();
    await discordRPC.initialize();
  }
}
