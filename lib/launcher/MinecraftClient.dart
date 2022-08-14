import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:rpmlauncher/launcher/GameRepository.dart';
import 'package:rpmlauncher/launcher/InstallingState.dart';
import 'package:rpmlauncher/model/Game/Libraries.dart';
import 'package:archive/archive.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/model/Game/MinecraftMeta.dart';
import 'package:rpmlauncher/model/Game/MinecraftSide.dart';
import 'package:rpmlauncher/model/IO/download_info.dart';
import 'package:rpmlauncher/mod/mod_loader.dart';
import 'package:rpmlauncher/model/Game/instance.dart';
import 'package:rpmlauncher/util/i18n.dart';
import 'package:rpmlauncher/util/logger.dart';
import 'package:rpmlauncher/util/data.dart';

import 'Arguments.dart';

abstract class MinecraftClient {
  MinecraftMeta get meta => handler.meta;

  MinecraftClientHandler get handler;

  StateSetter get setState => handler.setState;

  Instance get instance => handler.instance;

  String get versionID => handler.versionID;
}

class MinecraftClientHandler {
  final MinecraftMeta meta;
  final String versionID;
  final StateSetter setState;
  final Instance instance;

  MinecraftClientHandler(
      {required this.meta,
      required this.versionID,
      required this.setState,
      required this.instance});

  void clientJar() {
    installingState.downloadInfos.add(DownloadInfo(
        meta.rawMeta["downloads"]["client"]["url"],
        savePath: join(
            dataHome.absolute.path, "versions", versionID, "$versionID.jar"),
        sh1Hash: meta.rawMeta["downloads"]["client"]["sha1"],
        description: I18n.format('version.list.downloading.main')));
  }

  Future<void> getArgs() async {
    File argsFile = GameRepository.getArgsFile(
        versionID, ModLoader.vanilla, MinecraftSide.client);
    await argsFile.create(recursive: true);
    await argsFile
        .writeAsString(json.encode(Arguments().getArgsString(versionID, meta)));
  }

  Future<void> getAssets() async {
    final url = Uri.parse(meta.rawMeta["assetIndex"]["url"]);
    Response response = await get(url);
    Map<String, dynamic> body = json.decode(response.body);
    File indexFile = File(join(dataHome.absolute.path, "assets", "indexes",
        "${meta.rawMeta["assets"]}.json"))
      ..createSync(recursive: true);
    indexFile.writeAsStringSync(response.body);
    for (var i in body["objects"].keys) {
      String hash = body["objects"][i]["hash"].toString();

      installingState.downloadInfos.add(DownloadInfo(
          "https://resources.download.minecraft.net/${hash.substring(0, 2)}/$hash",
          savePath: GameRepository.getAssetsObjectFile(hash).path,
          sh1Hash: hash,
          hashCheck: true,
          description: I18n.format('version.list.downloading.assets')));
    }
  }

  void getLib() {
    Libraries libraries = Libraries.fromList(meta.rawMeta["libraries"]);
    instance.config.libraries = libraries;

    for (Library lib in libraries) {
      if (lib.need) {
        if (lib.downloads.classifiers != null) {
          Classifiers classifiers = lib.downloads.classifiers!;
          downloadNatives(
              classifiers.path, classifiers.url, classifiers.sha1, versionID);
        }

        Artifact? artifact = lib.downloads.artifact;
        if (artifact != null) {
          if (lib.name.contains('natives')) {
            downloadNatives(
                artifact.path, artifact.url, artifact.sha1, versionID);
          } else {
            installingState.downloadInfos.add(DownloadInfo(artifact.url,
                savePath: artifact.localFile.path,
                sh1Hash: artifact.sha1,
                hashCheck: true,
                description: I18n.format('version.list.downloading.library')));
          }
        }
      }
    }
  }

  void downloadNatives(String path, String url, String? sha1, version) {
    List split_ = path.split("/");
    installingState.downloadInfos.add(DownloadInfo(url,
        savePath: join(GameRepository.getNativesDir(version).absolute.path,
            split_[split_.length - 1]),
        sh1Hash: sha1,
        hashCheck: true,
        description: I18n.format('version.list.downloading.library'),
        onDownloaded: () {
      handlingNativesJar(split_[split_.length - 1],
          GameRepository.getNativesDir(version).absolute.path);
    }));
  }

  void handlingNativesJar(String fileName, dir) {
    File file = File(join(dir, fileName));

    try {
      final bytes = file.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive.files) {
        final filePath = file.name;
        if (filePath.contains("META-INF")) continue;
        if (file.isFile) {
          if (filePath.endsWith(".git") || filePath.endsWith(".sha1")) {
            continue;
          }
          final data = file.content as List<int>;
          File(join(dir, filePath))
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          Directory(join(dir, filePath)).create(recursive: true);
        }
      }
    } on ArchiveException {
      logger.error(ErrorType.io, "failed to decompress natives library jar");
    } on FileSystemException {
      logger.error(ErrorType.io, "failed to open natives library jar");
    } catch (e, stackTrace) {
      logger.error(ErrorType.unknown, e, stackTrace: stackTrace);
    }
    try {
      file.deleteSync(recursive: true);
    } catch (e) {}
  }

  Future<void> handlingLogging() async {
    if (meta.containsKey('logging') && meta['logging'].containsKey('client')) {
      Map logging = meta['logging']['client'];
      if (logging.containsKey('file')) {
        Map file = logging['file'];
        String url = file['url'];
        String sha1 = file['sha1'];
        installingState.downloadInfos.add(DownloadInfo(url,
            savePath: GameRepository.getAssetsObjectFile(sha1).path,
            sh1Hash: sha1,
            hashCheck: true,
            description: I18n.format('version.list.downloading.logging')));
      }
    }
  }

  Future<MinecraftClientHandler> install() async {
    getLib();
    clientJar();
    await getAssets();
    await handlingLogging();
    await installingState.downloadInfos.downloadAll(
        onReceiveProgress: (progress) {
      try {
        setState(() {});
      } catch (e) {}
    });
    try {
      setState(() {
        installingState.nowEvent = I18n.format('version.list.downloading.args');
      });
    } catch (e) {}
    await getArgs();
    return this;
  }
}
