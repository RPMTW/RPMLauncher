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
    required Map versionInfo,
    required Map packData,
    required String instanceDirName,
    required StateSetter setState,
  });

  static Future<FTBModPackClient> createClient({
    required Map meta,
    required Map versionInfo,
    required Map packData,
    required String instanceDirName,
    required StateSetter setState,
  }) async {
    return await FTBModPackClient._init(
      versionInfo: versionInfo,
      packData: packData,
      instanceDirName: instanceDirName,
      setState: setState,
    )._ready(meta, versionInfo, packData, instanceDirName, setState);
  }

  Future<void> getFiles(Map versionInfo, instanceDirName) async {
    for (Map file in versionInfo["files"]) {
      if (!file["serveronly"] == true) return; //如果非必要檔案則不下載 (目前RWL僅支援客戶端安裝)

      final String filepath = file['path'].toString().replaceFirst('./',
          InstanceRepository.getInstanceDir(instanceDirName).absolute.path);
      final String fileName = file["name"];

      infos.add(DownloadInfo(file["url"],
          savePath: join(filepath, fileName),
          sh1Hash: file["sha1"],
          hashCheck: true));
    }
  }

  Future<FTBModPackClient> _ready(Map meta, Map versionInfo, packData,
      instanceDirName, StateSetter setState) async {
    String versionID = versionInfo["targets"][1]["version"];
    String loaderID = versionInfo["targets"][0]["name"];
    String loaderVersionID = versionInfo["targets"][0]["version"];
    bool isFabric = loaderID.startsWith(ModLoaders.fabric.fixedString);
    bool isForge = loaderID.startsWith(ModLoaders.forge.fixedString);

    if (isFabric) {
      await FabricClient.createClient(
        setState: setState,
        meta: meta,
        versionID: versionID,
        loaderVersion: loaderVersionID,
        instance: Instance(instanceDirName),
      );
    } else if (isForge) {
      await ForgeClient.createClient(
          setState: setState,
          meta: meta,
          gameVersionID: versionID,
          forgeVersionID: loaderVersionID,
          instance: Instance(instanceDirName));
    }
    nowEvent = "下載模組包檔案中";
    await getFiles(versionInfo, instanceDirName);
    await infos.downloadAll(onReceiveProgress: (_progress) {
      setState(() {});
    });
    finish = true;
    return this;
  }
}
