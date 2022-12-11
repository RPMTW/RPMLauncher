import 'dart:io';

import 'package:quiver/iterables.dart';
import 'package:rpmlauncher/launcher/Fabric/FabricClient.dart';
import 'package:rpmlauncher/launcher/Forge/ForgeClient.dart';
import 'package:rpmlauncher/launcher/InstallingState.dart';
import 'package:rpmlauncher/launcher/InstanceRepository.dart';
import 'package:rpmlauncher/launcher/MinecraftClient.dart';
import 'package:rpmlauncher/model/Game/MinecraftMeta.dart';
import 'package:rpmlauncher/model/IO/download_info.dart';
import 'package:rpmlauncher/mod/mod_loader.dart';
import 'package:rpmlauncher/model/Game/instance.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/util/logger.dart';
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

  CurseForgeModpackClient._init({required this.handler});

  static Future<CurseForgeModpackClient> createClient(
      {required MinecraftMeta meta,
      required Map manifest,
      required Instance instance,
      required setState,
      required Archive archive}) async {
    InstanceConfig config = instance.config;

    return await CurseForgeModpackClient._init(
      handler: MinecraftClientHandler(
        meta: meta,
        versionID: config.version,
        instance: instance,
        setState: setState,
      ),
    )._ready(meta, manifest, archive);
  }

  Future<void> getFileInfo(Map file, String instanceUUID) async {
    int projectID = file['projectID'];
    int fileID = file['fileID'];
    bool required = file['required'] ?? true;
    if (!required) return; // skip optional files

    CurseForgeModFile? fileInfo;
    try {
      fileInfo = await RPMTWApiClient.instance.curseforgeResource
          .getModFile(projectID, fileID);
    } catch (e) {
      fileInfo = null;
    }

    if (fileInfo != null) {
      String fileName = fileInfo.fileName;
      Directory? filePath;

      if (path.extension(fileName) == '.jar') {
        // The file maybe is mod
        filePath = InstanceRepository.getModRootDir(instanceUUID);
      } else if (path.extension(fileName) == '.zip') {
        // The file maybe is a resourcepack
        filePath = InstanceRepository.getResourcePackRootDir(instanceUUID);
      } else {
        logger.error(ErrorType.modpack, 'Unknown file type: $fileName');
        return;
      }

      installingState.downloadInfos.add(DownloadInfo(fileInfo.downloadUrl,
          savePath: path.join(filePath.path, fileInfo.fileName),
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
      logger.error(ErrorType.modpack,
          'Cannot find file from CurseForge (modId: $projectID, fileId: $fileID)');
    }

    parsedAddonFiles++;

    setState(() {
      installingState.nowEvent = I18n.format('modpack.getting.assets.progress',
          args: {'parsed': parsedAddonFiles, 'total': totalAddonFiles});
    });
  }

  Future<void> getAddonFiles(Map manifest, String instanceUUID) async {
    List<Map> addonFiles = manifest['files'].cast<Map>();

    totalAddonFiles = addonFiles.length;

    final queue = partition(addonFiles, 15).toList();
    // Async queue to get addon files info
    for (final item in queue) {
      await Future.wait(item.map((file) => getFileInfo(file, instanceUUID)));
    }
  }

  Future<void> overrides(
      Map packMeta, String instanceUUID, Archive packArchive) async {
    final String overridesDir = packMeta['overrides'];
    final String instanceDir =
        InstanceRepository.getInstanceDir(instanceUUID).path;

    for (ArchiveFile file in packArchive) {
      final String path =
          instanceDir + Util.split(file.name, overridesDir, max: 1).join('');

      if (file.toString().startsWith(overridesDir)) {
        final data = file.content as List<int>;
        if (file.isFile) {
          File(path)
            ..createSync(recursive: true)
            ..writeAsBytes(data);
        } else {
          Directory(path).create(recursive: true);
        }
      }
    }
  }

  Future<CurseForgeModpackClient> _ready(
      MinecraftMeta meta, Map manifest, Archive archive) async {
    final InstanceConfig config = handler.instance.config;
    final ModLoader loader = config.loaderEnum;

    if (loader == ModLoader.fabric) {
      await FabricClient.createClient(
          setState: setState,
          meta: meta,
          versionID: config.version,
          loaderVersion: config.loaderVersion!,
          instance: handler.instance);
    } else {
      await ForgeClient.createClient(
              setState: setState,
              meta: meta,
              gameVersionID: config.version,
              forgeVersionID: config.loaderVersion!,
              instance: handler.instance)
          .then((ForgeClientState state) => state.handlerState(
              navigator.context, setState, instance,
              notFinal: true));
    }

    installingState.nowEvent = I18n.format('modpack.getting.assets');
    setState(() {});
    await getAddonFiles(manifest, config.uuid);
    await installingState.downloadInfos.downloadAll(
        onReceiveProgress: (progress) {
      setState(() {});
    });
    installingState.nowEvent = I18n.format('modpack.downloading.assets');
    await overrides(manifest, config.uuid, archive);

    installingState.finish = true;
    return this;
  }
}
