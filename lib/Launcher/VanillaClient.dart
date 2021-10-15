// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'package:flutter/material.dart';
import 'package:rpmlauncher/Model/Instance.dart';

import 'MinecraftClient.dart';

class VanillaClient extends MinecraftClient {
  
  MinecraftClientHandler handler;

  VanillaClient._init({
    required this.handler,
  });

  static Future<VanillaClient> createClient(
      {required Map Meta,
      required String VersionID,
      required Instance instance,
      required StateSetter setState}) async {
    return await VanillaClient._init(
      handler: MinecraftClientHandler(
          meta: Meta,
          versionID: VersionID,
          instance: instance,
          setState: setState),
    )._Ready();
  }

  Future<VanillaClient> _Ready() async {
    await handler.Install();
    return this;
  }
}
