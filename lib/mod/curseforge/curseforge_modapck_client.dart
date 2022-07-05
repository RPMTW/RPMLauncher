import 'dart:io';

import 'package:rpmlauncher/launcher/Fabric/FabricClient.dart';
import 'package:rpmlauncher/launcher/Forge/ForgeClient.dart';
import 'package:rpmlauncher/launcher/InstallingState.dart';
import 'package:rpmlauncher/launcher/InstanceRepository.dart';
import 'package:rpmlauncher/launcher/MinecraftClient.dart';
import 'package:rpmlauncher/model/Game/MinecraftMeta.dart';
import 'package:rpmlauncher/model/IO/DownloadInfo.dart';
import 'package:rpmlauncher/mod/mod_loader.dart';
import 'package:rpmlauncher/model/Game/instance.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:rpmlauncher/util/Logger.dart';
import 'package:rpmlauncher/util/util.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmtw_api_client/rpmtw_api_client.dart' hide ModLoader;

class CurseForgeModpackClient extends MinecraftClient {
  int totalAddonFiles = 0;
  int parsedAddonFiles = 0;
  int downloadedAddonFiles = 0;

  @override
  MinecraftClientHandler handler;

  CurseForgeModpackClient._init(
      {required Map packMeta,
      required this.handler,
      required String loaderVersion,
      required String instanceUUID,
      required Archive packArchive});

  static Future<CurseForgeModpackClient> createClient(
      {required MinecraftMeta meta,
      required Map manifest,
      required String versionID,
      required String instanceUUID,
      required setState,
      required String loaderVersion,
      required Archive archive}) async {
    return await CurseForgeModpackClient._init(
            handler: MinecraftClientHandler(
              meta: meta,
              versionID: versionID,
              instance: Instance.fromUUID(instanceUUID)!,
              setState: setState,
            ),
            loaderVersion: loaderVersion,
            instanceUUID: instanceUUID,
            packMeta: manifest,
            packArchive: archive)
        ._ready(
            meta, manifest, versionID, instanceUUID, archive, loaderVersion);
  }

  Future<void> getAddonFiles(Map packMeta, String instanceUUID) async {
    List<Map> addonFiles = packMeta['files'].cast<Map>();
    totalAddonFiles = addonFiles.length;
    return await Future.forEach(addonFiles, (Map file) async {
      bool required = file['required'] ?? true;
      if (!required) return; //如果非必要檔案則不下載

      CurseForgeModFile? fileInfo;
      try {
        fileInfo = await RPMTWApiClient.instance.curseforgeResource
            .getModFile(file['projectID'], file['fileID']);
      } catch (e) {
        fileInfo = null;
      }

      late Directory filepath;

      if (fileInfo != null) {
        String fileName = fileInfo.fileName;
        if (path.extension(fileName) == '.jar') {
          //類別為模組
          filepath = InstanceRepository.getModRootDir(instanceUUID);
        } else if (path.extension(fileName) == '.zip') {
          //類別為資源包
          filepath = InstanceRepository.getResourcePackRootDir(instanceUUID);
        }

        installingState.downloadInfos.add(DownloadInfo(fileInfo.downloadUrl,
            savePath: path.join(filepath.absolute.path, fileInfo.fileName),
            onDownloaded: () {
          setState(() {
            downloadedAddonFiles++;
            installingState.nowEvent =
                I18n.format('modpack.downloading.assets.progress', args: {
              'downloaded': downloadedAddonFiles,
              'total': totalAddonFiles
            });
          });
        }));
      } else {
        logger.error(ErrorType.download,
            'cannot find file from curseforge api (modId: ${file['projectID']}, fileId: ${file['fileID']})');
      }

      parsedAddonFiles++;

      setState(() {
        installingState.nowEvent = I18n.format(
            'modpack.getting.assets.progress',
            args: {'parsed': parsedAddonFiles, 'total': totalAddonFiles});
      });
    });
  }

  Future<void> overrides(
      Map packMeta, String instanceUUID, Archive packArchive) async {
    final String overridesDir = packMeta['overrides'];
    final String instanceDir =
        InstanceRepository.getInstanceDir(instanceUUID).absolute.path;

    for (ArchiveFile file in packArchive) {
      if (file.toString().startsWith(overridesDir)) {
        final data = file.content as List<int>;
        if (file.isFile) {
          File(instanceDir +
              Util.split(file.name, overridesDir, max: 1).join(''))
            ..createSync(recursive: true)
            ..writeAsBytes(data);
        } else {
          Directory(instanceDir +
                  Util.split(file.name, overridesDir, max: 1).join(''))
              .create(recursive: true);
        }
      }
    }
  }

  Future<CurseForgeModpackClient> _ready(
      MinecraftMeta meta,
      Map packMeta,
      String versionID,
      String instanceUUID,
      Archive packArchive,
      String loaderVersion) async {
    String loaderID = packMeta['minecraft']['modLoaders'][0]['id'];
    bool isFabric = loaderID.startsWith(ModLoader.fabric.name);

    if (isFabric) {
      await FabricClient.createClient(
          setState: setState,
          meta: meta,
          versionID: versionID,
          loaderVersion: loaderVersion,
          instance: Instance.fromUUID(instanceUUID)!);
    } else {
      await ForgeClient.createClient(
              setState: setState,
              meta: meta,
              gameVersionID: versionID,
              forgeVersionID: loaderVersion,
              instance: Instance.fromUUID(instanceUUID)!)
          .then((ForgeClientState state) => state.handlerState(
              navigator.context, setState, instance,
              notFinal: true));
    }
    installingState.nowEvent = I18n.format('modpack.getting.assets');
    setState(() {});
    await getAddonFiles(packMeta, instanceUUID);
    await installingState.downloadInfos.downloadAll(
        onReceiveProgress: (progress) {
      setState(() {});
    });
    installingState.nowEvent = I18n.format('modpack.downloading.assets');
    await overrides(packMeta, instanceUUID, packArchive);

    installingState.finish = true;
    return this;
  }
}
