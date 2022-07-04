import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rpmlauncher/launcher/GameRepository.dart';
import 'package:rpmlauncher/launcher/MinecraftServer.dart';
import 'package:rpmlauncher/model/Game/instance.dart';
import 'package:rpmlauncher/model/Game/Libraries.dart';
import 'package:rpmlauncher/model/Game/MinecraftMeta.dart';
import 'package:rpmlauncher/model/Game/MinecraftSide.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/launcher/Arguments.dart';
import 'package:rpmlauncher/launcher/InstallingState.dart';
import 'package:rpmlauncher/mod/mod_loader.dart';
import 'package:rpmlauncher/model/IO/DownloadInfo.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:rpmlauncher/util/util.dart';

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

  void serverJar() {
    Map server = meta["downloads"]["server"];
    Libraries libraries = instance.config.libraries;
    libraries.add(Library(
        name: "net.minecraft:server:$versionID",
        downloads: LibraryDownloads(
            artifact: Artifact(
                url: server["url"],
                sha1: server["sha1"],
                size: server["size"],
                path: "net/minecraft/server/$versionID.jar"))));
    instance.config.libraries = libraries;

    installingState.downloadInfos.add(DownloadInfo(server["url"],
        savePath: join(GameRepository.getLibraryGlobalDir().path, "net",
            "minecraft", "server", "$versionID.jar"),
        sh1Hash: server["sha1"],
        hashCheck: true,
        description: I18n.format('version.list.downloading.main')));
  }

  Future<void> getArgs() async {
    File serverJar = File(join(GameRepository.getLibraryGlobalDir().path, "net",
        "minecraft", "server", "$versionID.jar"));

    File argsFile = GameRepository.getArgsFile(
        versionID, ModLoader.vanilla, MinecraftSide.server);
    await argsFile.create(recursive: true);
    Map argsMap = Arguments().getArgsString(versionID, meta);
    String? mainClass = Util.getJarMainClass(serverJar);
    argsMap['mainClass'] = mainClass ?? "net.minecraft.bundler.Main";
    await argsFile.writeAsString(json.encode(argsMap));
  }

  Future<VanillaServer> _ready() async {
    serverJar();
    await installingState.downloadInfos.downloadAll(
        onReceiveProgress: (progress) {
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
