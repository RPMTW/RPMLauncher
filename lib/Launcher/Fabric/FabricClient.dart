// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rpmlauncher/Launcher/Fabric/FabricAPI.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Model/Libraries.dart';
import 'package:rpmlauncher/Model/DownloadInfo.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Model/Instance.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:path/path.dart';

import '../MinecraftClient.dart';

class FabricClient extends MinecraftClient {
  Map fabricMeta;
  String loaderVersion;

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
      NowEvent = "正在解析Fabric數據資料";
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
        ._Ready();
  }

  Future<FabricClient> getFabricLibrary() async {
    /*    PackageName example: (abc.ab.com)
    name: PackageName:JarName:JarVersion
    url: https://maven.fabricmc.net
     */

    await Future.forEach(fabricMeta["libraries"].cast<Map>(), (Map lib) async {
      Map Result = await utility.ParseLibMaven(lib);
      Libraries _lib = instance.config.libraries;

      _lib.add(Library(
          name: lib["name"],
          downloads: LibraryDownloads(
              artifact: Artifact(
            url: Result["Url"],
            sha1: Result["Sha1Hash"],
            path: Result["Path"],
          ))));

      instance.config.libraries = _lib;

      List<String> _ = [GameRepository.getLibraryGlobalDir().path];
      _.addAll(split(Result["Path"]));

      infos.add(DownloadInfo(Result["Url"],
          savePath: join(
            joinAll(_),
          ),
          description: i18n.format('version.list.downloading.fabric.library')));
    });
    return this;
  }

  Future getFabricArgs() async {
    File VanillaArgsFile =
        GameRepository.getArgsFile(versionID, ModLoaders.Vanilla);
    File FabricArgsFile =
        GameRepository.getArgsFile(versionID, ModLoaders.Fabric, loaderVersion);
    Map ArgsObject = await json.decode(VanillaArgsFile.readAsStringSync());
    ArgsObject["mainClass"] = fabricMeta["mainClass"];
    FabricArgsFile
      ..createSync(recursive: true)
      ..writeAsStringSync(json.encode(ArgsObject));
  }

  Future<FabricClient> _Ready() async {
    await handler.Install();
    setState(() {
      NowEvent = i18n.format('version.list.downloading.fabric.args');
    });
    await this.getFabricArgs();
    await this.getFabricLibrary();
    await infos.downloadAll(onReceiveProgress: (_progress) {
      setState(() {});
    });
    return this;
  }
}
