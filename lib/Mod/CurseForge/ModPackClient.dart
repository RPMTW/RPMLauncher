import 'dart:io';

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
  @override
  MinecraftClientHandler handler;

  CurseModPackClient._init(
      {required Map packMeta,
      required this.handler,
      required String loaderVersion,
      required String instanceDirName,
      required Archive packArchive});

  static Future<CurseModPackClient> createClient(
      {required Map meta,
      required Map packMeta,
      required String versionID,
      required String instanceDirName,
      required setState,
      required String loaderVersion,
      required Archive packArchive}) async {
    return await CurseModPackClient._init(
            handler: MinecraftClientHandler(
              meta: meta,
              versionID: versionID,
              instance: Instance(instanceDirName),
              setState: setState,
            ),
            loaderVersion: loaderVersion,
            instanceDirName: instanceDirName,
            packMeta: packMeta,
            packArchive: packArchive)
        ._ready(meta, packMeta, versionID, instanceDirName, packArchive,
            loaderVersion);
  }

  Future<void> getMods(Map packMeta, instanceDirName) async {
    return await Future.forEach(packMeta["files"].cast<Map>(),
        (Map file) async {
      if (!file["required"]) return; //如果非必要檔案則不下載

      Map fileInfo = await CurseForgeHandler.getFileInfo(
          file["projectID"], file["fileID"]);

      late Directory filepath;
      String fileName = fileInfo["fileName"];
      if (path.extension(fileName) == ".jar") {
        //類別為模組
        filepath = InstanceRepository.getModRootDir(instanceDirName);
      } else if (path.extension(fileName) == ".zip") {
        //類別為資源包
        filepath = InstanceRepository.getResourcePackRootDir(instanceDirName);
      }

      infos.add(DownloadInfo(fileInfo["downloadUrl"],
          savePath: path.join(filepath.absolute.path, fileInfo["fileName"]),
          description: "下載模組包資源中..."));
    });
  }

  Future<void> overrides(
      Map packMeta, String instanceDirName, Archive packArchive) async {
    final String OverridesDir = packMeta["overrides"];
    final String InstanceDir =
        InstanceRepository.getInstanceDir(instanceDirName).absolute.path;

    for (ArchiveFile file in packArchive) {
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

  Future<CurseModPackClient> _ready(Map meta, Map packMeta, String versionID,
      String instanceDirName, Archive packArchive, String loaderVersion) async {
    String loaderID = packMeta["minecraft"]["modLoaders"][0]["id"];
    bool isFabric = loaderID.startsWith(ModLoaders.fabric.fixedString);
    bool isForge = loaderID.startsWith(ModLoaders.forge.fixedString);

    if (isFabric) {
      await FabricClient.createClient(
          setState: setState,
          meta: meta,
          versionID: versionID,
          loaderVersion: loaderVersion,
          instance: Instance(instanceDirName));
    } else if (isForge) {
      await ForgeClient.createClient(
          setState: setState,
          meta: meta,
          gameVersionID: versionID,
          forgeVersionID: loaderVersion,
          instance: Instance(instanceDirName));
    }
    nowEvent = "取得模組包資源中...";
    setState(() {});
    await getMods(packMeta, instanceDirName);
    await infos.downloadAll(onReceiveProgress: (_progress) {
      setState(() {});
    });
    nowEvent = "處理模組包資源中...";
    await overrides(packMeta, instanceDirName, packArchive);

    finish = true;
    return this;
  }
}
