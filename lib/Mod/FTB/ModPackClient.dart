// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Launcher/Fabric/FabricClient.dart';
import 'package:rpmlauncher/Launcher/Forge/ForgeClient.dart';
import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Launcher/MinecraftClient.dart';
import 'package:rpmlauncher/Model/DownloadInfo.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Model/Instance.dart';

class FTBModPackClient {
  FTBModPackClient._init({
    required Map VersionInfo,
    required Map PackData,
    required String InstanceDirName,
    required StateSetter SetState,
  });

  static Future<FTBModPackClient> createClient({
    required Map Meta,
    required Map VersionInfo,
    required Map PackData,
    required String InstanceDirName,
    required StateSetter SetState,
  }) async {
    return await FTBModPackClient._init(
      VersionInfo: VersionInfo,
      PackData: PackData,
      InstanceDirName: InstanceDirName,
      SetState: SetState,
    )._Ready(Meta, VersionInfo, PackData, InstanceDirName, SetState);
  }

  Future<void> getFiles(Map VersionInfo, InstanceDirName) async {
    for (Map file in VersionInfo["files"]) {
      if (!file["serveronly"] == true) return; //如果非必要檔案則不下載 (目前RWL僅支援客戶端安裝)

      final String Filepath = file['path'].toString().replaceFirst('./',
          InstanceRepository.getInstanceDir(InstanceDirName).absolute.path);
      final String FileName = file["name"];

      infos.add(DownloadInfo(file["url"],
          savePath: join(Filepath, FileName),
          sh1Hash: file["sha1"],
          hashCheck: true));
    }
  }

  Future<FTBModPackClient> _Ready(Meta, VersionInfo, PackData, InstanceDirName,
      StateSetter setState) async {
    String VersionID = VersionInfo["targets"][1]["version"];
    String LoaderID = VersionInfo["targets"][0]["name"];
    String LoaderVersionID = VersionInfo["targets"][0]["version"];
    bool isFabric = LoaderID.startsWith(ModLoaders.Fabric.fixedString);
    bool isForge = LoaderID.startsWith(ModLoaders.Forge.fixedString);

    if (isFabric) {
      await FabricClient.createClient(
        setState: setState,
        meta: Meta,
        versionID: VersionID,
        loaderVersion: LoaderVersionID,
        instance: Instance(InstanceDirName),
      );
    } else if (isForge) {
      await ForgeClient.createClient(
          setState: setState,
          meta: Meta,
          gameVersionID: VersionID,
          forgeVersionID: LoaderVersionID,
          instance: Instance(InstanceDirName));
    }
    NowEvent = "下載模組包檔案中";
    await getFiles(VersionInfo, InstanceDirName);
    await infos.downloadAll(onReceiveProgress: (_progress) {
      setState(() {});
    });
    finish = true;
    return this;
  }
}
