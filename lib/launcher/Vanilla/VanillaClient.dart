import 'package:flutter/material.dart';
import 'package:rpmlauncher/model/Game/instance.dart';
import 'package:rpmlauncher/model/Game/MinecraftMeta.dart';

import '../MinecraftClient.dart';

class VanillaClient extends MinecraftClient {
  @override
  MinecraftClientHandler handler;

  VanillaClient._init({
    required this.handler,
  });

  static Future<VanillaClient> createClient(
      {required MinecraftMeta meta,
      required String versionID,
      required Instance instance,
      required StateSetter setState}) async {
    return await VanillaClient._init(
      handler: MinecraftClientHandler(
          meta: meta,
          versionID: versionID,
          instance: instance,
          setState: setState),
    )._ready();
  }

  Future<VanillaClient> _ready() async {
    await handler.install();
    return this;
  }
}
