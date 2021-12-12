import 'package:flutter/material.dart';
import 'package:rpmlauncher/Launcher/MinecraftServer.dart';
import 'package:rpmlauncher/Model/Game/Instance.dart';
import 'package:rpmlauncher/Model/Game/MinecraftMeta.dart';

class VanillaServer extends MinecraftServer {
  @override
  MinecraftServerHandler handler;

  VanillaServer._init({
    required this.handler,
  });

  static Future<VanillaServer> createServer(
      {required MinecraftMeta meta,
      required String versionID,
      required Instance instance,
      required StateSetter setState}) async {
    return await VanillaServer._init(
      handler: MinecraftServerHandler(
          meta: meta,
          versionID: versionID,
          instance: instance,
          setState: setState),
    )._ready();
  }

  Future<VanillaServer> _ready() async {
    await handler.install();
    return this;
  }
}
