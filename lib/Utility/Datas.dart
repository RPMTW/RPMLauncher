import 'dart:io';

import 'package:dart_discord_rpc/dart_discord_rpc.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/main.dart';

late bool isInit;
late DiscordRPC discordRPC;

class Datas {
  static Future<void> init() async {
    isInit = false;
    discordRPC = DiscordRPC(
        applicationId: 903883530822627370,
        libTempPath: Directory(join(dataHome.path, 'discord-rpc-library')));
    await discordRPC.initialize();
  }
}
