import 'package:flutter/material.dart';
import 'package:rpmlauncher/Model/Instance.dart';

import 'MinecraftClient.dart';

class VanillaClient extends MinecraftClient {
  @override
  MinecraftClientHandler handler;

  VanillaClient._init({
    required this.handler,
  });

  static Future<VanillaClient> createClient(
      {required Map meta,
      required String versionID,
      required Instance instance,
      required StateSetter setState}) async {
    return await VanillaClient._init(
      handler: MinecraftClientHandler(
          meta: meta,
          versionID: versionID,
          instance: instance,
          setState: setState),
    )._Ready();
  }

  Future<VanillaClient> _Ready() async {
    await handler.Install();
    return this;
  }
}
