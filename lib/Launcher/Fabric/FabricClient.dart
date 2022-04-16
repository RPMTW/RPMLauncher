import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rpmlauncher/Launcher/Fabric/FabricAPI.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Launcher/InstallingState.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Model/Game/MinecraftMeta.dart';
import 'package:rpmlauncher/Model/Game/MinecraftSide.dart';
import 'package:rpmlauncher/Model/IO/DownloadInfo.dart';
import 'package:rpmlauncher/Model/Game/Instance.dart';
import 'package:rpmlauncher/Model/Game/Libraries.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/RPMHttpClient.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:path/path.dart';

import '../MinecraftClient.dart';

class FabricClient extends MinecraftClient {
  Map fabricMeta;
  String loaderVersion;

  @override
  MinecraftClientHandler handler;

  FabricClient._init({
    required this.fabricMeta,
    required this.handler,
    required this.loaderVersion,
  });

  static Future<FabricClient> createClient(
      {required MinecraftMeta meta,
      required String versionID,
      required StateSetter setState,
      required String loaderVersion,
      required Instance instance}) async {
    setState(() {
      installingState.nowEvent =
          I18n.format('version.list.downloading.fabric.info');
    });
    return await FabricClient._init(
            handler: MinecraftClientHandler(
                versionID: versionID,
                meta: meta,
                setState: setState,
                instance: instance),
            fabricMeta:
                await FabricAPI.getProfileJson(versionID, loaderVersion),
            loaderVersion: loaderVersion)
        ._ready();
  }

  Future<FabricClient> getFabricLibrary() async {
    /*    PackageName example: (abc.ab.com)
    name: PackageName:JarName:JarVersion
    url: https://maven.fabricmc.net
     */

    await Future.forEach(fabricMeta["libraries"].cast<Map>(),
        (Map libMap) async {
      Map result = Uttily.parseLibMaven(libMap);
      Libraries lib = instance.config.libraries;

      lib.add(Library(
          name: libMap["name"],
          downloads: LibraryDownloads(
              artifact: Artifact(
            url: result["Url"],
            sha1: (await RPMHttpClient().get(result["Url"] + ".sha1"))
                .data
                .toString(),
            path: result["Path"],
          ))));

      instance.config.libraries = lib;

      List<String> paths = [GameRepository.getLibraryGlobalDir().path];
      paths.addAll(split(result["Path"]));

      installingState.downloadInfos.add(DownloadInfo(result["Url"],
          savePath: join(
            joinAll(paths),
          ),
          description: I18n.format('version.list.downloading.fabric.library')));
    });
    return this;
  }

  Future getFabricArgs() async {
    File vanillaArgsFile = GameRepository.getArgsFile(
        versionID, ModLoader.vanilla, MinecraftSide.client);
    File fabricArgsFile = GameRepository.getArgsFile(
        versionID, ModLoader.fabric, MinecraftSide.client,
        loaderVersion: loaderVersion);
    Map argsObject = await json.decode(vanillaArgsFile.readAsStringSync());
    argsObject["mainClass"] = fabricMeta["mainClass"];
    fabricArgsFile
      ..createSync(recursive: true)
      ..writeAsStringSync(json.encode(argsObject));
  }

  Future<FabricClient> _ready() async {
    await handler.install();
    setState(() {
      installingState.nowEvent =
          I18n.format('version.list.downloading.fabric.args');
    });
    await getFabricArgs();
    await getFabricLibrary();
    await installingState.downloadInfos.downloadAll(
        onReceiveProgress: (progress) {
      setState(() {});
    });
    return this;
  }
}
