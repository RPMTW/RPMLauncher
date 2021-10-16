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
    required String instanceDirName,
    required StateSetter SetState,
  });

  static Future<FTBModPackClient> createClient({
    required Map Meta,
    required Map VersionInfo,
    required Map PackData,
    required String instanceDirName,
    required StateSetter SetState,
  }) async {
    return await FTBModPackClient._init(
      VersionInfo: VersionInfo,
      PackData: PackData,
      instanceDirName: instanceDirName,
      SetState: SetState,
    )._Ready(Meta, VersionInfo, PackData, instanceDirName, SetState);
  }

  Future<void> getFiles(Map VersionInfo, instanceDirName) async {
    for (Map file in VersionInfo["files"]) {
      if (!file["serveronly"] == true) return; //如果非必要檔案則不下載 (目前RWL僅支援客戶端安裝)

      final String Filepath = file['path'].toString().replaceFirst('./',
          InstanceRepository.getInstanceDir(instanceDirName).absolute.path);
      final String FileName = file["name"];

      infos.add(DownloadInfo(file["url"],
          savePath: join(Filepath, FileName),
          sh1Hash: file["sha1"],
          hashCheck: true));
    }
  }

  Future<FTBModPackClient> _Ready(Meta, VersionInfo, PackData, instanceDirName,
      StateSetter setState) async {
    String versionID = VersionInfo["targets"][1]["version"];
    String LoaderID = VersionInfo["targets"][0]["name"];
    String loaderVersionID = VersionInfo["targets"][0]["version"];
    bool isFabric = LoaderID.startsWith(ModLoaders.fabric.fixedString);
    bool isForge = LoaderID.startsWith(ModLoaders.forge.fixedString);

    if (isFabric) {
      await FabricClient.createClient(
        setState: setState,
        meta: Meta,
        versionID: versionID,
        loaderVersion: loaderVersionID,
        instance: Instance(instanceDirName),
      );
    } else if (isForge) {
      await ForgeClient.createClient(
          setState: setState,
          meta: Meta,
          gameVersionID: versionID,
          forgeVersionID: loaderVersionID,
          instance: Instance(instanceDirName));
    }
    NowEvent = "下載模組包檔案中";
    await getFiles(VersionInfo, instanceDirName);
    await infos.downloadAll(onReceiveProgress: (_progress) {
      setState(() {});
    });
    finish = true;
    return this;
  }
}
