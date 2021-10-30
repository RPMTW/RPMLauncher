import 'package:dart_discord_rpc/dart_discord_rpc.dart';

late bool isInit;
late DiscordRPC discordRPC;

class Datas {
  static void init() {
    isInit = false;
    discordRPC = DiscordRPC(
      applicationId: 903883530822627370,
    );
  }
}
