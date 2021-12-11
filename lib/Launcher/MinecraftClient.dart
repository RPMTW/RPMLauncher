import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Model/Game/Libraries.dart';
import 'package:archive/archive.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Model/Game/MinecraftMeta.dart';
import 'package:rpmlauncher/Model/IO/DownloadInfo.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Model/Game/Instance.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/Logger.dart';
import 'package:rpmlauncher/Utility/Data.dart';

import 'Arguments.dart';

DownloadInfos infos = DownloadInfos.empty();
String nowEvent = I18n.format('version.list.downloading.ready');
bool finish = false;

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
    infos.add(DownloadInfo(meta.rawMeta["downloads"]["client"]["url"],
        savePath: join(
            dataHome.absolute.path, "versions", versionID, "$versionID.jar"),
        sh1Hash: meta.rawMeta["downloads"]["client"]["sha1"],
        description: I18n.format('version.list.downloading.main')));
  }

  Future<void> getArgs() async {
    File argsFile = GameRepository.getArgsFile(versionID, ModLoader.vanilla);
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

      infos.add(DownloadInfo(
          "https://resources.download.minecraft.net/${hash.substring(0, 2)}/$hash",
          savePath: GameRepository.getAssetsObjectFile(hash).path,
          sh1Hash: hash,
          hashCheck: true,
          description: I18n.format('version.list.downloading.assets')));
    }
  }

  void getLib() {
    Libraries _libs = Libraries.fromList(meta.rawMeta["libraries"]);
    instance.config.libraries = _libs;

    for (Library lib in _libs) {
      if (lib.need) {
        if (lib.downloads.classifiers != null) {
          downloadNatives(lib.downloads.classifiers!, versionID);
        }

        Artifact? artifact = lib.downloads.artifact;
        if (artifact != null) {
          infos.add(DownloadInfo(artifact.url,
              savePath: artifact.localFile.path,
              sh1Hash: artifact.sha1,
              hashCheck: true,
              description: I18n.format('version.list.downloading.library')));
        }
      }
    }
  }

  void downloadNatives(Classifiers classifiers, version) {
    List split_ = classifiers.path.split("/");
    infos.add(DownloadInfo(classifiers.url,
        savePath: join(GameRepository.getNativesDir(version).absolute.path,
            split_[split_.length - 1]),
        sh1Hash: classifiers.sha1,
        hashCheck: true,
        description: I18n.format('version.list.downloading.library'),
        onDownloaded: () {
      handlingNativesJar(split_[split_.length - 1],
          GameRepository.getNativesDir(version).absolute.path);
    }));
  }

  void handlingNativesJar(String fileName, dir_) {
    File file = File(join(dir_, fileName));

    try {
      final bytes = file.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive.files) {
        final _fileName = file.name;
        if (_fileName.contains("META-INF")) continue;
        if (file.isFile) {
          if (_fileName.endsWith(".git") || _fileName.endsWith(".sha1")) {
            continue;
          }
          final data = file.content as List<int>;
          File(join(dir_, _fileName))
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          Directory(join(dir_, _fileName)).create(recursive: true);
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
        infos.add(DownloadInfo(url,
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
    await infos.downloadAll(onReceiveProgress: (_progress) {
      try {
        setState(() {});
      } catch (e) {}
    });
    try {
      setState(() {
        nowEvent = I18n.format('version.list.downloading.args');
      });
    } catch (e) {}
    await getArgs();
    return this;
  }
}
