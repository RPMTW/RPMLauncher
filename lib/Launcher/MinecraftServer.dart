import 'package:flutter/material.dart';

import 'package:rpmlauncher/Model/Game/Instance.dart';
import 'package:rpmlauncher/Model/Game/MinecraftMeta.dart';

abstract class MinecraftServer {
  MinecraftMeta get meta => handler.meta;

  MinecraftServerHandler get handler;

  StateSetter get setState => handler.setState;

  Instance get instance => handler.instance;

  String get versionID => handler.versionID;
}

class MinecraftServerHandler {
  final MinecraftMeta meta;
  final String versionID;
  final StateSetter setState;
  final Instance instance;

  MinecraftServerHandler(
      {required this.meta,
      required this.versionID,
      required this.setState,
      required this.instance});
}
