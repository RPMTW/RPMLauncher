import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rpmlauncher/Launcher/Fabric/FabricAPI.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Model/Libraries.dart';
import 'package:rpmlauncher/Model/DownloadInfo.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Model/Instance.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
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
      {required Map meta,
      required String versionID,
      required StateSetter setState,
      required String loaderVersion,
      required Instance instance}) async {
    setState(() {
      nowEvent = "正在解析Fabric數據資料";
    });
    String bodyString =
        await FabricAPI().getProfileJson(versionID, loaderVersion);
    Map<String, dynamic> body = await json.decode(bodyString);
    return await FabricClient._init(
            handler: MinecraftClientHandler(
                versionID: versionID,
                meta: meta,
                setState: setState,
                instance: instance),
            fabricMeta: body,
            loaderVersion: loaderVersion)
        ._ready();
  }

  Future<FabricClient> getFabricLibrary() async {
    /*    PackageName example: (abc.ab.com)
    name: PackageName:JarName:JarVersion
    url: https://maven.fabricmc.net
     */

    await Future.forEach(fabricMeta["libraries"].cast<Map>(), (Map lib) async {
      Map result = await Uttily.parseLibMaven(lib);
      Libraries _lib = instance.config.libraries;

      _lib.add(Library(
          name: lib["name"],
          downloads: LibraryDownloads(
              artifact: Artifact(
            url: result["Url"],
            sha1: result["Sha1Hash"],
            path: result["Path"],
          ))));

      instance.config.libraries = _lib;

      List<String> _ = [GameRepository.getLibraryGlobalDir().path];
      _.addAll(split(result["Path"]));

      infos.add(DownloadInfo(result["Url"],
          savePath: join(
            joinAll(_),
          ),
          description: I18n.format('version.list.downloading.fabric.library')));
    });
    return this;
  }

  Future getFabricArgs() async {
    File vanillaArgsFile =
        GameRepository.getArgsFile(versionID, ModLoaders.vanilla);
    File fabricArgsFile =
        GameRepository.getArgsFile(versionID, ModLoaders.fabric, loaderVersion: loaderVersion);
    Map argsObject = await json.decode(vanillaArgsFile.readAsStringSync());
    argsObject["mainClass"] = fabricMeta["mainClass"];
    fabricArgsFile
      ..createSync(recursive: true)
      ..writeAsStringSync(json.encode(argsObject));
  }

  Future<FabricClient> _ready() async {
    await handler.install();
    setState(() {
      nowEvent = I18n.format('version.list.downloading.fabric.args');
    });
    await getFabricArgs();
    await getFabricLibrary();
    await infos.downloadAll(onReceiveProgress: (_progress) {
      setState(() {});
    });
    return this;
  }
}
