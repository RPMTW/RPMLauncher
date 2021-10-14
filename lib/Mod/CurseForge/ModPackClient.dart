// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rpmlauncher/Launcher/Fabric/FabricClient.dart';
import 'package:rpmlauncher/Launcher/Forge/ForgeClient.dart';
import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Launcher/MinecraftClient.dart';
import 'package:rpmlauncher/Model/DownloadInfo.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Model/Instance.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

import 'Handler.dart';

class CurseModPackClient extends MinecraftClient {
  MinecraftClientHandler handler;

  CurseModPackClient._init(
      {required Map PackMeta,
      required this.handler,
      required String LoaderVersion,
      required String InstanceDirName,
      required Archive PackArchive});

  static Future<CurseModPackClient> createClient(
      {required Map Meta,
      required Map PackMeta,
      required String VersionID,
      required String InstanceDirName,
      required setState,
      required String LoaderVersion,
      required Archive PackArchive}) async {
    return await CurseModPackClient._init(
            handler: MinecraftClientHandler(
              meta: Meta,
              versionID: VersionID,
              instance: Instance(InstanceDirName),
              setState: setState,
            ),
            LoaderVersion: LoaderVersion,
            InstanceDirName: InstanceDirName,
            PackMeta: PackMeta,
            PackArchive: PackArchive)
        ._Ready(Meta, PackMeta, VersionID, InstanceDirName, PackArchive,
            LoaderVersion, setState);
  }

  Future<void> getMods(Map PackMeta, InstanceDirName) async {
    return await Future.forEach(PackMeta["files"].cast<Map>(),
        (Map file) async {
      if (!file["required"]) return; //如果非必要檔案則不下載

      Map FileInfo = await CurseForgeHandler.getFileInfo(
          file["projectID"], file["fileID"]);

      late Directory Filepath;
      final String FileName = FileInfo["fileName"];
      if (path.extension(FileName) == ".jar") {
        //類別為模組
        Filepath = InstanceRepository.getModRootDir(InstanceDirName);
      } else if (path.extension(FileName) == ".zip") {
        //類別為資源包
        Filepath = InstanceRepository.getResourcePackRootDir(InstanceDirName);
      }

      infos.add(DownloadInfo(FileInfo["downloadUrl"],
          savePath: path.join(Filepath.absolute.path, FileInfo["fileName"]),
          description: "下載模組包資源中..."));
    });
  }

  Future<void> Overrides(Map PackMeta, InstanceDirName, PackArchive) async {
    final String OverridesDir = PackMeta["overrides"];
    final String InstanceDir =
        InstanceRepository.getInstanceDir(InstanceDirName).absolute.path;

    for (ArchiveFile file in PackArchive) {
      if (file.toString().startsWith(OverridesDir)) {
        final data = file.content as List<int>;
        if (file.isFile) {
          File(InstanceDir +
              utility.split(file.name, OverridesDir, max: 1).join(""))
            ..createSync(recursive: true)
            ..writeAsBytes(data);
        } else {
          Directory(InstanceDir +
                  utility.split(file.name, OverridesDir, max: 1).join(""))
              .create(recursive: true);
        }
      }
    }
  }

  Future<CurseModPackClient> _Ready(Meta, Map PackMeta, VersionID,
      String InstanceDirName, PackArchive, LoaderVersion, SetState) async {
    String LoaderID = PackMeta["minecraft"]["modLoaders"][0]["id"];
    bool isFabric = LoaderID.startsWith(ModLoaders.Fabric.fixedString);
    bool isForge = LoaderID.startsWith(ModLoaders.Forge.fixedString);

    if (isFabric) {
      await FabricClient.createClient(
          setState: setState,
          meta: Meta,
          versionID: VersionID,
          loaderVersion: LoaderVersion,
          instance: Instance(InstanceDirName));
    } else if (isForge) {
      await ForgeClient.createClient(
          setState: setState,
          meta: Meta,
          gameVersionID: VersionID,
          forgeVersionID: LoaderVersion,
          instance: Instance(InstanceDirName));
    }
    NowEvent = "取得模組包資源中...";
    SetState(() {});
    await getMods(PackMeta, InstanceDirName);
    await infos.downloadAll(onReceiveProgress: (_progress) {
      setState(() {});
    });
    NowEvent = "處理模組包資源中...";
    await Overrides(PackMeta, InstanceDirName, PackArchive)
        .then((value) => PackArchive = Null);

    finish = true;
    return this;
  }
}
