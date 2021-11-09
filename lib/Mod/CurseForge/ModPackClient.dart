import 'dart:io';

import 'package:rpmlauncher/Launcher/Fabric/FabricClient.dart';
import 'package:rpmlauncher/Launcher/Forge/ForgeClient.dart';
import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Launcher/MinecraftClient.dart';
import 'package:rpmlauncher/Model/Game/MinecraftMeta.dart';
import 'package:rpmlauncher/Model/IO/DownloadInfo.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Model/Game/Instance.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

import 'Handler.dart';

class CurseModPackClient extends MinecraftClient {
  int totalAddonFiles = 0;
  int parsedAddonFiles = 0;
  int downloadedAddonFiles = 0;

  @override
  MinecraftClientHandler handler;

  CurseModPackClient._init(
      {required Map packMeta,
      required this.handler,
      required String loaderVersion,
      required String instanceUUID,
      required Archive packArchive});

  static Future<CurseModPackClient> createClient(
      {required MinecraftMeta meta,
      required Map packMeta,
      required String versionID,
      required String instanceUUID,
      required setState,
      required String loaderVersion,
      required Archive packArchive}) async {
    return await CurseModPackClient._init(
            handler: MinecraftClientHandler(
              meta: meta,
              versionID: versionID,
              instance: Instance(instanceUUID),
              setState: setState,
            ),
            loaderVersion: loaderVersion,
            instanceUUID: instanceUUID,
            packMeta: packMeta,
            packArchive: packArchive)
        ._ready(meta, packMeta, versionID, instanceUUID, packArchive,
            loaderVersion);
  }

  Future<void> getAddonFiles(Map packMeta, String instanceUUID) async {
    List<Map> addonFiles = packMeta["files"].cast<Map>();
    totalAddonFiles = addonFiles.length;
    return await Future.forEach(addonFiles, (Map file) async {
      if (!file["required"]) return; //如果非必要檔案則不下載

      Map fileInfo = await CurseForgeHandler.getFileInfo(
          file["projectID"], file["fileID"]);

      late Directory filepath;
      String fileName = fileInfo["fileName"];
      if (path.extension(fileName) == ".jar") {
        //類別為模組
        filepath = InstanceRepository.getModRootDir(instanceUUID);
      } else if (path.extension(fileName) == ".zip") {
        //類別為資源包
        filepath = InstanceRepository.getResourcePackRootDir(instanceUUID);
      }

      infos.add(DownloadInfo(fileInfo["downloadUrl"],
          savePath: path.join(filepath.absolute.path, fileInfo["fileName"]),
          onDownloaded: () {
        setState(() {
          downloadedAddonFiles++;
          nowEvent = "下載模組包資源中... ( $downloadedAddonFiles/$totalAddonFiles )";
        });
      }));

      parsedAddonFiles++;

      setState(() {
        nowEvent = "取得模組包資源中... ( $parsedAddonFiles/$totalAddonFiles )";
      });
    });
  }

  Future<void> overrides(
      Map packMeta, String instanceUUID, Archive packArchive) async {
    final String overridesDir = packMeta["overrides"];
    final String instanceDir =
        InstanceRepository.getInstanceDir(instanceUUID).absolute.path;

    for (ArchiveFile file in packArchive) {
      if (file.toString().startsWith(overridesDir)) {
        final data = file.content as List<int>;
        if (file.isFile) {
          File(instanceDir +
              Uttily.split(file.name, overridesDir, max: 1).join(""))
            ..createSync(recursive: true)
            ..writeAsBytes(data);
        } else {
          Directory(instanceDir +
                  Uttily.split(file.name, overridesDir, max: 1).join(""))
              .create(recursive: true);
        }
      }
    }
  }

  Future<CurseModPackClient> _ready(MinecraftMeta meta, Map packMeta, String versionID,
      String instanceUUID, Archive packArchive, String loaderVersion) async {
    String loaderID = packMeta["minecraft"]["modLoaders"][0]["id"];
    bool isFabric = loaderID.startsWith(ModLoaders.fabric.fixedString);
    bool isForge = loaderID.startsWith(ModLoaders.forge.fixedString);

    if (isFabric) {
      await FabricClient.createClient(
          setState: setState,
          meta: meta,
          versionID: versionID,
          loaderVersion: loaderVersion,
          instance: Instance(instanceUUID));
    } else if (isForge) {
      await ForgeClient.createClient(
          setState: setState,
          meta: meta,
          gameVersionID: versionID,
          forgeVersionID: loaderVersion,
          instance: Instance(instanceUUID));
    }
    nowEvent = "取得模組包資源中...";
    setState(() {});
    await getAddonFiles(packMeta, instanceUUID);
    await infos.downloadAll(onReceiveProgress: (_progress) {
      setState(() {});
    });
    nowEvent = "處理模組包資源中...";
    await overrides(packMeta, instanceUUID, packArchive);

    finish = true;
    return this;
  }
}
