import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Launcher/Arguments.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Launcher/InstallingState.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Model/Game/Instance.dart';
import 'package:rpmlauncher/Model/Game/Libraries.dart';
import 'package:rpmlauncher/Model/Game/MinecraftMeta.dart';
import 'package:rpmlauncher/Model/Game/MinecraftSide.dart';
import 'package:rpmlauncher/Model/IO/DownloadInfo.dart';
import 'package:rpmlauncher/Utility/I18n.dart';

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

  void serverJar() {
    Map server = meta["downloads"]["server"];
    Libraries _libraries = instance.config.libraries;
    _libraries.add(Library(
        name: "net.minecraft:server:$versionID",
        downloads: LibraryDownloads(
            artifact: Artifact(
                url: server["url"],
                sha1: server["sha1"],
                size: server["size"],
                path: "net/minecraft/server/$versionID.jar"))));
    instance.config.libraries = _libraries;

    installingState.downloadInfos.add(DownloadInfo(server["url"],
        savePath: join(GameRepository.getLibraryGlobalDir().path, "net",
            "minecraft", "server", "$versionID.jar"),
        sh1Hash: server["sha1"],
        hashCheck: true,
        description: I18n.format('version.list.downloading.main')));
  }

  Future<void> getArgs() async {
    File argsFile = GameRepository.getArgsFile(
        versionID, ModLoader.vanilla, MinecraftSide.server);
    await argsFile.create(recursive: true);
    Map argsMap = Arguments().getArgsString(versionID, meta);
    argsMap['mainClass'] = "net.minecraft.bundler.Main";
    await argsFile.writeAsString(json.encode(argsMap));
  }

  Future<MinecraftServerHandler> install() async {
    serverJar();
    await installingState.downloadInfos.downloadAll(
        onReceiveProgress: (_progress) {
      try {
        setState(() {});
      } catch (e) {}
    });
    setState(() {
      installingState.nowEvent = I18n.format('version.list.downloading.args');
    });
    await getArgs();

    return this;
  }
}
